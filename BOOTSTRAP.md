# Bootstrap — setting this repository up, once

Written 2026-11-25 as a bundle, before the repository existed. At the time of writing nothing in
it had been applied. `tofu validate` and `tofu fmt -check` pass (integrations/github 6.13.0).
Everything that needs a credential was untested: `plan`, `apply`, `adopt`, `import-repos`, and
the App script's network paths.

Everything below runs on your own machine, as an owner of the organisation.

## Before the first push

Done 2026-11-26: `CODEOWNERS` names its owner, the licence is decided (MIT), and `SECURITY.md`,
`profile/README.md` and `CONTRIBUTING.md` were read. Still open in `CONTRIBUTING.md`, in comments
so they do not show: the test and release sections, until publishing starts.

## Order

1. Create the public repository `.github` in the organisation by hand, empty (no README: it
   holds the tofu, so it cannot create itself) and push this directory to its `main`. This first
   push is direct: the rule that forbids it arrives with step 5.
2. `devbox install`, then `devbox run validate`.
3. Create the admin token and its wallet: "The admin token" below.
4. Check `var.repos` in `tofu/github/variables.tf`: every repository listed must exist or be
   declared in `tofu/github/repos.tf`, which creates it (`mobile-id-mock` is: the first apply
   creates it with a README and the MIT licence), and one not listed gets no ruleset. Approvals and code-owner
   review are off by default; a repository that turns `require_code_owner_review` on needs its
   `CODEOWNERS` committed first.
5. `devbox run github-tofu plan`, read it, `devbox run github-tofu apply`. After a successful
   apply the wrapper turns on private vulnerability reporting for every public repository, which
   is the channel `SECURITY.md` names.
6. Check the gate: `gh api repos/Test-Government/<repo>/rules/branches/<default branch>` lists a
   `pull_request` rule for you too (`admin_bypass_mode = "pull_request"`: an owner lands a change
   through a pull request, never by a direct push). `[]` would mean you bypass outright.
7. Not now: the App. It is for unsupervised workers, and none run today; supervised sessions
   use a maintainer's own repository-scoped tokens, held outside the session. When the day
   comes: `scripts/github-app.sh test-government-agents manifest`, then `catch`, one Create
   click, one Install click ("Only select repositories": the mock repositories, **not**
   `.github`), then `install-id` and `verify`. Move the private key into a wallet.
8. Optional: `devbox run github-tofu import-repos` imports every repository in `var.repos` that
   `repos.tf` does not already declare and writes `tofu/github/repos_imported.tf` from its current
   settings, so adopting them changes nothing. Edit the generated file as the notes in
   `scripts/github-tf.sh` say, commit, plan (imports, no change), apply. From then on `.github`
   itself and the others have their settings in tofu.

## The admin token

One token, used by `scripts/github-tf.sh` and nothing else. It is a fine-grained personal access
token, because that kind is bound to one organisation. Not `gh auth token`: it lacks the
permission, and widening it with classic scopes (`admin:org`, `repo`) covers every organisation
you belong to.

1. github.com → your avatar → Settings → Developer settings → Personal access tokens →
   Fine-grained tokens → Generate new token.
2. **Resource owner:** `Test-Government`. If the organisation is not offered, fine-grained tokens
   are not enabled for it: Organisation settings → Personal access tokens → Settings.
3. **Expiration:** GitHub caps it (a year at most, less if the organisation sets a limit). Note
   the date; nothing here reminds you.
4. **Repository access:** All repositories. (Selected repositories also works, but then every new
   repository has to be added to the token as well as to `var.repos`.)
5. **Repository permissions:** **Administration: Read and write**. Metadata: Read is added by
   GitHub. Nothing else, and no organisation permission: the rulesets are repository rulesets.
6. Generate. If the organisation requires approval of fine-grained tokens, the token is pending
   until an owner approves it: Organisation settings → Personal access tokens → Pending requests.

What that permission is used for: creating and changing repository rulesets, reading and changing
repository settings, and switching on private vulnerability reporting. If a plan fails with a 403
on some repository read, the response header `x-accepted-github-permissions` names the permission
the endpoint wants; add that one, as Read, and record it here. (Not observed: no plan has been
run with such a token yet.)

Store it in a KeePass wallet of its own. The token is read from the prompt, so it is in no shell
history:

