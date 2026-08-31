# systemd User-Service Recovery

## Inspect the service

```bash
systemctl --user status openclaw-gateway.service --no-pager
systemctl --user cat openclaw-gateway.service
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

Compare service metadata/command with the intended OpenClaw installation.

## Stale service after upgrade

In the documented incident, the service definition reflected an older release after the package had been upgraded. For the tested release, the supported reinstall command was:

```bash
openclaw gateway install --force
```

Always verify this against documentation for your installed version.

## Unsafe permissions

The installer refused to proceed while user systemd paths were group/other-writable. The repair was deliberately narrow:

```bash
chmod go-w ~/.config/systemd ~/.config/systemd/user
chmod go-w ~/.config/systemd/user/openclaw-gateway.service
```

If another specific service file is reported, correct that file individually rather than applying recursive permission changes.

### Avoid broad operations

```bash
sudo chmod -R ...
chmod -R 755 ~/.config
sudo chown -R ...
```

These can alter unrelated application state and make diagnosis harder.

## start-limit-hit

Repeated startup failures can trigger systemd's rate limiter. This is normally a consequence of the underlying gateway failure rather than the primary OpenClaw problem.

After fixing the evidenced startup blocker:

```bash
systemctl --user reset-failed openclaw-gateway.service
openclaw gateway start
openclaw gateway status --deep
```

## Runtime versus connectivity

Do not treat `Runtime: running` alone as proof of recovery. Confirm the connectivity probe and inspect fresh logs if it fails.

A sanitized healthy pattern is:

```text
Runtime: running
Connectivity probe: ok
Listening: loopback:<gateway-port>
```
