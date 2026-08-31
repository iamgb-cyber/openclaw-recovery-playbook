# Recovery Procedure

This is a conservative decision framework derived from the documented incident. It is **not a command list to run blindly**.

## Phase A — Preserve and observe

Capture version, deep gateway status, systemd state, recent journal output, agents, and plugins. Back up persistent OpenClaw state before modifying migrations or configuration.

```bash
openclaw --version
openclaw gateway status --deep
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
openclaw agents list --bindings
openclaw plugins list
```

## Phase B — Correct service drift only if evidenced

If the installed service is stale after an upgrade, use the service installer supported by your OpenClaw version. For the tested 2026.8.1 incident:

```bash
openclaw gateway install --force
```

If the installer reports unsafe permissions, fix only the paths it identifies.

## Phase C — Resolve multi-agent ownership only if evidenced

If logs report that multiple agents exist but startup has no explicit owner, select an appropriate existing agent and configure it explicitly:

```bash
openclaw config set agents.defaults.systemAgent.agentId <system-agent-id>
openclaw config get agents.defaults.systemAgent.agentId
```

Never copy an environment-specific agent ID from an incident report.

## Phase D — Resolve official plugin drift

If deep status reports a specific official plugin version mismatch, update that identified plugin using the plugin command supported by your installed release, then verify the plugin list.

Re-check the gateway. If it still fails, read the new journal output rather than assuming the plugin was the only blocker.

## Phase E — Migrate legacy session stores

If startup explicitly reports a legacy session store requiring migration, follow [Legacy Session Store → SQLite Migration](session-sqlite-migration.md).

Use `inspect`, `dry-run`, `import`, and `validate`, preferably targeted to the agent named by the error.

## Phase F — Recover systemd and start

After actual startup blockers are corrected:

```bash
systemctl --user reset-failed openclaw-gateway.service
openclaw gateway start
openclaw gateway status --deep
```

## Phase G — Validate

Confirm:

```text
CLI version == expected version
Gateway version == expected version
Runtime == running
Connectivity probe == ok
Expected bind/port == listening
```

Then confirm agents/plugins and review the latest journal for new fatal errors.

## If it still fails

Do not immediately move or delete more state. Capture a fresh journal:

```bash
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

The new failure may be evidence that the previous blocker was successfully removed and startup progressed to a later stage.
