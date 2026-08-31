#!/usr/bin/env bash

# OpenClaw Recovery Playbook - conservative diagnostic collector
#
# Design goals:
#   - no sudo
#   - no service restarts/stops/starts
#   - no OpenClaw configuration changes
#   - no migrations
#   - no OpenClaw/system permission changes
#   - sanitized output by default
#   - journal logs excluded unless explicitly requested
#
# The script may query the locally configured OpenClaw runtime through normal
# OpenClaw CLI commands. It does not invoke curl, wget, ssh, scp, or any upload
# command. Sanitization is best-effort, not a guarantee: review output before
# sharing it publicly.

set -u

SCRIPT_VERSION="0.2.0"
INCLUDE_LOGS=0
OUTPUT_FILE=""
SERVICE_NAME="openclaw-gateway.service"

usage() {
  cat <<'EOF'
Usage:
  openclaw-diagnostics.sh [--include-logs] [--output FILE] [--help]

Options:
  --include-logs   Include the last 80 journal message bodies for the OpenClaw
                   gateway. Logs can contain sensitive information. They are
                   sanitized on a best-effort basis but MUST be manually
                   reviewed before sharing.

  --output FILE    Write the sanitized report to a new FILE instead of stdout.
                   The script refuses to overwrite an existing file or symlink.
                   The new report is created with user-only permissions (0600).

  --help           Show this help text.

This script is diagnostic-only with respect to OpenClaw and system state. It
does not restart services, modify OpenClaw configuration, migrate sessions,
change OpenClaw/system permissions, or delete files.

When --output is used, the only intended write is creation of the requested
local report file.
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

sanitize() {
  # Conservative pattern-based redaction. Keep diagnostic meaning where
  # possible, but never claim that automated sanitization is complete.
  sed -E \
    -e 's#/home/[^/[:space:]]+#~#g' \
    -e 's#/Users/[^/[:space:]]+#~#g' \
    -e 's#(\.openclaw/agents/)[^/[:space:]]+#\1<agent-id>#g' \
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
    -e 's#sk-[A-Za-z0-9_-]{12,}#<redacted-token>#g'
}

sanitize_agents() {
  # Agent identifiers are environment-specific. Redact only agent-list header
  # lines instead of globally replacing every line beginning with a dash.
  sanitize | sed -E \
    -e 's#^-[[:space:]]+[^[:space:]]+#- <agent-id>#' \
    -e 's#^[[:space:]]*Agent:[[:space:]].*#  Agent: <agent-id>#'
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

emit_agent_stream() {
  if [ -n "$OUTPUT_FILE" ]; then
    sanitize_agents >> "$OUTPUT_FILE"
  else
    sanitize_agents
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

run_agent_command() {
  section "$1"
  shift

  if ! command -v "$1" >/dev/null 2>&1; then
    emit "Command unavailable: $1"
    return 0
  fi

  { "$@" 2>&1 || true; } | emit_agent_stream
}

if [ -n "$OUTPUT_FILE" ]; then
  # Refuse obvious system destinations. No elevated privileges are used.
  case "$OUTPUT_FILE" in
    /etc/*|/usr/*|/bin/*|/sbin/*|/boot/*|/proc/*|/sys/*|/dev/*)
      printf 'Error: refusing system path: %s\n' "$OUTPUT_FILE" >&2
      exit 2
      ;;
  esac

  if [ -e "$OUTPUT_FILE" ] || [ -L "$OUTPUT_FILE" ]; then
    printf 'Error: output file or symlink already exists; refusing to overwrite: %s\n' "$OUTPUT_FILE" >&2
    exit 2
  fi

  umask 077
  if ! ( set -C; : > "$OUTPUT_FILE" ) 2>/dev/null; then
    printf 'Error: cannot safely create new output file: %s\n' "$OUTPUT_FILE" >&2
    exit 1
  fi

  chmod 600 "$OUTPUT_FILE" 2>/dev/null || {
    printf 'Error: could not enforce 0600 on output file; removing report.\n' >&2
    rm -f -- "$OUTPUT_FILE"
    exit 1
  }
fi

emit "OpenClaw Diagnostic Report (sanitized)"
emit "Collector version: ${SCRIPT_VERSION}"
emit "Generated locally. No upload command is invoked by this script."
emit "WARNING: Sanitization is best-effort. Review before sharing."

run_command "UTC time" date -u '+%Y-%m-%dT%H:%M:%SZ'
run_command "Operating system" uname -srm
run_command "OpenClaw version" openclaw --version
run_command "Gateway deep status" openclaw gateway status --deep
run_command "OpenClaw status" openclaw status
run_agent_command "Configured agents (identifiers redacted)" openclaw agents list --bindings
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
  section "Gateway journal - last 80 message bodies (SENSITIVE; review manually)"
  if command -v journalctl >/dev/null 2>&1; then
    {
      # -o cat omits journal metadata such as timestamp/hostname and returns
      # message bodies only, reducing unnecessary identifying information.
      journalctl --user -u "$SERVICE_NAME" -n 80 --no-pager -o cat 2>&1 || true
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
emit "No OpenClaw configuration change was requested."
emit "No service restart/stop/start was requested."
emit "No session migration was requested."
emit "No OpenClaw/system permission change was requested."
emit "No sudo command was requested."
emit "No curl/wget/ssh/scp/upload command was requested."
emit "If --output was used, only the requested local report file was created."

if [ -n "$OUTPUT_FILE" ]; then
  printf 'Sanitized report written to: %s\n' "$OUTPUT_FILE"
  printf 'Review it manually before sharing.\n'
fi
