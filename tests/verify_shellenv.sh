#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <interpreter> <rendered-shellenv>" >&2
  exit 64
fi

interpreter="$1"
rendered_shellenv="$2"
stub_dir=$(mktemp -d)
trap 'rm -rf "${stub_dir}"' EXIT HUP INT TERM

cat >"${stub_dir}/gh" <<'STUB'
#!/bin/sh
set -eu
for variable in GITHUB_TOKEN GITHUB_MCP_TOKEN GHORG_GITHUB_TOKEN GRAFANA_TOKEN PARALLEL_API_KEY ARGOCD_STAGING_TOKEN ARGOCD_PROD_TOKEN ARGOCD_MAKEITWORK_TOKEN APIFY_TOKEN OPENCODE_WEB_PASSWORD; do
  if printenv "${variable}" >/dev/null 2>&1; then
    exit 1
  fi
done
STUB

cat >"${stub_dir}/ghorg" <<'STUB'
#!/bin/sh
set -eu
[ "${1:-}" = "version" ]
test -n "${GHORG_GITHUB_TOKEN:-}"
for variable in GITHUB_TOKEN GITHUB_MCP_TOKEN GRAFANA_TOKEN PARALLEL_API_KEY ARGOCD_STAGING_TOKEN ARGOCD_PROD_TOKEN ARGOCD_MAKEITWORK_TOKEN APIFY_TOKEN OPENCODE_WEB_PASSWORD; do
  if printenv "${variable}" >/dev/null 2>&1; then
    exit 1
  fi
done
STUB

cat >"${stub_dir}/opencode" <<'STUB'
#!/bin/sh
set -eu
if [ "${1:-}" = "attach" ]; then
  [ "${2:-}" = "https://opencode.makeitwork.cloud" ]
  [ "${3:-}" = "--dir" ]
  [ "${4:-}" = "/home/opencode" ]
  [ "${5:-}" = "--version" ]
  [ "${OPENCODE_SERVER_USERNAME:-}" = "opencode" ]
  test -n "${OPENCODE_SERVER_PASSWORD:-}"
fi
for variable in GITHUB_TOKEN GITHUB_MCP_TOKEN GHORG_GITHUB_TOKEN GRAFANA_TOKEN PARALLEL_API_KEY ARGOCD_STAGING_TOKEN ARGOCD_PROD_TOKEN ARGOCD_MAKEITWORK_TOKEN APIFY_TOKEN OPENCODE_WEB_PASSWORD; do
  if printenv "${variable}" >/dev/null 2>&1; then
    exit 1
  fi
done
STUB

cat >"${stub_dir}/curl" <<'STUB'
#!/bin/sh
set -eu
# opencode_list passes basic-auth credentials through a stdin config, never argv.
config="$(cat)"
case "${config}" in
  *'user = "opencode:'*'"'*) ;;
  *)
    echo "curl stub: missing stdin credential config" >&2
    exit 1
    ;;
esac
for arg in "$@"; do
  case "${arg}" in
    *fixture-opencode-password*)
      echo "curl stub: credential leaked into argv" >&2
      exit 1
      ;;
  esac
done
[ "${1:-}" = "-fsS" ]
[ "${2:-}" = "--config" ]
[ "${3:-}" = "-" ]
[ "${4:-}" = "https://opencode.makeitwork.cloud/session" ]
printf '%s\n' '[{"id":"ses_fixture","title":"Fixture session","directory":"/home/opencode","time":{"created":0,"updated":0}}]'
STUB

chmod +x "${stub_dir}/gh" "${stub_dir}/ghorg" "${stub_dir}/opencode" "${stub_dir}/curl"

case "${interpreter}" in
  sh) mode=posix ;;
  *) mode=interactive ;;
esac

# shellcheck disable=SC2016
"${interpreter}" -c '
set -eu
stub_dir="$1"
rendered_shellenv="$2"
mode="$3"
PATH="${stub_dir}:${PATH}"

assert_unexported() {
  for variable in GITHUB_TOKEN GITHUB_MCP_TOKEN GHORG_GITHUB_TOKEN GRAFANA_TOKEN PARALLEL_API_KEY ARGOCD_STAGING_TOKEN ARGOCD_PROD_TOKEN ARGOCD_MAKEITWORK_TOKEN APIFY_TOKEN OPENCODE_WEB_PASSWORD; do
    if printenv "${variable}" >/dev/null 2>&1; then
      echo "${variable} unexpectedly exported" >&2
      return 1
    fi
  done
}

assert_cf_exported() {
  for variable in CF_ACCESS_CLIENT_ID CF_ACCESS_CLIENT_SECRET; do
    if ! printenv "${variable}" >/dev/null 2>&1; then
      echo "${variable} unexpectedly absent" >&2
      return 1
    fi
  done
}

. "${rendered_shellenv}"
assert_unexported
assert_cf_exported

if [ "${mode}" = posix ]; then
  for helper in opencode-web opencode-list opencode-list-sessions; do
    if command -v "${helper}" >/dev/null 2>&1; then
      echo "${helper} unexpectedly defined in POSIX sh" >&2
      exit 1
    fi
  done
else
  for helper in opencode-web opencode-list opencode-list-sessions; do
    command -v "${helper}" >/dev/null 2>&1 || {
      echo "${helper} helper missing" >&2
      exit 1
    }
  done
fi
command -v opencode_web >/dev/null 2>&1 || {
  echo "opencode_web helper missing" >&2
  exit 1
}
command -v opencode_list >/dev/null 2>&1 || {
  echo "opencode_list helper missing" >&2
  exit 1
}

gh --version
ghorg version
opencode_web --version
list_output="$(opencode_list)"
case "${list_output}" in
  *ses_fixture*) ;;
  *)
    echo "opencode_list output missing fixture session" >&2
    exit 1
    ;;
esac
assert_unexported
assert_cf_exported
' verify-shellenv "${stub_dir}" "${rendered_shellenv}" "${mode}"
