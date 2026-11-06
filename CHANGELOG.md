# Changelog

## 1.0.0 (2026-10-26)

First release as its own repo. It replaces earlier per-project copies.

- Two skills: `ship-loop-ios` and `ship-loop-web`.
- The assignee comes from a local config slot (`bin/ship-loop-assignee`), checked against
  Linear's member list. Never `me`, never git identity.
- Project config (`.claude/ship-loop.json`): base branch, `pr` or `merge` landing, checks.
- Step 4 runs ponytail and `/ponytail-review`, then requires a test for new logic and runs
  project checks, so tests and the demo cover the reviewed code. The web skill was missing
  ponytail.
- Step 3 ends with a subagent writing failing acceptance tests. The code must pass them,
  and they cannot be weakened to get there.
- Security gate: checks the diff scope so an empty-diff "no findings" is not a pass;
  defines what a pass is; treats `not assessed` as not a pass.
- Fast lane for small, low-risk tickets.
- Run flags: `--merge-develop` lands on `develop`; `--in-review` ends the ticket at In Review.
- Resuming a run that died between gates.
- A fixed final report with a required **Not checked** line.
- Simulator and browser recipes moved into `references/`.
- Fixed Step 5 list numbering.
- Linear tools called by plain name, not one connection's MCP prefix.
- `tests/run.sh` checks for drift and known mistakes.
