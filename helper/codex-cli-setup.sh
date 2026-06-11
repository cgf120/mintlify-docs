#!/usr/bin/env bash
set -euo pipefail

umask 077

PROVIDER_ID="${CHENYU_CODEX_PROVIDER:-chenyu-codex}"
DEFAULT_MODEL="${CHENYU_CODEX_MODEL:-doubao-seed-2-0-lite-260428}"
RAW_BASE_URL="${CHENYU_CODEX_BASE_URL:-https://api.chenyu.cn/codex/v1}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_DIR/config.toml"
KEY_FILE="${CHENYU_CODEX_KEY_FILE:-$CODEX_DIR/chenyu-codex-key}"

info() {
  printf '\033[0;32m%s\033[0m\n' "$1"
}

warn() {
  printf '\033[1;33m%s\033[0m\n' "$1" >&2
}

die() {
  printf '\033[0;31mError: %s\033[0m\n' "$1" >&2
  exit 1
}

has_tty() {
  [ -r /dev/tty ] && [ -w /dev/tty ]
}

prompt() {
  local message="$1"
  local default_value="$2"
  local value=""

  if ! has_tty; then
    printf '%s' "$default_value"
    return
  fi

  if [ -n "$default_value" ]; then
    printf '%s [%s]: ' "$message" "$default_value" >/dev/tty
  else
    printf '%s: ' "$message" >/dev/tty
  fi
  read -r value </dev/tty || true
  printf '%s' "${value:-$default_value}"
}

prompt_secret() {
  local message="$1"
  local value=""

  has_tty || die "No terminal available. Run: export CHENYU_LLM_API_KEY='sk-...' && curl -fsSL <script-url> | bash"
  printf '%s: ' "$message" >/dev/tty
  read -r -s value </dev/tty || true
  printf '\n' >/dev/tty
  printf '%s' "$value"
}

normalize_base_url() {
  local url="$1"

  [ -n "$url" ] || die "Base URL cannot be empty"
  if [[ ! "$url" =~ ^https?:// ]]; then
    url="https://$url"
  fi
  url="${url%/}"
  url="${url%/v1}"
  url="${url%/codex}"
  printf '%s/codex/v1' "$url"
}

toml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/}"
  value="${value//$'\r'/}"
  printf '%s' "$value"
}

sh_quote() {
  printf "'"
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
  printf "'"
}

clean_api_key() {
  local key="$1"
  key="$(printf '%s' "$key" | tr -d '\r\n')"
  key="${key#Bearer }"
  key="${key#bearer }"
  key="${key#sk }"
  printf '%s' "$key"
}

strip_managed_config() {
  local source_file="$1"
  local target_file="$2"

  awk -v provider="$PROVIDER_ID" '
    BEGIN {
      managed = "model_providers." provider
      current_section = ""
      skip = 0
    }
    function section_name(line, s) {
      s = line
      sub(/^[[:space:]]*\[/, "", s)
      sub(/\][[:space:]]*($|#.*$)/, "", s)
      gsub(/"/, "", s)
      return s
    }
    /^[[:space:]]*\[/ {
      current_section = section_name($0)
      if (current_section == managed || index(current_section, managed ".") == 1) {
        skip = 1
        next
      }
      skip = 0
    }
    skip { next }
    current_section == "" && /^[[:space:]]*model[[:space:]]*=/ { next }
    current_section == "" && /^[[:space:]]*model_provider[[:space:]]*=/ { next }
    { print }
  ' "$source_file" >"$target_file"
}

main() {
  [[ "$PROVIDER_ID" =~ ^[A-Za-z0-9_-]+$ ]] || die "Provider id must contain only letters, numbers, underscore, or hyphen"

  local base_url
  base_url="$(normalize_base_url "$RAW_BASE_URL")"

  info "Chenyu Codex setup"
  printf 'Provider: %s\n' "$PROVIDER_ID"
  printf 'Base URL: %s\n' "$base_url"
  printf 'Model: %s\n' "$DEFAULT_MODEL"
  printf '\n'

  mkdir -p "$CODEX_DIR"
  chmod 700 "$CODEX_DIR" 2>/dev/null || true

  local api_key="${CHENYU_CODEX_API_KEY:-${CHENYU_LLM_API_KEY:-}}"
  local keep_existing_key="n"

  if [ -z "$api_key" ] && [ -f "$KEY_FILE" ]; then
    keep_existing_key="$(prompt "Existing API key file found. Keep it? (Y/n)" "Y")"
  fi

  if [[ "$keep_existing_key" =~ ^[Yy]$ ]]; then
    info "Keeping existing API key file: $KEY_FILE"
  else
    if [ -z "$api_key" ]; then
      api_key="$(prompt_secret "Enter Chenyu API key")"
    fi
    api_key="$(clean_api_key "$api_key")"
    [ -n "$api_key" ] || die "API key cannot be empty"
    printf '%s' "$api_key" >"$KEY_FILE"
    chmod 600 "$KEY_FILE" 2>/dev/null || true
    info "API key saved: $KEY_FILE"
  fi

  if [ ! -f "$CONFIG_FILE" ]; then
    : >"$CONFIG_FILE"
  fi
  chmod 600 "$CONFIG_FILE" 2>/dev/null || true

  local timestamp
  timestamp="$(date +%Y%m%d%H%M%S)"
  local backup_file="$CONFIG_FILE.bak.$timestamp"
  cp "$CONFIG_FILE" "$backup_file"

  local tmp_file
  tmp_file="$(mktemp "$CODEX_DIR/config.toml.tmp.XXXXXX")"
  local body_file
  body_file="$(mktemp "$CODEX_DIR/config.toml.body.XXXXXX")"
  trap 'rm -f "$tmp_file" "$body_file"' EXIT

  strip_managed_config "$CONFIG_FILE" "$body_file"

  cat >"$tmp_file" <<EOF
# Chenyu Codex default model. Managed by helper/codex-cli-setup.sh.
model = "$(toml_escape "$DEFAULT_MODEL")"
model_provider = "$(toml_escape "$PROVIDER_ID")"
EOF

  if [ -s "$body_file" ]; then
    printf '\n' >>"$tmp_file"
    cat "$body_file" >>"$tmp_file"
  fi
  printf '\n' >>"$tmp_file"

  local auth_command
  auth_command="cat $(sh_quote "$KEY_FILE")"

  cat >>"$tmp_file" <<EOF
# Chenyu Codex provider. Managed by helper/codex-cli-setup.sh.
[model_providers.$PROVIDER_ID]
name = "Chenyu Codex"
base_url = "$(toml_escape "$base_url")"
wire_api = "responses"
supports_websockets = false

[model_providers.$PROVIDER_ID.auth]
command = "/bin/sh"
args = ["-lc", "$(toml_escape "$auth_command")"]
refresh_interval_ms = 0
EOF

  mv "$tmp_file" "$CONFIG_FILE"
  trap - EXIT

  info "Configuration updated: $CONFIG_FILE"
  printf 'Backup: %s\n' "$backup_file"
  printf '\n'
  info "Next steps"
  printf '1. Run: codex debug models\n'
  printf '2. Run: codex exec --skip-git-repo-check --ephemeral --sandbox read-only "only reply OK"\n'
  printf '3. Restart the Codex desktop app if you use it.\n'
}

main "$@"
