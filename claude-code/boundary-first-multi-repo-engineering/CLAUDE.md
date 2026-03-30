# Boundary-First Multi-Repo Engineering

**Use when:** a task may touch more than one repo, service, runtime, or contract surface.
**Prevents:** changing the wrong repo, missing contract boundaries, skipping rollback design, validating the wrong side.
**Requires:** reading source and local rules before assuming implementation details.
**Produces:** explicit owner/consumer identification, risk-matched validation, reviewable close-out with mechanical evidence.

## Authority Order

1. Explicit user request
2. Repo-local instructions (`CLAUDE.md`, `AGENTS.md`, specs, guardrails)
3. Executable checks (tests, gates, builds, CI)
4. This workflow

If local rules conflict with this workflow, follow local rules and explain the conflict.

## Workflow Stages

```text
1. Classify    → What kind of change is this?
2. Decide      → How much ceremony? (D0-D3)
3. Plan        → Write implementation plan (D1+)
4. Execute     → Make changes, guided by adapter
5. Verify      → Run mechanical verification at matched depth
6. Close out   → Structured summary with evidence
```

## Step 0: Decision Gate

Decision Gate decides **how much ceremony is required**. Preflight (Step 1) decides **what risks and validations apply**.

Before preflight, classify the change severity. Read `references/decision-gate.md` for the full decision tree.

- **D0** (local, no protected surface): proceed directly to preflight.
- **D1** (single-repo protected surface): confirm assumption, owner, rollback stance. Then preflight.
- **D2** (cross-boundary contract): write decision note, producer/consumer impact, validation plan. Then preflight.
- **D3** (auth/signature, schema migration, destructive write, permissions): get user confirmation first. Maker-checker required at close-out.

For trivial edits with no protected surface (typo fixes, comment updates, formatting), D0 preflight is sufficient. Do not over-apply ceremony to changes that carry no boundary, contract, or security risk.

**No source guessing.** If source files, local rules, or nearest tests were not read, do not assume implementation details.

## Step 1: Preflight

Before planning or editing, complete this internally:

1. **Classify**: UI / API / auth / schema / automation / observability / extension-runtime / migration. If multiple apply, let the highest-risk class drive validation depth.
2. **Owner**: Which repo or runtime owns this? Which consumes it? What boundary is crossed? Do not start editing until owner and consumer are explicit.
3. **Contract**: Does this change request/response shapes, auth headers, schema fields, env bindings, storage keys, or message formats? If yes, inspect both producer and consumer.
4. **Security**: Does this touch auth, signatures, secrets, durable writes, permissions, or host access? If yes, treat as high risk.
5. **State**: Does this change durable state (database, key-value, spreadsheets, browser storage, config)? If yes, identify rollback path before coding. **Rollback is mandatory for durable changes — no rollback stance means no close-out.**
6. **Observability**: What belongs in normal logs vs debug-only? How are correlation IDs preserved? Do not add noisy diagnostics without a toggle strategy.
7. **Validation**: Narrowest direct test > repo-standard lint/test > strong gate or build > cross-system validation. If the repo has a real gate, prefer it over ad-hoc spot checks. Read `references/mechanical-verification.md` for the depth ladder and gate guidance.
8. **Stop conditions**: Pause and escalate on auth/signature changes, destructive write flows, schema migrations, permission changes, new host access, file deletes/moves/broad overwrites without explicit request, or high-risk writes without executable verification.

## Step 2: Adapter Selection

Read `references/owner-selection.md` to identify the owner system, then load the matching adapter:

- Backend service: `references/adapters/backend-service.md`
- Frontend app: `references/adapters/frontend-app.md`
- Admin console: `references/adapters/admin-console.md`
- Automation bot or sync worker: `references/adapters/automation-bot.md`
- Browser extension: `references/adapters/browser-extension.md`

If no adapter matches, read `references/fallback-adapter.md`.
If the task spans multiple systems, also read `references/cross-boundary-contracts.md` and `references/conflict-resolution.md`.

## Hard Rules

- Put boundaries before implementation.
- Treat auth, routes, schemas, env bindings, storage keys, permissions, and message formats as protected surfaces.
- Keep default logs lean and operational; gate noisy diagnostics behind explicit debug-only paths.
- Prefer the strongest repo-defined verification path over shallow spot checks.
- **Cross-boundary safety requires both sides.** If a shared contract changes and only one side was validated, the task is not complete.
- **Rollback is mandatory for durable changes.** No rollback/fallback/blast-radius control = no close-out.
- **File safety.** Do not delete, move, rename, or broadly overwrite files just to reduce complexity or silence failing paths. Read repo-local instructions (`CLAUDE.md`, `AGENTS.md`, or equivalent) before cleanup or broad rewrites. Treat file deletes, broad moves, and overwrite-heavy rewrites as stop conditions requiring explicit user request.
- Do not pretend caller-side validation is enough when a producer or shared contract also changes.

## Step 3: Close-Out

Use this template:

```markdown
Decision level: D0 / D1 / D2 / D3
Owner: [repo or runtime and layer]
Consumer: [repo, caller, or downstream system affected]
Surfaces touched: [contract / auth / schema / storage / permission]
Validation run: [commands executed and results]
Validation skipped: [commands not run and why]
Rollback stance: [rollback path, fallback, or blast-radius control]
Maker-checker evidence: [n/a for D0/D1, or user confirmation / second review / waiver]
Residual risk: [unknowns or items that need future attention]
```

For D2/D3: confirm that both sides were validated and that maker-checker review was completed or escalated.

If a stop-condition surface was touched and executable verification is unavailable, call that out explicitly.

## References

- `references/decision-gate.md` -- D0-D3 severity classification
- `references/implementation-plan-template.md` -- required plan format for D1/D2/D3
- `references/constitution.md` -- authority order and protected surfaces (SSOT)
- `references/owner-selection.md` -- decision tree for identifying the owner
- `references/cross-boundary-contracts.md` -- producer/consumer model with examples
- `references/mechanical-verification.md` -- gates, guards, GT, contract tests, and verification depth ladder
- `references/security-and-gates.md` -- security rules and validation depth
- `references/architecture-and-observability.md` -- boundary architecture and logging
- `references/validation-matrix.md` -- validation commands by adapter type
- `references/fallback-adapter.md` -- when no standard adapter matches
- `references/conflict-resolution.md` -- resolving multi-repo rule conflicts
