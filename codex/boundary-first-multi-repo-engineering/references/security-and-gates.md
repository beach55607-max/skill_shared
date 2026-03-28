# Security And Gates

Use this reference when a task touches auth, privileged flows, durable writes, or shared contracts.

## Core Security Rules

- Keep secrets in environment-backed configuration.
- Do not weaken auth to make local testing easier.
- Keep privileged operations behind the owning runtime.
- Treat headers, tokens, signatures, nonces, timestamps, permissions, and host access as protected surfaces.
- Do not log raw secrets, raw tokens, or unnecessary PII.

## Validation Depth

Raise validation depth when the task changes:

- auth
- signatures
- route dispatch
- storage schema
- privileged admin behavior
- browser permissions
- background message routing
- destructive or durable writes

When a repo exposes a strong gate, packaging check, or contract test, use it instead of stopping at lint alone.

## Logging Guidance

- Put lifecycle decisions, policy branches, and durable-write outcomes in normal logs.
- Put raw payload previews, large internals, and branch-heavy diagnostics behind debug-only output.
- Keep debug output easy to disable and absent from the default success path.

## Finish Criteria

Before closing a task, state:

- which auth, permission, or contract surfaces were touched
- which strong validation path ran
- what could not be validated locally
