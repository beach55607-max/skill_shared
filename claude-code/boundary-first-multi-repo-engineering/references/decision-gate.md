# Decision Gate

Use this reference before preflight to classify the change severity and determine the required level of ceremony.

## Severity Levels

### D0 — Local Implementation

The change is confined to a single repo, does not touch any protected surface (see `constitution.md`), and has no cross-boundary impact.

- No contract, auth, schema, or durable state changes.
- Proceed directly to preflight.
- Standard repo lint and test are sufficient.

### D1 — Single-Repo Protected Surface

The change touches a protected surface within one repo but does not cross a contract boundary.

Examples: adding a route, changing a storage key, modifying auth logic within the owning system.

Before preflight, confirm:

- Assumption: what behavior is expected to change.
- Owner: which system and layer.
- Rollback stance: what happens if this needs to be reverted.

### D2 — Cross-Boundary Contract Change

The change affects a shared contract between two or more systems.

Examples: request/response shape change, auth header format change, schema field rename consumed by another system, new event type on a shared channel.

Before preflight, confirm:

- Decision note: why this change is needed and what alternatives were considered.
- Producer and consumer impact: which systems break if the contract changes.
- Validation plan: how both sides will be verified.
- Rollback stance: whether a staged rollout or dual-format transition is needed.

### D3 — High-Risk Governance Change

The change involves auth/signature behavior, schema migration, destructive writes, permission model changes, or infrastructure that affects multiple systems.

Examples: HMAC canonical format change, database migration, new extension permissions, bulk delete operation, guard script modification.

Before preflight, confirm everything from D2, plus:

- Explicit user confirmation before implementation begins.
- Maker-checker: require a second-pass review or explicit escalation before close-out.
- Blast radius assessment: how many systems, users, or data records are affected.

## Decision Flow

```
Is a protected surface touched?
  NO  -> D0. Proceed to preflight.
  YES -> Does it cross a contract boundary?
    NO  -> D1. Confirm assumption, owner, rollback. Then preflight.
    YES -> Does it involve auth, schema migration, destructive writes, or permissions?
      NO  -> D2. Write decision note and validation plan. Then preflight.
      YES -> D3. Get user confirmation. Write decision note. Then preflight.
```

## Implementation Plan

For D1/D2/D3 tasks, use the template in `implementation-plan-template.md` to document assumption, owner, contract/security surfaces, validation plan, and rollback stance before coding.

## Rules

- **No source guessing.** If source files, local rules, or nearest tests were not read, do not assume implementation details. Read first, then classify.
- **Rollback is mandatory for durable changes.** Any change to durable state (database, key-value, storage, spreadsheets) that does not state a rollback path, fallback, or blast-radius control cannot be closed out.
- **Cross-boundary safety requires both sides.** If a shared contract changes and only one side was validated, the task is not complete. This is a hard rule, not a suggestion.
- **D2/D3 require maker-checker.** If the task touches protected surfaces at D2 or D3 level, require a second-pass review or explicit user confirmation before marking as done. Minimum evidence for maker-checker: (a) user explicitly confirmed the approach before implementation, or (b) a second review pass was requested and the user approved, or (c) the user explicitly waived review. State which evidence applies in close-out.
