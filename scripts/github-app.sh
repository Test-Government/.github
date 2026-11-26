#!/usr/bin/env bash
# github-app.sh — create, verify and use a GitHub App declared in github-apps.json.
#
#   scripts/github-app.sh <slug> check                 what is declared, what needs the browser
#   scripts/github-app.sh <slug> manifest              write the App-manifest page (permissions FROM the json)
#   scripts/github-app.sh <slug> catch                 listen for GitHub's redirect, save app id + key
#   scripts/github-app.sh <slug> convert <code>        the same, with the code copied by hand
#   scripts/github-app.sh <slug> install-id            resolve and save the installation id
#   scripts/github-app.sh <slug> verify                declared permissions against the live App; exit 1 on drift
#   scripts/github-app.sh <slug> token [repo ...]      mint an installation token (1 hour) on stdout
#
# A new App: manifest → catch (one Create click) → one Install click (select repositories) →
# install-id → verify. The two clicks are GitHub's; nothing is pasted by hand.
#
# Runs on a maintainer's machine, never in an agent session: the private key is the root of
# everything the App can do. Needs bash, jq, curl, openssl, python3 (catch only).
#
#   ORG       default Test-Government
#   CRED_DIR  default ~/.config/test-government/<slug>  (app-id, private-key.pem, slug, installation-id)
#   PERMS     token: a JSON object narrowing the token, e.g. '{"contents":"write","pull_requests":"write"}'
set -euo pipefail
cd "$(dirname "$0")/.."

DECLARED=github-apps.json
SLUG="${1:?usage: github-app.sh <slug> <check|manifest|catch|convert|install-id|verify|token>}"
CMD="${2:-check}"
shift; shift || true
ORG="${ORG:-Test-Government}"
API=https://api.github.com

say()  { printf '\n==> %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing tool: $1"; }
need jq; need curl

app_json=$(jq --arg s "$SLUG" '.apps[] | select(.slug==$s)' "$DECLARED")
[ -n "$app_json" ] || die "slug '$SLUG' is not declared in $DECLARED"
CRED_DIR="${CRED_DIR:-$HOME/.config/test-government/$SLUG}"
REDIRECT_PORT=$(jq -r '.bootstrap.redirect_port // 8766' <<<"$app_json")
PERMS_JSON=$(jq -c '.permissions | map_values(.level)' <<<"$app_json")

cmd_check() {
  say "Declared for $SLUG ($DECLARED)"
  jq '{slug, installs, permissions: (.permissions | map_values(.level)), absent: (.absent // {} | keys)}' <<<"$app_json"
  cat >&2 <<EOT

  Needs the browser, as an owner of $ORG:
    1. Create the App   'manifest', then 'catch' (or 'convert <code>'): one Create click.
    2. Install the App  one Install click; "Only select repositories".
  Then: 'install-id', 'verify'.
EOT
}

cmd_manifest() {
  local out="${TMPDIR:-/tmp}/gh-$SLUG-manifest.html" manifest
  manifest=$(jq -nc --arg n "$SLUG" --arg url "https://github.com/$ORG" \
    --arg redir "http://localhost:$REDIRECT_PORT/callback" --argjson perms "$PERMS_JSON" \
    '{name:$n, url:$url, redirect_url:$redir, public:false, default_permissions:$perms, default_events:[]}')
  cat > "$out" <<HTML
<!doctype html><meta charset=utf-8><title>Create $SLUG GitHub App</title>
<body onload="document.forms[0].submit()">
<p>Submitting the App manifest to GitHub. If nothing happens, press the button.</p>
<form action="https://github.com/organizations/$ORG/settings/apps/new" method="post">
  <input type="hidden" name="manifest" value='$manifest'>
  <button type="submit">Create the '$SLUG' App on $ORG</button>
</form></body>
HTML
  say "Wrote $out"
  cat >&2 <<EOT
  In another shell start:  scripts/github-app.sh $SLUG catch
  Then open $out in a browser logged in as an owner of $ORG and press Create.
  By hand instead: copy code= from the localhost:$REDIRECT_PORT redirect, then
      scripts/github-app.sh $SLUG convert <code>
EOT
}

# The code is the credential; this endpoint takes no Authorization header.
convert_code() {
  local body http
  body=$(curl -sS -w '\n%{http_code}' -X POST -H 'Accept: application/vnd.github+json' \
    "$API/app-manifests/$1/conversions")
  http=${body##*$'\n'}; body=${body%$'\n'*}
  [ "$http" = 201 ] || die "conversion failed (HTTP $http): $(jq -r '.message // empty' <<<"$body" 2>/dev/null)"
  ( umask 077; mkdir -p "$CRED_DIR"
    jq -r '.id'   <<<"$body" > "$CRED_DIR/app-id"
    jq -r '.pem'  <<<"$body" > "$CRED_DIR/private-key.pem"
    jq -r '.slug' <<<"$body" > "$CRED_DIR/slug" )
  say "Saved App id $(cat "$CRED_DIR/app-id") and its private key under $CRED_DIR"
  cat >&2 <<EOT
  Move the key into your wallet; $CRED_DIR is then only a cache.
  Next, one Install click ("Only select repositories"; not .github):
      https://github.com/organizations/$ORG/settings/apps/$(cat "$CRED_DIR/slug")/installations
  Then:  scripts/github-app.sh $SLUG install-id && scripts/github-app.sh $SLUG verify
EOT
}

cmd_catch() {
  need python3
  say "Listening on http://localhost:$REDIRECT_PORT for GitHub's redirect"
  local code
  code=$(REDIRECT_PORT="$REDIRECT_PORT" python3 -I -c '
import http.server, os, sys, urllib.parse
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        code = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query).get("code", [None])[0]
        self.send_response(200 if code else 400)
        self.send_header("Content-Type", "text/plain; charset=utf-8"); self.end_headers()
        self.wfile.write(b"Got it. Close this tab and return to the terminal." if code else b"No code in the redirect.")
        if code:
            print(code); sys.stdout.flush(); os._exit(0)
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", int(os.environ["REDIRECT_PORT"])), H).serve_forever()
')
  [ -n "$code" ] || die "no code captured"
  convert_code "$code"
}

b64url() { openssl base64 -e -A | tr '+/' '-_' | tr -d '='; }

# A 9-minute App JWT, signed with the private key. Authenticates as the App itself.
app_jwt() {
  need openssl
  local id pem now unsigned
  id=$(cat "$CRED_DIR/app-id" 2>/dev/null) || die "no $CRED_DIR/app-id (run catch or convert)"
  pem="$CRED_DIR/private-key.pem"; [ -r "$pem" ] || die "no private key at $pem"
  now=$(date +%s)
  unsigned="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url).$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$((now - 60))" "$((now + 540))" "$id" | b64url)"
  printf '%s.%s' "$unsigned" "$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "$pem" -binary | b64url)"
}

app_api() { # <method> <path> [json body]
  # The JWT goes to curl on stdin, so it is not on a command line for the process list to show.
  printf 'Authorization: Bearer %s\n' "$(app_jwt)" |
    curl -fsS -X "$1" -H @- -H 'Accept: application/vnd.github+json' \
      -H 'X-GitHub-Api-Version: 2022-11-28' ${3:+-d "$3"} "$API$2"
}

cmd_install_id() {
  local id
  id=$(app_api GET /app/installations | jq -r --arg o "$ORG" '.[] | select((.account.login|ascii_downcase)==($o|ascii_downcase)) | .id')
  case "$id" in ''|*[!0-9]*) die "no installation on $ORG: is the App installed?" ;; esac
  echo "$id" > "$CRED_DIR/installation-id"
  say "Installation id $id saved"
}

