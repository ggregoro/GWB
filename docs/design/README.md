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

Nothing has been scoped this way for GWB yet — everything built so far
(packages, `restore`/`--dry-run`/`--undo`, the interactive picker) was
small enough to build directly. The next candidates likely to need a
real design doc, per [`docs/ROADMAP.md`](../ROADMAP.md): `developer`/
`server` profiles (Windows equivalents of GLB's picks need their own
scoping pass, not a blind port) and the `export`/`diff`/`repair`
configuration-management trio (Version 0.6).
