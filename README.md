# .github — Test-Government's organisation defaults, rulesets and agent App

The organisation's governance in one repository: the defaults GitHub shows on every repository,
the branch and tag protection as code, and the declared permissions of the App that agents work
through. First-time setup, or recreating it from nothing: [BOOTSTRAP.md](BOOTSTRAP.md).

## The rules it enforces

- **Agents push branches, people merge.** Supervised agent sessions push branches and open pull
  requests with a maintainer's own repository-scoped token, held outside the session; landing a
  pull request is a person's click.
- **Default branch** of every repository: changes arrive by pull request only, no force-push, no
  deletion, optional required checks. Approvals and code-owner review are off by default
  (`required_approvals`, `require_code_owner_review` per repository): with a couple of
  maintainers, a rule that needs a second person stops the work.
- **Tags:** only organisation owners create, move or delete them. A tag is what publishes, so a
  release stays a person's decision.
- **Organisation owners** bypass the tag rule, and the default-branch rule only through a pull
  request (`admin_bypass_mode`): nobody pushes to a default branch directly.
- **The agents App** (`github-apps.json`, `scripts/github-app.sh`) is declared for unsupervised
  workers and is not in use: nothing mints its tokens today.
- **Workflow files:** the tokens agents work with have no Workflows permission, so changes under
  `.github/workflows/` are pushed by a person. That is rare by design: a repository's daily work, CI included, lives
  under `devbox run`, in files agents can change. Only what is specific to GitHub (triggers,
  publishing, secrets) is in a workflow file.
- **This repository** is owned by a person throughout (`CODEOWNERS`) and the App is not installed
  on it: an author able to edit the gate unreviewed is not gated.

## What is where

| Path | What it is |
|---|---|
| `SECURITY.md`, `CONTRIBUTING.md` | shown on every repository of the organisation that has no file of its own. Displayed only, never copied into clones |
| `profile/README.md` | the organisation's front page |
| `tofu/github/` | the rulesets (`rulesets.tf`), the repositories tofu creates (`repos.tf`), and the settings of the older ones once `repos_imported.tf` exists |
| `github-apps.json` | the App's declared permissions, each with its reason, and the decided non-grants |
| `scripts/github-tf.sh` | runs tofu with the admin token from its wallet (`devbox run github-tofu`) |
| `scripts/github-app.sh` | creates, verifies and mints tokens for the App |
| `.github/workflows/ci.yml` | the one CI job every repository calls: it runs that repository's `devbox run ci` and nothing else |
| `templates/CODEOWNERS`, `templates/ci-caller.yml` | what each repository starts from |

Not inherited from here, so each repository keeps its own: `LICENSE`, `CODEOWNERS`, and formatter
and editor configuration. There is no style guide; `CONTRIBUTING.md` lists the checks.

## Day to day

Everything runs on an owner's own machine, never in an agent session.

```sh
devbox run validate                 # no token needed
devbox run github-tofu plan         # opens the admin wallet
devbox run github-tofu apply
```

- **A new repository:** declare it in `tofu/github/repos.tf` and add it to `var.repos` in
  `tofu/github/variables.tf`, then apply: it is created with its rulesets already on. (One created
  by hand is unprotected until it is in `var.repos` and applied.) Only after that add it to the
  tokens agent sessions work with (a click in each token's settings).
- **A required check:** add the job name to the repository's `required_checks`, only once it
  reports on `pull_request`. A check that never reports blocks every merge.
- **A ruleset change:** edit the tofu and apply. A change made in the UI or through the API is
  reverted by the next apply.
- **An App permission:** change `github-apps.json` first, with its reason; then click it in the
  App's settings and approve the update on the installation; then
  `scripts/github-app.sh test-government-agents verify`.
- **A token for an agent:** `scripts/github-app.sh test-government-agents token <repo>…` prints a
  one-hour token for those repositories alone.
- **A fresh clone:** state is local and gitignored. `devbox run github-tofu adopt` rebuilds it
  from GitHub. There is no lock: one applier at a time.
- **Rollback:** `devbox run github-tofu apply -var enforcement=disabled` turns the rulesets off.
  There is no dry run: `evaluate` enforcement is Enterprise-only.
- **Your bypass:** `gh api repos/Test-Government/<repo>/rules/branches/<default branch>` returns
  `[]` when you bypass, and a `pull_request` rule object when you are held to it.
- **The admin token** expires within a year. Rotation is in [BOOTSTRAP.md](BOOTSTRAP.md).

## What stays a click

- Which repositories the App is installed on.
- Possibly a GHCR package's visibility. Not verified: a new package may be private even under a
  public repository, or may follow the repository's visibility. Check at the first release and
  correct this line.
- Creating a GitHub App, and creating the admin token.

## Known provider behaviour

- **`OrganizationAdmin` bypass `actor_id`** reads back as 0 or 1 for the identical write, so no
  literal converges. Both rulesets carry `ignore_changes = [bypass_actors[0].actor_id]`. It is by
  index: the admin block stays first.
- **`has_downloads`** on a repository diffs `true -> false` on every plan when omitted and warns
  when declared: ignore it (`lifecycle { ignore_changes = [has_downloads] }`).
- **`allow_forking = false`** on a public repository never applies.
- **Push rulesets** on a public repository are refused with a 422; none is declared.
