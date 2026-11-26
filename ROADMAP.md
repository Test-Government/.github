# Roadmap

## Aim

One repository set up completely, as the example the others copy. Two or three mocks taken only
as far as publishing their container images and Helm charts needs. Everything else stays as it
is until someone who uses it needs more: the table says what each repository lacks, and the
example shows how to add it.

## Where each repository stands

An empty cell is work not done; "n/a" is work that does not exist for that repository.

| Repository | Rulesets | `devbox run ci` | Calls shared CI | Image published | Helm chart | Dependency updates | Agent file |
|---|---|---|---|---|---|---|---|
| `.github` | yes | yes | yes (`ci-self.yml`) | n/a | n/a | | `AGENTS.md` |
| `mobile-id-mock` | yes | | | | | | |
| `SID-mock` | yes | | own workflows | Docker Hub | | Dependabot | |
| `smart-id-mock` | | | own workflow | | | | `CLAUDE.md` |
| `ee-eid-test-pki` | | | own workflow | GHCR | | | `CLAUDE.md` |
| `TSL-test-server` | | | | | | | |
| `DD4J-test-application` | | | | | | | |
| `mock-ocsp` | | | | Docker Hub, old | | | |

- `smart-id-mock`: `main` holds only the licence and the code is on `develop`. A ruleset follows
  the default branch, so settle the trunk before the repository goes into `var.repos`.
- `mock-ocsp` is legacy (`ee-eid-test-pki` has its own OCSP) and its `controllable` branch was
  never merged. Whether it is kept or archived is undecided.
- `nordic-testing-days-2024-talk` is a talk's material, not a tool, and outside this plan. Its
  Apache-2.0 licence names no copyright holder and does not cover the logo and slide images.

## Entries, in order

### 1. The organisation
Rulesets are applied on three repositories. The next joins by an entry in `var.repos`, once it
has a `ci` to require.

### 2. Take over what was built outside the organisation
Work on the mocks was done in the projects that use them and now moves here, each piece by pull
request in its own repository: the Mobile-ID mock (the whole project, into `mobile-id-mock`); a
Helm chart for `SID-mock`; a `SID-mock` change (the status poll waits on a timer, certificates
come from the test PKI); a delegated OCSP responder for `ee-eid-test-pki`. Only the mock's own
code crosses: nothing of the project it was written in.

### 3. The example: `mobile-id-mock`
Every column of the table filled, in this order: a `devbox.json` with a `ci` script
(the tools are in `CONTRIBUTING.md`, "Checks"; gitleaks needs an allow-list for the committed
test keys and certificates); the CI caller from `templates/`; an `AGENTS.md`; then image and
chart. It is new, so nothing has to be migrated, and a ruleset change is tried on it first.

### 4. Publishing images and charts
For the mocks that need it. Two release models are in use, and a repository has one of them:
- an owner creates a tag and the tag publishes (`ee-eid-test-pki`, `smart-id-mock`): tags are
  protected;
- a merge to the default branch publishes and the workflow creates the tag (`SID-mock`): tags
  are unprotected (`protect_tags = false`), and the merged pull request is the release decision.

Before a repository's images or charts are relied on:
- its publishing workflow must not be startable by hand on a branch (`workflow_dispatch` without
  an environment or a branch condition);
- the Workflows permission stays withheld from the tokens agent sessions use;
- check whether a new GHCR package is private under a public repository, and correct
  `README.md`, "What stays a click";
- write the two placeholder sections of `CONTRIBUTING.md`: tests, and releases and versions.

### 5. Dependency updates on one repository
Renovate, on one repository first, to learn what installing its App takes. It needs the
Workflows permission to change files under `.github/workflows/`, which agents here do not get:
decide between granting it to Renovate's App and letting Renovate propose while a person pushes.
actionlint does not check a bumped SHA-pinned action; `ci-self.yml` runs the bumped job.

### 6. Agent instructions in every repository
A clone of a mock does not contain this repository, so each needs its own short `AGENTS.md`
from a template in `templates/`. Where a `CLAUDE.md` exists, it has to import the `AGENTS.md`.

## Parked

- The agents App for unsupervised workers: declared in `github-apps.json`, not created
  (`BOOTSTRAP.md` step 7).
- Repository settings under tofu: `devbox run github-tofu import-repos` (`BOOTSTRAP.md` step 8).
- A written code style: it needs the existing code mined first. `CONTRIBUTING.md` lists linters.
