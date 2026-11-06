#!/usr/bin/env bash
# Checks the skills for the drift and mistakes that broke earlier copies. Run: tests/run.sh
set -uo pipefail
cd "$(dirname "$0")/.."
fails=0
ok()   { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
t()    { local name="$1"; shift; if "$@"; then ok "$name"; else fail "$name"; fi; }

skills=(skills/ship-loop-ios/SKILL.md skills/ship-loop-web/SKILL.md)

frontmatter_name() { awk 'NR==1 && $0!="---"{exit 1} NR>1 && /^---$/{exit} /^name:/{print $2}' "$1"; }

# Numbered list items inside each "## " section must count 1,2,3... with no gaps or repeats.
numbering_ok() {
  awk '
    /^```/ { code = !code; next }
    code { next }
    /^## / { n = 0; sec = $0; next }
    /^[0-9]+\. / { k = $0 + 0; if (k != n + 1) { printf "  %s: item %d after %d\n", sec, k, n; bad = 1 } n = k }
    END { exit bad }
  ' "$1"
}

steps_ok() { # "## Step N" headers run 0..7 in order
  [ "$(grep -oE '^## Step [0-9]+' "$1" | awk '{print $3}' | tr '\n' ' ')" = "0 1 2 3 4 5 6 7 " ]
}

section() { awk "/<!-- $2:start -->/{f=1} f{print} /<!-- $2:end -->/{f=0}" "$1"; }

links_ok() { # every relative markdown link resolves
  local f="$1" dir; dir="$(dirname "$f")"
  grep -oE '\]\([^)#:]+\)' "$f" | sed 's/^](//; s/)$//' | while read -r l; do
    [ -e "$dir/$l" ] || { echo "  broken link $l"; exit 1; }
  done
}

for f in "${skills[@]}"; do
  d="$(basename "$(dirname "$f")")"
  t "$d: frontmatter name matches folder" [ "$(frontmatter_name "$f")" = "$d" ]
  t "$d: has a description" grep -q '^description: .\{40,\}' "$f"
  t "$d: Steps 0-7 in order" steps_ok "$f"
  t "$d: list numbering has no gaps" numbering_ok "$f"
  t "$d: no personal email addresses" bash -c "! grep -qE '[A-Za-z0-9._%+-]+@(gmail|icloud|yahoo|outlook)\.com' '$f'"
  t "$d: never assigns to Linear 'me'" bash -c "! grep -n 'assignee: \"me\"' '$f' | grep -v -i 'never'"
  t "$d: no hardcoded Linear MCP prefix" bash -c "! grep -q 'mcp__claude_ai_Linear__' '$f'"
  t "$d: no stale develop default" bash -c "! grep -qE 'merged into \`?develop|off \`?develop' '$f'"
  t "$d: uses ponytail in Step 4" bash -c "awk '/^## Step 4/{f=1} /^## Step 5/{f=0} f' '$f' | grep -q ponytail"
  t "$d: Step 4 requires tests" bash -c "awk '/^## Step 4/{f=1} /^## Step 5/{f=0} f' '$f' | grep -qi 'gets a test'"
  t "$d: ponytail-review runs before tests and checks" bash -c "awk '/^## Step 4/{f=1} /^## Step 5/{f=0} f' '$f' | grep -nE 'ponytail-review|gets a test|Run every command' | cut -d: -f2- | grep -q '^2\. .*ponytail-review'"
  t "$d: Step 3 has a subagent write acceptance tests" bash -c "awk '/^## Step 3/{f=1} /^## Step 4/{f=0} f' '$f' | grep -q 'acceptance tests with a subagent'"
  t "$d: Step 4 protects the acceptance tests" bash -c "awk '/^## Step 4/{f=1} /^## Step 5/{f=0} f' '$f' | grep -q 'Never weaken, skip or delete'"
  t "$d: Resuming handles a test-only commit" grep -q '^| Only the acceptance-test commit | Step 4 |' "$f"
  t "$d: final report has Acceptance" grep -q '^Acceptance:' "$f"
  t "$d: description lists the run flags" grep -q '^description: .*--merge-develop.*--in-review' "$f"
  t "$d: --merge-develop checks that develop exists" grep -q 'ls-remote --exit-code --heads origin develop' "$f"
  t "$d: --in-review changes the merge status" grep -q '`--in-review`, move it to \*\*In Review' "$f"
  t "$d: batch subagents get the flags" grep -q '<ID> <flags>. with three overrides' "$f"
  t "$d: security gate checks diff scope" grep -q 'git diff --stat origin/<base_branch>...HEAD' "$f"
  t "$d: final report has Not checked" grep -q '^Not checked:' "$f"
  t "$d: has Resuming section" grep -q '^## Resuming' "$f"
  t "$d: relative links resolve" links_ok "$f"
  for r in "$(dirname "$f")"/references/*.md; do
    t "$d: $(basename "$r") linked from SKILL.md" grep -q "references/$(basename "$r")" "$f"
  done
done

t "assignee section identical in both skills" \
  diff <(section "${skills[0]}" assignee) <(section "${skills[1]}" assignee)
t "assignee section present" bash -c "[ -n \"\$(awk '/<!-- assignee:start -->/' '${skills[0]}')\" ]"

for j in examples/*.json; do
  t "$j is valid JSON" python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' "$j"
done
t "ios example has every ios key the skill reads" python3 -I -c '
import json; c=json.load(open("examples/ship-loop.ios.json"))
assert {"base_branch","land_mode","checks","ios"} <= c.keys()
assert {"workspace","scheme","bundle_id","devices"} <= c["ios"].keys()
assert c["land_mode"] in ("pr","merge")'
t "web example has every web key the skill reads" python3 -I -c '
import json; c=json.load(open("examples/ship-loop.web.json"))
assert {"base_branch","land_mode","checks","web"} <= c.keys()
assert {"dev_command","port"} <= c["web"].keys()
assert c["land_mode"] in ("pr","merge")'

# Scripts, run against a throwaway HOME so nothing real is touched.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config"; mkdir -p "$HOME"
t "scripts parse" bash -n install.sh bin/ship-loop-assignee
t "assignee: --show fails when unset" bash -c "! bin/ship-loop-assignee --show '$tmp' >/dev/null"
bin/ship-loop-assignee 'Ada "Al" Lovelace' >/dev/null
t "assignee: global write, quotes survive" bash -c "[ \"\$(bin/ship-loop-assignee --show '$tmp' | sed 's/  (from.*//')\" = 'Ada \"Al\" Lovelace' ]"
mkdir -p "$tmp/repo" && git -C "$tmp/repo" init -q
bin/ship-loop-assignee --project "$tmp/repo" "Grace" >/dev/null
t "assignee: project slot wins over global" bash -c "bin/ship-loop-assignee --show '$tmp/repo' | grep -q '^Grace '"
t "assignee: project slot is gitignored" grep -qxF ".claude/ship-loop.local.json" "$tmp/repo/.gitignore"
mkdir -p "$tmp/nonl" && git -C "$tmp/nonl" init -q && printf 'node_modules' > "$tmp/nonl/.gitignore"
bin/ship-loop-assignee --project "$tmp/nonl" "Grace" >/dev/null
t "assignee: gitignore without trailing newline keeps both lines" \
  bash -c "grep -qxF node_modules '$tmp/nonl/.gitignore' && grep -qxF .claude/ship-loop.local.json '$tmp/nonl/.gitignore'"
CLAUDE_SKILLS_DIR="$tmp/skills" ./install.sh >/dev/null 2>&1
t "install: links both skills" bash -c "[ -L '$tmp/skills/ship-loop-ios' ] && [ -f '$tmp/skills/ship-loop-web/SKILL.md' ]"
./install.sh --project "$tmp/repo" web >/dev/null 2>&1
t "install --project: copies skill + config" bash -c "[ -f '$tmp/repo/.claude/skills/ship-loop-web/SKILL.md' ] && [ -f '$tmp/repo/.claude/ship-loop.json' ]"
t "install --project: gitignore not duplicated" [ "$(grep -cxF ".claude/ship-loop.local.json" "$tmp/repo/.gitignore")" = 1 ]
CLAUDE_SKILLS_DIR="$tmp/skills" ./install.sh --uninstall >/dev/null
t "install --uninstall: removes links" bash -c "[ ! -e '$tmp/skills/ship-loop-ios' ]"

echo
[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
