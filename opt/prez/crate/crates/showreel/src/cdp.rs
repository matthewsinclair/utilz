//! The DevTools protocol over `--remote-debugging-pipe` (ST0021).
//!
//! Chrome reads commands on its fd 3 and writes replies and events on its fd 4,
//! each message one JSON object ended by a NUL byte. That is the whole
//! transport: no port, no socket, no handshake, and no crate beyond the
//! serde_json showreel already carries.
//!
//! **A READER THREAD OWNS THE PIPE, AND EVERY WAIT HAS A WATCHDOG.** A blocking
//! read cannot time out in std, so the thread reads and the session waits on a
//! channel with a deadline. A reply that never comes is then a refusal naming
//! the step that stalled (AC-02.6), eg `during frame 63: screenshot`, rather
//! than a recording that hangs with nothing on the screen.
//!
//! **EVENTS THAT ARRIVE WHILE A REPLY IS AWAITED ARE KEPT, IN ORDER.** Chrome
//! interleaves the two freely, and the load event can land before the reply to
//! the call that caused it. `event` looks through what was kept before it reads
//! on.

use artifact::Failure;
use serde_json::{json, Value};
use std::collections::VecDeque;
use std::io::{ErrorKind, Read, Write};
use std::sync::mpsc::{self, Receiver, RecvTimeoutError, Sender};
use std::time::{Duration, Instant};

const RETRY: &str =
  "run it again; if it fails at the same step twice, report the step with Chrome's version";
const REPORT: &str = "report it with Chrome's version: the recording depends on this command";

/// What the reader thread hands the session: one per message, or the reason
/// it could not read one.
enum Heard {
  Message(Value),
  /// Bytes between two NULs that are not JSON, and how they begin.
  NotJson(serde_json::Error, String),
  /// The pipe could not be read. The thread stops after sending this.
  Unreadable(std::io::Error),
}

/// One DevTools connection: commands out, replies and events in.
pub struct Session<W: Write> {
  out: W,
  inbox: Receiver<Heard>,
  kept: VecDeque<Value>,
  next_id: u64,
  watchdog: Duration,
  step: String,
}

