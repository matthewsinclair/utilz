/// The descendants of a process, read from `ps -A -o pid=,ppid=`, so a
/// shell stopped at its deadline takes its children with it: a label's
/// `$(...)` or an each's line would otherwise outlive the cap and keep the
/// pipe open.
public enum ProcessTable {
  /// Every process below `root`, children before their own children.
  public static func descendants(of root: Int32, in psOutput: String) -> [Int32] {
    var children: [Int32: [Int32]] = [:]
    for line in psOutput.split(separator: "\n") {
      let fields = line.split(separator: " ", omittingEmptySubsequences: true)
      guard fields.count == 2, let pid = Int32(fields[0]), let ppid = Int32(fields[1]) else { continue }
      children[ppid, default: []].append(pid)
    }
    var out: [Int32] = []
    var queue = children[root] ?? []
    while !queue.isEmpty {
      let pid = queue.removeFirst()
      guard pid != root, !out.contains(pid) else { continue }
      out.append(pid)
      queue.append(contentsOf: children[pid] ?? [])
    }
    return out
  }
}
