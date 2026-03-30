# Cross-Boundary Contracts

Use this reference when one change can ripple into another repo, service, or runtime.

## Producer And Consumer Model

For every shared boundary, identify:

- which system produces the contract
- which system consumes it
- where the contract is validated
- where compatibility can silently drift

Do not treat request payloads, response shapes, schema fields, or env bindings as local-only details.

## Contract Checklist

Check whether the change affects:

- request fields and nullability
- response fields and error envelopes
- auth headers, tokens, or signatures
- route names or query params
- event names or message channels
- storage schema or durable-write format
- debug or metadata fields that downstream systems parse

If yes, inspect producer and consumer in the same turn.

## Example Contracts

### Example 1: Frontend Request To Backend Route

An anonymized request contract may include:

- request fields such as `items`, `mode`, and optional `metadata`
- nullability rules such as `mode` required and `metadata` optional
- auth in headers rather than body fields
- response fields that drive caller-side UI state
- metadata keys that the receiver stores, whitelists, or logs

In this shape, the caller may own form flow and mapping, but the backend route still owns validation, defaults, persistence, and compatibility rules.

### Example 2: Admin Bulk Action With Downstream Storage

An anonymized admin contract may include:

- bulk action payload fields such as `selectionIds`, `action`, and `actor`
- review-state transitions that other systems interpret later
- write-side schema constraints in the backing store
- exported status fields consumed by another dashboard or automation job

In this shape, the admin tool owns operator workflow, but the backend or store-owning system still owns write semantics and historical compatibility.

## Design Guidance

- Prefer additive changes over breaking renames.
- If a breaking change is required, decide on versioning, dual-read, or staged rollout before coding.
- Keep contract ownership explicit; do not hide producer rules inside caller-side mappers.
- Treat metadata as part of the contract when the receiver stores, whitelists, or depends on it.
- When producer and consumer rules conflict, prefer the system-of-record for shared contract behavior and escalate consumer-side breaking tradeoffs.

## Validation Guidance

When a contract changes:

1. Run the narrowest caller-side test.
2. Run the narrowest producer-side test.
3. Run repo-standard validation in both systems.
4. Run the strongest gate on the system that owns auth, persistence, or schema.

Do not claim cross-boundary safety if only one side was exercised.