cmd_verify() {
  local live drift
  live=$(app_api GET /app | jq -c '.permissions')
  drift=$(jq -n --argjson d "$PERMS_JSON" --argjson l "$live" --argjson a "$(jq -c '.absent // {} | keys' <<<"$app_json")" '
    [ ($d | to_entries[] | select($l[.key] != .value) | "\(.key): declared \(.value), live \($l[.key] // "none")"),
      ($l | to_entries[] | select($d[.key] == null) | "\(.key): live \(.value), not declared\(if (.key as $k | $a | index($k)) then " (a decided non-grant)" else "" end)") ] | .[]' -r)
  if [ -n "$drift" ]; then say "DRIFT between $DECLARED and the live App"; printf '  %s\n' "$drift" >&2; exit 1; fi
  say "$SLUG: live permissions equal the declaration"
}

# The token goes to stdout and nowhere else. Named repositories narrow it to those; PERMS narrows
# the permissions. GitHub refuses a request wider than the installation.
cmd_token() {
  local inst body
  inst=$(cat "$CRED_DIR/installation-id" 2>/dev/null) || die "no installation id (run install-id)"
  body=$(jq -nc --argjson p "${PERMS:-null}" '{} + (if $p then {permissions:$p} else {} end) + (if ($ARGS.positional|length)>0 then {repositories:$ARGS.positional} else {} end)' --args "$@")
  app_api POST "/app/installations/$inst/access_tokens" "$body" | jq -er '.token'
}

case "$CMD" in
  check) cmd_check ;;
  manifest) cmd_manifest ;;
  catch) cmd_catch ;;
  convert) convert_code "${1:?convert <code>}" ;;
  install-id) cmd_install_id ;;
  verify) cmd_verify ;;
  token) cmd_token "$@" ;;
  *) die "unknown command: $CMD" ;;
esac
