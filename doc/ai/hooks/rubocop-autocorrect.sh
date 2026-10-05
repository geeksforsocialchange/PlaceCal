#!/usr/bin/env bash
#
# Claude Code PostToolUse hook — auto-correct RuboCop on Ruby files the agent
# just edited, and surface any remaining offenses back so it fixes them itself.
#
# Why: letting the model self-correct RuboCop is unreliable (it skips files,
# defers, or hand-fixes instead of running auto-correct). A hook makes it
# deterministic. Installed into .claude/settings.json by bin/setup-ai.
#
# Protocol: reads the hook payload as JSON on stdin, runs `rubocop -A` on the
# edited file. Exit 0 = clean (or not applicable). Exit 2 = offenses remain;
# stderr is fed back to the agent as a non-blocking instruction to fix them.

set -uo pipefail

payload="$(cat)"

# Extract the edited file path (Write/Edit/MultiEdit all carry tool_input.file_path).
file="$(printf '%s' "$payload" \
  | ruby -rjson -e 'print(JSON.parse(STDIN.read).dig("tool_input", "file_path").to_s)' 2>/dev/null || true)"

[ -n "$file" ] && [ -f "$file" ] || exit 0

# Ruby files only.
case "$file" in
  *.rb | *.rake | *.gemspec | *Gemfile | *Rakefile | *.ru) : ;;
  *) exit 0 ;;
esac

# Need the project's bundle; no-op quietly if RuboCop isn't installed in this
# checkout (e.g. a fresh worktree) rather than breaking the agent's edit.
command -v bundle >/dev/null 2>&1 || exit 0
bundle exec rubocop --version >/dev/null 2>&1 || exit 0

# Auto-correct in place; --force-exclusion respects .rubocop.yml Exclude globs.
# `rubocop -A` exits non-zero iff offenses remain after correction.
output="$(bundle exec rubocop -A --force-exclusion "$file" 2>&1)"
status=$?

[ "$status" -eq 0 ] && exit 0

{
  echo "RuboCop auto-corrected what it could, but offenses remain in ${file}."
  echo "Fix them before continuing:"
  echo
  printf '%s\n' "$output"
} >&2
exit 2
