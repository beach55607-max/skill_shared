# Architecture And Observability

Use this reference when the task may blur boundaries between systems or add noisy diagnostics.

## Boundary-First Architecture Principle

Prefer edits that reinforce existing ownership:

- backend owns validation, policy, and persistence
- frontend owns interaction flow and presentation
- admin tools own operator workflows
- automation owns scheduled or batch orchestration
- extensions own manifest, runtime, and message passing

Do not move policy or storage rules into the caller just because that seems faster.

## Observability Rules

Keep two layers of signal:

- normal operational logs for important business and runtime decisions
- debug-only logs for noisy internals that are useful during investigations

Normal logs should focus on:

- lifecycle stage
- route or workflow outcome
- correlation ID
- compact metadata that helps triage failures

Debug-only logs may include:

- branch diagnostics
- payload summaries
- intermediate state snapshots
- expensive internal traces

Avoid raw payload dumps unless there is an explicit opt-in path and a clear need.
