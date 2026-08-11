# Reference

Mirrors GLB's `docs/reference/` — quick command/config cheat sheets for
tools GWB curates or depends on, separate from the design/architecture
docs one level up.

## Current docs

- [`ipban-manual-install.md`](ipban-manual-install.md) — install/
  verify/uninstall commands for IPBan (`server`'s fail2ban equivalent),
  deliberately not automated by `gwb restore` — see
  [`../design/server-profile.md`](../design/server-profile.md) for why.

Other plausible candidates, not written yet: a winget cheat sheet
(search/list/upgrade syntax), a Starship config reference for
`default`'s prompt setup.

**One standing caution, carried over from GLB directly**: GLB once had
a reference page with a real machine's LAN IP and SSH username in
plaintext, found during a pre-public-release privacy audit and removed
entirely rather than redacted. Anything added here that touches a real
machine's config should stay generic/example-shaped — no real
hostnames, IPs, usernames, or paths specific to one of Greg's actual
machines.
