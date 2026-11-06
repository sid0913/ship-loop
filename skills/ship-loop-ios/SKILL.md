---
name: ship-loop-ios
description: Take one or more Linear tickets from "ready" to landed for an iOS / React Native / Expo app: worktree, plan reviews, ponytail implementation, tests, simulator demo video, security gate, land, cleanup. Multiple IDs fan out to one subagent per ticket. Invoke explicitly with /ship-loop-ios <LINEAR-ID> [<LINEAR-ID>...] [--fast] [--merge-develop] [--in-review].
---

# /ship-loop-ios: Linear ticket to landed, end to end (iOS)

Follow the steps in order. Do not skip or reorder them. The user runs this skill on
purpose (`/ship-loop-ios ENG-12`). Never trigger it from loose wording, because it creates
worktrees, pushes branches and deletes worktrees.

- One ID: start at **Before you start**, then Steps 1-7.
- Two or more IDs: do **Step 0** first.
- `--fast`: ask for the fast lane (see **Lanes**). You still decide if the ticket qualifies.
- `--merge-develop`: the final stage is a merge to `develop` (see **Before you start**).
- `--in-review`: the final Linear status is In Review, not Done.

Simulator commands, Maestro and build traps live in
[`references/simulator-runbook.md`](references/simulator-runbook.md). Read it before Step 5,
and before Step 2 if the ticket has UI.

## Before you start

1. **Load the project config** from `.claude/ship-loop.json` at the repo root (see
   `examples/ship-loop.ios.json` in the ship-loop repo). The keys used below are
   `base_branch`, `land_mode`, `checks`, `ios.workspace`, `ios.scheme`,
   `ios.bundle_id` and `ios.devices`. If the file is missing, ask the user for
   `base_branch` and `land_mode`, offer to write the file, and continue. Never guess a
   base branch from what exists on the remote: a stale `develop` has cost a full rebase.
2. **Apply the run flags.** They change this run only and never edit the config file.
   - `--merge-develop`: use `develop` as `<base_branch>` and `merge` as `land_mode` for the
     whole run, so the worktree, the rebase and the final merge all use it. Run
     `git ls-remote --exit-code --heads origin develop` first. If that branch is missing,
     stop and ask. This flag is the user's explicit choice, not a guess.
   - `--in-review`: the ticket ends at **In Review** instead of **Done**. `pr` mode
     already ends there, so the flag only changes `merge` mode.
   - Say the target branch and final status in one line before Step 1.
3. **Resolve the assignee** (next section) before touching Linear.
4. **Check for an earlier run** (see **Resuming**). Never start a second worktree for a
   ticket that already has one.
5. **Pick a lane** and say which one in one line.

<!-- assignee:start -->
## Assignee: who the ticket goes to

The person a ticket is assigned to comes from a local config slot, never from Linear's
`me` and never from git identity. The Linear MCP is often signed in as one person on a
shared machine, so `me` assigns everyone's tickets to that one person, and git
`user.name`/`user.email` often match no Linear account.

Look in this order and use the first one found:

1. `.claude/ship-loop.local.json` in the repo root (gitignored, one person, this repo)
2. `~/.config/ship-loop/config.json` (one person, every repo)

Both have the same shape: `{"linear_assignee": "<Linear display name or email>"}`.

- **Check that the value is real.** Call the Linear MCP `list_users` and confirm that
  exactly one workspace member matches the stored name or email. Pass that member's
  id or exact name to `save_issue`.
- **No slot, or no match:** do not guess. Call `AskUserQuestion` with the workspace
  members from `list_users`, then write the choice to `~/.config/ship-loop/config.json`
  (or to the repo-local file if the user says it is for this repo only). The user can
  also set it ahead of time with `bin/ship-loop-assignee "<name>"` from the ship-loop
  repo.
- **Never pass `assignee: "me"`.**
- **Ticket already assigned to someone else:** do not take it silently. Name the
  current assignee and confirm before reassigning.
