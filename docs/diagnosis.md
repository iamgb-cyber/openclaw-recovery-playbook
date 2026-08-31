# Diagnosis Workflow

This workflow minimizes destructive changes while determining why an OpenClaw gateway is not healthy.

## 1. Capture current state

```bash
openclaw --version
openclaw gateway status --deep
openclaw status
```

Record versions, runtime state, connectivity probe, bind mode, and port. A process shown as `running` is not sufficient by itself; connectivity should also succeed.

## 2. Inspect systemd

```bash
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

Look for the first concrete startup exception near the most recent start attempt.

If the service reaches `start-limit-hit`, fix the underlying error before resetting the failure counter:

```bash
systemctl --user reset-failed openclaw-gateway.service
```

## 3. Verify agents and plugins

```bash
openclaw agents list --bindings
openclaw plugins list
```

In multi-agent environments, pay attention to errors mentioning explicit ownership, fallback agent selection, ambient work, or `AgentSelectionRequiredError`.

## 4. Detect service/version drift

After an upgrade:

```bash
systemctl --user cat openclaw-gateway.service
```

If the installed user service is stale, consult current OpenClaw documentation. For the documented 2026.8.1 incident, the supported repair was:

```bash
openclaw gateway install --force
```

Do not bypass installer permission checks with broad `sudo` or recursive `chmod` operations.

## 5. Treat migration errors as migration errors

If the journal says:

```text
Legacy session store requires migration:
.../agents/<agent-id>/sessions/sessions.json
```

do not rename or delete `sessions.json` to hide the error. Use the supported workflow in [session-sqlite-migration.md](session-sqlite-migration.md).

## 6. Repeat after each fix

```text
observe
  ↓
backup / preserve evidence
  ↓
fix one evidenced blocker
  ↓
start or restart
  ↓
probe
  ↓
read fresh journal
  ↓
next blocker (if any)
```

One startup failure can mask another. A new error after a successful fix can mean initialization progressed further.

## Stop conditions

Consider the gateway recovered only when, at minimum:

- the service remains active;
- CLI and gateway versions are expected;
- the connectivity probe succeeds;
- the expected bind/port is listening;
- configured agents are still present;
- no new fatal migration/startup error appears in the fresh journal.
