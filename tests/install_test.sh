#!/usr/bin/env bash
#
# Smoke tests for install.sh. Installs Sly from this checkout into throwaway
# folders and checks the resulting files.
#
#   ./tests/install_test.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$ROOT/install.sh"
FAILURES=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() {
  printf '  \033[31m✗\033[0m %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

assert_file() { if [ -f "$1" ]; then pass "$2"; else fail "$2 (missing $1)"; fi; }
assert_no_path() { if [ ! -e "$1" ]; then pass "$2"; else fail "$2 ($1 exists)"; fi; }
assert_contains() { if grep -qF -- "$2" "$1"; then pass "$3"; else fail "$3 ('$2' not in $1)"; fi; }

new_project() { mktemp -d; }

sly() { bash "$INSTALL" --source "$ROOT" "$@" >/dev/null; }

COMMANDS="$(for f in "$ROOT"/core/commands/*.md; do basename "$f" .md; done)"

echo "fresh install with every IDE"
P="$(new_project)"
sly --dir "$P" --ide all
assert_file "$P/.sly/rules.md" "core rules copied"
assert_file "$P/.sly/commands/goal.md" "core commands copied"
assert_file "$P/.sly/templates/plan.md" "core templates copied"
assert_contains "$P/.sly/.manifest" "version=local" "manifest records version"
for name in $COMMANDS; do
  assert_file "$P/.agents/skills/sly.$name/SKILL.md" "antigravity: sly.$name"
  assert_file "$P/.claude/commands/sly.$name.md" "claude: sly.$name"
  assert_file "$P/.github/prompts/sly.$name.prompt.md" "copilot: sly.$name"
  assert_file "$P/.cursor/commands/sly.$name.md" "cursor: sly.$name"
  assert_file "$P/.gemini/commands/sly.$name.toml" "gemini: sly.$name"
done
assert_contains "$P/.agents/skills/sly.goal/SKILL.md" "name: sly.goal" "antigravity skill has a name"
assert_contains "$P/.agents/skills/sly.goal/SKILL.md" 'description: "Creates a feature goal' "adapter description comes from the command frontmatter"
assert_contains "$P/.claude/commands/sly.goal.md" '.sly/commands/goal.md' "adapter points at the core command"

echo "upgrade switching IDEs keeps project files"
mkdir -p "$P/.sly/memory" "$P/.github/workflows"
echo "my lore" >"$P/.sly/memory/lore.md"
echo "ci" >"$P/.github/workflows/ci.yml"
sly --dir "$P" --ide claude
assert_file "$P/.claude/commands/sly.goal.md" "claude adapters still there"
assert_no_path "$P/.agents" "antigravity adapters removed (and empty folders pruned)"
assert_no_path "$P/.github/prompts" "copilot adapters removed"
assert_file "$P/.github/workflows/ci.yml" "unrelated files in shared folders kept"
assert_contains "$P/.sly/memory/lore.md" "my lore" "lore preserved"

echo "upgrade without --ide reuses previous IDEs"
sly --dir "$P"
assert_contains "$P/.sly/.manifest" "ides=claude" "previous IDEs reused"
assert_file "$P/.claude/commands/sly.goal.md" "claude adapters reinstalled"

echo "uninstall"
bash "$INSTALL" --dir "$P" --uninstall >/dev/null
assert_no_path "$P/.claude" "adapters removed"
assert_no_path "$P/.sly/commands" "core removed"
assert_no_path "$P/.sly/.manifest" "manifest removed"
assert_contains "$P/.sly/memory/lore.md" "my lore" "lore kept after uninstall"
rm -rf "$P"

echo "invalid input"
P="$(new_project)"
if bash "$INSTALL" --source "$ROOT" --dir "$P" --ide notepad >/dev/null 2>&1; then
  fail "unknown IDE rejected"
else
  pass "unknown IDE rejected"
fi
assert_no_path "$P/.sly" "nothing written on error"
rm -rf "$P"

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES check(s) failed"
  exit 1
fi
echo "all checks passed"
