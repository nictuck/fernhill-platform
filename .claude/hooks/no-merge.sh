#!/usr/bin/env bash
# Gate: the agent has no route to main or production.
# Blocks merging, approving, pushing to main/production and starting
# release runs from a Claude session. A human does these in GitHub.
#
# Exception: `gh pr merge` is allowed when the command names an exception
# id (EX-NNN) and that exception is `active`, unexpired and grants `merge`
# on the platform's origin/main (see exceptions/README.md). Nothing else
# is ever delegated. (PreToolUse, matcher: Bash)
set -u
source "$(dirname "$0")/lib.sh"

# ---- exceptions ---------------------------------------------------------------
exceptions_platform() { # prints the platform checkout that holds exceptions/
  local root="${CLAUDE_PROJECT_DIR:-$PWD}"
  if [ -d "$root/exceptions" ]; then printf '%s' "$root"; return 0; fi
  if [ -f "$root/.sdlc.yaml" ]; then
    local rel; rel=$(sed -n 's/^platform_path: *\([^ #]*\).*/\1/p' "$root/.sdlc.yaml")
    if [ -n "$rel" ] && [ -d "$root/$rel/exceptions" ]; then printf '%s' "$root/$rel"; return 0; fi
  fi
  return 1
}

exception_text() { # exception_text <id> — the file as it is on origin/main
  local id="$1"
  if [ -n "${SDLC_EXCEPTIONS_DIR:-}" ]; then            # --test mode
    cat "$SDLC_EXCEPTIONS_DIR"/"$id"-*.md 2>/dev/null; return
  fi
  local platform path
  platform=$(exceptions_platform) || return 1
  path=$(git -C "$platform" ls-tree --name-only origin/main exceptions/ 2>/dev/null | grep -m1 "^exceptions/$id-") || return 1
  git -C "$platform" show "origin/main:$path" 2>/dev/null
}

exception_grants() { # exception_grants <id> <grant> → 0 if active, unexpired and granting
  local id="$1" grant="$2" text exp
  text=$(exception_text "$id") || return 1
  [ -n "$text" ] || return 1
  printf '%s\n' "$text" | grep -q '^status: *active *$' || return 1
  printf '%s\n' "$text" | sed -n 's/^grants: *//p' | tr -d '[]' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -qx "$grant" || return 1
  exp=$(printf '%s\n' "$text" | sed -n 's/^expires: *//p' | head -1)
  if [ -n "$exp" ] && [[ "$(date +%F)" > "$exp" ]]; then return 1; fi
  return 0
}

