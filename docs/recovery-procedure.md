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

Raw output from these commands can contain environment-specific or sensitive data. Review before sharing publicly.

## Phase B — Correct service drift only if evidenced

If the installed service is stale after an upgrade, use the service installer supported by your OpenClaw version. For the tested 2026.8.1 incident:

```bash
openclaw gateway install --force
```

If the installer reports unsafe permissions, fix only the paths it identifies. Do not use recursive permission changes as a shortcut.

## Phase C — Resolve multi-agent ownership only if evidenced

If logs report that multiple agents exist but startup has no explicit owner, select an appropriate existing agent and configure it explicitly:

```bash
openclaw config set agents.defaults.systemAgent.agentId <system-agent-id>
openclaw config get agents.defaults.systemAgent.agentId
```

Never copy an environment-specific agent ID from an incident report.

## Phase D — Resolve official plugin drift

If deep status reports a specific official plugin version mismatch, update only that identified plugin using the plugin command supported by your installed release, then verify the plugin list.

Re-check the Gateway. If it still fails, read the new journal output rather than assuming the plugin was the only blocker.

## Phase E — Migrate legacy session stores

If startup explicitly reports a legacy session store requiring migration, follow [Legacy Session Store → SQLite Migration](session-sqlite-migration.md).

Use this sequence:

1. `inspect` the affected target;
2. `dry-run` the affected target;
3. stop the Gateway before destructive maintenance;
4. verify a backup of OpenClaw state and sufficient free space;
5. run `import` for the evidenced target;
6. run `validate`;
7. restart/probe only after maintenance is complete.

Current OpenClaw documentation classifies `inspect`, `dry-run`, and `validate` as read-only. `import`, `compact`, `recover`, and `restore` are destructive maintenance modes that use the Gateway state ownership lock and must not race a running Gateway.

Prefer targeting the agent named by the current error during sequential recovery. Do not delete or rename `sessions.json` to suppress the startup check.

## Phase F — Recover systemd and start

After actual startup blockers and any required offline maintenance are corrected:

```bash
systemctl --user reset-failed openclaw-gateway.service
openclaw gateway start
openclaw gateway status --deep
```

Resetting `start-limit-hit` is not itself a repair. Do it only after the underlying startup failure has been addressed.

## Phase G — Validate transport and agent runtime separately

First confirm Gateway transport health:

```text
CLI version == expected version
Gateway version == expected version
Runtime == running
Connectivity probe == ok
Expected bind/port == listening
```

Then validate what deep Gateway status cannot prove:

1. open the control UI from the intended client;
2. select each expected production agent that matters to the installation;
3. send a simple non-destructive test message;
4. confirm that each expected agent completes a turn successfully;
5. inspect fresh logs for any agent that fails.

A reachable UI is not sufficient evidence of complete recovery.

If an agent turn reports:

```text
Legacy workspace setup state requires migration for <workspace-path>;
run openclaw doctor --fix.
```

or:

```text
Legacy exec approvals exist at ~/.openclaw/exec-approvals.json.
Run `openclaw doctor --fix` before using exec approvals.
```

follow [UI Reachable but Agent Turns Fail After Upgrade](ui-agent-runtime-migration.md). For OpenClaw `2026.8.1`, these states were observed as additional upgrade blockers after the Gateway itself had become reachable.

## If it still fails

Do not immediately move or delete more state. Capture a fresh journal:

```bash
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

The new failure may be evidence that the previous blocker was successfully removed and startup progressed to a later stage.
