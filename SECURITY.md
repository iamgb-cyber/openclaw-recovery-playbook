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

## Recovery safety

Commands in this repository can modify service configuration or migrate persistent state. Always verify commands against your installed OpenClaw version, create a backup, understand what can change, prefer inspect/dry-run modes, and preserve migration/rollback artifacts until recovery is confirmed.

## Vulnerabilities

Do not publish exploitable security vulnerabilities, credentials, or sensitive forensic material in a public issue. Use the appropriate private disclosure channel for the affected upstream project.
