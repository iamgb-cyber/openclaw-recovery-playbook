#!/usr/bin/env bash

# OpenClaw Recovery Playbook - read-only diagnostic collector
#
# Design goals:
#   - no sudo
#   - no service restarts/stops/starts
#   - no configuration changes
#   - no migrations
#   - no network calls performed by this script
#   - sanitized output by default
#   - journal logs excluded unless explicitly requested
#
# IMPORTANT: Sanitization is best-effort, not a guarantee. Review the output
# before sharing it publicly.

set -u

SCRIPT_VERSION="0.1.0"
INCLUDE_LOGS=0
OUTPUT_FILE=""
SERVICE_NAME="openclaw-gateway.service"

usage() {
  cat <<'EOF'
Usage:
  openclaw-diagnostics.sh [--include-logs] [--output FILE] [--help]

Options:
  --include-logs   Include the last 80 journal lines for the OpenClaw gateway.
                   Logs can contain sensitive information. They are sanitized
                   on a best-effort basis but MUST be manually reviewed before
                   sharing.

  --output FILE    Write the sanitized report to FILE instead of stdout.
                   The file is created with user-only permissions (0600).

  --help           Show this help text.

This script is diagnostic-only. It does not restart services, modify OpenClaw
configuration, change permissions, migrate sessions, or delete files.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --include-logs)
      INCLUDE_LOGS=1
      shift
      ;;
    --output)
      if [ "$#" -lt 2 ]; then
        printf 'Error: --output requires a file path.\n' >&2
        exit 2
      fi
      OUTPUT_FILE=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Error: unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# Escape a literal string for use in the replacement side of sed s///.
sed_replacement_escape() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

HOME_ESCAPED=$(sed_replacement_escape "${HOME:-}")
USER_ESCAPED=$(sed_replacement_escape "${USER:-}")
HOST_VALUE=$(hostname 2>/dev/null || true)
HOST_ESCAPED=$(sed_replacement_escape "$HOST_VALUE")

sanitize() {
  # The first sed handles values known from the local environment.
  # The second applies conservative pattern-based redaction.
  sed \
    -e "s|${HOME_ESCAPED}|~|g" \
    -e "s|/home/${USER_ESCAPED}|~|g" \
    -e "s|/Users/${USER_ESCAPED}|~|g" \
    -e "s|${HOST_ESCAPED}|<host>|g" \
  | sed -E \
    -e 's#(\.openclaw/agents/)[^/[:space:]]+#\1<agent-id>#g' \
    -e 's#(^|[[:space:]])-[[:space:]]+[^[:space:]]+#\1- <agent-id>#' \
    -e 's#^[[:space:]]*Identity:.*#  Identity: <redacted>#' \
    -e 's#^[[:space:]]*Workspace:.*#  Workspace: <redacted>#' \
    -e 's#^[[:space:]]*Agent dir:.*#  Agent dir: <redacted>#' \
    -e 's#127\.0\.0\.1#<loopback>#g' \
    -e 's#([0-9]{1,3}\.){3}[0-9]{1,3}#<ip-address>#g' \
    -e 's#<loopback>#127.0.0.1#g' \
    -e 's#[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}#<uuid>#g' \
    -e 's#[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}#<email>#g' \
    -e 's#(Bearer[[:space:]]+)[^[:space:]]+#\1<redacted-token>#Ig' \
    -e 's#((api[_-]?key|access[_-]?token|auth[_-]?token|password|secret)[[:space:]]*[:=][[:space:]]*)[^[:space:]]+#\1<redacted-secret>#Ig' \
    -e 's#\b(sk-[A-Za-z0-9_-]{12,})\b#<redacted-token>#g'
}

emit() {
  if [ -n "$OUTPUT_FILE" ]; then
    printf '%s\n' "$1" >> "$OUTPUT_FILE"
  else
    printf '%s\n' "$1"
  fi
}

emit_stream() {
  if [ -n "$OUTPUT_FILE" ]; then
    sanitize >> "$OUTPUT_FILE"
  else
    sanitize
  fi
}

section() {
  emit ""
  emit "===== $1 ====="
}

run_command() {
  section "$1"
  shift

  if ! command -v "$1" >/dev/null 2>&1; then
    emit "Command unavailable: $1"
    return 0
  fi

  { "$@" 2>&1 || true; } | emit_stream
}

if [ -n "$OUTPUT_FILE" ]; then
  # Refuse obvious dangerous destinations and avoid accidental append to an
  # existing report. This script never needs privileged paths.
  case "$OUTPUT_FILE" in
    /etc/*|/usr/*|/bin/*|/sbin/*|/boot/*|/proc/*|/sys/*|/dev/*)
      printf 'Error: refusing system path: %s\n' "$OUTPUT_FILE" >&2
      exit 2
      ;;
  esac

  if [ -e "$OUTPUT_FILE" ]; then
    printf 'Error: output file already exists; refusing to overwrite: %s\n' "$OUTPUT_FILE" >&2
    exit 2
  fi

  umask 077
  : > "$OUTPUT_FILE" || {
    printf 'Error: cannot create output file: %s\n' "$OUTPUT_FILE" >&2
    exit 1
  }
  chmod 600 "$OUTPUT_FILE" 2>/dev/null || true
fi

emit "OpenClaw Diagnostic Report (sanitized)"
emit "Collector version: ${SCRIPT_VERSION}"
emit "Generated locally. Nothing is uploaded by this script."
emit "WARNING: Sanitization is best-effort. Review before sharing."

run_command "UTC time" date -u '+%Y-%m-%dT%H:%M:%SZ'
run_command "Operating system" uname -srm
run_command "OpenClaw version" openclaw --version
run_command "Gateway deep status" openclaw gateway status --deep
run_command "OpenClaw status" openclaw status
run_command "Configured agents (identifiers redacted)" openclaw agents list --bindings
run_command "Plugins" openclaw plugins list

section "systemd gateway state"
if command -v systemctl >/dev/null 2>&1; then
  {
    systemctl --user show "$SERVICE_NAME" \
      --property=LoadState \
      --property=ActiveState \
      --property=SubState \
      --property=UnitFileState \
      --property=ExecMainStatus \
      --property=NRestarts 2>&1 || true
  } | emit_stream
else
  emit "Command unavailable: systemctl"
fi

if [ "$INCLUDE_LOGS" -eq 1 ]; then
  section "Gateway journal - last 80 lines (SENSITIVE; review manually)"
  if command -v journalctl >/dev/null 2>&1; then
    {
      journalctl --user -u "$SERVICE_NAME" -n 80 --no-pager 2>&1 || true
    } | emit_stream
  else
    emit "Command unavailable: journalctl"
  fi
else
  section "Gateway journal"
  emit "Not collected by default. Re-run with --include-logs only if needed."
  emit "Logs can contain sensitive data and require manual review before sharing."
fi

section "Safety statement"
emit "No OpenClaw configuration changes were requested."
emit "No service restart/stop/start was requested."
emit "No session migration was requested."
emit "No permission change was requested."
emit "No sudo command was requested."
emit "No report upload or network transmission was performed by this script."

if [ -n "$OUTPUT_FILE" ]; then
  printf 'Sanitized report written to: %s\n' "$OUTPUT_FILE"
  printf 'Review it manually before sharing.\n'
fi
