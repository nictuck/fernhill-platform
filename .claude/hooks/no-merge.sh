#!/usr/bin/env bash
# Gate: the agent has no route to main.
# Blocks merging, approving, and pushing to main from a Claude session.
# A human does these in GitHub. (PreToolUse, matcher: Bash)
set -u
source "$(dirname "$0")/lib.sh"

if [ "${1:-}" = "--test" ]; then
  echo "no-merge.sh"
  fail=0
  run_case 2 "gh pr merge"              "$(bash_cmd_json 'gh pr merge 12 --squash')" || fail=1
  run_case 2 "gh pr review --approve"   "$(bash_cmd_json 'gh pr review 12 --approve')" || fail=1
  run_case 2 "git push origin main"     "$(bash_cmd_json 'git push origin main')" || fail=1
  run_case 2 "git push HEAD:main"       "$(bash_cmd_json 'git push -u origin HEAD:main')" || fail=1
  run_case 2 "gh api approve deploy"    "$(bash_cmd_json 'gh api -X POST repos/x/y/actions/runs/1/pending_deployments')" || fail=1
  run_case 2 "gh api review APPROVE"    "$(bash_cmd_json 'gh api repos/x/y/pulls/1/reviews -f event=APPROVE')" || fail=1
  run_case 0 "git push feature branch"  "$(bash_cmd_json 'git push -u origin intent/0001-flow')" || fail=1
  run_case 0 "gh pr create"             "$(bash_cmd_json 'gh pr create --fill')" || fail=1
  run_case 0 "gh pr review --comment"   "$(bash_cmd_json 'gh pr review 12 --comment -b "looks fine"')" || fail=1
  run_case 0 "git checkout main"        "$(bash_cmd_json 'git checkout main && git pull')" || fail=1
  exit $fail
fi

input=$(hook_input)
[ "$(json_field "$input" '.tool_name')" = "Bash" ] || exit 0
cmd=$(json_field "$input" '.tool_input.command')
[ -n "$cmd" ] || exit 0

reason="Blocked by no-merge hook: the agent has no route to main. A human merges, approves and releases in GitHub (docs/flow.md, gates 4-5)."

# gh pr merge / gh pr review --approve
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+merge\b'; then block "$reason"; fi
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+review\b.*--approve'; then block "$reason"; fi
# gh api routes that approve reviews or pending deployments
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+api\b.*pending_deployments'; then block "$reason"; fi
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+api\b.*/pulls/.*(APPROVE|/merge)'; then block "$reason"; fi
# git push to main (origin main, HEAD:main, refs/heads/main, --delete main)
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+push\b' \
   && printf '%s' "$cmd" | grep -Eq '(^|[[:space:]:/])main([[:space:]]|$)'; then block "$reason"; fi

exit 0