<!-- assignee:end -->

## Lanes

| Lane | When | What changes |
| --- | --- | --- |
| **full** | Default. Anything with UI, logic worth a design or eng review, native config, auth, payments, data writes, migrations. | Every step. |
| **fast** | No UI change, a small expected diff (about 30 lines or less), and no auth, payments, data writes, migrations, entitlements or native modules. | Skip Steps 2 and 3. In Step 5, the demo is the check output plus one screenshot if anything visible changed. Steps 1, 4, 6 and 7 and every gate still run. |

If you are not sure, use full. If a fast-lane ticket grows past the limits during Step 4,
switch to full, say so, and go back to Step 3.

## Step 0: Several tickets at once (2+ IDs only)

One subagent per ticket, each in its own worktree. The parallelism has limits: the loop has
human gates and pushes a shared branch.

1. **Check dependencies first.** Call `get_issue` for every ID (blocks, blocked by,
   parent, sub-issues). If one ticket blocks another, run them one after the other in
   dependency order. If the relations form a cycle, stop and ask the user how to order
   them.
2. **Check for shared files.** Tickets that will clearly touch the same files (same
   screen, same native config) are not independent, even if Linear records no relation.
   Ask the user: run them one after the other, or accept the conflict risk. If the user
   accepts the risk, tell each subagent about the other ticket and have it report overlap
   to the parent. Subagents never message each other.
3. **Spawn one subagent per independent ticket** with the `Agent` tool and no
   `isolation: "worktree"`. The loop makes its own worktree, and a harness worktree would
   put a second checkout inside it. Spawn it with this text, where `<flags>` repeats any
   `--merge-develop` or `--in-review` from this run:

   > Run `/ship-loop-ios <ID> <flags>` with three overrides. (1) You are a delegated subagent:
   > never call `AskUserQuestion`. (2) At each STOP gate, stop and return a report: the
   > gate, what the approver needs to see, and the artifact paths. Do not decide the
   > gate yourself. (3) Your run ends once the Step 5 demo is produced and reported. Do
   > not run Step 6 or Step 7. Simulator: use only UDID <UDID> and Metro port <PORT>.

4. **One shared simulator, used one ticket at a time.** Pick one demo device. Record on it
   one ticket at a time and shut it down between tickets. Allow a second device only when
   a ticket needs a different screen size. Never boot more than two. Pass `-d <UDID>` on
   every `simctl` call, give each run its own Metro port, and overwrite `RCT_jsLocation`
   for each run. Six booted simulators once pushed load average to 642 and left an
   `xcodebuild` stuck for 8 hours.
5. **The parent owns every gate.** A subagent stops at its gate and reports. The parent
   shows the report to the user, gets the decision, and resumes that subagent with
   `SendMessage`, except at the Step 5 gate (item 6). A subagent that approves its own
   gate is a bug.
6. **Steps 6 and 7 belong to the parent, one ticket at a time.** After the user approves a
   demo, the parent runs Step 6 for that ticket to the end before starting the next one,
   so each ticket lands on top of the one before it.
7. **For a batch, record one combined demo** on a throwaway integration branch that merges
   every ticket. It shows the tickets working together, it surfaces merge conflicts
   before approval, and the user approves once. Do not push the integration branch. Land
   the real branches one by one in Step 6.
8. **No `git stash` anywhere in the batch.** All worktrees share one stash list.
9. **Report per ticket at the end** (see **Final report**). A failed ticket does not roll
   back tickets that already landed. Say which ones landed and which did not.

## Step 1: Worktree, related-issues gate, assign

