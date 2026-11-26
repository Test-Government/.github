#!/bin/sh
# follow-ups-lint.sh — hold docs/follow-ups.md to its own conventions (the header of that file,
# docs/adr/0001). Run by `devbox run ci` and on its own as `devbox run follow-ups-lint`.
#
# An id is a stable name: ids are never reused, so a mention of a finished (deleted) item is legal
# anywhere as provenance. Only FORWARD-POINTING references must resolve to an open item: every id
# in NEXT.md and ROADMAP.md, and any line of the form "Tracked by FU-NNN".
#
# FAILS on:
#   NEXT-SIZE       NEXT.md over MAX_NEXT lines: the detail belongs in the tracker.
#   NO-COUNTER      no "Next id: FU-NNN" line.
#   DUPLICATE       two items with the same id.
#   DANGLING        an id at or past the counter, anywhere: it never existed.
#   RETIRED         a forward-pointing reference to an id that is not open.
#   BROKEN-POINTER  an item links a relative path that is not on disk.
# WARNS on (judgment calls, never fail):
#   OVERSIZE        an item over MAX_ITEM lines: move the detail to a doc, keep status and next action.
#   DONE-MARKER     an open item that reads as finished: delete it, or delete the finished part.
#   NO-BACKLINK     an item links a doc that never mentions the item's id.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
FU=docs/follow-ups.md
MAX_NEXT=40
MAX_ITEM=10
rc=0
fail() { echo "FAIL $*" >&2; rc=1; }
num() { echo "$1" | sed 's/^FU-0*//; s/^$/0/'; }

lines=$(wc -l < NEXT.md)
[ "$lines" -le "$MAX_NEXT" ] || fail "NEXT-SIZE: NEXT.md has $lines lines, the limit is $MAX_NEXT"

open=$(sed -n 's/^### \(FU-[0-9][0-9][0-9]\) .*/\1/p' "$FU")
nl='
'
is_open() { case "$nl$open$nl" in *"$nl$1$nl"*) return 0 ;; esac; return 1; }

dup=$(printf '%s\n' "$open" | sort | uniq -d | tr '\n' ' ')
[ -z "$dup" ] || fail "DUPLICATE: $dup"

next=$(sed -n 's/^Next id: \(FU-[0-9][0-9][0-9]\)$/\1/p' "$FU")
if [ -z "$next" ]; then
  fail "NO-COUNTER: $FU has no 'Next id: FU-NNN' line"; nextn=1000
else
  nextn=$(num "$next")
fi

# Every mention in the tracked and new files. "<id> <file>" per line: the id first, so a file
# name with spaces stays whole. A file name is data from a pull request: it is only ever passed
# as an argument after `--` and printed with printf, never spliced into a sed or shell expression.
refs=$(git ls-files -co --exclude-standard | while read -r f; do
  [ -f "$f" ] || continue
  grep -Io 'FU-[0-9][0-9][0-9]' -- "$f" 2>/dev/null | sort -u | while read -r id; do
    printf '%s %s\n' "$id" "$f"
  done
done)
problems=$(printf '%s\n' "$refs" | while read -r id f; do
  [ -n "$id" ] || continue
  if [ "$f" = "$FU" ] && [ "$id" = "$next" ]; then continue; fi
  if [ "$(num "$id")" -ge "$nextn" ]; then echo "DANGLING: $f mentions $id, at or past the counter $next"; continue; fi
  case "$f" in NEXT.md|ROADMAP.md) is_open "$id" || echo "RETIRED: $f points at $id, which is not open" ;; esac
done)
tracked=$(git ls-files -co --exclude-standard | while read -r f; do
  [ -f "$f" ] || continue
  grep -Io 'Tracked by[^.]*FU-[0-9][0-9][0-9]' -- "$f" 2>/dev/null | grep -o 'FU-[0-9][0-9][0-9]' | sort -u |
    while read -r id; do printf '%s %s\n' "$id" "$f"; done
done)
problems2=$(printf '%s\n' "$tracked" | while read -r id f; do
  [ -n "$id" ] || continue
  is_open "$id" || echo "RETIRED: $f says 'Tracked by $id', which is not open"
done)
for p in "$problems" "$problems2"; do
  [ -n "$p" ] || continue
  printf '%s\n' "$p" | while read -r line; do echo "FAIL $line" >&2; done
  rc=1
done

# Per item: "<id>|<lines>|<body on one line>". An item runs from its heading to the next heading.
items=$(awk '
  function flush() { if (id != "") printf "%s|%d|%s\n", id, n, body }
  /^### FU-[0-9][0-9][0-9] / { flush(); id = $2; n = 0; body = ""; next }
  /^#/ { flush(); id = ""; next }
  id != "" && NF { n++; body = body " " $0 }
  END { flush() }' "$FU")
notes=$(printf '%s\n' "$items" | while IFS='|' read -r id n body; do
  [ -n "$id" ] || continue
  [ "$n" -le "$MAX_ITEM" ] || echo "warn OVERSIZE: $id has $n lines, the limit is $MAX_ITEM"
  case "$body" in
    *" done."*|*" Done."*|*"shipped"*|*"merged in"*|*"fixed in"*|*"✅"*) echo "warn DONE-MARKER: $id reads as finished" ;;
  esac
  printf '%s\n' "$body" | grep -o '](\([^)#]*\)' | sed 's/^](//' | while read -r link; do
    case "$link" in ''|http://*|https://*|mailto:*) continue ;; esac
    target="docs/$link"
    if [ ! -e "$target" ]; then echo "FAIL BROKEN-POINTER: $id links $link, which is not on disk"; continue; fi
    [ -f "$target" ] || continue
    grep -q "$id" "$target" || echo "warn NO-BACKLINK: $id links $link, which never mentions $id"
  done
done)
if [ -n "$notes" ]; then
  printf '%s\n' "$notes" >&2
  case "$notes" in *"FAIL "*) rc=1 ;; esac
fi

echo "follow-ups-lint: $(printf '%s\n' "$open" | grep -c .) open, next id $next" >&2
exit $rc
