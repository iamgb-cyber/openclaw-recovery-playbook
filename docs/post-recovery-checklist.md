# Post-Recovery Checklist

Use this after the gateway appears healthy.

## Core health

- [ ] CLI reports the expected release.
- [ ] Deep status reports the expected gateway version.
- [ ] Runtime remains `running`.
- [ ] Connectivity probe reports `ok`.
- [ ] Expected bind mode and port are listening.
- [ ] Dashboard/client access works from the intended location.

## Agents and plugins

- [ ] Expected agents are present.
- [ ] Agent workspaces/directories resolve correctly.
- [ ] Official plugins do not show version drift.
- [ ] Multi-agent system/ambient owner configuration is intentional.

```bash
openclaw agents list --bindings
openclaw plugins list
```

## Sessions and migrations

- [ ] Required legacy stores were migrated using supported tooling.
- [ ] Migration commands reported no unresolved issues.
- [ ] Migration manifests were retained privately.
- [ ] Pre-migration backup still exists.
- [ ] No manual cleanup of archived/unreferenced session artifacts is performed until stability is established.

## systemd

- [ ] User service is enabled if desired.
- [ ] Service definition points to the intended OpenClaw installation.
- [ ] No `start-limit-hit` remains.
- [ ] Fresh journal contains no repeating fatal startup exception.

```bash
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

## Cleanup policy

Do not immediately delete recovery backups, quarantine directories, old service backups, or migration manifests.

Retain them until the gateway has remained stable, agents work normally, expected data is accessible, and a separate backup policy covers the recovered state.
