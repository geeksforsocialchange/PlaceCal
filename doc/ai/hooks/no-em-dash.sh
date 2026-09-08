#!/usr/bin/env bash
#
# Claude Code PostToolUse hook - flag em and en dashes in files the agent just
# edited, so it strips them before moving on.
#
# Why: the house style bans em/en dashes in prose, comments and copy (they read
# as an AI tell). The model forgets. A hook makes it deterministic. Installed
# into .claude/settings.json by bin/setup-ai.
#
# Protocol: reads the hook payload as JSON on stdin. Exit 0 = clean or not
# applicable. Exit 2 = dashes found; stderr is fed back to the agent as an
# instruction to remove them.

set -uo pipefail

payload="$(cat)"

file="$(printf '%s' "$payload" \
  | ruby -rjson -e 'print(JSON.parse(STDIN.read).dig("tool_input", "file_path").to_s)' 2>/dev/null || true)"

[ -n "$file" ] && [ -f "$file" ] || exit 0

# Text and source files only; skip vendored and generated trees where a dash
# may be legitimate data we do not own.
case "$file" in
  */vendor/* | */node_modules/* | */public/assets/* | */app/assets/builds/*) exit 0 ;;
esac
case "$file" in
  *.rb | *.rake | *.ru | *.gemspec | *Gemfile | *Rakefile | *.erb | *.haml | \
  *.md | *.markdown | *.yml | *.yaml | *.js | *.ts | *.css | *.scss | *.json | *.txt) : ;;
  *) exit 0 ;;
esac

# Report every line carrying an em dash (U+2014), en dash (U+2013) or
# horizontal bar (U+2015). Ruby, not grep: BSD grep has no -P for \x escapes.
hits="$(ruby -e '
  file = ARGV[0]
  File.foreach(file, encoding: "UTF-8").with_index(1) do |line, n|
    puts "#{n}:#{line}" if line.match?(/[\u2013\u2014\u2015]/)
  end
' "$file" 2>/dev/null || true)"

[ -z "$hits" ] && exit 0

{
  echo "Em or en dashes found in ${file}. The house style bans them: replace with"
  echo "full stops, commas, parentheses or colons, then continue."
  echo
  printf '%s\n' "$hits"
} >&2
exit 2
