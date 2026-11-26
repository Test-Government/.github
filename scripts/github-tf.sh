#!/bin/sh
# github-tf.sh — run tofu against tofu/github with the organisation admin token.
#
#     devbox run github-tofu plan | apply | <any tofu subcommand>
#     devbox run github-tofu adopt      # rebuild local state from the rulesets and declared repositories that already exist
#     devbox run github-tofu import-repos   # once: write repos_imported.tf from the repositories' CURRENT settings
#
# Run by an organisation owner on their own machine, never in an agent session.
#
# GITHUB_TOKEN: a fine-grained PAT, resource owner = the organisation, the repositories in
# var.repos, Repository permissions Administration: read and write (Metadata comes with it).
# Not `gh auth token`: it lacks the permission, and widening it with classic scopes covers every
# organisation you belong to.
#
# Settings come from github-tf.local: gitignored, yours, created from github-tf.local.example
# (cp github-tf.local.example github-tf.local && chmod 600 github-tf.local). It is looked for at
# the repository root, then in the directory above the clone, and nowhere else. It holds where the
# token is, never the token: nothing here needs your shell profile. A variable already in the
# environment is replaced by the file's line of the same name.
#
# Where the token comes from, first match wins:
#   1. GITHUB_TOKEN already exported (a one-off; do not put a token in github-tf.local).
#   2. GITHUB_TOKEN_CMD: a command that prints it (another wallet tool).
#   3. A dedicated KeePass wallet holding only this organisation's admin token:
#        GH_ADMIN_KP_DB       default ~/Documents/test-government-admin.kdbx
#        GH_ADMIN_KP_ENTRY    default github-test-government-admin (the token is its Password field)
#        GH_ADMIN_KP_YUBIKEY  <slot>:<serial>, e.g. 2:12345678: the wallet opens with the hardware
#                             key's challenge-response (a touch), no password. `keepassxc-cli`
#                             needs to reach the key's OTP interface: Yubico's udev rule
#                             (69-yubikey.rules) and an unconfined KeePassXC (not the snap).
#        GH_ADMIN_KP_KEY      a keyfile, default ~/Documents/test-government-admin.keyx if present
#      With neither a hardware key nor a keyfile, keepassxc-cli asks for the password.
#        KEEPASSXC_CLI        default keepassxc-cli (the devbox one under `devbox run`); point it
#                             at your system's if that is the one that reaches the hardware key
# The token is in no file of this repository and is never printed.
#
# State is LOCAL and gitignored: it holds ruleset ids and no secret, and is rebuilt from GitHub
# with `adopt`, so any owner can apply from a fresh clone. One applier at a time: there is no lock.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
DIR="$ROOT/tofu/github"

LOCAL=""
for f in "$ROOT/github-tf.local" "$ROOT/../github-tf.local"; do
  if [ -f "$f" ]; then LOCAL=$f; break; fi
done
if [ -n "$LOCAL" ]; then
  if git -C "$ROOT" ls-files --error-unmatch -- "$LOCAL" >/dev/null 2>&1; then
    echo "github-tf: REFUSED: $LOCAL is tracked by git. It is a local file: git rm --cached it." >&2; exit 1
  fi
  # The user's own file, not in the repository: nothing for shellcheck to follow.
  set -a
  # shellcheck source=/dev/null
  . "$LOCAL"
  set +a
fi

# The root applies from THIS checkout, so it has to be the default branch as it is on the remote:
#   - behind it (tofu/github commits on the remote this checkout lacks): a merged change would read
#     as "nothing to change", or be reverted. Refused for plan, apply, destroy and adopt.
#     GITHUB_TF_ALLOW_STALE=1 overrides.
#   - ahead of it (tofu/github commits here that are not on the remote's default branch): an
#     unmerged change would go live unreviewed. Refused for apply and destroy; a plan from a
#     branch is how a change is read before it merges, so plan only warns.
#     GITHUB_TF_ALLOW_UNMERGED=1 overrides.
#   - uncommitted changes under tofu/github: the same, with the same override.
case "${1:-}" in
  plan|apply|destroy|adopt)
    def=$(git -C "$ROOT" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##') || def=""
    if git -C "$ROOT" fetch -q origin "${def:-main}" 2>/dev/null; then
      missing=$(git -C "$ROOT" rev-list --count HEAD..FETCH_HEAD -- tofu/github)
      if [ "$missing" -gt 0 ] && [ "${GITHUB_TF_ALLOW_STALE:-}" != 1 ]; then
        echo "github-tf: REFUSED: this checkout lacks $missing commit(s) on origin/${def:-main} touching tofu/github. Pull first." >&2
        exit 1
      fi
      unmerged=$(git -C "$ROOT" rev-list --count FETCH_HEAD..HEAD -- tofu/github)
      dirty=$(git -C "$ROOT" status --porcelain -- tofu/github | wc -l)
      if [ "$unmerged" -gt 0 ] || [ "$dirty" -gt 0 ]; then
        what="$unmerged commit(s) not on origin/${def:-main} and $dirty uncommitted file(s) under tofu/github"
        case "$1" in
          apply|destroy)
            if [ "${GITHUB_TF_ALLOW_UNMERGED:-}" != 1 ]; then
              echo "github-tf: REFUSED: $what. Merge first, then apply from the default branch." >&2
              exit 1
            fi ;;
          *) echo "github-tf: NOTE: $what: this $1 is of an unmerged change." >&2 ;;
        esac
      fi
    else
      echo "github-tf: WARN: could not fetch origin/${def:-main}; currency of tofu/github unchecked." >&2
    fi ;;
