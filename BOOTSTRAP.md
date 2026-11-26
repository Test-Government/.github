# Bootstrap — setting this repository up, once

Recreating the organisation's setup from nothing. `plan` and `apply` have run as written here.
Not yet exercised: `adopt`, `import-repos` and the App script's network paths.

Everything below runs on your own machine, as an owner of the organisation.

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
the endpoint wants; add that one, as Read, and record it here. (Not seen yet: no plan has run with such a token.)

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

## What is still open

`NEXT.md` for the next steps, `ROADMAP.md` for the rest.

## Origin and licence

Derived from the GitHub governance of `teststuffstash/homelab` and relicensed here, by its
copyright holder, from AGPL-3.0 to MIT (`LICENSE`), like the organisation's other repositories.
