# Contributing to Test-Government

<!-- SKELETON: the process sections state what the rulesets enforce. There is no code style guide
     yet, on purpose: see "Checks". -->

Shown on every repository of the organisation that has no CONTRIBUTING.md of its own.

## How a change gets in

- Changes reach the default branch by pull request only, merged by an organisation owner. No
  direct pushes, owners included.
- Tags are created by owners. A tag is what publishes images and charts.
- Much of the work is done with AI agents. An agent's commits carry a `Co-Authored-By` trailer,
  its branches and pull requests appear under the person who supervised it, and it cannot merge,
  approve, tag or release: those stay a person's.
- Changes under `.github/workflows/` are pushed by a person.
- Licence: MIT unless the repository says otherwise. By contributing you agree to it.

## Checks

There is no written code style, and no formatter is prescribed: follow the code around your
change. What a repository does hold you to is what its tools check. These are the tools the
repositories are being put under, each inside that repository's `devbox run ci` once it is
configured there; until it is, it does not apply. A repository's own `devbox.json` says what
runs today.

| Applies to | Tools |
|---|---|
| Every repository | gitleaks (committed secrets; the test keys and certificates are intended and allow-listed), ShellCheck (shell scripts) |
| Java | PMD, SpotBugs with FindSecBugs, Checkstyle, Semgrep, JaCoCo (coverage); CodeNarc for Groovy and Spock tests |
| Helm charts | `helm lint`, kubeconform on the rendered templates, helm-unittest, chart-testing (`ct lint`), helm-docs |
| Container images | Grype (known vulnerabilities) |

Rule sets and exclusions live in each repository, not here.

## Commits and pull requests

Taken from what the repositories' history already does, not from a rule set in advance.

- **Subject line:** imperative, says what the change does, no full stop. Most commits are the
  subject alone; add a body when the reason is not obvious from the change.
- **Prefix:** one of two, and a repository keeps the one its history uses.
  - A [Conventional Commits](https://www.conventionalcommits.org/) type, lower case after the
    colon, no scope: `fix: keep CRL Last-Modified strictly increasing`. Types in use: `feat`,
    `fix`, `docs`, `refactor`, `test`, `build`, `ci`. This is what SID-mock, smart-id-mock and
    ee-eid-test-pki use, and what a new repository starts with.
  - The key of the ticket the work was done under, then a capitalised subject:
    `SIVA-1203 Add configuration example for withdrawn OCSP service`. TSL-test-server and
    DD4J-test-application use this. The key is whatever tracker the author's project uses;
    nobody else needs access to it, so the subject must make sense without it.
- **Branch:** from the default branch, named for the change (`barbados-user`) or for its ticket
  key.
- **Pull request title:** the commit's subject when there is one commit, otherwise a plain
  summary of the whole change.
- **Merging:** commits have reached the default branch as they were written, not squashed, so
  each one should build and make sense on its own.

## Tests

- `devbox run ci` is the gate, and the only thing CI runs. Whatever must pass before review is in
  that script, in the repository's `devbox.json`; it runs the same on your machine.
- The toolchain (JDK, Helm and the rest) comes from the repository's `devbox.json` and
  `devbox.lock`, not from what is installed on the machine.

<!-- TODO: which suites need Docker (Testcontainers), and the name of the script that leaves
     them out for machines without it. -->

## Releases and versions

<!-- TODO: versioning scheme, who tags, where images and charts are published. -->