impl<W: Write> Session<W> {
  /// Starts the reader thread on `input`. `watchdog` bounds every wait.
  pub fn new<R: Read + Send + 'static>(out: W, input: R, watchdog: Duration) -> Self {
    let (tx, inbox) = mpsc::channel();
    std::thread::spawn(move || pump(input, &tx));
    Self {
      out,
      inbox,
      kept: VecDeque::new(),
      next_id: 0,
      watchdog,
      step: String::from("the start"),
    }
  }

  /// Names what the recording is doing, for any refusal that follows.
  pub fn step(&mut self, step: impl Into<String>) {
    self.step = step.into();
  }

  /// Everything written to Chrome so far.
  pub fn writer(&self) -> &W {
    &self.out
  }

  /// Sends one command and waits for its result.
  ///
  /// The watchdog covers the whole wait, not each message: a Chrome that keeps
  /// sending events and never replies is still a stall.
  pub fn call(
    &mut self,
    method: &str,
    params: Value,
    session: Option<&str>,
  ) -> Result<Value, Failure> {
    let id = self.send(method, params, session)?;
    let deadline = Instant::now() + self.watchdog;
    loop {
      let message = self.next(deadline)?;
      match message.get("id").and_then(Value::as_u64) {
        Some(got) if got == id => return reply(method, message),
        Some(got) => return Err(self.stray(got, method)),
        None => self.kept.push_back(message),
      }
    }
  }

  /// Sends one command without waiting for its reply, and returns its id. Only
  /// the shutdown wants this: `Browser.close` may take the pipe down before it
  /// answers, and what follows it does not depend on the answer.
  pub fn send(
    &mut self,
    method: &str,
    params: Value,
    session: Option<&str>,
  ) -> Result<u64, Failure> {
    self.next_id += 1;
    let id = self.next_id;
    let mut message = json!({ "id": id, "method": method, "params": params });
    if let Some(session) = session {
      message["sessionId"] = json!(session);
    }
    let mut bytes = message.to_string().into_bytes();
    bytes.push(0);
    match self.out.write_all(&bytes).and_then(|()| self.out.flush()) {
      Ok(()) => Ok(id),
      Err(e) => Err(self.closed(&format!(" ({e})"))),
    }
  }

  /// Evaluates `expression` in the page, awaiting it when it is a promise, and
  /// returns its value. An exception in the page is a refusal naming the step.
  pub fn evaluate(&mut self, expression: &str, session: Option<&str>) -> Result<Value, Failure> {
    let params = json!({ "expression": expression, "awaitPromise": true, "returnByValue": true });
    let mut result = self.call("Runtime.evaluate", params, session)?;
    if let Some(thrown) = result.get("exceptionDetails") {
      let said = thrown
        .pointer("/exception/description")
        .or_else(|| thrown.get("text"))
        .and_then(Value::as_str)
        .unwrap_or("no description");
      return Err(Failure::new(
        format!("the reel's page threw during {}: {said}", self.step),
        REPORT,
      ));
    }
    Ok(
      result
        .pointer_mut("/result/value")
        .map(Value::take)
        .unwrap_or(Value::Null),
    )
  }

  /// Waits for an event, first among those kept while replies were awaited.
  /// With a `session`, an event from any other session does not match.
  pub fn event(&mut self, method: &str, session: Option<&str>) -> Result<Value, Failure> {
    let at = self.kept.iter().position(|m| is_event(m, method, session));
    if let Some(found) = at.and_then(|at| self.kept.remove(at)) {
      return Ok(found);
    }
    let deadline = Instant::now() + self.watchdog;
    loop {
      let message = self.next(deadline)?;
      if is_event(&message, method, session) {
        return Ok(message);
      }
      if let Some(got) = message.get("id").and_then(Value::as_u64) {
        return Err(self.stray(got, method));
      }
      self.kept.push_back(message);
    }
  }

  /// Whether an event is among those already kept. It never waits, so what it
  /// answers depends only on what was read, in order, and not on timing.
  pub fn seen(&self, method: &str, session: Option<&str>) -> bool {
    self.kept.iter().any(|m| is_event(m, method, session))
  }

  /// Waits up to `grace` for Chrome to close its end of the pipe, and says
  /// whether it did. Anything Chrome sends meanwhile is set aside unread: this
  /// runs once the recording is over, when nothing it could say changes what
  /// happens next.
  pub fn closes_within(&mut self, grace: Duration) -> bool {
    let deadline = Instant::now() + grace;
    loop {
      let left = deadline.saturating_duration_since(Instant::now());
      match self.inbox.recv_timeout(left) {
        Ok(_) => continue,
        Err(RecvTimeoutError::Disconnected) => return true,
        Err(RecvTimeoutError::Timeout) => return false,
      }
    }
  }

  fn next(&mut self, deadline: Instant) -> Result<Value, Failure> {
    let left = deadline.saturating_duration_since(Instant::now());
    match self.inbox.recv_timeout(left) {
      Ok(Heard::Message(message)) => Ok(message),
      Ok(Heard::NotJson(e, head)) => Err(Failure::new(
        format!(
          "Chrome sent a message that is not JSON, during {}: {e}: {head}",
          self.step
        ),
        REPORT,
      )),
      Ok(Heard::Unreadable(e)) => Err(Failure::new(
        format!(
          "the DevTools pipe could not be read during {}: {e}",
          self.step
        ),
        RETRY,
      )),
      Err(RecvTimeoutError::Timeout) => Err(Failure::new(
        format!(
          "no reply from Chrome in {} s, during {}",
          self.watchdog.as_secs_f64(),
          self.step
        ),
        RETRY,
      )),
      Err(RecvTimeoutError::Disconnected) => Err(self.closed("")),
    }
  }

  fn closed(&self, detail: &str) -> Failure {
    Failure::new(
      format!(
        "Chrome closed the DevTools pipe during {}{detail}",
        self.step
      ),
      RETRY,
    )
  }

  fn stray(&self, got: u64, waiting: &str) -> Failure {
    Failure::new(
      format!(
        "Chrome answered message {got}, which is not the one waiting, during {}: {waiting}",
        self.step
      ),
      REPORT,
    )
  }
}

/// A reply's result, or its error as a refusal naming the method.
fn reply(method: &str, mut message: Value) -> Result<Value, Failure> {
  if let Some(error) = message.get("error") {
    let said = error
      .get("message")
      .and_then(Value::as_str)
      .unwrap_or("no message");
    return Err(Failure::new(
      format!("Chrome refused {method}: {said}"),
      REPORT,
    ));
  }
  Ok(
    message
      .get_mut("result")
      .map(Value::take)
      .unwrap_or(Value::Null),
  )
}

fn is_event(message: &Value, method: &str, session: Option<&str>) -> bool {
  message.get("method").and_then(Value::as_str) == Some(method)
    && session.is_none_or(|s| message.get("sessionId").and_then(Value::as_str) == Some(s))
}

