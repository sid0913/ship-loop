# Install

Run `./install.sh --check ios` or `./install.sh --check web` at any time to see what is
missing. Everything below is for macOS with [Homebrew](https://brew.sh).

## Required for both skills

| Prereq | Why | Install |
| --- | --- | --- |
| Claude Code | Runs the skills | <https://docs.anthropic.com/en/docs/claude-code> |
| git, python3 | Worktrees; the assignee script | `xcode-select --install` |
| GitHub CLI, signed in | Opens PRs, finds earlier runs | `brew install gh && gh auth login` |
| Node.js + npm | Project checks, Expo/Metro, web dev servers | `brew install node` |
| ffmpeg | Converts demo recordings to MP4 | `brew install ffmpeg` |
| Linear MCP | Reads tickets, assigns, sets status, attaches demos | see [Linear](#linear) |
| gstack | `/plan-eng-review`, `/plan-design-review`, `/cso`, `/design-html`, `/browse` | see [gstack](#gstack) |
| ponytail | `ponytail` (Step 4) and `/ponytail-review` | see [ponytail](#ponytail) |

`security-review` is built into Claude Code and needs no install.

### gstack

gstack needs [Bun](https://bun.sh) 1.3.3 or newer:

```bash
curl -fsSL https://bun.sh/install | bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

`/cso` also needs Xcode command line tools on macOS. If they are missing, `/cso` reports
`not assessed`, and ship-loop treats that as **not a pass**. Upgrade later with
`/gstack-upgrade`. Details: <https://github.com/garrytan/gstack>.

### ponytail

In Claude Code, send these as two separate prompts:

```
/plugin marketplace add DietrichGebert/ponytail
```
```
/plugin install ponytail@ponytail
```

The plugin's hooks need `node` on the PATH of a non-interactive shell. Other agents and
details: <https://github.com/DietrichGebert/ponytail/blob/main/INSTALL.md>.

### Linear

Either connect Linear in claude.ai (Settings → Connectors), or add the MCP server to Claude
Code:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

Then run `/mcp` in Claude Code and sign in. The skills call the tools by their plain names
(`get_issue`, `save_issue`, `list_users`, `create_attachment`), so either connection works.

Then set who your tickets go to:

```bash
bin/ship-loop-assignee "Your Linear name"
```

## Extra for `/ship-loop-ios`

| Prereq | Why | Install |
| --- | --- | --- |
| Xcode + an iOS Simulator runtime | Build, run and record the app | App Store, then `sudo xcode-select -s /Applications/Xcode.app`; add a runtime in Xcode → Settings → Components |
| Maestro | Drives the simulator (AppleScript and CGEvent do not work) | `curl -fsSL https://get.maestro.mobile.dev \| bash` |
| OpenJDK | Maestro needs Java | `brew install openjdk` (keg-only, so the runbook sets `JAVA_HOME`) |

## Optional

| Prereq | Used in | Install |
| --- | --- | --- |
| impeccable | Step 2: design and polish new UI | <https://github.com/pbakaus/impeccable> (follow its README) |
| hallmark | Step 2: audit the design | <https://github.com/Nutlope/hallmark> (follow its README) |
| Playwright | `/ship-loop-web` Step 5: real video instead of a screenshot slideshow | `npm i -D playwright && npx playwright install chromium` in the project |

Do not turn on impeccable's or ponytail's hooks from inside a ship-loop run. Hooks change
every later session.

## Install the skills

```bash
./install.sh                              # link both skills into ~/.claude/skills
./install.sh --project <repo> ios|web     # or copy one into a repo, with a starter config
./install.sh --uninstall                  # remove the links
```

Linked skills pick up `git pull` right away. Copied project skills do not: re-run
`--project` to update them.