1. `git fetch origin <base_branch>`.
2. Create a **new** worktree from `origin/<base_branch>`. Name the branch
   `<id-lowercase>-<short-slug>` (for example `eng-12-sign-in-button`); **Resuming**
   depends on this name. Use `EnterWorktree`, or
   `git worktree add -b <branch> .claude/worktrees/<branch> origin/<base_branch>`.
   - **Never `git stash` or `stash pop` in a worktree.** All worktrees of a repo share one
     stash list, so a stash can pull another run's changes into yours. To shelve work,
     run `git commit -m wip`, then later `git reset --soft HEAD~1`.
   - The main checkout may have uncommitted changes. The new worktree will not contain
     them. Before you trust code you read in the main checkout, check that the files
     you will edit are the same on `origin/<base_branch>`.
   - Copy `.env` (and any other gitignored config the app needs) into the worktree. Run
     `npm ci` there. **Never symlink `node_modules`**: `git worktree remove --force`
     follows the link and deletes the real folder.
3. Get the ticket from Linear (`get_issue`) and its related issues: dependencies, linked
   issues, sub-issues, and other open tickets in the same area.
4. **STOP if any related issue is not Done or not landed on `<base_branch>`.** Call
   `AskUserQuestion` with each blocker (title, status, why it blocks) and wait for an
   explicit go-ahead. A blocker that "looks minor" is still a blocker.
5. Once the gate clears, **assign the ticket and move it to In Progress** in one
   `save_issue` call, using the assignee from **Assignee**. Never move status backwards:
   if it is already In Progress, In Review or Done, leave the status, fix only the
   assignee, and say so.

No Linear ticket for this run (the user said to skip Linear)? Skip the Linear parts of
Steps 1, 2, 5 and 6 and keep the rest.

## Step 2: Design gate (UI changes only, full lane)

Skip this step if the ticket has no UI change.

`/design-html` makes HTML/CSS, and React Native renders neither. Do not get a static HTML
mockup approved as if it were a native screen.

1. **Built only from Apple or existing in-repo components** (`src/components/ui`, system
   buttons)? Nothing new needs approval. Say so, skip ahead, and let the Step 5 recording
   be the design review.
2. **Genuinely new UI:** read `UX-research.md` and `DESIGN.md` if they exist. Build the
   screen in the worktree from the app's theme tokens and UI primitives. Capture it in the
   simulator on every device in `ios.devices`, in light and dark mode.
3. Optional design tools, if installed: `/impeccable shape` then `critique`/`polish` to
   design it, then `/hallmark audit <path>` to review it. Both make web HTML/CSS, so use
   them on an HTML mock only and build the real screen from the app's tokens. Do not
   install their hooks during a run. Say in the gate report what each tool found and what
   you changed.
4. Attach the captures to the ticket (`create_attachment`).
5. **STOP.** Call `AskUserQuestion` for explicit design approval before writing more
   code. If you took path 1, state that and why, and continue.

## Step 3: Plan the work (full lane)

1. Run `/plan-eng-review`. Skip it only if the ticket is pure UI with no logic, data
   model or API change.
2. Run `/plan-design-review`. Skip it only if the ticket has no UI change.
3. Every ticket gets at least one of the two. Fold their feedback into the plan before
   writing code.
4. **Write the acceptance tests with a subagent, after `/plan-eng-review` and before any
   implementation.** Skip this item only if `/plan-eng-review` was skipped. Spawn one
   subagent with the `Agent` tool and no `isolation: "worktree"`, and pass it the reviewed
   plan with this text:

   > In the worktree at <absolute path>, write the test cases that the code for <ID> must
   > pass. Use the ticket's acceptance criteria, the reviewed plan below, and the test
   > setup the repo already has. Cover each criterion, plus the edge and failure cases the
   > plan names. Test behavior, not internals. Write tests only: no implementation code.
   > Run them and report which fail and why. List every criterion a test cannot check.
   > Commit only the tests: `git commit -m "test: acceptance tests for <ID>"`.

   - **Check the result.** Each new test must fail because the behavior is missing, not
     because of a typo or broken setup. A test that already passes proves nothing: fix it
     or drop it.
   - **Criteria no test can check** (visual, device-only) go on the Step 5 demo list.
   - **No test runner in the repo:** do not add one on your own. Call `AskUserQuestion`
     to add one or skip this item.
   - **No `Agent` tool in this run:** write the tests yourself now, before any
     implementation, and say so in the final report.

