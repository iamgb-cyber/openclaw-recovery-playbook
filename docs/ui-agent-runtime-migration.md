# UI Reachable but Agent Turns Fail After Upgrade

This guide covers a failure mode observed during recovery of OpenClaw `2026.8.1`: the Gateway and control UI can be reachable while one or more agent turns still fail because legacy runtime state has not completed migration to SQLite.

> **Version-aware warning:** The workaround described here was observed on OpenClaw `2026.8.1`. Migration behavior can change between releases. Prefer the current supported OpenClaw repair path when a fixed release is available, and verify commands against current upstream documentation before applying them.

## Why this matters

A healthy Gateway transport does not prove that every agent workspace is runtime-ready.

A system can show:

```text
Runtime: running
Connectivity probe: ok
Listening: 127.0.0.1:<gateway-port>
```

while an agent turn still fails with a migration error.

Use this stronger recovery model:

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

## Failure signature A — Legacy workspace setup state

Representative sanitized error:

```text
Legacy workspace setup state requires migration for <workspace-path>;
run openclaw doctor --fix.
```

### What it tells you

Legacy workspace setup or attestation state still exists and the agent runtime expects its canonical SQLite representation.

### Important observation

On the affected `2026.8.1` installation, running `openclaw doctor --fix` while the Gateway owned the shared state did not complete the required workspace migration. With the Gateway stopped, Doctor later detected and migrated the legacy workspace state.

A related upstream report documents the same class of behavior:

- <https://github.com/openclaw/openclaw/issues/133881>

## Failure signature B — Exec approvals migration gate

Representative sanitized error:

```text
ExecApprovalsMigrationRequiredError:
Legacy exec approvals exist at ~/.openclaw/exec-approvals.json.
Run `openclaw doctor --fix` before using exec approvals.
```

### What it tells you

A retired file-backed approvals source is still present while the current runtime expects the canonical SQLite approvals store.

On the observed `2026.8.1` installation, this could create a repair catch-22: Doctor was instructed as the repair path, but the presence of the same legacy approvals file prevented Doctor from reaching the migration that would retire it.

A closely matching upstream regression report exists for `2026.8.1`:

- <https://github.com/openclaw/openclaw/issues/133813>

## Safe evidence collection

Do not print the raw approvals file into a public issue. It can contain sensitive socket or policy data.

With the Gateway stopped, inspect only metadata and safe structure as needed.

Example file-presence check:

```bash
find ~/.openclaw -maxdepth 1 -type f \
  -name 'exec-approvals*' \
  -printf '%f | size=%s | modified=%TY-%Tm-%Td %TH:%TM:%TS\n' \
  2>/dev/null
```

Check whether the public approvals CLI is blocked:

```bash
openclaw approvals get --json
```

If you need to determine whether the canonical SQLite approvals table exists, use a read-only SQLite connection and report only table/row counts. Do not publish raw policy rows.

## Conservative recovery sequence

### 1. Stop the Gateway before state migration

```bash
openclaw gateway stop
openclaw gateway status --deep
```

A failed connectivity probe is expected while the Gateway is intentionally stopped.

### 2. Create and verify a backup

For releases that provide the backup CLI:

```bash
mkdir -p ~/Backups/openclaw
openclaw backup create --output ~/Backups/openclaw --verify
```

Keep the archive private. A full OpenClaw backup can contain credentials, sessions, configuration, agent state, and workspaces.

### 3. Run Doctor offline

```bash
openclaw doctor --fix
```

If Doctor now reports workspace setup/attestation migration and verifies canonical SQLite state, retain that output as recovery evidence.

Representative successful messages can include:

```text
Migrated workspace setup state to SQLite.
Migrated workspace attestation to SQLite.
Verified canonical SQLite workspace setup state.
Removed retired workspace state after verified SQLite import.
```

### 4. If legacy exec approvals block Doctor on 2026.8.1

Do **not** delete the approvals file and do **not** edit the SQLite database manually.

The version-specific workaround observed during the incident was:

1. keep the Gateway stopped;
2. preserve the legacy file outside its canonical blocking path;
3. import that preserved document through the public approvals CLI;
4. verify the canonical store;
5. rerun Doctor while the Gateway is still stopped.

Generic pattern:

```bash
mkdir -p ~/openclaw-recovery

mv ~/.openclaw/exec-approvals.json \
  ~/openclaw-recovery/exec-approvals.json.pre-sqlite-import

openclaw approvals set \
  --file ~/openclaw-recovery/exec-approvals.json.pre-sqlite-import \
  --json

openclaw approvals get --json

openclaw doctor --fix
```

Before the `mv`, confirm that the destination does not already exist. Preserve the moved file until recovery has been validated.

This workaround is intentionally documented as **release-specific**. Upstream issue `#133813` describes a closely related Doctor ordering regression in `2026.8.1`; future releases may repair it differently.

## Validation

After offline migrations complete, start or confirm the managed Gateway and validate transport health:

```bash
openclaw gateway start
openclaw gateway status --deep
```

Look for:

```text
Runtime: running
Connectivity probe: ok
Listening: 127.0.0.1:<gateway-port>
```

Then perform the validation that transport checks cannot provide:

- open the control UI;
- select each expected production agent that matters to the installation;
- send a simple non-destructive test message;
- confirm that the agent completes a turn successfully;
- review fresh logs if any agent still fails.

Do not declare full recovery from Gateway health alone.

## Do not do this

- Do not delete `exec-approvals.json` merely to suppress the migration gate.
- Do not manually insert or edit rows in `openclaw.sqlite`.
- Do not run destructive SQLite maintenance while the Gateway owns the shared state.
- Do not assume a reachable UI means every agent workspace is ready.
- Do not publish raw approvals JSON, state databases, workspace files, tokens, or unreviewed logs.
- Do not copy environment-specific agent IDs from another incident.

## Related guides

- [Known Failure Patterns](known-failure-patterns.md)
- [Recovery Procedure](recovery-procedure.md)
- [Legacy Session Store → SQLite Migration](session-sqlite-migration.md)
- [Post-Recovery Checklist](post-recovery-checklist.md)
- [Sanitized Error Examples](../examples/errors/sanitized-errors.md)
