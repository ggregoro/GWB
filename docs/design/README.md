# Design Docs

Mirrors GLB's `docs/design/` — this is where a feature gets scoped
*before* being built, when there's a real decision to make (multiple
candidate approaches, an open question worth writing down and getting
confirmed before code gets written), not for every small addition.

GLB's own `docs/design/` has examples of the shape these take:
`guided-wizard.md`, `installation-manifests.md`, `repair.md`,
`state-export-import.md`, `update-components.md` — each one scopes a
single feature, gets resolved (often via a direct question to Greg
before building), and then stays as a record of *why* the feature ended
up shaped the way it did, even after the feature ships.

## Current docs

- [`developer-profile.md`](developer-profile.md) — **Decided and
  built.** Scoped and resolved the real forks in porting GLB's
  `developer` profile to Windows: no container tooling (WSL2
  constraint), MinGW/gcc over MSVC, `mise` and Fresh both confirmed to
  have real Windows support, no resource monitor (Task Manager already
  covers it). Verified end-to-end on real hardware.
- [`server-profile.md`](server-profile.md) — **Decided and built.**
  No firewall tool (Windows Firewall already covers it), `restic` alone
  for backups (real, native, no WSL — `robocopy` already covers
  `rsync`'s role), no fail2ban equivalent (IPBan is real but has no
  winget package — a genuine gap, documented rather than forced), no
  resource monitor. Verified end-to-end on real hardware.
- [`export-diff-repair.md`](export-diff-repair.md) — **Decided and
  built.** Scoped package tracking to packages known to some profile
  (winget has no manual-vs-dependency tracking at all — a harder gap
  than any GLB package manager faced). `$PROFILE` export captures only
  the GWB-managed block, not the whole file. Verified end-to-end on
  real hardware, including two real bugs caught and fixed (a
  mixed-line-endings false-positive diff, `Read-Host` crashing instead
  of failing gracefully with no input).
- [`from-manifest.md`](from-manifest.md) — **Decided and built, no real
  fork found.** `Invoke-GwbApplyProfile` already accepted an arbitrary
  path, so `--from-manifest <path>` needed only argument parsing, no
  new logic. Verified end-to-end with a real scratch manifest.

Everything else built so far (packages, `restore`/`--dry-run`/`--undo`,
the interactive picker) was small enough to build directly, without a
design doc. **Version 0.6 (Configuration Management) is now fully
complete** — see [`docs/ROADMAP.md`](../ROADMAP.md) for what's next.
