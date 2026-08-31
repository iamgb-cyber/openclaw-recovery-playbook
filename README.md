# OpenClaw Recovery Playbook

A community troubleshooting and recovery playbook for OpenClaw, built from a real multi-stage recovery after an upgrade to OpenClaw `2026.8.1`.

> **Unofficial project.** This repository is not affiliated with or maintained by the OpenClaw project. Always verify commands against the current OpenClaw documentation before running them on production systems.

## Why this repository exists

An OpenClaw gateway can fail for more than one reason at the same time. In the incident documented here, the visible symptom was a gateway that would not stay online, but the actual recovery required resolving several independent blockers in sequence:

- stale systemd user-service metadata after an upgrade;
- unsafe permissions on the user systemd directory/service files;
- multi-agent ownership ambiguity (`AgentSelectionRequiredError`);
- official plugin version drift (`codex`);
- legacy per-agent `sessions.json` stores requiring migration to SQLite;
- systemd `start-limit-hit` after repeated failed starts.

The goal of this repository is to help operators diagnose the **next exact blocker** instead of deleting state or applying broad, destructive fixes.

## Recovery principles

1. **Back up first.** Preserve `~/.openclaw` before modifying state.
2. **Read the logs.** Fix the error the gateway is currently reporting, not the error you expect to see.
3. **Prefer supported migration commands.** Do not manually edit or delete session stores to make startup errors disappear.
4. **Avoid broad permission changes.** Do not use recursive `chmod` or `sudo` against a user-owned OpenClaw service unless the documentation explicitly requires it.
5. **Validate after every stage.** A command completing successfully does not guarantee that the gateway is healthy.
6. **Preserve rollback artifacts.** Keep backups, migration manifests, and quarantined files until the system has remained stable.

## Real incident summarized

Verified environment:

```text
OpenClaw CLI:      2026.8.1
OpenClaw Gateway:  2026.8.1
Service manager:   systemd --user
Gateway bind:      loopback
Gateway port:      18789
Daemon Node:       24.x
Agents involved:   3
```

Final healthy state:

```text
Runtime: running
Connectivity probe: ok
Listening: loopback:18789
```

The recovery was completed without deleting the configured agents or their migrated session data.

## Start here

- [Incident report](docs/incident-2026-08-31.md)
- [Diagnosis workflow](docs/diagnosis.md)
- [Recovery procedure](docs/recovery-procedure.md)
- [Session SQLite migration](docs/session-sqlite-migration.md)
- [systemd recovery notes](docs/systemd-recovery.md)
- [Post-recovery checklist](docs/post-recovery-checklist.md)

## Fast diagnostic commands

These commands are intentionally read-only or low-risk:

```bash
openclaw --version
openclaw gateway status --deep
openclaw status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
openclaw agents list --bindings
openclaw plugins list
```

If systemd has stopped retrying after repeated failures, **fix the root cause first**, then reset the failure counter:

```bash
systemctl --user reset-failed openclaw-gateway.service
```

## Scope

This repository currently focuses on recovery patterns observed on Linux with a systemd user service and a multi-agent OpenClaw configuration. It is not intended to replace the official OpenClaw documentation.

## Privacy model

Environment-specific identifiers are intentionally generalized. Agent IDs, local usernames, session UUIDs, migration-run IDs, hostnames, private infrastructure names, and nonessential paths are replaced with neutral placeholders.

## Security

Never publish raw OpenClaw state directories, session databases, tokens, secrets, complete logs, pairing data, or unreviewed configuration files. See [SECURITY.md](SECURITY.md).

## Contributing

Reproducible incident reports and corrections are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
