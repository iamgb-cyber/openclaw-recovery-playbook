# Safe Recovery Workflow

This workflow is the operational backbone of the playbook. It is designed to reduce accidental data loss, avoid speculative changes, and preserve evidence while recovering an OpenClaw Gateway.

The workflow is intentionally conservative:

```text
observe
  ↓
preserve evidence / back up state
  ↓
classify the current blocker
  ↓
make one justified change
  ↓
probe again
  ↓
read fresh evidence
  ↓
repeat only if a new blocker remains
```

## 1. Establish the current state

Start with read-only inspection whenever possible:

```bash
openclaw --version
openclaw gateway status --deep
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

If you are preparing output for public sharing, prefer the repository's privacy-first diagnostic collector:

```bash
bash scripts/diagnostics/openclaw-diagnostics.sh
```

Do not include higher-risk sections unless you actually need them.

## 2. Preserve the recoverable state

Before configuration changes, service reinstall work, session migration, or manual file quarantine, create and retain a backup of the relevant OpenClaw state.

A backup should be treated as a rollback asset, not as a substitute for understanding the problem.

Do not publish the backup. It may contain sessions, credentials, device information, agent metadata, or other sensitive material.

For destructive session-SQLite maintenance, also confirm sufficient free space before importing or rebuilding data.

## 3. Identify the exact current blocker

Classify what the latest evidence actually says.

Examples:

```text
ECONNREFUSED
AgentSelectionRequiredError
Plugin version drift
Legacy session store requires migration
start-limit-hit
```

Use [Known Failure Patterns](known-failure-patterns.md) to map the signature to the next safe inspection step.

Avoid reasoning such as:

```text
Gateway is down → reinstall everything
```

Prefer:

```text
Gateway is down
  ↓
what exact exception caused the latest start to fail?
```

## 4. Separate blockers from secondary symptoms

Several visible conditions are consequences rather than root causes.

Examples:

- `ECONNREFUSED` can simply mean the Gateway process never became ready.
- `start-limit-hit` means systemd stopped retrying; it does not explain the original crash.
- a new error after a repair may mean startup progressed farther.

Treat the first concrete startup exception as higher-value evidence than a generic connectivity symptom.

## 5. Make one justified change

A change should satisfy all three conditions:

1. the current evidence points to the component being changed;
2. the change is supported by the installed OpenClaw version/documentation or by a verified recovery path;
3. rollback/recovery artifacts are preserved when persistent state is involved.

Examples of properly scoped changes:

```text
stale user service evidenced
→ reinstall that Gateway service definition

specific official plugin drift evidenced
→ update that specific plugin

missing system-agent ownership evidenced
→ configure an existing appropriate agent as system owner

legacy session store explicitly reported
→ inspect/dry-run the affected target, then stop the Gateway before import
```

For session-SQLite maintenance, keep the read-only/destructive boundary explicit:

```text
read-only:   inspect · dry-run · validate
maintenance: import · compact · recover · restore
```

Current OpenClaw documentation states that destructive maintenance modes use the same state ownership lock as Gateway startup. Stop the Gateway before those operations; do not race them against a running service.

Do **not** combine unrelated changes simply to save time. That destroys diagnostic clarity.

## 6. Re-probe immediately

After the justified change — and after restarting the Gateway when offline maintenance was required — gather fresh evidence:

```bash
openclaw gateway status --deep
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

Compare the new result to the previous blocker.

Three outcomes are possible:

### A. Same blocker remains

The attempted change did not resolve the root cause or was incomplete. Do not stack another speculative fix. Reassess the evidence.

### B. New blocker appears

This can represent forward progress. Classify the new error independently and continue the workflow.

### C. Gateway reaches a healthy state

Proceed to post-recovery validation rather than assuming success from one successful command.

## 7. Validate recovery

At minimum confirm:

```text
expected CLI version
expected Gateway version
Runtime: running
Connectivity probe: ok
expected bind/port listening
```

Then verify that expected agents/plugins/state are still present and review a fresh journal for fatal startup/migration errors.

Use the [Post-Recovery Checklist](post-recovery-checklist.md).

## 8. Preserve recovery artifacts

Do not immediately delete:

- pre-change backups;
- session migration manifests;
- archived migration inputs;
- quarantined files;
- incident notes and sanitized evidence.

Retain them until the installation has remained stable long enough for you to be confident rollback is no longer needed.

## High-risk shortcuts to avoid

These are intentionally excluded from the recommended workflow:

```text
sudo chmod -R ...
chmod -R 777 ...
rm -rf ~/.openclaw/...
manual SQLite edits
renaming/deleting sessions.json to suppress migration errors
running destructive session maintenance against a live Gateway
removing configured agents to bypass owner resolution
resetting systemd repeatedly without fixing the crash
publishing raw logs/state files
```

The absence of an error message after deleting evidence is **not** proof of a successful recovery.

## Decision rule

When uncertain, prefer the action that preserves the most information while changing the least state.

```text
more evidence + less mutation
          >
less evidence + broader mutation
```

That principle is what makes this a recovery playbook rather than a collection of repair commands.
