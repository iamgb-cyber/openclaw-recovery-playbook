# Security Policy

Troubleshooting output can contain sensitive operational information.

## Do not publish

Remove or redact:

- API keys, access tokens, passwords, cookies, and authorization headers;
- raw OpenClaw state directories;
- SQLite databases and raw session stores;
- private conversation/session transcripts;
- device pairing or pending-device data;
- private keys and certificates;
- environment files containing secrets;
- personally identifying information;
- hostnames, internal agent IDs, infrastructure/project names, and network details that are not required to reproduce the problem;
- session UUIDs and migration identifiers unless essential and safe to disclose.

## Diagnostic collector

The repository includes a privacy-first diagnostic collector at:

```text
scripts/diagnostics/openclaw-diagnostics.sh
```

Its default mode deliberately avoids higher-risk `openclaw status`, agent-list, plugin-list, and journal sections unless explicitly requested with opt-in flags.

The collector is **not an anonymization guarantee**. Automated redaction is best-effort and can miss environment-specific information, especially when command output changes format, wraps values across terminal lines, or contains identifiers the sanitizer does not recognize.

Always perform a manual review before sharing generated output.

The current collector is diagnostic-only with respect to OpenClaw/system state: it does not request `sudo`, restart/stop/start the Gateway, modify OpenClaw configuration, migrate sessions, change OpenClaw/system permissions, or invoke an upload command. If `--output FILE` is used, it creates only the requested new local report file with user-only permissions and refuses existing files/symlinks.

## Logs

Prefer a minimal sanitized excerpt containing the error and a small amount of surrounding context. Do not upload complete logs without reviewing every line.

Example sanitization:

```text
/home/<local-user>/.openclaw/... → ~/.openclaw/...
<real-agent-id>                  → <agent-id>
<real-hostname>                  → <host>
<session-uuid>                   → <session-id>
<secret-value>                   → <redacted-secret>
```

Useful technical failure signatures should normally be preserved when they do not identify the environment. For example, retaining strings such as `AgentSelectionRequiredError`, `Legacy session store requires migration`, or `start-limit-hit` makes a report searchable without requiring disclosure of local agent names, usernames, or session identifiers.

See [Sanitized Error Examples](examples/errors/sanitized-errors.md) for the repository's publication pattern.

## Recovery safety

Commands in this repository can modify service configuration or migrate persistent state. Always verify commands against your installed OpenClaw version, create a backup, understand what can change, prefer inspect/dry-run modes, and preserve migration/rollback artifacts until recovery is confirmed.

When a recovery requires a persistent-state maintenance operation, stop the Gateway first when required by the installed OpenClaw tooling/documentation and avoid manually editing the underlying SQLite/session files.

## Vulnerabilities

Do not publish exploitable security vulnerabilities, credentials, or sensitive forensic material in a public issue. Use the appropriate private disclosure channel for the affected upstream project.
