# Known Failure Patterns

This document maps recognizable OpenClaw failure signatures to the **next safe diagnostic step**. It is intentionally evidence-driven: a matching symptom is a reason to inspect a specific area, not proof that a particular repair applies.

The patterns below were observed during the documented OpenClaw `2026.8.1` recovery and cross-checked against current upstream documentation where applicable.

## Pattern 1 — Gateway connection refused

### Observable signature

```text
ECONNREFUSED
```

or a deep status showing a failed connectivity probe.

### What it tells you

The client cannot establish the expected Gateway connection. It does **not** identify why the Gateway is unavailable.

### Do not assume

- firewall or port configuration is automatically the root cause;
- the Gateway binary is broken;
- reinstalling OpenClaw is the correct first response.

### Safe evidence to collect

```bash
openclaw --version
openclaw gateway status --deep
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

The journal usually provides the first actionable startup exception.

### Recovery gate

Do not change networking merely because `ECONNREFUSED` is visible. Fix the concrete startup blocker reported by the service/Gateway first.

---

## Pattern 2 — Multi-agent owner ambiguity

### Observable signature

Representative incident error:

```text
AgentSelectionRequiredError: Multiple agents are configured, but session agent resolution has no explicit owner. Pass an agentId, an agent-scoped session key, or a prepared fallbackAgentId.
```

### What it tells you

OpenClaw is executing an operation that requires an agent owner, but the current multi-agent configuration does not provide one for that path.

Current OpenClaw documentation describes `agents.defaults.systemAgent.agentId` as the owner for ambient system work and fallback ownership when an ambient path omits `agentId`.

### Do not assume

- an agent is corrupt;
- one of the configured agents should be deleted;
- the agent ID used by another installation is appropriate for yours.

### Safe evidence to collect

```bash
openclaw agents list
openclaw config get agents.defaults.systemAgent.agentId
```

Review the actual configured agents and determine whether the failing path requires an explicit system owner.

### Change only if evidenced

For an environment where the error is specifically caused by missing ambient/system ownership, select an **existing appropriate agent** and configure that installation's own ID:

```bash
openclaw config set agents.defaults.systemAgent.agentId <system-agent-id>
openclaw config get agents.defaults.systemAgent.agentId
```

Never copy the placeholder or an ID from an incident report.

Upstream reference: <https://docs.openclaw.ai/gateway/config-agents>

---

## Pattern 3 — Stale Gateway service after an upgrade

### Observable signature

The CLI reports the new OpenClaw version while the installed Gateway service definition still references an older installation/version or wrapper.

### What it tells you

The executable used interactively and the executable/service definition used by the managed Gateway may no longer represent the same installation.

### Safe evidence to collect

```bash
which openclaw
openclaw --version
openclaw gateway status --deep
systemctl --user cat openclaw-gateway.service
```

Compare the CLI version/path with the managed service command.

### Do not assume

- a full application reinstall is required;
- editing the systemd unit by hand is safer than using the supported installer;
- `sudo` is appropriate for a user-owned service.

### Change only if evidenced

Current OpenClaw troubleshooting documentation recommends reinstalling the intended Gateway service from the newer installation when the service is stale:

```bash
openclaw gateway install --force
```

Re-probe the Gateway after the service definition is corrected.

Upstream references:

- <https://docs.openclaw.ai/gateway/troubleshooting>
- <https://docs.openclaw.ai/cli/gateway>

---

## Pattern 4 — Gateway installer refuses unsafe permissions

### Observable signature

The Gateway installer refuses to rewrite the user service because the relevant service definition/directory has unsafe write permissions.

### What it tells you

OpenClaw is protecting a managed service definition whose write authority cannot be safely verified.

### Do not assume

- recursive permission repair is needed;
- ownership should be changed broadly;
- `sudo`, `chmod -R`, or a blanket `777` permission change is acceptable.

### Safe evidence to collect

On Linux, inspect directory metadata only:

```bash
ls -ld ~/.config ~/.config/systemd ~/.config/systemd/user
ls -l ~/.config/systemd/user/openclaw-gateway.service*
```

### Change only if evidenced

If the affected path is owned by the user, is not intentionally shared, and the installer specifically reports group/other write access, remove only that excess write permission from the identified path:

```bash
chmod go-w <identified-path>
```

Retry the same supported Gateway installer command afterward.

Upstream reference: <https://docs.openclaw.ai/cli/gateway>

---

## Pattern 5 — Official plugin version drift

### Observable signature

Representative form:

```text
Plugin version drift: <count> active official plugin not on gateway <version>
- <plugin-name>: <installed-version> -> expected <gateway-version>
```

### What it tells you

At least one active official plugin does not match the Gateway release expected by the installed OpenClaw version.

### Do not assume

- every plugin needs to be upgraded;
- plugin drift is necessarily the only startup blocker;
- unrelated custom plugins should be changed at the same time.

### Safe evidence to collect

```bash
openclaw gateway status --deep
openclaw plugins list
```

Identify the exact plugin named by the diagnostic before changing anything.

### Recovery gate

Update only the plugin supported by the evidence and installed release, then re-check the Gateway and read the **fresh** journal. A new startup error can indicate that the plugin blocker was removed and initialization progressed farther.

---

## Pattern 6 — Legacy session store requires migration

### Observable signature

```text
Legacy session store requires migration:
.../agents/<agent-id>/sessions/sessions.json
```

### What it tells you

A legacy session source still requires migration into the per-agent SQLite runtime store.

### Do not assume

- deleting or renaming `sessions.json` is a migration;
- unreferenced JSONL files should be manually deleted;
- all agents should be migrated blindly without inspection.

### Safe evidence to collect

Target the affected agent:

```bash
openclaw doctor --session-sqlite inspect --session-sqlite-agent <agent-id>
openclaw doctor --session-sqlite dry-run --session-sqlite-agent <agent-id>
```

Review target count, entry/event counts, unreferenced artifacts, and issues before import.

### Change only if evidenced

Back up OpenClaw state and stop the Gateway before a destructive session-SQLite maintenance operation such as `import`. Then use the supported migration workflow described in [Legacy Session Store → SQLite Migration](session-sqlite-migration.md).

Current OpenClaw documentation classifies `inspect`, `dry-run`, and `validate` as read-only and `import`, `compact`, `recover`, and `restore` as destructive maintenance modes that use the state ownership lock.

Upstream reference: <https://docs.openclaw.ai/cli/doctor>

---

## Pattern 7 — systemd `start-limit-hit`

### Observable signature

```text
start-limit-hit
```

or systemd stops retrying after repeated fast failures.

### What it tells you

The service manager has limited further restart attempts. This is usually a **secondary condition**, not the original Gateway failure.

### Do not assume

- resetting systemd is the repair;
- the service is healthy because the failure counter was reset.

### Safe evidence to collect

```bash
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
systemctl --user status openclaw-gateway.service --no-pager
```

Locate the startup exception that occurred **before** systemd reached the restart limit.

### Change only after root cause repair

Once the actual startup blocker has been corrected:

```bash
systemctl --user reset-failed openclaw-gateway.service
```

Then start/restart using the supported OpenClaw Gateway command and validate connectivity.

---

## Pattern 8 — A different error appears after a fix

### Observable signature

The previous error disappears, but the Gateway still fails with a new concrete startup error.

### What it can mean

This is not automatically regression. Multi-stage startup can expose blockers sequentially. Removing one blocker can allow initialization to proceed far enough to reveal the next one.

### Correct response

Return to evidence collection:

```text
previous blocker removed
        ↓
