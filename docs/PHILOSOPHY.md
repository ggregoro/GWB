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

## Terminal-First, Not Terminal-Only

GWB's mission is the terminal: making the shell, prompt, and CLI tooling
of a fresh Windows install pleasant in one pass. The default move is to
**enhance whatever terminal you already have** (Windows Terminal,
ConHost, VS Code's integrated terminal) rather than replace it — none of
GWB's `$PROFILE` configuration assumes a particular terminal.

**GUI applications are in scope when they're a deliberate, opinionated
pick that complements that mission** — installed via `winget` and
lightly configured the same way as any other tool, not deeply managed.
What stays out of scope is GWB behaving like a general app store (a menu
of browsers, editors, utilities anyone can install themselves), and
sinking real effort into owning a GUI app's full configuration. Install
it, set the handful of options that make it useful for GWB's purpose,
and stop there.

This boundary is inherited from GLB, including the history that produced
it. GLB briefly *managed* WezTerm as part of its `default` profile
(2026-08-09) and removed it after real time lost to Flatpak-sandbox and
window-decoration issues that had nothing to do with shell/prompt setup.
The lesson that survived isn't "never install a terminal" — it's
**install, don't vendor-manage**. GLB dropped its own outright "no GUI
apps" rule on 2026-08-30, replacing it with exactly that boundary (its
first pick under the relaxed stance: Ghostty, so Yazi's image preview
works where a distro's default terminal can't draw one). GWB follows the
same stance. `lib/terminal.ps1` remains an unused, opt-in stub (see
`docs/ROADMAP.md` Version 0.4) — no shipped profile wires it up, and
that's the right default, not a prohibition.

Terminal-based tools were never in question and remain the core: a
full-screen console application — `lf`, `yazi`, the Claude Code CLI — is
in scope no matter how involved it is, because it runs inside whatever
terminal is already there.

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
