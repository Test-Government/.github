# Working in this repository

Test-Government's organisation repository: shared policy files, rulesets as tofu, the shared CI
job, and the plan for the organisation's repositories. `README.md` says what is where.

## Continue working

1. Take the first item under "Ready" in `NEXT.md`.
2. Branch, `devbox run ci`, pull request. A person merges.
3. Update the state in the same change: delete the finished line, change the `ROADMAP.md` cell.

## Rules

- `devbox run ci` is the gate; tools come from `devbox.json`.
- `github-tofu plan` and `apply` need the admin token, which only an owner has.
- A person pushes changes under `.github/workflows/`.
- Files say what is true now. History goes in the commit message; a finished item is deleted.
- Commit subjects: Conventional Commits (`CONTRIBUTING.md`).

## Where a thing goes

| What | Where |
|---|---|
| The next few steps | `NEXT.md` |
| A direction, or what a repository lacks | `ROADMAP.md` |
| Deferred work between those in size | `docs/follow-ups.md` (read its bar first) |
| A decision | `docs/adr/` |
| Anything private or about a client | not in this repository |