new start attempt
        ↓
fresh status + fresh journal
        ↓
classify new blocker
        ↓
one justified change
```

Avoid stacking speculative fixes. The central discipline of this playbook is **one evidenced blocker at a time**.

---

## Pattern 9 — UI is reachable but an agent turn fails on workspace migration

### Observable signature

```text
Legacy workspace setup state requires migration for <workspace-path>;
run openclaw doctor --fix.
```

### What it tells you

The Gateway transport and control UI can be healthy while a selected agent's workspace setup/attestation state is still legacy and not ready for runtime use.

### Do not assume

- a reachable UI proves the agent runtime is healthy;
- the agent itself is corrupt;
- changing the system-agent selection will repair workspace state;
- deleting workspace files is an acceptable migration.

### Safe next step

Preserve state, stop the Gateway before Doctor-owned shared-state migrations, and rerun the supported repair path offline. Retain the output showing whether workspace setup/attestation state was imported and verified.

Related upstream report for OpenClaw `2026.8.1`:

- <https://github.com/openclaw/openclaw/issues/133881>

See [UI Reachable but Agent Turns Fail After Upgrade](ui-agent-runtime-migration.md).

---

## Pattern 10 — Legacy exec approvals block the repair path

### Observable signature

```text
ExecApprovalsMigrationRequiredError:
Legacy exec approvals exist at ~/.openclaw/exec-approvals.json.
Run `openclaw doctor --fix` before using exec approvals.
```

The same warning may also appear during Doctor itself.

### What it tells you

A retired file-backed approvals source remains visible while the current runtime expects canonical approvals state in SQLite.

On affected OpenClaw `2026.8.1` builds, upstream reports show that this can become a catch-22: the error directs the operator to Doctor, but Doctor can encounter the same gate before reaching the migration step that would retire the file.

### Do not assume

- deleting the legacy file is safe;
- a repeated `doctor --fix` invocation will necessarily produce a different result;
- manually editing `openclaw.sqlite` is appropriate;
- this release-specific workaround applies unchanged to future OpenClaw releases.

### Safe next step

Keep the Gateway stopped, create a verified backup, preserve the legacy approvals document privately, and follow the version-aware recovery guidance in [UI Reachable but Agent Turns Fail After Upgrade](ui-agent-runtime-migration.md).

Related upstream regression report:

- <https://github.com/openclaw/openclaw/issues/133813>

## Related guides

- [Diagnosis Workflow](diagnosis.md)
- [Safe Recovery Workflow](safe-recovery-workflow.md)
- [Recovery Procedure](recovery-procedure.md)
- [Legacy Session Store → SQLite Migration](session-sqlite-migration.md)
- [UI Reachable but Agent Turns Fail After Upgrade](ui-agent-runtime-migration.md)
- [systemd Recovery Notes](systemd-recovery.md)
- [Sanitized Error Examples](../examples/errors/sanitized-errors.md)
