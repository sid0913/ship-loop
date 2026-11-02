#!/usr/bin/env bash
# ship-loop installer.
#   ./install.sh                        link both skills into ~/.claude/skills, then check prereqs
#   ./install.sh --project DIR ios|web  copy one skill into DIR/.claude/skills and add a starter config
#   ./install.sh --check [ios|web]      only check prereqs
#   ./install.sh --uninstall            remove the links from ~/.claude/skills
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
skills_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
missing=0

usage() { sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

have() { # label, test command..., hint
  local label="$1" hint="${*: -1}"; shift
  if "${@:1:$#-1}" >/dev/null 2>&1; then printf '  ok       %s\n' "$label"
  else printf '  MISSING  %s  ->  %s\n' "$label" "$hint"; missing=$((missing + 1)); fi
}
optional() {
  local label="$1" hint="${*: -1}"; shift
  if "${@:1:$#-1}" >/dev/null 2>&1; then printf '  ok       %s\n' "$label"
  else printf '  optional %s  ->  %s\n' "$label" "$hint"; fi
}
skill_installed() { # name: as a skill or inside a plugin
  [ -f "$skills_dir/$1/SKILL.md" ] ||
    find "$HOME/.claude/plugins" -path "*/skills/$1/SKILL.md" -print -quit 2>/dev/null | grep -q .
}

check() {
  local variant="${1:-all}"
  echo "Prerequisites (see INSTALL.md for each one):"
  have "git" command -v git "install Xcode command line tools: xcode-select --install"
  have "claude (Claude Code)" command -v claude "https://docs.anthropic.com/en/docs/claude-code"
  have "gh, signed in" gh auth status "brew install gh && gh auth login"
  have "python3" command -v python3 "xcode-select --install"
  have "node + npm" command -v npm "brew install node"
  have "ffmpeg" command -v ffmpeg "brew install ffmpeg"
  have "bun (for gstack)" command -v bun "curl -fsSL https://bun.sh/install | bash"
  have "gstack skills" test -d "$skills_dir/gstack" "see INSTALL.md: gstack"
  have "ponytail skill" skill_installed ponytail "/plugin marketplace add DietrichGebert/ponytail, then /plugin install ponytail@ponytail"
  if [ "$variant" = ios ] || [ "$variant" = all ]; then
    have "xcodebuild (Xcode)" xcodebuild -version "install Xcode from the App Store, then: sudo xcode-select -s /Applications/Xcode.app"
    have "iOS Simulator" xcrun simctl help "Xcode > Settings > Components: add an iOS simulator runtime"
    have "maestro" test -x "$HOME/.maestro/bin/maestro" "curl -fsSL https://get.maestro.mobile.dev | bash"
    have "openjdk (for maestro)" test -x /opt/homebrew/opt/openjdk/bin/java "brew install openjdk"
  fi
  optional "impeccable skill" skill_installed impeccable "see INSTALL.md: impeccable"
  optional "hallmark skill" skill_installed hallmark "see INSTALL.md: hallmark"
  if [ "$variant" = web ] || [ "$variant" = all ]; then
    optional "playwright (real web recordings)" npx --no-install playwright --version "npm i -D playwright && npx playwright install chromium"
  fi
  echo "  check by hand: Linear MCP is connected (claude mcp list, or claude.ai connector)"
  local assignee
  if assignee="$("$here/bin/ship-loop-assignee" --show 2>/dev/null)"; then echo "  ok       assignee: $assignee"
  else echo "  not set  assignee  ->  $here/bin/ship-loop-assignee \"Your Linear name\""; fi
  [ "$missing" -eq 0 ] && echo "All required prereqs found." || echo "$missing required prereq(s) missing."
}

link_skills() {
  mkdir -p "$skills_dir"
  for s in ship-loop-ios ship-loop-web; do
    local dest="$skills_dir/$s"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      echo "skip $dest: a real folder is already there. Move it away and re-run."; continue
    fi
    ln -sfn "$here/skills/$s" "$dest"; echo "linked $dest -> $here/skills/$s"
  done
}

install_project() { # dir variant
  local dir="$1" v="$2"
  [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || { echo "$dir is not a git repo"; exit 1; }
  case "$v" in ios|web) ;; *) usage 1 ;; esac
  mkdir -p "$dir/.claude/skills"
  rm -rf "$dir/.claude/skills/ship-loop-$v"
  cp -R "$here/skills/ship-loop-$v" "$dir/.claude/skills/ship-loop-$v"
  echo "copied skill -> $dir/.claude/skills/ship-loop-$v"
  if [ ! -f "$dir/.claude/ship-loop.json" ]; then
    cp "$here/examples/ship-loop.$v.json" "$dir/.claude/ship-loop.json"
    echo "wrote starter $dir/.claude/ship-loop.json: edit it before the first run"
  fi
  if ! grep -qxF ".claude/ship-loop.local.json" "$dir/.gitignore" 2>/dev/null; then
    [ -s "$dir/.gitignore" ] && [ -n "$(tail -c1 "$dir/.gitignore")" ] && echo >> "$dir/.gitignore"
    echo ".claude/ship-loop.local.json" >> "$dir/.gitignore"; echo "gitignored .claude/ship-loop.local.json"
  fi
}

case "${1:-}" in
  "") link_skills; check all ;;
  --project) [ $# -eq 3 ] || usage 1; install_project "$2" "$3"; check "$3" ;;
  --check) check "${2:-all}" ;;
  --uninstall)
    for s in ship-loop-ios ship-loop-web; do
      [ -L "$skills_dir/$s" ] && rm "$skills_dir/$s" && echo "removed $skills_dir/$s"
    done; true ;;
  -h|--help) usage ;;
  *) usage 1 ;;
esac
