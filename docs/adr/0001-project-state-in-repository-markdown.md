# 0001 Project state lives in repository Markdown; issues are opened late

Status: accepted 2026-11-26

## Context

Nobody is assigned to these repositories. Work happens when someone who uses a tool has time,
often through an AI agent that starts from a fresh clone. That person or agent has to find out
what is unfinished and what was decided without asking anyone.

GitHub issues were the other candidate. Against them: a few hundred items in one Markdown file
can be searched offline with grep, while issues need the API, which is rate limited and which
agent sessions already exhaust; and keeping a file current in the same commit as the work is
less effort than keeping an issue current beside it.

## Decision

The state of the work is in the repository:

- `NEXT.md`: the next few steps, ordered, at most 40 lines.
- `docs/follow-ups.md`: deferred work with some weight, open items only, each with an id that is
  never reused. Expected to stay at a handful.
- `ROADMAP.md`: the plan across repositories.
- `docs/adr/`: decisions.

These files say what is true now. History is the commit log: a finished item is deleted, and the
commit that finishes it names the id.

An issue is opened for an item only when it is about to be worked on by someone who needs one,
for example when it is queued to an agent. Issues from other people are welcome as always; what
they ask for is copied into the follow-ups when it is accepted.

## Consequences

- A clone is enough to continue the work; no account or API access is needed to read the state.
- The files drift unless they change in the same pull request as the work. `AGENTS.md` asks for
  that. Three things hold the tracker to its own rules: `scripts/follow-ups-lint.sh` in the gate,
  a hook that holds a new item once against the bar (`.claude/hooks/fu-mint-gate.sh`), and the
  `/fu-sweep` skill that re-reads every open item. The hook and the skill act only in Claude Code.
- Someone browsing GitHub does not see open work under Issues. `README.md` points here.
- Cross-repository state sits in this repository, which a clone of another repository does not
  contain.
