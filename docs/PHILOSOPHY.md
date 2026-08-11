# GWB Philosophy

## Purpose

Greg's Windows Bootstrap (GWB) exists to make the terminal the easiest,
most approachable part of using Windows — the same mission
[GLB](https://github.com/ggregoro/GLB) has on Linux, ported to
PowerShell. A default PowerShell prompt gives no hints, no color, no
context; GWB closes that gap with a good prompt and a handful of
well-chosen CLI tools, applied in one command instead of pieced together
by hand every time a machine gets reimaged.

GWB is built on the belief that a good prompt and a small, well-chosen
toolkit can turn PowerShell from "the blue window you avoid" into
something people actually want to work in — and that getting there
should take one command, not hours of manually reinstalling the same
tools and rewriting the same profile.

---

# Our Philosophy

## User Experience First

Every design decision should improve the overall user experience.

Users should be guided through the installation process with clear
choices and sensible defaults rather than being overwhelmed by
technical details.

## Curate, Don't Reinvent

GWB exists to integrate the best open-source projects, not replace them:

- Starship
- eza
- bat
- fzf
- ripgrep
- fd
- lf

GWB provides the framework that brings these projects together into a
cohesive terminal setup, installed via winget and wired into `$PROFILE`
— it doesn't reimplement any of them.

## Enhance the Terminal You Have, Don't Replace It

**GWB does not install terminal emulators or other GUI applications —
inherited directly from GLB, not relearned the hard way a second time.**
GLB tried managing WezTerm as part of its `default` profile and reversed
it after real, wasted time chasing Flatpak-sandbox and
desktop-compositor issues that had nothing to do with shell/prompt
configuration — see GLB's own `docs/PHILOSOPHY.md` for the full account.
GWB starts from that conclusion rather than re-discovering it: `lib/
terminal.ps1` exists only as an unused, opt-in stub (see `docs/
ROADMAP.md` Version 0.4), not something any shipped profile wires up.

**The line is GUI vs. terminal, not "simple" vs. "complex."** A
full-screen console application — `lf`, a TUI file manager, even
something as involved as the Claude Code CLI itself — is fully in
scope, because it never opens a window of its own; it runs entirely
inside whatever terminal (Windows Terminal, ConHost, VS Code's
integrated terminal) is already there. Windows Terminal itself, PowerToys,
VS Code, or any other application with its own window is out of scope —
someone who wants one is free to install it themselves; GWB just needs
whatever they land on to keep working, which "enhance whatever terminal
is already there" already guarantees.

## Opinionated but Customizable

GWB provides carefully selected defaults based on real, verified use —
the `default` profile is what's actually installed and tested on a real
Windows 11 machine, not a placeholder list.

Users who prefer different tools should always be able to customize
their installation — a profile is just a `packages.txt` and a
`profile-snippet.ps1`, both plain text, both easy to fork or edit.

## Profiles Instead of Package Lists

Users should choose experiences rather than individual packages.
`default` is the only one so far; `developer`/`server`-style profiles
(mirroring GLB's) are planned — see `docs/ROADMAP.md`.

## Modular by Design

Every feature exists as an independent `lib/*.ps1` module: reusable,
testable, maintainable, independent. This is what let GWB's whole
architecture be built by directly mirroring GLB's module boundaries
rather than inventing new ones.

## Open Source First

Every tool GWB curates — Starship, eza, bat, fzf, ripgrep, fd, lf — is
open source, distributed through winget rather than a proprietary
installer. GWB succeeds when the tools it curates succeed.

## Consistent With GLB

Where GLB and GWB solve the same problem on different platforms, they
should feel like the same tool: the same command names where they
translate directly (`restore`, `profiles`, `--dry-run`, `--undo`), the
same profile shape (packages + a place for shell customization +
optional description), the same idempotent, safe-to-rerun behavior.
Someone who knows GLB should be able to guess most of GWB.

## Simplicity Over Complexity

Complexity should live inside GWB, not in front of the user. The
installer presents clear choices and hides implementation detail —
winget package IDs, `$PROFILE` marker-block mechanics — behind logical
names and a single `restore` command.

## Learn by Building

GWB is both a practical tool and a way to build real PowerShell
engineering practice: clean module boundaries, consistent documentation,
idempotent behavior, and verification against a real machine rather than
just a syntax check (see `CONTRIBUTING.md`).

---

# Long-Term Vision

GWB aims to become the same thing for a Windows/PowerShell terminal that
GLB is for a Linux one: a curated, reproducible, one-command setup for a
modern, pleasant command-line environment.

---

# Guiding Principle

Whenever a design decision is uncertain, ask one question:

**Does this improve the user's experience inside the terminal they
already have?**

If the answer is yes, it's likely consistent with the philosophy of
GWB. If it requires opening a window of its own, it's out of scope.

---

> **Our Mission:** Build the Windows terminal experience we'd want to
> set up ourselves, and make it reproducible with one command.
