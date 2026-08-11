# GWB Documentation

Welcome to the **Greg's Windows Bootstrap (GWB)** documentation.

This documentation records the configuration, tools, workflows, and
lessons learned while building and maintaining the GWB project — the
PowerShell/Windows sibling to
[GLB](https://github.com/ggregoro/GLB), whose own `docs/README.md`
this is adapted from.

---

# Project Documentation

- [`PROJECT.md`](PROJECT.md) — mission, principles, target audience, goals
- [`PHILOSOPHY.md`](PHILOSOPHY.md) — the guiding design philosophy
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — module breakdown and how a profile is applied
- [`ROADMAP.md`](ROADMAP.md) — current progress and planned work, by version
- [`CODING_STANDARDS.md`](CODING_STANDARDS.md) — naming/style conventions for `lib/` modules
- [`design/`](design/) — design docs for individual features, once any get scoped this way
- [`reference/`](reference/) — quick tool/config cheat sheets, once any get written
- [`DOCS_CHANGELOG.md`](DOCS_CHANGELOG.md) — documentation/dev-environment milestones (see the root [`CHANGELOG.md`](../CHANGELOG.md) for `gwb`'s actual feature changes)

See also the root [`CLAUDE.md`](../CLAUDE.md) for session-by-session
working notes.

---

# Tutorials

Step-by-step guides. None written yet — candidate topics:

- Installing winget on a fresh Windows machine
- Setting up SSH keys on Windows (for `git` over SSH, matching how GLB
  itself is cloned/pushed)
- PowerShell `$PROFILE` basics — what it is, where it lives, how GWB's
  managed block fits into it
- Starship configuration on Windows

---

# Reference

Quick command references — see [`reference/`](reference/). None written
yet; candidate topics listed there.

---

# Troubleshooting

See [`troubleshooting.md`](troubleshooting.md) — `PATH` not refreshing
after a new install (confirmed, hit during the initial build), PowerShell
execution-policy/downloaded-file-blocking errors running `gwb.ps1`
(anticipated), and missing Nerd Font glyphs (anticipated).

---

> Like GLB's own docs, this file is expected to grow — add real
> tutorials/reference/troubleshooting entries here as they're actually
> written, rather than leaving the placeholders above as the permanent
> state.