esac

if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN_CMD:-}" ]; then
  echo "github-tf: GITHUB_TOKEN and GITHUB_TOKEN_CMD are both set: keep one" >&2; exit 1
fi
if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN_CMD:-}" ]; then
  GITHUB_TOKEN=$(sh -c "$GITHUB_TOKEN_CMD")
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  GH_ADMIN_KP_DB="${GH_ADMIN_KP_DB:-$HOME/Documents/test-government-admin.kdbx}"
  GH_ADMIN_KP_KEY="${GH_ADMIN_KP_KEY-$HOME/Documents/test-government-admin.keyx}"
  GH_ADMIN_KP_ENTRY="${GH_ADMIN_KP_ENTRY:-github-test-government-admin}"
  [ -f "$GH_ADMIN_KP_DB" ] || { echo "github-tf: no GITHUB_TOKEN and no wallet at $GH_ADMIN_KP_DB (set GH_ADMIN_KP_DB or GITHUB_TOKEN_CMD in github-tf.local, see github-tf.local.example)" >&2; exit 1; }
  KEEPASSXC_CLI="${KEEPASSXC_CLI:-keepassxc-cli}"
  command -v "$KEEPASSXC_CLI" >/dev/null 2>&1 || { echo "github-tf: $KEEPASSXC_CLI not found (keepassxc is in devbox.json: run through devbox run github-tofu, or set KEEPASSXC_CLI)" >&2; exit 1; }
  kp_show() { "$KEEPASSXC_CLI" show -q "$@" -a Password "$GH_ADMIN_KP_DB" "$GH_ADMIN_KP_ENTRY"; }
  kf=""; if [ -n "$GH_ADMIN_KP_KEY" ] && [ -f "$GH_ADMIN_KP_KEY" ]; then kf=1; fi
  if   [ -n "${GH_ADMIN_KP_YUBIKEY:-}" ] && [ -n "$kf" ]; then GITHUB_TOKEN=$(kp_show --no-password -y "$GH_ADMIN_KP_YUBIKEY" -k "$GH_ADMIN_KP_KEY")
  elif [ -n "${GH_ADMIN_KP_YUBIKEY:-}" ];                 then GITHUB_TOKEN=$(kp_show --no-password -y "$GH_ADMIN_KP_YUBIKEY")
  elif [ -n "$kf" ];                                      then GITHUB_TOKEN=$(kp_show --no-password -k "$GH_ADMIN_KP_KEY")
  else                                                         GITHUB_TOKEN=$(kp_show)
  fi
fi
[ -n "${GITHUB_TOKEN:-}" ] || { echo "github-tf: the admin token is empty (wallet entry '${GH_ADMIN_KP_ENTRY:-}' has no password?)" >&2; exit 1; }
export GITHUB_TOKEN

tofu -chdir="$DIR" init -input=false >&2

# GitHub API call with the admin token. The header goes to curl on stdin, so the token is not on
# a command line for the process list to show. Usage: gh_api [curl options] <url>
gh_api() {
  printf 'Authorization: Bearer %s\n' "$GITHUB_TOKEN" |
    curl -fsS -H @- -H 'Accept: application/vnd.github+json' "$@"
}

