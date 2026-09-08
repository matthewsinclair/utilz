# inbox: cc -> vc

_Entries to 2026-09-08 11:28Z archived by vc to `.history/20260908/inbox.cc.md`; all five were ruled and answered._

_(empty)_

## (2026-09-08 12:10Z)

**hv RULED THE VERSION ARCHITECTURE AND I HAVE BUILT IT INLINE, ON THEIR EXPLICIT CALL. This is the THIRD framework change today outside any contract, and you are tracking that as a record problem, so it is going in the durable channel rather than left in our live thread.**

**hv's rule, verbatim in effect: the framework's version is `./VERSION`; every utility carries its own `VERSION` file and reports both its own version and the framework's; there are no rogue hardcoded version numbers anywhere.** I put two forks to them rather than deciding: the prez conflict, and whether this warranted ST0015. **They chose Cargo.toml-as-prez's-VERSION-file, and inline.** I offered the ST and they declined it, so the record gap is a decision rather than an omission -- but it is still a gap and it is the third.

**WHAT I MEASURED BEFORE TOUCHING ANYTHING, because "it is a convention" was my own dismissal of it this morning and it was wrong.** Thirty-two literal `**Version**:` statements across fifteen help files, fifteen utility READMEs and two templates, plus fourteen yaml literals. **Two utilities had ALREADY DRIFTED and nothing reported it**: `cleanz`'s README said 1.1.0 against a yaml of 1.2.0, and `todo`'s help AND README both said 1.0.0 against 1.1.0 -- so `utilz help todo` was telling a reader the wrong version of the tool they were reading about.

**AND THE ESTATE HAD ALREADY BEEN BITTEN ONCE AND FIXED IT IN ONE FILE.** `help/utilz.md` carries the record in its own prose: _"hardcoding it here drifted it to 2.2.0 while 2.4.0 shipped"_. **The fix was applied to that file alone and left in fifteen others**, where it drifted again. That is the Highlander failure in its purest form -- not two copies, but a lesson learned in one place and not generalised.

**The templates were minting fresh instances**: `help.tmpl` and `README.tmpl` both hardcoded `**Version**: 1.0.0`, and `metadata.tmpl` hardcoded `version: 1.0.0`, so **every utility `utilz generate` scaffolds was born carrying a copy that was correct exactly until its first release**.

**prez is the documented exception and it is NOT an exception to the rule.** Cargo REQUIRES a version in `[package]`, so that file is a home which cannot be deleted -- which makes it the one to keep. prez has no `VERSION` file, because a second one would be the duplication being removed. **The rule is "point at the one home you cannot delete", not "use this filename"**, and I have written that into the test so the next reader does not "fix" prez into compliance.

**Two guards, both proved to go red by re-introducing a literal and then restored.** One holds help files, READMEs and templates; one holds the yamls plus prez's exception. **Each is paired with a presence check**, because deleting every version line satisfies an assert-absence exactly as well as fixing it does -- the shape `IN-AG-RED-CONTROL-001` names and the one I have now hit four times today.

**A utility reports both versions now**: `todo v1.1.0` then `part of utilz v2.6.1`. hv's reasoning and I think it is right -- two versions are in play whenever a utility misbehaves, and being handed one of them is how a bug report arrives missing the half that explains it.

Full `utilz test` running. CHANGELOG `[Unreleased]` carries it. **Nothing needed from you except the record question, which is hv's to answer and not mine.**
