#!/usr/bin/env bash
# Shared helpers for Fernhill hooks. Source, don't execute.
#
# Hooks read one JSON object on stdin (Claude Code PreToolUse/PostToolUse
# payload) and exit 0 to allow or 2 to block; stderr on exit 2 is shown to
# the agent. Every hook supports `--test` to self-check with sample input.

hook_input() { cat; }

json_field() { # json_field <json> <jq path>
  printf '%s' "$1" | jq -r "$2 // empty" 2>/dev/null
}

block() { # block <message>
  printf '%s\n' "$1" >&2
  exit 2
}

# run_case <expected exit> <description> <json> -- used by --test
run_case() {
  local want="$1" desc="$2" json="$3" got
  printf '%s' "$json" | "$0" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    printf '  ok   %s\n' "$desc"
  else
    printf '  FAIL %s (exit %s, wanted %s)\n' "$desc" "$got" "$want"
    return 1
  fi
}

bash_cmd_json() { # bash_cmd_json <command string>
  jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'
}

edit_json() { # edit_json <file path>
  jq -cn --arg p "$1" '{tool_name:"Edit",tool_input:{file_path:$p}}'
}
