# OpenClaw Recovery Playbook

A community troubleshooting and recovery playbook for OpenClaw, built from a real multi-stage recovery after an upgrade to OpenClaw `2026.8.1`.

> **Unofficial project.** This repository is not affiliated with or maintained by the OpenClaw project. Always verify commands against the current OpenClaw documentation before running them on production systems.

## Why this repository exists

An OpenClaw gateway can fail for more than one reason at the same time. In the incident documented here, recovery required resolving several independent blockers in sequence:

- stale systemd user-service metadata after an upgrade;
- unsafe permissions on the user systemd directory/service files;
- multi-agent ownership ambiguity (`AgentSelectionRequiredError`);
- official plugin version drift;
- legacy per-agent `sessions.json` stores requiring migration to SQLite;
- systemd `start-limit-hit` after repeated failed starts;
- a later legacy exec-approvals migration gate;
- legacy workspace setup/attestation state that could block agent turns even while the control UI was reachable.

The goal of this repository is to help operators diagnose the **next exact blocker** instead of deleting state or applying broad, destructive fixes.

One of the central lessons from the incident is:

```text
Gateway healthy ≠ application fully recovered
```

A stronger completion model is:

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

## Quick failure triage

Start with the exact error you can observe. Do not treat this table as proof of root cause; use it to choose the next safe inspection step.

