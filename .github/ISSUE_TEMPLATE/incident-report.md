---
name: OpenClaw recovery incident
description: Report a reproducible OpenClaw Gateway failure or recovery pattern using sanitized evidence
title: "[Incident] "
labels: []
assignees: []
---

# Privacy check first

Before submitting, confirm all of the following:

- [ ] I removed API keys, access tokens, passwords, cookies, authorization headers, and other secrets.
- [ ] I removed or generalized local usernames, hostnames, IP addresses, internal agent/workspace names, organization/customer/project names, account/channel/binding names, session IDs, UUIDs, and migration-run identifiers unless they are essential and intentionally disclosed.
- [ ] I am **not** uploading raw OpenClaw state directories, SQLite databases, session stores, pairing data, private transcripts, backups, `.env` files, private keys, or unreviewed full logs.
- [ ] I manually reviewed any output produced by the diagnostic collector. I understand that automated sanitization is best-effort.

If you cannot safely sanitize the evidence, do not publish it in a public issue.

# Summary

Briefly describe what stopped working and when the problem became visible.

<!-- Example: Gateway stopped becoming ready after an OpenClaw upgrade. -->

# Environment

**OpenClaw CLI version:**  
**OpenClaw Gateway version (if available):**  
**Operating system:**  
**Service manager / launch method:**  
**Single-agent or multi-agent:**  
**Gateway bind/port (generalize if sensitive):**  

Do not include private hostnames or infrastructure names.

# Exact sanitized failure signature

Paste the smallest useful error excerpt.

```text
<sanitized error here>
```

Prefer the exact technical signature over a long raw log.

# How the evidence was collected

List the diagnostic commands used.

```bash
# example
openclaw --version
openclaw gateway status --deep
```

If you used the repository collector, include its version:

```text
Collector version: <version>
```

# What changed immediately before the failure?

Examples: OpenClaw upgrade, plugin update, configuration change, host reboot, session migration, service reinstall, or unknown.

# Diagnostic observations

Separate observations from hypotheses.

## Observed

- 

## Hypotheses / not yet proven

- 

# Recovery attempts

For each meaningful attempt, state:

1. what evidence justified the change;
2. what command/action was performed;
3. what changed afterward.

Do not list unrelated speculative changes as one step.

## Attempt 1

**Evidence:**  
**Action:**  
**Result / new evidence:**  

## Attempt 2 (if needed)

**Evidence:**  
**Action:**  
**Result / new evidence:**  

# Session SQLite maintenance (only if relevant)

- [ ] Not applicable.
- [ ] `inspect` / `dry-run` evidence was reviewed before import.
- [ ] Gateway was stopped before destructive Session SQLite maintenance.
- [ ] A private backup existed before destructive maintenance.
- [ ] Import/validation issue counts were reviewed.
- [ ] Migration manifests/backups were retained privately.

Do not upload the database, raw session files, migration manifests, or private backups.

# Final state

If recovered, provide sanitized validation evidence such as:

```text
Runtime: running
Connectivity probe: ok
Listening: loopback:<gateway-port>
```

Also state whether the expected agents/plugins/data remained present.

# Reproducibility / scope

Does this appear specific to one installation, or can you reproduce it in another environment? State what is actually known.

# Upstream references

Link any relevant OpenClaw documentation, issue, release note, or other authoritative reference used to justify the recovery step.

# Additional sanitized context

Only include information necessary to understand or reproduce the failure.
