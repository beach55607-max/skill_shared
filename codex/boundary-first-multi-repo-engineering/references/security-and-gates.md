# Security And Gates

Use this reference when a task touches auth, privileged flows, durable writes, or shared contracts.

## Core Security Rules

- Keep secrets in environment-backed configuration.
- Do not weaken auth to make local testing easier.
- Keep privileged operations behind the owning runtime.
- Treat headers, tokens, signatures, nonces, timestamps, permissions, and host access as protected surfaces.
- Do not log raw secrets, raw tokens, or unnecessary PII.
- Read repo-local `AGENTS.md`, task rules, or generation docs before cleanup or broad rewrites.
- Do not delete, move, rename, or broadly overwrite files simply to reduce complexity or silence failing paths.

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

If a shared contract changed and only one side was validated, report the result as partial or blocked, not as passed.

## Logging Guidance

- Put lifecycle decisions, policy branches, and durable-write outcomes in normal logs.
- Put raw payload previews, large internals, and branch-heavy diagnostics behind debug-only output.
- Keep debug output easy to disable and absent from the default success path.

## Finish Criteria

Before closing a task, state:

- the decision level when the task is more than local implementation
- which auth, permission, or contract surfaces were touched
- which strong validation path ran
- what could not be validated locally
- what rollback or blast-radius stance applies if durable state was affected
- what maker-checker evidence applies for D2/D3 work
