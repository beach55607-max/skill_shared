# Architecture And Observability

Use this reference when the task may blur boundaries between systems or add noisy diagnostics.

## Boundary-First Architecture Principle

Each adapter defines its own ownership scope. The key rule: do not move policy or storage rules into the caller just because that seems faster.

- Backend owns validation, policy, and persistence.
- Frontend owns interaction flow and presentation.
- Admin tools own operator workflows.
- Automation owns scheduled or batch orchestration.
- Extensions own manifest, runtime, and message passing.

## Observability Rules

Keep two layers of signal:

### Normal Operational Logs

- lifecycle stage
- route or workflow outcome
- correlation ID
- compact metadata that helps triage failures

### Debug-Only Logs

- branch diagnostics
- payload summaries
- intermediate state snapshots
- expensive internal traces

Avoid raw payload dumps unless there is an explicit opt-in path and a clear need.

Do not add noisy diagnostics without a toggle strategy. Debug output should be off by default and easy to enable only when needed.