/// Appends `chunk` to `partial` and returns every message it completed. Each
/// byte is scanned once, because a screenshot arrives as megabytes of base64
/// over many reads and rescanning the whole of it on every read is quadratic.
pub fn split_messages(partial: &mut Vec<u8>, chunk: &[u8]) -> Vec<Vec<u8>> {
  let mut done = Vec::new();
  let mut rest = chunk;
  while let Some(nul) = rest.iter().position(|&b| b == 0) {
    partial.extend_from_slice(&rest[..nul]);
    done.push(std::mem::take(partial));
    rest = &rest[nul + 1..];
  }
  partial.extend_from_slice(rest);
  done
}

/// The reader thread: bytes in, one parsed message per NUL out. It ends at the
/// end of the pipe, and dropping its sender is how the session learns of it.
fn pump<R: Read>(mut input: R, tx: &Sender<Heard>) {
  let mut partial = Vec::new();
  let mut chunk = vec![0u8; 1 << 16];
  loop {
    let n = match input.read(&mut chunk) {
      Ok(0) => return,
      Ok(n) => n,
      Err(e) if e.kind() == ErrorKind::Interrupted => continue,
      Err(e) => {
        // Sent as a message, so the session reports the cause before it sees
        // the pipe close. If the session has gone there is nobody to tell.
        let _ = tx.send(Heard::Unreadable(e));
        return;
      }
    };
    for message in split_messages(&mut partial, &chunk[..n]) {
      let heard = match serde_json::from_slice(&message) {
        Ok(value) => Heard::Message(value),
        Err(e) => {
          let head = String::from_utf8_lossy(&message[..message.len().min(80)]).into_owned();
          Heard::NotJson(e, head)
        }
      };
      if tx.send(heard).is_err() {
        return;
      }
    }
  }
}

#[cfg(test)]
mod tests {
  use super::*;
  use serde_json::json;
  use std::time::Duration;

  #[test]
  fn messages_are_framed_on_nul_whatever_the_reads_look_like() {
    let mut buf = Vec::new();
    assert!(split_messages(&mut buf, b"{\"a\":1}").is_empty());
    let got = split_messages(&mut buf, b"\0{\"b\":2}\0{\"c\"");
    assert_eq!(got, vec![b"{\"a\":1}".to_vec(), b"{\"b\":2}".to_vec()]);
    assert_eq!(buf, b"{\"c\"".to_vec());
    let rest = split_messages(&mut buf, b":3}\0");
    assert_eq!(rest, vec![b"{\"c\":3}".to_vec()]);
    assert!(buf.is_empty());
  }

