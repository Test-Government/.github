#!/bin/sh
# PreToolUse gate on Edit/Write/MultiEdit/Bash: ADDING a new follow-up id is denied once per id
# per session, with the tracker's own bar as the reason; the same edit retried passes. Changing
# or deleting an existing item is untouched.
#
# Why a hook: the bar is written in docs/follow-ups.md, and a written rule does not fire at the
# moment of filing. One denial makes the bar the next thing read. No jq: it runs on any machine.
# A new item is a heading `### FU-NNN ` in the tool input whose id heads no item in the tracker.
input=$(cat)
case "$input" in *follow-ups.md*) ;; *) exit 0 ;; esac
tracker="${CLAUDE_PROJECT_DIR:-.}/docs/follow-ups.md"
[ -f "$tracker" ] || exit 0
new=""
for id in $(printf '%s' "$input" | grep -oE '### FU-[0-9]{3} ' | grep -oE 'FU-[0-9]{3}' | sort -u); do
  grep -qE "^### $id " "$tracker" || new="$new $id"
done
[ -n "$new" ] || exit 0
sid=$(printf '%s' "$input" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -n 1p | sed 's/.*"\([^"]*\)"$/\1/')
state="${TMPDIR:-/tmp}/fu-mint-gate-${sid:-nosession}"
mkdir -p "$state" 2>/dev/null
first=""
for id in $new; do [ -e "$state/$id" ] || { first="$first $id"; : > "$state/$id"; }; done
[ -n "$first" ] || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Adding%s is held once (fu-mint-gate). The tracker is for work someone must do LATER (docs/follow-ups.md, The bar). Before retrying: (1) Can it be done now? Context in hand and safe now = DO IT, and doing it includes handing it to a background subagent that builds the pull request; a bounded, decided change is never a follow-up. (2) Is there a next action someone could start today? If not, it is not a follow-up: a finding goes to the doc that owns the subject, a decision to docs/adr/, a larger undecided direction to ROADMAP.md. (3) Does an existing item already own it? Extend that one, and re-run test 1. Only if it is genuinely blocked (an owner decision, a credential, a dependency) retry the same edit: the retry passes."}}\n' "$first"