## Step 4: Implement

1. **Write the code with `ponytail`.** Load the `ponytail` skill and follow it: the
   smallest change that fully solves the ticket, reuse before new files, no speculative
   options. It must not cut validation, error handling, security checks, accessibility
   labels or tests. A diff smaller than the plan is fine. A diff that drops an acceptance
   criterion is not.
2. **Run `/ponytail-review` on the diff before any tests or demo.** Fix its Must-fix
   findings. A missing-test finding is handled by the next item. Note what it removed.
3. **New non-trivial logic gets a test** (a branch, a parser, a bug fix, money, auth, data
   writes). One test that fails when the logic breaks. A bug fix gets a test that fails
   before the fix. The Step 3 acceptance tests count: add only what they miss.
4. **Native changes need a rebuild.** A native dependency, config plugin, entitlement or
   `app.json` `ios`/`plugins` change does not hot reload. Run `npx expo prebuild` if
   needed and rebuild before you trust any result.
5. **Run every command in `checks`** (for example `npx tsc --noEmit` and
   `npx vitest run`) from the worktree. Write down pass counts. If a check fails, run it
   on a clean `origin/<base_branch>` worktree too, so you report only the failures you
   added.
   - **Every acceptance test from Step 3 must pass.** Never weaken, skip or delete one to
     get there. If a test contradicts the ticket, stop and ask, then record the change in
     the final report.

## Step 5: Demo and QA

Full lane:

1. **Format: MP4** from a real simulator recording. Not a GIF, not a slideshow. The
   commands are in the runbook.
2. **Show every change**: one segment per distinct state the change touches, including
   error and cancel paths.
3. **UI changes: record on every device in `ios.devices`, in light and dark.** Record only
   the device families the app ships: check `UIDeviceFamily` / `supportsTablet`. An
   iPhone-only app on iPad shows the same iPhone layout, so an iPad pass proves nothing.
4. **Watch the recording.** Look for broken layout, unreadable contrast, wrong theme
   tokens, clipped text at large Dynamic Type, and layout shift. Fix and re-record. This
   loop needs no user stop.
5. Use real, live data over a mock where you can reach it.
6. Attach the MP4 to the ticket (`create_attachment`, or `prepare_attachment_upload` for
   large files).
7. If nothing in the session can record video, ask the user how to capture the demo. Do
   not quietly drop to a lesser format.

Fast lane: the demo is the `checks` output, the diff summary, and one screenshot if
anything visible changed.

8. **STOP: demo approval.** Call `AskUserQuestion` for explicit approval before any part
   of Step 6. Attaching the demo and moving on without approval is the exact failure this
   gate exists to stop.

## Step 6: Security gate, then land

Start only after the Step 5 demo is approved.

1. **Confirm the scope first.** From the worktree, run
   `git diff --stat origin/<base_branch>...HEAD`. It must list your files. Keep that list.
2. Run `/cso`, then `security-review`, both from inside the worktree.
3. **What counts as a pass:**
   - The tool's report names the files from item 1. A report on an empty diff, or on the
     main checkout instead of the worktree, is **not a pass**, even if it says "no
     findings". `security-review` reads git state from the session's main working
     directory, so in a worktree it often reviews nothing. If that happens, re-run it on
     the branch explicitly, or review the diff yourself against its checklist and say so.
   - No high or critical findings left. Every finding is fixed, or the user explicitly
     accepts it in `AskUserQuestion`.
   - A tool that reports `not assessed` (missing toolchain) did not pass. Tell the user
     what is missing and let them decide.
