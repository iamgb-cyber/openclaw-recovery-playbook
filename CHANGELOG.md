# Changelog

All notable changes to the OpenClaw Recovery Playbook are documented here.

This project is an unofficial community playbook. Documentation is version-aware because OpenClaw behavior and supported maintenance commands can change between releases.

## Unreleased

### Added

- Known failure-pattern reference mapping recognizable errors to the next safe diagnostic step.
- Safe Recovery Workflow centered on evidence preservation and one justified change at a time.
- Sanitized error examples designed for troubleshooting, searchability, and safe public issue references.
- GitHub incident-report template with explicit privacy and evidence requirements.
- UI/agent-runtime migration recovery guide for the case where the Gateway and control UI are reachable but agent turns still fail after an upgrade.
- Version-specific documentation for the OpenClaw `2026.8.1` legacy exec-approvals migration catch-22, with upstream issue references and a preservation-first workaround.

### Changed

- Session SQLite migration guidance now explicitly separates read-only modes (`inspect`, `dry-run`, `validate`) from destructive maintenance modes (`import`, `compact`, `recover`, `restore`).
- Recovery guidance now requires the Gateway to be stopped before destructive Session SQLite maintenance so the operation does not race the Gateway state ownership lock.
- Recovery procedure and safe workflow were aligned with the same offline-maintenance rule.
- Security guidance was expanded to emphasize manual review even after automated sanitization.
- Post-recovery validation now requires successful test turns from expected production agents; Gateway transport health and UI reachability alone are no longer treated as proof of complete recovery.

### Incident follow-up — UI reachable, agent runtime blocked

A later validation stage of the `2026.8.1` recovery exposed two additional migration-sensitive states:

- legacy workspace setup/attestation state that prevented agent turns even though the control UI was reachable;
- a retired `exec-approvals.json` source that could block the repair path intended to migrate it.

The documented recovery sequence now emphasizes:

```text
Gateway process healthy
        ↓
control UI reachable
        ↓
agent runtime/state ready
        ↓
expected agent completes a test turn
        ↓
recovery confirmed
```

Related upstream reports:

- <https://github.com/openclaw/openclaw/issues/133813>
- <https://github.com/openclaw/openclaw/issues/133881>

### Quality review

- Reviewed repository structure and internal documentation links.
- Re-checked the public repository for known private identifiers from the original environment; no matches were found for the reviewed identifiers.
- Preserved exact technical error signatures where useful while keeping environment-specific identities generalized.

## Diagnostic collector 0.3.1 — 2026-08-31

### Fixed

- Corrected an IPv6 sanitization pattern that falsely matched the `HH:MM:SS` portion of ISO-8601 timestamps.

### Verified

- Bash syntax validation passed with `bash -n`.
- Default privacy-mode test produced a normal UTC timestamp.
- Default report did not include the internal agent identifiers, private host/IP details, sessions, bindings, plugins, or journal sections that had caused concern in earlier testing.

### Safety model

The collector remains diagnostic-only with respect to OpenClaw/system state. It does not request `sudo`, restart services, modify OpenClaw configuration, migrate sessions, change permissions, or upload reports.

Automated sanitization remains best-effort; manual review is required before public sharing.

## Diagnostic collector 0.3.0 — 2026-08-31

### Changed

- Switched to privacy-first minimal collection by default.
- Made higher-risk sections opt-in:
  - `--include-status`
  - `--include-agents`
  - `--include-plugins`
  - `--include-logs`
- Removed agent bindings from collector requests.
- Added best-effort IPv6 redaction.
- Kept local report creation optional through `--output FILE` with `0600` permissions and overwrite/symlink refusal.

### Reason

Testing of 0.2.0 showed that broad status output could expose environment-specific host, network, heartbeat, session, and agent information. Version 0.3.0 reduced the amount of data collected before trying to sanitize it.

## Diagnostic collector 0.2.0 — 2026-08-31

### Added

- Read-only diagnostic collection for OpenClaw version, Gateway state, agents, plugins, systemd state, and optional logs.
- Best-effort redaction for common home paths, agent paths, IPv4 addresses, UUIDs, email addresses, bearer/common secret patterns, and token-like values.
- Optional local report output with restricted permissions.

### Lessons learned

A controlled local test demonstrated that line-oriented sanitization could fail when terminal table wrapping split a private IPv4 address across lines, and that broad `openclaw status` output could expose internal agent/session details. The output from that test was not published as a repository example.

## Initial playbook — 2026-08-31

### Added

- Incident report for the OpenClaw `2026.8.1` multi-stage Gateway recovery.
- Diagnosis workflow.
- Conservative recovery procedure.
- Legacy Session Store → SQLite migration guide.
- systemd user-service recovery notes.
- Post-recovery checklist.
- `SECURITY.md`, `CONTRIBUTING.md`, `.gitignore`, and MIT license.

### Incident patterns documented

- `ECONNREFUSED`
- `AgentSelectionRequiredError`
- stale systemd user-service metadata after upgrade
- unsafe service-path permissions
- official plugin version drift
- legacy `sessions.json` migration to SQLite
- systemd `start-limit-hit`

The incident documentation intentionally uses placeholders or pseudonyms for environment-specific identities.
