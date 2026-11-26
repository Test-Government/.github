# Follow-ups

Loose ends and deferred work: open items only. `devbox run follow-ups-lint` checks this file, and
`/fu-sweep` re-reads all of it.

Next id: FU-001

## Conventions

- **Ids** are `FU-NNN`, sequential, never reused. A new item takes the next id and raises the
  counter above, in the same change.
- **This file is the only tracker.** Anywhere else, name the id instead of writing a bare TODO.
- **Size.** A follow-up is a piece of deferred work with some weight: more than a step and less
  than a direction. A step (one edit, one click, one check after a run) is a line in `NEXT.md`.
  A direction (dependency updates, publishing, a code style) is an entry in `ROADMAP.md`. A choice
  already made is a record in `docs/adr/`. Expect a handful of items here, not dozens.
- **The bar: this file is for work someone must do later, and nothing else.** Before adding to it
  or extending an item, three tests:
  1. Can it be done now? Context in hand and safe: do it. Handing it to a subagent that opens the
     pull request counts as doing it.
  2. Is there a next action someone could start today? If not, it is not a follow-up: a finding
     goes to the doc that owns the subject, a decision to `docs/adr/`, an undecided direction to
     `ROADMAP.md`.
  3. Does an existing item already own it? Extend that one, after test 1 again.
- **An item is at most 10 lines:** what is wrong, why it waits, the next concrete action. When it
  outgrows that, the detail moves to a doc that mentions the id, and the item keeps status and
  next action.
- **Finishing an item:** delete it in the same change as the fix; the commit names the id. Then
  grep for the id and re-read every hit: a finished item is often what another was waiting for.
- **References:** an id stays a legal name after its item is gone, except where it points
  forward: `NEXT.md`, `ROADMAP.md` and any "Tracked by FU-NNN" line must name an open item.

## Open

None.