4. **Bring the branch up to date.** `git fetch origin <base_branch>`, then
   `git rebase origin/<base_branch>` in the worktree.
   - Resolve conflicts so that code already landed keeps working: keep what both sides
     meant. If keeping both needs a judgment about which behavior is correct, stop and
     ask.
   - A clean auto-merge can still be wrong. Read every file both sides touched and check
     that it still makes sense.
   - Re-run every command in `checks` after the rebase.
5. **Land by `land_mode`:**
   - `pr`: `git push -u origin <branch>`, then `gh pr create --base <base_branch>`. The
     body gives what shipped, the Linear ID with a closing keyword (`Closes ENG-12`),
     the demo, and the **Not checked** list. Do not put closing keywords in commit
     messages. Do not merge your own PR. Move the ticket to **In Review** and link the PR.
   - `merge`: check out local `<base_branch>` and run `git merge --ff-only
     origin/<base_branch>`. Confirm it matches the remote. Merge the branch, re-run
     `checks`, and push `<base_branch>`. If local `<base_branch>` had commits that are
     not on the remote, list them and get approval before pushing, because the push
     would publish them. Confirm `git rev-parse HEAD` equals
     `git rev-parse origin/<base_branch>`, then move the ticket to **Done**. With
     `--in-review`, move it to **In Review** and put the merge commit in a ticket comment.
6. **Simulator-unverifiable criteria go to In Review, not Done.** Examples: lock-screen
   and Control Center media, push delivery, real background execution, anything that
   needs a physical device. Judge each acceptance criterion separately: one criterion
   like this keeps the whole ticket at In Review. Leave a numbered device checklist in a
   ticket comment.
7. **If the push or PR worked but the Linear write failed**, do not retry silently and do
   not undo the land. Say the code landed and the status did not, give the ticket ID and
   the target status, and let the user fix it.

## Step 7: Clean up

After you confirm the land worked, **STOP and call `AskUserQuestion`** to ask whether to
delete the worktree. In `pr` mode, say that review changes would mean recreating it. On
yes, use `ExitWorktree` with `action: "remove"` or `git worktree remove <path>`. On no,
tell the user where the worktree lives.

## Resuming

A run can die between gates. Before Step 1, look for earlier work on this ticket:
`git worktree list`, `git branch --list '<id-lowercase>-*'`, the ticket's attachments and
status, and `gh pr list --head <branch>`.

If you find any, use `AskUserQuestion` to ask whether to resume or start fresh. To resume,
work out the step from the evidence and continue from the first step without it:

| Evidence | Resume at |
| --- | --- |
| Worktree only, no commits | Step 2 (or Step 4 in the fast lane) |
| Only the acceptance-test commit | Step 4 |
| Commits, no demo attached | Step 4.5 (re-run `checks`), then Step 5 |
| Demo attached, not approved | Step 5.8 |
| PR open, or branch landed | Step 6.5's Linear write, then Step 7 |

Never assume a gate was approved because its artifact exists. Ask again.

Run flags are not stored: a resumed run uses the flags given this time. If the branch
was not cut from this run's `<base_branch>`, ask before you continue.

## Final report

End every run, and every ticket in a batch, with this block:

```
Ticket:    ENG-12 Sign in with Apple
Result:    landed on main | PR open <url> | stopped at <gate> | failed at <step>
Lane:      full | fast
Branch:    eng-12-sign-in-button (worktree: <path or "removed">)
Checks:    tsc ok, vitest 412/412 ok (on rebased branch)
Acceptance: 6/6 pass, written before the code, 0 changed | skipped: <reason>
Security:  cso: no findings (7 files in scope); security-review: 1 low, accepted by user
Demo:      <attachment or path>
Linear:    assignee <name>, status <status>
Not checked: <each thing that mattered and could not be checked, or "nothing">
```

`Not checked` is required. Leave out no limit you know about. A green report that hides a
gap is worse than a red one.