  /// AT28 (AC-02.6): a reply that never comes is refused NAMING THE STEP, so a
  /// stall reads as "frame 63: screenshot" rather than as a silent hang.
  #[test]
  fn a_stalled_reply_is_refused_naming_the_step() {
    let (reader, writer) = std::io::pipe().unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_millis(150));
    s.step("frame 63: screenshot");
    let e = s
      .call("Page.captureScreenshot", json!({}), None)
      .unwrap_err();
    assert!(e.message.contains("no reply from Chrome"), "{}", e.message);
    assert!(
      e.message.contains("during frame 63: screenshot"),
      "{}",
      e.message
    );
    drop(writer);
  }

  /// The watchdog bounds the whole wait: a Chrome that keeps talking and never
  /// replies is a stall, not a live connection.
  #[test]
  fn a_stream_of_events_does_not_keep_a_stalled_call_waiting() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    std::thread::spawn(move || {
      while writer
        .write_all(b"{\"method\":\"Page.frameNavigated\",\"params\":{}}\0")
        .is_ok()
      {
        std::thread::sleep(Duration::from_millis(20));
      }
    });
    let mut s = Session::new(Vec::new(), reader, Duration::from_millis(200));
    s.step("the load");
    let began = Instant::now();
    let e = s.call("Page.navigate", json!({}), None).unwrap_err();
    assert!(e.message.contains("no reply from Chrome"), "{}", e.message);
    assert!(
      began.elapsed() < Duration::from_secs(5),
      "{:?}",
      began.elapsed()
    );
  }

  #[test]
  fn a_closed_pipe_is_refused_as_closed_not_as_a_stall() {
    let (reader, writer) = std::io::pipe().unwrap();
    drop(writer);
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    s.step("the load");
    let e = s.call("Page.navigate", json!({}), None).unwrap_err();
    assert!(e.message.contains("Chrome closed"), "{}", e.message);
    assert!(e.message.contains("during the load"), "{}", e.message);
  }

  #[test]
  fn an_event_that_arrives_before_the_reply_is_kept_for_its_waiter() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    writer
      .write_all(
        b"{\"method\":\"Page.loadEventFired\",\"params\":{}}\0{\"id\":1,\"result\":{\"ok\":true}}\0",
      )
      .unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    let r = s.call("Page.enable", json!({}), None).unwrap();
    assert_eq!(r["ok"], true);
    assert!(s.seen("Page.loadEventFired", None));
    let e = s.event("Page.loadEventFired", None).unwrap();
    assert_eq!(e["method"], "Page.loadEventFired");
    assert!(
      !s.seen("Page.loadEventFired", None),
      "an event is taken once"
    );
    drop(writer);
  }

  #[test]
  fn an_event_from_another_session_is_not_the_one_waited_for() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    writer
      .write_all(
        b"{\"method\":\"Page.loadEventFired\",\"sessionId\":\"OTHER\"}\0{\"method\":\"Page.loadEventFired\",\"sessionId\":\"S1\"}\0",
      )
      .unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    let e = s.event("Page.loadEventFired", Some("S1")).unwrap();
    assert_eq!(e["sessionId"], "S1");
    assert!(s.seen("Page.loadEventFired", Some("OTHER")));
    drop(writer);
  }

  #[test]
  fn a_message_that_is_not_json_is_refused_naming_the_step() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    writer.write_all(b"{\"id\":1,\"result\":\0").unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    s.step("frame 7: screenshot");
    let e = s
      .call("Page.captureScreenshot", json!({}), None)
      .unwrap_err();
    assert!(e.message.contains("not JSON"), "{}", e.message);
    assert!(
      e.message.contains("during frame 7: screenshot"),
      "{}",
      e.message
    );
    drop(writer);
  }

  #[test]
  fn a_protocol_error_is_refused_naming_the_method() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    writer
      .write_all(b"{\"id\":1,\"error\":{\"code\":-32000,\"message\":\"Not allowed\"}}\0")
      .unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    let e = s
      .call("Emulation.setVirtualTimePolicy", json!({}), None)
      .unwrap_err();
    assert!(
      e.message.contains("Emulation.setVirtualTimePolicy"),
      "{}",
      e.message
    );
    assert!(e.message.contains("Not allowed"), "{}", e.message);
    drop(writer);
  }

  #[test]
  fn a_call_writes_one_nul_terminated_message_carrying_its_session() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    writer.write_all(b"{\"id\":1,\"result\":{}}\0").unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    s.call("Page.enable", json!({"a": 1}), Some("S1")).unwrap();
    let sent = s.writer().clone();
    assert_eq!(sent.last(), Some(&0u8));
    let v: serde_json::Value = serde_json::from_slice(&sent[..sent.len() - 1]).unwrap();
    assert_eq!(v["id"], 1);
    assert_eq!(v["method"], "Page.enable");
    assert_eq!(v["params"]["a"], 1);
    assert_eq!(v["sessionId"], "S1");
    drop(writer);
  }

  #[test]
  fn an_exception_in_the_page_is_refused_naming_the_step_and_a_value_is_returned() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    writer
      .write_all(
        b"{\"id\":1,\"result\":{\"result\":{\"type\":\"object\"},\"exceptionDetails\":{\"text\":\"Uncaught\",\"exception\":{\"description\":\"ReferenceError: dwellOf is not defined\"}}}}\0{\"id\":2,\"result\":{\"result\":{\"type\":\"number\",\"value\":42}}}\0",
      )
      .unwrap();
    let mut s = Session::new(Vec::new(), reader, Duration::from_secs(5));
    s.step("the schedule");
    let e = s
      .evaluate("window.__showreelClock.schedule()", None)
      .unwrap_err();
    assert!(e.message.contains("during the schedule"), "{}", e.message);
    assert!(
      e.message.contains("dwellOf is not defined"),
      "{}",
      e.message
    );
    assert_eq!(s.evaluate("6 * 7", None).unwrap(), 42);
    drop(writer);
  }

  #[test]
  fn a_closing_pipe_is_seen_within_the_grace_and_an_open_one_is_not() {
    let (reader, writer) = std::io::pipe().unwrap();
    let mut open = Session::new(Vec::new(), reader, Duration::from_secs(5));
    assert!(!open.closes_within(Duration::from_millis(100)));
    drop(writer);
    assert!(open.closes_within(Duration::from_secs(5)));
  }
}
