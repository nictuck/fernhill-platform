#!/usr/bin/env bash
# Gate 5: the agent may act up to the production gate and cannot pass it.
# Blocks production deploys from a Claude session. The release manager
# approves the `production` GitHub environment instead. (PreToolUse: Bash)
set -u
source "$(dirname "$0")/lib.sh"

if [ "${1:-}" = "--test" ]; then
  echo "production-gate.sh"
  fail=0
  run_case 2 "netlify deploy --prod"          "$(bash_cmd_json 'netlify deploy --prod --dir=dist')" || fail=1
  run_case 2 "netlify deploy --prodIfUnlocked" "$(bash_cmd_json 'netlify deploy --prodIfUnlocked')" || fail=1
  run_case 2 "netlify api restoreSiteDeploy"   "$(bash_cmd_json 'netlify api restoreSiteDeploy --data {}')" || fail=1
  run_case 2 "gh workflow run deploy prod"     "$(bash_cmd_json 'gh workflow run deploy.yml -f environment=production')" || fail=1
  run_case 2 "gh workflow run release"         "$(bash_cmd_json 'gh workflow run release.yml')" || fail=1
  run_case 0 "netlify deploy (preview)"        "$(bash_cmd_json 'netlify deploy --dir=dist --alias=staging')" || fail=1
  run_case 0 "netlify status"                  "$(bash_cmd_json 'netlify status')" || fail=1
  run_case 0 "unrelated"                       "$(bash_cmd_json 'npm test')" || fail=1
  exit $fail
fi

input=$(hook_input)
[ "$(json_field "$input" '.tool_name')" = "Bash" ] || exit 0
cmd=$(json_field "$input" '.tool_input.command')
[ -n "$cmd" ] || exit 0

reason="Blocked by production-gate hook: production releases are authorized by the release manager in GitHub (Actions → release run → Review deployments → production → Approve). Merging to main already deploys staging; tell the human it is ready."

if printf '%s' "$cmd" | grep -Eq 'netlify[[:space:]]+deploy\b.*--prod'; then block "$reason"; fi
if printf '%s' "$cmd" | grep -Eq 'netlify[[:space:]]+api[[:space:]]+(restoreSiteDeploy|lockDeploy|unlockDeploy)'; then block "$reason"; fi
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+workflow[[:space:]]+run\b.*(prod|production|release)'; then block "$reason"; fi

exit 0
