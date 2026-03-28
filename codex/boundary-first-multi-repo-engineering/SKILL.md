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

Before planning or editing, complete this preflight internally:

1. Classify the change.
2. Identify the owner repo or runtime and the consumer.
3. Check contract surfaces.
4. Check security and permission surfaces.
5. Check durable state and rollback risk.
6. Design observability and debug behavior.
7. Map the required validation depth.
8. Pause on stop conditions that need escalation.

Read [preflight-protocol.md](./references/preflight-protocol.md) for the detailed sequence.

## Adapter Selection

After preflight, load the narrowest adapter that matches the owner surface.

Use [owner-selection.md](./references/owner-selection.md) first, then pick one adapter:

- backend service: [backend-service.md](./references/adapters/backend-service.md)
- frontend app: [frontend-app.md](./references/adapters/frontend-app.md)
- admin console: [admin-console.md](./references/adapters/admin-console.md)
- automation bot or sync worker: [automation-bot.md](./references/adapters/automation-bot.md)
- browser extension: [browser-extension.md](./references/adapters/browser-extension.md)

If the task spans multiple systems, read [cross-boundary-contracts.md](./references/cross-boundary-contracts.md) after owner selection.
If no adapter matches cleanly, apply the preflight protocol directly, state the assumed system type, and prefer the system that owns validation, persistence, auth, or runtime policy.
Treat repeated no-match cases as a signal to create a new adapter later, not as a reason to skip boundary analysis now.

## Core Non-Negotiables

- Put boundaries before implementation.
- Treat auth, routes, schemas, env bindings, storage keys, permissions, and message formats as protected surfaces.
- Keep default logs lean and operational; gate noisy diagnostics behind explicit debug-only paths.
- Prefer the strongest repo-defined verification path over shallow spot checks.
- Do not pretend caller-side validation is enough when a producer or shared contract also changes.

For deeper guidance, read:

- [security-and-gates.md](./references/security-and-gates.md)
- [architecture-and-observability.md](./references/architecture-and-observability.md)
- [validation-matrix.md](./references/validation-matrix.md)

## Close-Out

Before finishing, make the outcome reviewable.

State clearly:

- owner repo or runtime and consumer surface
- contract, auth, schema, storage, or permission surfaces touched
- validation run, skipped, or blocked
- rollback or compatibility risks that remain

If the task touches a stop-condition surface and executable verification is unavailable, call that out explicitly instead of treating the skill alone as sufficient evidence.
