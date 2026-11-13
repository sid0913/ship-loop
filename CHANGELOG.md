# Changelog

## 1.1.0 (2026-11-12)

- impeccable is now required, not optional. `install.sh --check` reports it as missing,
  and `INSTALL.md` gives the install command (skills only, no hooks).
- Step 2 designs new UI with `/impeccable shape`, `critique` and `polish`. hallmark stays
  optional.
- Step 4 checks changed UI with impeccable. The web skill runs `npx impeccable detect` on
  changed files and on each changed page from the dev server. The iOS skill runs
  `/impeccable audit`, because the detector reads web markup only and reports React
  Native source as clean.
- A run stops if impeccable is missing. It never installs impeccable or turns on its hooks.
- Tests cover the impeccable steps and the required check.

## 1.0.0 (2026-10-26)

First release as its own repo. It replaces earlier per-project copies.

- Two skills: `ship-loop-ios` and `ship-loop-web`.
- The assignee comes from a local config slot (`bin/ship-loop-assignee`), checked against
  Linear's member list. Never `me`, never git identity.
- Project config (`.claude/ship-loop.json`): base branch, `pr` or `merge` landing, checks.
- Step 4 runs ponytail, requires a test for new logic, runs project checks, and runs
  `/ponytail-review`. The web skill was missing ponytail.
- Security gate: checks the diff scope so an empty-diff "no findings" is not a pass;
  defines what a pass is; treats `not assessed` as not a pass.
- Fast lane for small, low-risk tickets.
- Resuming a run that died between gates.
- A fixed final report with a required **Not checked** line.
- Simulator and browser recipes moved into `references/`.
- Fixed Step 5 list numbering.
- Linear tools called by plain name, not one connection's MCP prefix.
- `tests/run.sh` checks for drift and known mistakes.