```sh
# once, in the KeePassXC window: new database ~/Documents/test-government-admin.kdbx, no password,
# "Add additional protection" → Challenge-Response with the hardware key (the CLI cannot create one)
keepassxc-cli add -y 2:<serial> --no-password -p ~/Documents/test-government-admin.kdbx github-test-government-admin
cp github-tf.local.example github-tf.local && chmod 600 github-tf.local         # then set GH_ADMIN_KP_YUBIKEY=2:<serial> in it
```

`github-tf.local` is gitignored and holds where the token is (wallet path, entry, key slot),
never the token; nothing goes into your shell profile. It may also sit in the directory above the
clone. The wrapper then opens the wallet with a touch; `github-tf.local.example` lists the
keyfile, password and other-wallet alternatives. If the touch never comes under `devbox run`, set
`KEEPASSXC_CLI` there to your system's `keepassxc-cli`.

To rotate: generate a new token the same way, `keepassxc-cli edit … -p` on the same entry, delete
the old token on GitHub.

## Open at bootstrap

- **Plan.** Repository rulesets on public repositories are free; an organisation ruleset, which
  would cover new repositories automatically, needs a paid plan. Which plan the organisation is
  on was not read.
- **`SID-mock` has a classic branch protection on `master`** (read 2026-11-26), from before the
  rulesets. Both apply once the ruleset exists, and the stricter wins. Compare the two after the
  first apply and delete the classic one (Settings → Branches) so tofu is the only source.
- **`mobile-id-mock` is created by the first apply** (`tofu/github/repos.tf`). If someone creates
  it by hand first, the apply fails on the name: `tofu import github_repository.mobile_id_mock
  mobile-id-mock` through the wrapper, then plan again.
- **`required_checks` are empty** for every repository.
- **`smart-id-mock`:** the default branch `main` holds only the licence and the code is on
  `develop`. The ruleset follows the default branch, so `develop` is unprotected until the trunk
  is settled.
- **Workflows permission.** Withheld from the tokens agent sessions work with, and from the App.
  Granting it means a branch workflow could publish to GHCR without review.
- **Publishing workflows** must not be startable by hand on a branch (`workflow_dispatch` without
  an environment or a branch condition): a tag, which only an owner creates, is what publishes.
- **`devbox run ci` per repository.** The shared job (`.github/workflows/ci.yml`) and the caller
  (`templates/ci-caller.yml`) are written and have never run. Each repository needs its own
  `devbox.json` with a `ci` script, and its caller pushed by a person. The check's name in a pull
  request is probably `ci / ci` (caller job / called job): read it off the first run before
  adding it to `required_checks`.
- **Code style.** Deliberately not written: it needs the same mining of existing code and style
  experiments as was done for the eID projects. `CONTRIBUTING.md` lists the linters instead; none
  is wired into any repository's `devbox run ci` yet.
- **Agent sessions do not see this repository** from a clone of another. Whatever runs them has
  to mount it read-only and point at `CONTRIBUTING.md`.
- **Repositories not yet in `var.repos`** have no ruleset: nothing but habit keeps a push off
  their default branch.

## Where this came from

Derived from `teststuffstash/homelab`:

| homelab | here |
|---|---|
| `tofu/github/org_ruleset.tf` + `repo_rulesets.tf` (organisation ruleset, plus per-repository checks and approval) | one `rulesets.tf`, repository rulesets only; checks, approval and code-owner review in one ruleset; a tag ruleset added |
| `OrganizationAdmin` bypass with `ignore_changes` on its `actor_id` | kept as is; `admin_bypass_mode` added (`always` or `pull_request`) |
| `docs/github-apps.yaml` + `scripts/github-app-bootstrap.sh` (manifest flow, declared permissions) | `github-apps.json` + `scripts/github-app.sh`: same flow, jq only; Infisical, wallet and exporter steps dropped; `verify` and `token` added |
| `scripts/github-tf.sh` (wallet token, stale-checkout guard, Garage state) | same guard and wallet read, hardware-key unlock added; local state with `adopt` |
| `repos.tf`, written by hand per repository | `repos.tf` by hand only for a repository this root creates; the existing ones generated once by `import-repos` into `repos_imported.tf` |
| `CODEOWNERS` tiers | a two-tier template |
| organisation `SECURITY.md` written by tofu, vulnerability reporting switched on after apply | `SECURITY.md` rewritten and committed by hand; the switch kept |

Not taken: Actions secrets, the reviewer, merge, sentinel and Renovate Apps, and everything
in-cluster. The provider behaviour measured there is listed in the README.

## Licence

MIT (`LICENSE`), like the organisation's other repositories; decided 2026-11-26. The files derived
from `teststuffstash/homelab`, which is AGPL-3.0, are relicensed here by their copyright holder.
