# Legacy Session Store → SQLite Migration

OpenClaw 2026.8.1 can refuse gateway readiness when an agent still has a legacy session store that requires migration.

Representative sanitized error:

```text
Legacy session store requires migration:
.../agents/<agent-id>/sessions/sessions.json
```

## Safety rule

**Do not delete, truncate, rename, or manually rewrite the legacy store to bypass startup.**

Before importing important history:

1. stop the Gateway;
2. back up the OpenClaw state directory using a method appropriate for your installation;
3. confirm there is sufficient free space for the state volume and temporary staging volume;
4. use the migration tooling provided by the installed OpenClaw version.

Current OpenClaw documentation distinguishes the session-SQLite modes as follows:

- `inspect`, `dry-run`, and `validate` are read-only;
- `import`, `compact`, `recover`, and `restore` are destructive maintenance modes and take the same state ownership lock used by Gateway startup;
- destructive modes must not race a running Gateway. Stop the Gateway first.

Upstream reference: <https://docs.openclaw.ai/cli/doctor>

## Target one agent at a time

Targeting the agent named by the current error preserves diagnostic clarity in a multi-agent installation.

### 1. Inspect

```bash
openclaw doctor --session-sqlite inspect --session-sqlite-agent <agent-id>
```

Review the number of targets, legacy entries, existing SQLite entries, unreferenced JSONL artifacts, and reported issues.

### 2. Dry run

```bash
openclaw doctor --session-sqlite dry-run --session-sqlite-agent <agent-id>
```

Check especially:

```text
legacyEntries
referencedTranscriptFiles
validatedEntries
validatedTranscriptEvents
issues
```

If issues are reported, investigate before importing.

### 3. Stop, back up, then import

If the Gateway is not already stopped, stop it using the service lifecycle appropriate for your installation before running `import`.

Confirm the backup before proceeding. Then:

```bash
openclaw doctor --session-sqlite import --session-sqlite-agent <agent-id>
```

Retain the migration run and manifest produced by your own installation, but do not publish their identifiers unless necessary and safe.

Evaluate imported entry/event counts and issue count, not merely the shell exit status.

If an explicit import fails after artifacts have moved, keep the Gateway stopped and follow the current Doctor recovery procedure rather than manually moving archived artifacts.

### 4. Validate

```bash
openclaw doctor --session-sqlite validate --session-sqlite-agent <agent-id>
```

After successful import, validation may report no remaining target if the legacy source has already been archived or removed from the active migration set. Interpret this together with the import output and migration manifest.

### 5. Restart only after maintenance is complete

When the required imports/validation are complete, restart the Gateway using the lifecycle supported by your installation and re-check deep status plus the fresh journal.

## Multi-agent environments

A gateway may reveal legacy stores sequentially. A conservative workflow is:

1. identify the agent named by the current migration error;
2. inspect and dry-run that target;
3. with the Gateway stopped and state backed up, import and validate the target;
4. restart/probe and inspect the fresh journal;
5. repeat for another agent only when supported by new inspection/error evidence.

If several targets are already known, the installed Doctor also supports all-agent selectors. This playbook favors targeted recovery when diagnosing a sequential startup failure because it keeps each state change attributable to one evidenced blocker.

## Unreferenced JSONL files

`inspect` or `dry-run` can report unreferenced `.jsonl` or `.trajectory.jsonl` artifacts. Do not manually delete them during initial recovery.

The supported import process may archive artifacts as part of migration. Preserve migration manifests and the pre-migration backup until the recovered system has been verified.

## Sanitized example result

Three agents were migrated with zero reported import issues:

| Agent | Entries | Events |
|---|---:|---:|
| `agent-primary` | 1 | 33 |
| `agent-secondary` | 1 | 35 |
| `agent-specialized` | 1 | 63 |

These labels are pseudonyms. The counts are incident-specific and are not values another installation should expect.
