# Contributing

Contributions are welcome when they improve the accuracy, safety, or reproducibility of OpenClaw recovery guidance.

## Good contributions

Examples include reproducible failure signatures and verified resolutions, corrections for newer releases, additional non-destructive diagnostic checks, documentation for another platform/service manager, and improved sanitization guidance.

## Incident reports

Use the repository's [privacy-safe incident template](.github/ISSUE_TEMPLATE/incident-report.md) when reporting a recovery case.

Where safe, include:

- OpenClaw version;
- operating system/service manager;
- exact **sanitized** error text;
- diagnostic command used;
- what changed immediately before the failure;
- what was attempted;
- which action changed the failure state;
- final validation evidence.

Clearly distinguish observed facts from hypotheses.

Prefer the smallest useful error excerpt over a complete raw log. If the report was produced with the diagnostic collector, state the collector version and manually review the report before publishing it.

## Privacy and safety requirements

Do not submit secrets, private session data, databases, pairing records, raw OpenClaw state directories, real internal agent IDs, private hostnames, organization/project identifiers, account/channel/binding names, migration manifests, backups, or unreviewed logs. Read [SECURITY.md](SECURITY.md) first.

Avoid destructive shortcuts such as deleting persistent state merely to bypass a startup check. When an official migration or repair command exists, prefer and document that path.

For Session SQLite maintenance, keep the distinction explicit:

- `inspect`, `dry-run`, and `validate` are read-only;
- destructive maintenance such as `import` must not race a running Gateway;
- stop the Gateway and verify a private backup before destructive maintenance.

## Version awareness

OpenClaw evolves quickly. State the version for which a procedure was verified. A command that was correct for one release should not automatically be presented as universal.

## Evidence quality

A useful contribution should make it possible to distinguish:

```text
symptom
  ↓
evidence
  ↓
justified change
  ↓
new evidence
  ↓
validated outcome
```

Avoid presenting correlation as root cause when the evidence does not support it.
