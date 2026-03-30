# Constitution

This is the single source of truth for authority order and protected surfaces. Other files reference this document instead of repeating these lists.

## Purpose

This workflow improves engineering judgment for multi-repo and multi-runtime work. It tightens boundary reasoning without overriding repo-local truth.

## Order Of Authority

1. Explicit user request
2. Repo-local instructions (`CLAUDE.md`, `AGENTS.md`, specs, guardrails)
3. Executable checks (tests, gates, builds, CI definitions)
4. This workflow and its references

If local rules conflict with this workflow, follow the local rules and explain the conflict.

## Boundary-First Principle

Before editing, identify:

- the system of record
- the caller or consumer
- the contract boundary between them
- the high-risk surfaces affected by the change

Do not start implementation while the owner boundary is still implicit.

## Protected Surfaces

Treat the following as design-time boundaries:

- auth or signature behavior
- route names and request or response shapes
- schema fields and null semantics
- env bindings and feature flags
- storage keys and durable writes
- permissions, host access, or message channels
- observability fields that downstream systems rely on
- file deletes, broad moves, rename-heavy cleanup, and overwrite-heavy rewrites that change user-owned files or repo structure

## Hard Rules

- **No source guessing.** If source files, local rules, or nearest tests were not read, do not assume implementation details. Read first, then act.
- **File safety.** Do not delete, move, rename, or broadly overwrite files simply to reduce complexity or silence failing paths. Read repo-local instructions before cleanup or broad rewrites.
- **Rollback is mandatory for durable changes.** Any change to durable state that does not state a rollback path, fallback, or blast-radius control cannot be closed out.
- **Cross-boundary safety requires both sides.** If a shared contract changes and only one side was validated, the task is not complete.
- **D2/D3 require maker-checker.** If the task touches protected surfaces at cross-boundary or high-risk level, require a second-pass review or explicit user confirmation before marking as done.

## Finish Criteria

A task is not done just because code compiles. Finish only when owner, risk surface, validation evidence, and residual risk are clear enough for another engineer to review quickly.
