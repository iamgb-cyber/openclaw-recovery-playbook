# Contributing

Contributions are welcome when they improve the accuracy, safety, or reproducibility of OpenClaw recovery guidance.

## Good contributions

Examples include reproducible failure signatures and verified resolutions, corrections for newer releases, additional non-destructive diagnostic checks, documentation for another platform/service manager, and improved sanitization guidance.

## Incident reports

Where safe, include:

- OpenClaw version;
- operating system/service manager;
- exact **sanitized** error text;
- diagnostic command used;
- what was attempted;
- which action changed the failure state;
- final validation evidence.

Clearly distinguish observed facts from hypotheses.

## Privacy and safety requirements

Do not submit secrets, private session data, databases, pairing records, raw OpenClaw state directories, real internal agent IDs, private hostnames, organization/project identifiers, or unreviewed logs. Read [SECURITY.md](SECURITY.md) first.

Avoid destructive shortcuts such as deleting persistent state merely to bypass a startup check. When an official migration or repair command exists, prefer and document that path.

## Version awareness

OpenClaw evolves quickly. State the version for which a procedure was verified. A command that was correct for one release should not automatically be presented as universal.
