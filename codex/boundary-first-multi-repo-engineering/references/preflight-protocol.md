# Preflight Protocol

Run this protocol internally before substantial coding, debugging, or automation work.

## 0. Decision Gate

Before the numbered checks below, classify the task as D0, D1, D2, or D3.

Use:

- `decision-gate.md`

If the task is D1, D2, or D3, state the minimum implementation plan before editing.
Use:

- `implementation-plan-template.md`

## 1. Change Class

Classify the task into one or more:

- UI
- API
- auth
- schema
- automation
- observability
- extension-runtime
- migration

If more than one applies, let the highest-risk class drive validation depth.

If the task touches auth, schema, permissions, destructive writes, or cross-boundary contracts, write down:

- current assumption
- owner
- rollback stance
- validation plan

Do this before editing.

## 2. Owner And Boundary

Determine:

- owner repo or service
- owner layer or runtime
- consumer repo, caller, or downstream system
- contract boundary crossed

Do not start editing until owner and consumer are explicit.

## 3. Contract Surface

Check whether the task changes:

- request shape
- response shape
- error shape
- auth headers or tokens
- schema fields or nullability
- env bindings
- storage keys
- message passing formats

If yes, inspect both producer and consumer paths.

## 4. Security Surface

Check whether the task touches:

- auth
- signatures or canonical strings
- secrets
- durable writes
- permissions
- host access
- privileged admin flows

If yes, treat the task as high risk.

## 5. State And Rollback

Check whether the task changes durable state:

- database rows
- key-value storage
- spreadsheets or documents
- browser storage
- persisted config

If yes, identify rollback, fallback, or blast-radius controls before coding.

## 6. Observability Design

Decide:

- what belongs in normal operational logs
- what belongs in debug-only output
- how correlation IDs are preserved
- how verbose diagnostics stay off by default

Do not add noisy diagnostics without a toggle strategy.

## 7. Validation Mapping

Choose:

- the narrowest direct test
- repo-standard lint and test commands
- stronger build, gate, packaging, or integration verification
- cross-system validation when a contract changes

If the repo has a real gate, prefer it over ad-hoc spot checks.

## 8. Stop Conditions

Pause and escalate or explicitly confirm assumptions when the task includes:

- auth or signature changes
- destructive write flows
- file deletes, broad moves, or overwrite-heavy rewrites without explicit request and rollback
- schema migrations
- permission changes
- new host access
- high-risk writes without executable verification
