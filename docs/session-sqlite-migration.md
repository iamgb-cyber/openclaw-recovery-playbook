# Legacy Session Store → SQLite Migration

OpenClaw 2026.8.1 can refuse gateway readiness when an agent still has a legacy session store that requires migration.

Representative sanitized error:

```text
Legacy session store requires migration:
.../agents/<agent-id>/sessions/sessions.json
```

## Safety rule

**Do not delete, truncate, or manually rewrite the legacy store to bypass startup.**

Back up OpenClaw state first and use the migration tooling provided by the installed OpenClaw version.

## Target one agent at a time

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

### 3. Import

```bash
openclaw doctor --session-sqlite import --session-sqlite-agent <agent-id>
```

Retain the migration run and manifest produced by your own installation, but do not publish their identifiers unless necessary and safe.

Evaluate imported entry/event counts and issue count, not merely the shell exit status.

### 4. Validate

```bash
openclaw doctor --session-sqlite validate --session-sqlite-agent <agent-id>
```

After successful import, validation may report no remaining target if the legacy source has already been archived or removed from the active migration set. Interpret this together with the import output and migration manifest.

## Multi-agent environments

A gateway may reveal legacy stores sequentially. A conservative workflow is:

1. migrate the agent named by the current error;
2. retry startup;
3. inspect the fresh journal;
4. migrate another agent only when supported by inspection/error evidence.

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
