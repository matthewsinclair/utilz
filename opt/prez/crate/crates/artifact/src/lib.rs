// Primitives shared by the tools that emit a SELF-CONTAINED artifact.
//
// **WHAT BELONGS HERE IS DECIDED BY WHETHER TWO TOOLS ALREADY IMPLEMENT IT,
// NOT BY WHETHER IT LOOKS REUSABLE.** Every module below was measured as a
// duplicate before it moved: the same behaviour, implemented twice, in two
// languages. Speculative generality is how a shared crate becomes a place
// things are put rather than a place things are found.
//
// **`browser` IS THE ONE MODULE THAT MOVED AHEAD OF ITS SECOND COPY**, and the
// rule above is why it had to. Only prez found a browser until ST0021, and
// showreel's `video` is the second tool that needs one. Giving `video` a finder
// of its own, so that the duplicate existed before anything moved, would have
// built exactly what the rule exists to prevent. The move and its second
// consumer land in the same thread.
//
// **WHAT IS DELIBERATELY NOT HERE: data-URI INLINING.** It reads as the
// obvious fourth member and it is not one. prez rewrites `<img src=...>` in
// RENDERED HTML and leaves anything carrying a scheme alone, because a URL the
// author wrote is their content; the reel pipeline rewrites no HTML at all and
// builds data-URI strings into a payload its player consumes. Two tools, one
// English sentence, no shared surface. Only `base64` underneath them is common,
// and that is what moved.

pub mod base64;
pub mod browser;
pub mod path;
pub mod theme;

mod failure;
pub use failure::Failure;