| Symptom / error | Do **not** assume | Next safe check | Guide |
|---|---|---|---|
| `ECONNREFUSED` | The port or firewall is automatically the root cause | Check deep gateway status and the fresh service journal | [Known failure patterns](docs/known-failure-patterns.md#pattern-1--gateway-connection-refused) |
| `AgentSelectionRequiredError` | An agent must be deleted | Inspect the multi-agent ownership/system-agent configuration | [Known failure patterns](docs/known-failure-patterns.md#pattern-2--multi-agent-owner-ambiguity) |
| `Plugin version drift` | Every plugin or OpenClaw component should be updated blindly | Identify and verify the specific plugin/version reported by deep status | [Known failure patterns](docs/known-failure-patterns.md#pattern-5--official-plugin-version-drift) |
| `Legacy session store requires migration` | `sessions.json` should be renamed or deleted | Run targeted `inspect` and `dry-run` before any import | [Session SQLite migration](docs/session-sqlite-migration.md) |
| `start-limit-hit` | systemd itself is the root cause | Read the preceding gateway startup exception in the journal | [Known failure patterns](docs/known-failure-patterns.md#pattern-7--systemd-start-limit-hit) |
| `Legacy workspace setup state requires migration` | A reachable UI means the agent is healthy | Preserve state and inspect the offline migration path | [UI / agent runtime migration](docs/ui-agent-runtime-migration.md) |
| `Legacy exec approvals exist...` | Repeating `doctor --fix` must eventually resolve it | Verify whether the retired source still exists and use version-aware guidance | [UI / agent runtime migration](docs/ui-agent-runtime-migration.md) |

A useful mental model is:

```text
symptom → evidence → one justified change → probe → fresh evidence
```

A different error after a justified fix can be progress: the gateway may have advanced far enough to expose the next blocker.

## Recovery principles

1. **Back up first.** Preserve OpenClaw state before modifying migrations or configuration.
2. **Read the logs.** Fix the error the gateway or agent runtime is currently reporting, not the error you expect to see.
3. **Prefer supported migration commands.** Do not manually edit or delete session/state stores to make errors disappear.
4. **Avoid broad permission changes.** Do not use recursive `chmod` or `sudo` against a user-owned OpenClaw service unless the documentation explicitly requires it.
5. **Validate after every stage.** A command completing successfully does not guarantee that the gateway or agents are healthy.
6. **Validate the actual application.** A reachable UI is not proof that expected agent turns work.
7. **Preserve rollback artifacts.** Keep backups, migration manifests, and quarantined/preserved files until the system has remained stable.

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
Control UI: reachable
Expected agents: successful test turns
```

The recovery was completed without deleting the configured agents or their migrated session data.

## Start here

- [Safe recovery workflow](docs/safe-recovery-workflow.md)
- [Known failure patterns](docs/known-failure-patterns.md)
- [UI reachable but agent turns fail after upgrade](docs/ui-agent-runtime-migration.md)
- [Sanitized error examples](examples/errors/sanitized-errors.md)
- [Incident report](docs/incident-2026-08-31.md)
- [Diagnosis workflow](docs/diagnosis.md)
- [Recovery procedure](docs/recovery-procedure.md)
- [Session SQLite migration](docs/session-sqlite-migration.md)
- [systemd recovery notes](docs/systemd-recovery.md)
- [Post-recovery checklist](docs/post-recovery-checklist.md)
- [Project changelog](CHANGELOG.md)

## Privacy-first diagnostic collector

The repository includes [`scripts/diagnostics/openclaw-diagnostics.sh`](scripts/diagnostics/openclaw-diagnostics.sh), a conservative Bash collector intended to gather enough evidence for initial troubleshooting without making recovery changes.

Current collector version: **0.3.1**.

The default mode follows a **minimum collection** principle. It requests only:

- UTC time;
- operating system/kernel information;
- OpenClaw version;
- `openclaw gateway status --deep`;
- selected read-only systemd gateway properties.

It does **not** request `sudo`, restart/stop/start the service, change OpenClaw configuration, migrate sessions, change permissions, or upload data. Sanitization is best-effort and must never be treated as a guarantee that output is safe to publish.

### Run the default diagnostic

```bash
bash scripts/diagnostics/openclaw-diagnostics.sh
```

The following higher-risk sections are deliberately **opt-in**:

| Option | Adds | Why it is opt-in |
|---|---|---|
| `--include-status` | `openclaw status` | May expose host, agent, session, heartbeat, account, or network details |
| `--include-agents` | `openclaw agents list` | Agent identifiers and environment-specific metadata require additional sanitization/review |
| `--include-plugins` | `openclaw plugins list` | Custom/private plugin names or paths may reveal environment details |
| `--include-logs` | Last 80 gateway journal message bodies | Logs may contain sensitive runtime data |
| `--output FILE` | A local report file | Creates a new `0600` file; existing files and symlinks are refused |

Agent bindings are intentionally **not requested** by the collector, even when `--include-agents` is enabled.

### Sanitized example

A healthy default-mode report can resemble:

```text
OpenClaw Diagnostic Report (sanitized)
Collector version: 0.3.1
Privacy mode: minimal collection by default; sensitive sections are opt-in.

===== OpenClaw version =====
OpenClaw 2026.8.1 (<build-id>)

===== Gateway deep status =====
Gateway: bind=loopback (127.0.0.1), port=18789 (service args)
CLI version: 2026.8.1
Gateway version: 2026.8.1
Runtime: running (pid <pid>, state active, sub running, last exit 0, reason 0)
Connectivity probe: ok
Listening: 127.0.0.1:18789

===== OpenClaw status =====
Not collected by default. Use --include-status only if needed.

===== Configured agents =====
Not collected by default. Use --include-agents only if needed.

===== Plugins =====
Not collected by default. Use --include-plugins only if needed.

===== systemd gateway state =====
LoadState=loaded
ActiveState=active
SubState=running
UnitFileState=enabled
NRestarts=0
ExecMainStatus=0

===== Gateway journal =====
Not collected by default. Use --include-logs only if needed.
```

The example is intentionally shortened and generalized. Do not copy raw terminal prompts, usernames, hostnames, private addresses, agent IDs, session identifiers, tokens, or unreviewed logs into an issue or public report.

### Before sharing diagnostic output

Manually inspect the report even if it says `sanitized`. Look specifically for usernames, hostnames, public/private IP addresses, IPv6 addresses, email addresses, agent or workspace names, account/channel/binding names, UUIDs, tokens, secrets, organization/project names, custom plugin names/paths, and any other environment-specific information.

If sensitive data remains, **do not publish the report**. Redact it manually or improve the collector first.

## Fast diagnostic commands

For operators who prefer to inspect commands individually, these are useful diagnostic commands, but their raw output may contain sensitive information:

```bash
openclaw --version
openclaw gateway status --deep
openclaw status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
openclaw agents list --bindings
openclaw plugins list
```

Review raw output before sharing it publicly.

If systemd has stopped retrying after repeated failures, **fix the root cause first**, then reset the failure counter:

```bash
systemctl --user reset-failed openclaw-gateway.service
```

## Scope

This repository currently focuses on recovery patterns observed on Linux with a systemd user service and a multi-agent OpenClaw configuration. It is not intended to replace the official OpenClaw documentation.

## Privacy model

Environment-specific identifiers are intentionally generalized. Agent IDs, local usernames, session UUIDs, migration-run IDs, hostnames, private infrastructure names, and nonessential paths are replaced with neutral placeholders.

## Security

Never publish raw OpenClaw state directories, session databases, tokens, secrets, complete logs, pairing data, approvals data, or unreviewed configuration files. See [SECURITY.md](SECURITY.md).

## Contributing

Reproducible incident reports and corrections are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and use the [privacy-safe incident template](.github/ISSUE_TEMPLATE/incident-report.md) when reporting a recovery case.

## License

MIT. See [LICENSE](LICENSE).