if [ "${1:-}" = adopt ]; then
  org=$(echo 'var.org' | tofu -chdir="$DIR" console | tr -d '"')
  repos=$(echo 'jsonencode(keys(var.repos))' | tofu -chdir="$DIR" console | jq -r 'fromjson[]')
  tagged=$(echo 'jsonencode([for k, v in var.repos : k if v.protect_tags])' | tofu -chdir="$DIR" console | jq -r 'fromjson[]')
  in_words() { for w in $2; do [ "$w" = "$1" ] && return 0; done; return 1; }
  for r in $repos; do
    # A repository this root declares (created by repos.tf, or imported) goes back into state too:
    # without it the next plan would try to create a repository that exists.
    raddr=$(printf '%s' "$r" | sed 's/^\./dot_/; s/[^A-Za-z0-9_]/_/g')
    if grep -qs "^resource \"github_repository\" \"$raddr\"" "$DIR"/*.tf \
      && ! tofu -chdir="$DIR" state show "github_repository.$raddr" >/dev/null 2>&1; then
      tofu -chdir="$DIR" import "github_repository.$raddr" "$r"
    fi
    list=$(gh_api "https://api.github.com/repos/$org/$r/rulesets?includes_parents=false") \
      || { echo "github-tf: cannot list rulesets of $org/$r" >&2; exit 1; }
    for pair in default_branch:default-branch tags:tags; do
      addr="github_repository_ruleset.${pair%%:*}[\"$r\"]"
      id=$(printf '%s' "$list" | jq -r --arg n "${pair##*:}" '.[] | select(.name==$n and .source_type=="Repository") | .id')
      [ -n "$id" ] || continue
      # A ruleset GitHub has and this root does not declare for the repository (protect_tags =
      # false): nothing to import it into. Say so and go on; it stays until someone deletes it.
      if [ "${pair%%:*}" = tags ] && ! in_words "$r" "$tagged"; then
        echo "github-tf: WARN: $org/$r has a 'tags' ruleset ($id) that tofu does not declare (protect_tags = false). Not adopted." >&2
        continue
      fi
      tofu -chdir="$DIR" state show "$addr" >/dev/null 2>&1 && continue
      tofu -chdir="$DIR" import "$addr" "$r:$id"
    done
  done
  exit 0
fi

# Once, to bring the repositories that already existed under tofu WITHOUT changing them: an import
# block per repository in var.repos that no .tf file declares yet (repos.tf holds the ones this
# root created), then tofu writes repos_imported.tf from what GitHub reports. Nothing is applied.
# Then edit repos_imported.tf before committing; these are the provider's known rough edges, each one
# measured in teststuffstash/homelab's tofu/github history:
#   - has_downloads: deprecated. Declared, it warns; omitted, it diffs true -> false on every plan.
#     Delete the line and add to each repository:  lifecycle { ignore_changes = [has_downloads] }
#   - vulnerability_alerts, default_branch, private: deprecated or computed. Delete the lines
#     (visibility says what private said).
#   - allow_forking: a public repository is always forkable; GitHub ignores false. Keep true.
#   - archive_on_destroy = true: add it, so a `tofu destroy` or a removed block archives the
#     repository instead of deleting it.
# `tofu validate` names anything else that conflicts. Commit both files, then plan: it must show
# the imports and no change. From then on a setting changes by editing repos_imported.tf.
if [ "${1:-}" = import-repos ]; then
  [ ! -e "$DIR/repos_imported.tf" ] || { echo "github-tf: $DIR/repos_imported.tf exists; the existing repositories are already declared" >&2; exit 1; }
  echo 'jsonencode(keys(var.repos))' | tofu -chdir="$DIR" console | jq -r 'fromjson[]' | while read -r r; do
    addr=$(printf '%s' "$r" | sed 's/^\./dot_/; s/[^A-Za-z0-9_]/_/g')
    if grep -qs "^resource \"github_repository\" \"$addr\"" "$DIR"/*.tf; then continue; fi   # created here: already declared
    printf 'import {\n  to = github_repository.%s\n  id = "%s"\n}\n\n' "$addr" "$r"
  done > "$DIR/repos_import.tf"
  [ -s "$DIR/repos_import.tf" ] || { rm -f "$DIR/repos_import.tf"; echo "github-tf: every repository in var.repos is already declared; nothing to import" >&2; exit 0; }
  exec tofu -chdir="$DIR" plan -generate-config-out=repos_imported.tf
fi

[ "${1:-}" = apply ] || exec tofu -chdir="$DIR" "$@"
tofu -chdir="$DIR" "$@" || exit $?

# After a successful apply: private vulnerability reporting ON for every public, unarchived
# repository of the organisation. SECURITY.md sends reporters to it, and there is no provider
# resource for it. The PUT is idempotent and is never turned off here.
org=$(echo 'var.org' | tofu -chdir="$DIR" console | tr -d '"')
# Two steps, not a pipe: in a pipe the status would be jq's, and a failed listing would read as
# "no repositories". One page of 100: say so when it is full, instead of stopping silently.
listing=$(gh_api "https://api.github.com/orgs/$org/repos?type=public&per_page=100") \
  || { echo "github-tf: listing public repositories failed; vulnerability reporting NOT checked" >&2; exit 1; }
repos=$(printf '%s' "$listing" | jq -r '.[] | select(.archived | not) | .full_name') \
  || { echo "github-tf: the repository listing is not the JSON expected" >&2; exit 1; }
if [ "$(printf '%s' "$listing" | jq 'length')" -ge 100 ]; then
  echo "github-tf: WARN: 100 or more public repositories; only the first 100 are handled here" >&2
fi
for r in $repos; do
  if gh_api -o /dev/null -X PUT "https://api.github.com/repos/$r/private-vulnerability-reporting"; then echo "github-tf: vulnerability reporting on: $r" >&2
  else echo "github-tf: WARN: could not enable vulnerability reporting on $r (is it in the admin token's repository list?)" >&2; fi
done
