---
name: boundary-first-multi-repo-engineering
description: Boundary-first workflow for multi-repo coding, review, debugging, and automation work. Use when Codex needs to identify the true owner repo or runtime, map contract and security surfaces before editing, coordinate producer and consumer changes across frontend/backend/admin/automation/extension systems, and choose validation depth that matches risk instead of stopping at lint alone.
---

# Boundary-First Multi-Repo Engineering

## Overview

Use this skill for engineering tasks where the request may touch more than one repo, service, runtime, or contract surface.
Start by identifying the owner boundary, then map contract, security, state, observability, and validation requirements before making changes.

Read [constitution.md](./references/constitution.md) first.

## Mandatory Preflight

Before planning or editing:

1. Run the decision gate.
2. If the task is D1, D2, or D3, state the minimum implementation plan before coding.
3. Then complete this preflight internally.

Use:

- [decision-gate.md](./references/decision-gate.md)
- [implementation-plan-template.md](./references/implementation-plan-template.md)
- [preflight-protocol.md](./references/preflight-protocol.md)

The preflight itself remains:

1. Classify the change.
2. Identify the owner repo or runtime and the consumer.
3. Check contract surfaces.
4. Check security and permission surfaces.
5. Check durable state and rollback risk.
6. Design observability and debug behavior.
7. Map the required validation depth.
8. Pause on stop conditions that need escalation.

For high-risk changes such as auth, schema, destructive writes, permissions, or cross-boundary contract work, do not skip the decision gate or plan step just because the user asked for code quickly.

## Adapter Selection

After preflight, load the narrowest adapter that matches the owner surface.

Use [owner-selection.md](./references/owner-selection.md) first, then pick one adapter:

- backend service: [backend-service.md](./references/adapters/backend-service.md)
- frontend app: [frontend-app.md](./references/adapters/frontend-app.md)
- admin console: [admin-console.md](./references/adapters/admin-console.md)
- automation bot or sync worker: [automation-bot.md](./references/adapters/automation-bot.md)
- browser extension: [browser-extension.md](./references/adapters/browser-extension.md)

If the task spans multiple systems, read [cross-boundary-contracts.md](./references/cross-boundary-contracts.md) after owner selection.
If multiple systems have conflicting local rules, rollout constraints, or validation expectations, read [conflict-resolution.md](./references/conflict-resolution.md).
If no adapter matches cleanly, apply the preflight protocol directly, state the assumed system type, and prefer the system that owns validation, persistence, auth, or runtime policy.
Treat repeated no-match cases as a signal to create a new adapter later, not as a reason to skip boundary analysis now.

## Core Non-Negotiables

- Put boundaries before implementation.
- Treat repo-local `AGENTS.md`, task specs, and guardrails as higher authority than this skill.
- If source files, local rules, or the nearest tests were not read, do not assume implementation details.
- Treat auth, routes, schemas, env bindings, storage keys, permissions, and message formats as protected surfaces.
- Do not delete, move, rename, or broadly overwrite user files just to make the task easier.
- Keep default logs lean and operational; gate noisy diagnostics behind explicit debug-only paths.
- Prefer the strongest repo-defined verification path over shallow spot checks.
- Do not pretend caller-side validation is enough when a producer or shared contract also changes.
- Treat durable state changes as incomplete until rollback, fallback, or blast-radius stance is explicit.
- If a shared contract changes and only one side was validated, the task is partial or blocked, not passed.
- D2 and D3 work require maker-checker evidence or explicit user confirmation before close-out.

For deeper guidance, read:

- [security-and-gates.md](./references/security-and-gates.md)
- [architecture-and-observability.md](./references/architecture-and-observability.md)
- [validation-matrix.md](./references/validation-matrix.md)

## Close-Out

Before finishing, make the outcome reviewable.

State clearly:

- decision level
- owner repo or runtime and consumer surface
- contract, auth, schema, storage, or permission surfaces touched
- validation run, skipped, or blocked
- rollback or compatibility risks that remain
- maker-checker evidence when the task is D2 or D3

Use this template when helpful:

- Decision level:
- Owner:
- Consumer:
- Touched surfaces:
- Validation run:
- Validation skipped or blocked:
- Rollback or compatibility risk:
- Maker-checker evidence:
- Residual unknowns:

If the task touches a stop-condition surface and executable verification is unavailable, call that out explicitly instead of treating the skill alone as sufficient evidence.
