// Primitives shared by the tools that emit a SELF-CONTAINED artifact.
//
// **WHAT BELONGS HERE IS DECIDED BY WHETHER TWO TOOLS ALREADY IMPLEMENT IT,
// NOT BY WHETHER IT LOOKS REUSABLE.** Every module below was measured as a
// duplicate before it moved: the same behaviour, implemented twice, in two
// languages. Speculative generality is how a shared crate becomes a place
// things are put rather than a place things are found.
//
// **WHAT IS DELIBERATELY NOT HERE: data-URI INLINING.** It reads as the
// obvious fourth member and it is not one. prez rewrites `<img src=...>` in
// RENDERED HTML and leaves anything carrying a scheme alone, because a URL the
// author wrote is their content; the reel pipeline rewrites no HTML at all and
// builds data-URI strings into a payload its player consumes. Two tools, one
// English sentence, no shared surface. Only `base64` underneath them is common,
// and that is what moved.

pub mod base64;
pub mod theme;

mod failure;
pub use failure::Failure;
