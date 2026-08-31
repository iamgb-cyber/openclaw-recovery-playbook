# Sanitized Error Examples

These examples preserve useful search terms and failure signatures while removing environment-specific identifiers. They are intended for troubleshooting, documentation, issue references, and searchability.

> **Important:** These examples are not complete logs. They are deliberately reduced to the minimum context needed to recognize a failure pattern.

## Gateway connection failure

```text
Connectivity probe: failed
Error: connect ECONNREFUSED 127.0.0.1:<gateway-port>
```

Interpretation: the expected Gateway connection is unavailable. This is a symptom, not a root-cause diagnosis.

Related guide: [Known Failure Patterns — Gateway connection refused](../../docs/known-failure-patterns.md#pattern-1--gateway-connection-refused)

---

## Multi-agent ownership ambiguity

```text
Failed detecting Codex app-server thread bindings:
AgentSelectionRequiredError: Multiple agents are configured, but session agent resolution has no explicit owner. Pass an agentId, an agent-scoped session key, or a prepared fallbackAgentId.
OpenClaw startup migrations did not complete cleanly; refusing to report the gateway ready.
```

Interpretation: a startup path that needs agent ownership cannot resolve an explicit owner in the current multi-agent configuration.

What was removed from the public example: local agent IDs, user paths, session identifiers, and surrounding environment-specific log metadata.

Related guide: [Known Failure Patterns — Multi-agent owner ambiguity](../../docs/known-failure-patterns.md#pattern-2--multi-agent-owner-ambiguity)

---

## Stale Gateway service after an upgrade

Representative diagnostic comparison:

```text
CLI version:     <new-version>
Gateway service: <older-installation-or-version>
```

Interpretation: the interactive CLI and managed Gateway service may refer to different installation generations after an upgrade.

Related guide: [Known Failure Patterns — Stale Gateway service after an upgrade](../../docs/known-failure-patterns.md#pattern-3--stale-gateway-service-after-an-upgrade)

---

## Unsafe service permissions

Representative form:

```text
Gateway service installation refused because the user service path has unsafe write permissions.
```

Interpretation: the installer is refusing to manage a service definition whose write permissions are broader than expected.

The exact path and local username are intentionally omitted here.

Related guide: [Known Failure Patterns — Gateway installer refuses unsafe permissions](../../docs/known-failure-patterns.md#pattern-4--gateway-installer-refuses-unsafe-permissions)

---

## Official plugin version drift

```text
Plugin version drift: 1 active official plugin not on gateway <gateway-version>
- <official-plugin>: <installed-version> -> expected <gateway-version>
```

Interpretation: one active official plugin does not match the Gateway release expected by the installed OpenClaw version.

Do not replace `<official-plugin>` with a private/custom plugin name in a public report unless disclosure is intentional.

Related guide: [Known Failure Patterns — Official plugin version drift](../../docs/known-failure-patterns.md#pattern-5--official-plugin-version-drift)

---

## Legacy session store migration required

```text
Gateway failed to start: Legacy session store requires migration:
~/.openclaw/agents/<agent-id>/sessions/sessions.json
Run the supported OpenClaw doctor/session migration workflow before retrying startup.
```

Interpretation: the legacy session source still needs migration into the supported runtime store.

Related guides:

- [Known Failure Patterns — Legacy session store requires migration](../../docs/known-failure-patterns.md#pattern-6--legacy-session-store-requires-migration)
- [Legacy Session Store → SQLite Migration](../../docs/session-sqlite-migration.md)

---

## Session SQLite inspect result

```text
session-sqlite inspect: 1 target(s), 1 legacy entries, 0 sqlite entries, 0 issue(s)
- <agent-id>: unreferenced-jsonl=<count>
```

Interpretation: a legacy source is present and inspection found no reported migration issues at that stage.

The count of unreferenced artifacts is environment-specific and is generalized here.

---

## Session SQLite dry-run result

```text
legacyEntries: 1
referencedTranscriptFiles: 1
sqliteEntries: 0
validatedEntries: 1
validatedTranscriptEvents: <event-count>
issues: []
```

Interpretation: the dry run recognized and validated the candidate data without reporting issues. It is still not permission to skip backup or validation.

---

## Session SQLite import result

```text
session-sqlite import: 1 target(s), 1 legacy entries, 1 sqlite entries, 0 issue(s)
- migration-run=<migration-run-id>
- manifest=~/.openclaw/session-sqlite-migration-runs/<manifest>.json
- <agent-id>: imported=1/<event-count> events, archived-unreferenced-jsonl=<count>, unreferenced-jsonl=0
```

Interpretation: the targeted import completed with zero reported issues and produced recovery/migration artifacts that should be retained.

Public examples should not expose the real migration-run ID, manifest filename, agent ID, or private user path.

---

## systemd start limit reached

```text
Result: start-limit-hit
```

or equivalent systemd state indicating repeated rapid failures have exhausted restart attempts.

Interpretation: systemd has stopped retrying. The underlying Gateway startup exception must still be found and fixed.

Related guide: [Known Failure Patterns — systemd start-limit-hit](../../docs/known-failure-patterns.md#pattern-7--systemd-start-limit-hit)

---

## Healthy post-recovery state

```text
Runtime: running
Connectivity probe: ok
Listening: 127.0.0.1:<gateway-port>
NRestarts=0
ExecMainStatus=0
```

Interpretation: these are strong health indicators, but a complete recovery check should also verify versions, expected state, and the fresh journal.

## Sanitization checklist

Before turning a real error into a public example, remove or generalize at least:

- local usernames and home directory names;
- hostnames;
- private/public IP addresses that are not essential;
- IPv6 addresses;
- internal agent IDs and workspace names;
- session IDs and UUIDs;
- migration-run IDs and manifests;
- account/channel/binding names;
- API keys, tokens, passwords, cookies, authorization headers;
- organization, customer, infrastructure, and project names that are not necessary to reproduce the issue;
- private/custom plugin names when disclosure is not intentional;
- raw transcripts and conversation data.

Preserve the **error signature and technical meaning**, not the identity of the installation that produced it.