# ---- self-test ----------------------------------------------------------------------
if [ "${1:-}" = "--test" ]; then
  echo "no-merge.sh"
  fail=0
  run_case 2 "gh pr merge"              "$(bash_cmd_json 'gh pr merge 12 --squash')" || fail=1
  run_case 2 "gh pr review --approve"   "$(bash_cmd_json 'gh pr review 12 --approve')" || fail=1
  run_case 2 "git push origin main"     "$(bash_cmd_json 'git push origin main')" || fail=1
  run_case 2 "git push HEAD:main"       "$(bash_cmd_json 'git push -u origin HEAD:main')" || fail=1
  run_case 2 "git push to production"   "$(bash_cmd_json 'git push origin HEAD:production')" || fail=1
  run_case 2 "git push origin production" "$(bash_cmd_json 'git push origin production')" || fail=1
  run_case 2 "gh workflow run release"  "$(bash_cmd_json 'gh workflow run release.yml -f sha=abc')" || fail=1
  run_case 2 "gh api approve deploy"    "$(bash_cmd_json 'gh api -X POST repos/x/y/actions/runs/1/pending_deployments')" || fail=1
  run_case 2 "gh api review APPROVE"    "$(bash_cmd_json 'gh api repos/x/y/pulls/1/reviews -f event=APPROVE')" || fail=1
  run_case 0 "git push feature branch"  "$(bash_cmd_json 'git push -u origin intent/0001-flow')" || fail=1
  run_case 0 "gh pr create"             "$(bash_cmd_json 'gh pr create --fill')" || fail=1
  run_case 0 "gh pr review --comment"   "$(bash_cmd_json 'gh pr review 12 --comment -b "looks fine"')" || fail=1
  run_case 0 "git checkout main"        "$(bash_cmd_json 'git checkout main && git pull')" || fail=1
  # exceptions
  tmp=$(mktemp -d); export SDLC_EXCEPTIONS_DIR="$tmp"
  tomorrow=$(date -v+1d +%F 2>/dev/null || date -d tomorrow +%F)
  printf -- '---\nid: EX-001\nstatus: active\ngrants: [merge]\nexpires: %s\n---\n' "$tomorrow" > "$tmp/EX-001-ok.md"
  printf -- '---\nid: EX-002\nstatus: active\ngrants: [merge]\nexpires: 2020-01-01\n---\n' > "$tmp/EX-002-expired.md"
  printf -- '---\nid: EX-003\nstatus: revoked\ngrants: [merge]\nexpires: %s\n---\n' "$tomorrow" > "$tmp/EX-003-revoked.md"
  printf -- '---\nid: EX-004\nstatus: active\ngrants: [approve-plan]\nexpires: %s\n---\n' "$tomorrow" > "$tmp/EX-004-other-grant.md"
  run_case 0 "merge under active exception"   "$(bash_cmd_json 'gh pr merge 5 --squash --delete-branch --body "Merged under EX-001 after /review: ok"')" || fail=1
  run_case 2 "merge naming expired exception" "$(bash_cmd_json 'gh pr merge 5 --squash --body "Merged under EX-002"')" || fail=1
  run_case 2 "merge naming revoked exception" "$(bash_cmd_json 'gh pr merge 5 --squash --body "Merged under EX-003"')" || fail=1
  run_case 2 "merge naming wrong grant"       "$(bash_cmd_json 'gh pr merge 5 --squash --body "Merged under EX-004"')" || fail=1
  run_case 2 "merge naming unknown exception" "$(bash_cmd_json 'gh pr merge 5 --squash --body "Merged under EX-099"')" || fail=1
  run_case 2 "push main even with exception"  "$(bash_cmd_json 'git push origin main # EX-001')" || fail=1
  run_case 2 "approve even with exception"    "$(bash_cmd_json 'gh pr review 5 --approve -b EX-001')" || fail=1
  rm -rf "$tmp"; unset SDLC_EXCEPTIONS_DIR
  exit $fail
fi

# ---- the gate -------------------------------------------------------------------------
input=$(hook_input)
[ "$(json_field "$input" '.tool_name')" = "Bash" ] || exit 0
cmd=$(json_field "$input" '.tool_input.command')
[ -n "$cmd" ] || exit 0

reason="Blocked by no-merge hook: the agent has no route to main or production. A human merges, approves and releases in GitHub (docs/flow.md, gates 4-5)."

# gh pr merge — allowed only under a named, active exception that grants merge
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+merge\b'; then
  id=$(printf '%s' "$cmd" | grep -oE 'EX-[0-9]{3}' | head -1 || true)
  if [ -n "$id" ] && exception_grants "$id" merge; then
    :
  else
    block "$reason If an exception in exceptions/ is active and grants merge, run /review first and name the id in the merge body: gh pr merge N --squash --body 'Merged under EX-001 after /review: …'. ${id:+($id is not active, has expired, or does not grant merge.)}"
  fi
fi
# approving is never delegated
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+review\b.*--approve'; then block "$reason"; fi
# starting a release run is the release manager's act
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+workflow[[:space:]]+run\b.*release'; then block "$reason"; fi
# gh api routes that approve reviews or pending deployments
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+api\b.*pending_deployments'; then block "$reason"; fi
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+api\b.*/pulls/.*(APPROVE|/merge)'; then block "$reason"; fi
# git push to main or production (origin main, HEAD:main, refs/heads/main, --delete main)
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+push\b' \
   && printf '%s' "$cmd" | grep -Eq '(^|[[:space:]:/])(main|production)([[:space:]]|$)'; then block "$reason"; fi

exit 0
