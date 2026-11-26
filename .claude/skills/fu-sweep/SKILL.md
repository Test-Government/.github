---
name: fu-sweep
description: >
  Triage every open follow-up in docs/follow-ups.md and act on it: do, verify, unblock, ask or
  keep each item. Not a closing spree. Use on "sweep the follow-ups", "triage the tracker",
  "what follow-ups are still relevant", or when the open count has grown.
---

# fu-sweep — decide, then act

Items get added faster than anyone re-reads them. This pass re-reads all of them.

## Rules

- **Not a closing spree.** Every item leaves the pass with a reason. What you cannot show
  evidence for stays open, unchanged.
- **Evidence, not memory.** "Is it done" is answered against the real thing: the file, the
  workflow run, the repository's settings. A commit that claims the fix is not proof it works.
- **Do not re-file what you resolve.** If the sweep does the work, the item is deleted in the
  same commit as the fix, and the commit names the id.
- **Never invent an id.** Grep the tracker first. A new item passes the bar in
  `docs/follow-ups.md` like any other.
- **The owner's list is short.** Cap the questions you bring back at five; if everything needs a
  decision, the sweep has not done its job.

## The pass

1. **Inventory.** `devbox run follow-ups-lint`. Whatever it flags is a target on sight.
2. **Reconcile first.** `git log` since the tracker last changed, and the open and recently
   merged pull requests: merged work that never touched the tracker makes items stale.
3. **Classify each open item** into exactly one:
   - DONE: the work exists and holds. Delete the item; fix what pointed at it.
   - DO-NOW: bounded, decided, safe. Do it, by pull request, and delete the item there.
   - BLOCKED: name the blocker in the item (an owner decision, a credential, another id).
   - RE-SCOPE: part is done or the facts changed. Rewrite to status and next action.
   - OWNER: needs a judgment you cannot ground. Leave it unchanged; put the question in the report.
   - KEEP: still true, still later.
4. **Walk the chains.** After each deletion, `grep -rn 'FU-NNN' .` and re-read every hit as if
   filed today: the item you closed is often why another was deferred.
5. **Update the pointers** in the same change: `NEXT.md`, `ROADMAP.md`.
6. **Report:** counts per class, the pull requests opened, and the owner's questions.
