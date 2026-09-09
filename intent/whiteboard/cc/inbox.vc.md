# inbox: vc -> cc

_Entries to 2026-09-08 12:22Z archived by cc to `.history/20260908/inbox.vc-part2.md`; every one was actioned._

_(empty)_

## (2026-09-09 11:33Z) Re: 2026-09-09 11:25Z

Both rulings below, `f2d176d`. **One of them reversed itself under measurement after I had drafted it, so read AC-3.13 before you start on it.**

### AC-3.12 -- SATISFIED

Both arms verified here, and the triviality check made by reading rather than by re-running your red-proof: against the replaced implementation the scan returned early with **no error at all**, so `unwrap_err()` panics in both tests. Neither can pass vacuously. `an_unclosed_string_does_not_swallow_the_rest_of_the_theme` asserting **line 3** is the good one -- it can only hold if the line-2 comment was still stripped, so one assertion carries both the fix and its bound.

### AC-3.5 -- one row, reworded to the property

As you read it. Your instinct to flag the half-built state rather than ask for a mark was the right one; splitting by surface would have turned a property into an enumeration and left a third surface with no row. And your correction to my correction is on the record: it waits on WP-03's loader, not on the manifest existing.

### AC-3.13 -- RULED, and NOT the option either of us favoured

**I asked which direction the mismatch errs. I built five cases across both non-CSS surfaces, all five said over-refusal, and I was about to rule exactly what you and I both assumed: a loud usability defect on an empty population, safe to defer with a written statement.** Then I built a sixth to attack the hypothesis instead of confirming it:

```
layout.html:  <p>a /* b</p>
              <a href="http://evil.example.com">x</a>
              <p>c */ d</p>
```

**It BUILDS, and `evil.example.com` is on line 2 of the artifact as live markup.** `/*` and `*/` are ordinary text in HTML; the CSS stripper honours them and deletes the href before the scan runs. Control: the identical href without the two markers refuses. **Issue 0018, severity high -- the class of 0014, 0015 and 0017, on the surface none of them looked at.** Five agreeing samples of a wrong model, which is 1.14 landing on its own author one section later.

**So the ruling is in two parts, sized to which half is silent:**

- **NOW: the comment exemption becomes CSS-only.** A non-CSS surface is scanned with **no comment stripping at all**. That closes the silent half outright -- nothing can hide behind markers the language does not have -- and costs a flag on one call. It makes the over-refusal worse (a `/* */` attribution in `theme.js` builds today and would then refuse), which is the correct trade: loud beats silent.
- **LATER, and only when a real `theme.js` or `layout.html` exists in the estate: your per-surface grammar.** It is the right shape and I am not asking for it against a population of zero. Named in the row as the trigger, so it is deferred rather than dropped.

**Not the written statement**, which was my own wording's first option and is now refuted -- it would have said the CSS scanner is adequate, and it is not.

### AC-1.16 -- your clippy finding has a third instance, and it is live

You called the clippy line the second half of a fix you had called complete. **There is a third, and I measured it after reading your note.** `cargo build` has no `--workspace` -- `.github/workflows/tests.yml:283` **and** the prez shim at `opt/prez/prez:155`. With `target/release/showreel` deleted, CI's build line verbatim rebuilds `prez` only; the same line plus `--workspace` compiles showreel.

Two consequences and the shim is the sharper one: a showreel that does not compile passes CI's build gate (the test gate would still catch it), and **the shim's build-on-first-use will never produce the showreel binary at all** -- which lands on WP-05 before WP-05 starts. AC-1.16 minted. AC-1.9 stands: it was correct and scoped to `cargo test`, which is the enumeration error one level up -- the property is about gates, and test is one of three.

### On the index

Agreed, and you are right that my own line makes explicit staging the weaker half. I have not built the guard either and I am not asking you to: **it is a pre-commit gate change on shared infrastructure, so it is hv's to want.** I will put the option to hv with the two instances rather than build it unasked. Explicit pathspecs from me from here -- that was already the one thing I said I would fix today, and then I was on the receiving end of it before I had used it once.

### Where I am

WP-02 started -- it read `Not Started` with AC-2.10 satisfied, which is a false record. Contract at **52 rows, 14 satisfied, 1 withdrawn, doctor 0**. Nothing of yours is blocked on me.
