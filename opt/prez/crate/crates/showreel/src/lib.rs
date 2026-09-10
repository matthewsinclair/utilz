//! showreel -- a directory of pictures to a self-contained looping HTML reel.
//!
//! **THIS CRATE IS A LIBRARY WITH A BINARY ON TOP, WHERE prez IS A BINARY
//! ALONE, AND THE DIFFERENCE IS FORCED RATHER THAN CHOSEN.** In a bin-only
//! crate nothing outside `main` can reach an item, so anything not yet wired is
//! `dead_code` -- and under `-D warnings` that is a build failure. The two ways
//! out are an `#[allow(dead_code)]` that stays long after it is needed, or a
//! library target where a `pub` item is API rather than an orphan. The second
//! is the honest one: this crate carries real logic that wants testing
//! independently of a command line, and the first would switch off a live
//! signal permanently to buy silence during one commit.
//!
//! **THE COST, STATED: two unittest targets instead of one** (lib and bin). That
//! is a deviation from the one-target-per-crate note in this estate's TN001
//! reading, and it is a small one -- `main.rs` holds no tests, so the bin target
//! links nothing. TN001's actual harm is a `tests/` directory turning every file
//! into its own full link, and this crate has none.

pub mod admit;
pub mod build;
pub mod config;
pub mod deliver;
pub mod duration;
pub mod limits;
pub mod normalise;
pub mod payload;
pub mod plan;
pub mod segment;
pub mod slide;
pub mod stamp;
pub mod template;
pub mod theme;
