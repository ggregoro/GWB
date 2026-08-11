# Design: `restore --from-manifest <path>`

**Status:** Decided and built (2026-08-11). No real fork found — see
below.

## Purpose

GLB's `glb restore --from-manifest <path>` applies a profile-shaped
directory from *anywhere* on disk (not looked up by name under
`profiles/`/`snapshots/`), for a one-off custom install without adding
a profile to the repo.

## No real fork

Unlike `developer-profile.md`/`server-profile.md`/
`export-diff-repair.md`, this one turned out to have nothing to
research or decide. `Invoke-GwbApplyProfile` (`lib/profile.ps1`) was
already written to take an arbitrary `-ProfileDir` path — it never
assumed the directory lives under `$ProfilesRoot`. `restore
--from-snapshot` already exploits exactly this by passing a path under
`$SnapshotsRoot`; `--from-manifest` is the identical trick with a raw
user-supplied path instead. GLB's own `glb_apply_manifest` duplicates
`glb_apply_profile`'s body (same reason `glb_apply_snapshot` does —
avoiding breaking existing bats assertions on exact log wording); GWB
has no test suite yet holding it to specific wording, so — same
reasoning already used for `--from-snapshot` — there's no equivalent
reason to duplicate here either.

## Design

`gwb.ps1`'s `restore` argument loop gains a `--from-manifest <path>`
two-token flag, parsed the same way `--from-snapshot <name>` already
is. Unlike `--from-snapshot` (which `Join-Path`s a name onto
`$SnapshotsRoot`), the manifest path is used as-is — it's a real
filesystem path, not a name to resolve. `Invoke-GwbApplyProfile` is
called directly with that path as both `-ProfileDir` and `-ProfileName`
(so log output shows the actual path, since there's no separate
"name" concept for an arbitrary manifest — matching how GLB's own
manifest log wording shows the path).

## Verification

Built and verified for real: a scratch manifest directory outside the
repo (`packages.txt` + `profile-snippet.ps1`, hand-written) applied
successfully via both `--dry-run` and for real, and a nonexistent path
errors cleanly.
