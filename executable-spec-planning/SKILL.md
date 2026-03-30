---
name: executable-spec-planning
description: "Use this skill whenever a task requires producing an implementation spec, migration plan, feature build plan, or any deliverable that will be handed to an AI agent or human developer for execution. Triggers: 'write a spec', 'plan the migration', 'design the architecture', 'create a blueprint', any task involving new data fields, new API endpoints, new UI output, cross-module refactoring, permission/security changes, or keywords like 'CONTRACT', 'INPUT_CONTRACT', 'APPROVAL_CHECKLIST', 'Gate', 'Decision Lock'. Do NOT trigger for simple bug fixes with no architectural impact, README edits, or infrastructure console operations."
---

# Executable Spec Planning — Skill Pack

## Purpose

This skill encodes a proven workflow for going from a fuzzy requirement to an **executable specification** — one that an AI agent can implement without ambiguity, and that can be verified mechanically after implementation.

Reverse-engineered from 38+ real project artifacts across new feature builds, migrations, refactors, and incident responses.

**Core insight**: The transition from "discussion draft" to "executable spec" is NOT about document completeness — it's about whether every decision that affects implementation has an owner, a recorded rationale, and a verification method.

---

## When to Use

Trigger when the task meets ANY of these:

1. **Information output** — new messages, API responses, LLM replies, report formats
2. **New data fields / sources** — new database tables, new external data sources, new cache keys
3. **Cross-module changes** — 3+ files across different directories
4. **Permission / security logic** — ACL, auth, rate limiting, role-based access
5. **Will be handed to an AI agent for execution** — the spec IS the execution prompt
6. **Stakeholder explicitly requests** — "write a spec", "plan the migration", "design this"

## When NOT to Use

1. Single-line bug fix with no architectural impact
2. README / documentation-only edits
3. Infrastructure console operations
4. Pure discussion / brainstorming (no deliverable expected)

## D0 Fast Path — When to Skip Full Ceremony

D0 applies only when NONE of the "When to Use" triggers #1 (information output), #2 (new data fields/sources), #3 (cross-module), #4 (permission/security) are active, AND:

- **D0 severity** — local change, no protected surface (auth/schema/routes/permissions)
- **No database mutation changes** — not touching INSERT/UPDATE/DELETE logic
- **Affected files ≤ 3** — blast radius is small and obvious

**D0 may skip**: CONTRACT triple / Architecture Fit Check / independent Checker loop (HR-2 exempted for D0).
**D0 still required**: Step 2b (Query Actual Data) + Evidence Block + Scope/Non-Scope + Phase breakdown + PASS/FAIL criteria + Rollback.

> After Step 2b, write simplified spec → run `gate:quick` (= references/gate-quick-d0.md) → implement → Final Authority sign-off → close-out.
> Decision Lock Table is only needed **when multiple valid approaches exist and the choice affects downstream implementation**. A single obvious approach does not need a D-N entry.

---

## Core Flow

```
Step 1: Stakeholder gives requirement (fuzzy or structured)
         ↓
Step 2: Read project context
        Cross-reference existing architecture
        Identify affected modules + dependencies
         ↓
Step 2b: Query Actual Data（MANDATORY — do not skip）
         - If replacing existing behavior: cat the source code, extract key formulas and data flow
           If greenfield: inspect nearest analogous path or related module
         - Query the relevant live data source(s) for this change:
           Spreadsheet: read header + first 3 rows
           Database: query target table for first 5 rows
           No DB: query relevant API / config / env actual values
         - Print results, confirm with stakeholder before proceeding
         ↓
Step 3: Architecture Fit Check (BEFORE writing any spec)
        → Does the architectural assumption hold for this use case?
        → If uncertain, escalate to stakeholder before continuing
         ↓
Step 4: Produce Spec v1
        Use: references/spec-template.md
        Must include: Scope, Decision Lock, Phase breakdown, Gate, Rollback
        If information output OR new data fields/sources: add CONTRACT triple
        Run: references/completeness-guard.md
         ↓
Step 5: Send to independent Checker (different AI or person)
        Use: references/checker-review-prompt-template.md
        Include calibration test if high-risk (see trust-calibration guide (not in public pack))
         ↓
        ┌─ UNBLOCKED ─┐  ┌── BLOCKED ──┐
        ↓           ↓    ↓            ↓
Step 6: Produce     Fix findings → v(N+1)
        execution    Re-submit to Checker
        prompt       (loop until unblocked)
        (refs spec
         as SSOT)
         ↓
Step 7: Stakeholder merges + deploys + production verify
         ↓
Step 8: Close-out report
        Use: references/close-out-template.md
        Must pass: Governance Audit (7 items)
```

> **Note**: Checker outputs a blocker list only, not a binary verdict. Final Authority declares GO when blockers = 0.

---

## Hard Rules (8)

Violation of any hard rule = spec is rejected, rewrite required.

| # | Rule | Verification | Why |
|---|------|-------------|-----|
| HR-1 | Tasks involving information output OR new data fields/sources → CONTRACT triple (INPUT + OUTPUT + APPROVAL) must be delivered BEFORE logic code | 3 files/sections exist | Missing contract → interface mismatch in production |
| HR-2 | Maker ≠ Checker — writer and reviewer must be different AI/person | Review record shows different entities | Same-context review misses systematic blind spots |
| HR-3 | Every acceptance item must have mechanically decidable PASS/FAIL | Each ⬜ item has numeric threshold or executable command | Vague criteria ("works correctly") cannot be verified |
| HR-4 | Decision Lock Table complete before implementation | D-N table with zero TBD entries | Unlocked design choices cause implementation divergence |
| HR-5 | Declaration ≠ Behavior — any claim must have artifact evidence | Close-out links every PASS to artifact path | Documents ≠ code reality; always verify against actual state |
| HR-6 | Database mutation logic changes (INSERT/UPDATE/DELETE) require explicit Final Authority authorization | Authorization text in prompt or config | AI agents may autonomously "improve" mutation logic with catastrophic results |
| HR-7 | Red light = full stop — test failure stops all progress | CI log or test output as evidence | Cascading failures are cheaper to prevent than to debug |
| HR-8 | Bug-to-Gate Closure — any confirmed and replayable bug must leave behind a maintained regression gate at the narrowest effective layer. If no executable gate is feasible, close-out must record why, the temporary control, the owner, and the remediation date. | Close-out has “Regression Gate” section with gate type + layer + verification | A fixed bug without a gate is only remembered short-term, not structurally defended |

---

## Guidance (5)

Recommended but adjustable based on context.

| # | Guidance | When | Reference |
|---|---------|------|-----------|
| GD-1 | Trust calibration — embed known defect to verify reviewer depth | High-risk tasks or first time with new Checker | *(not in public pack)* |
| GD-2 | Governance Audit block at end of every close-out report | All close-out reports | references/close-out-requirements.md |
| GD-3 | One logical change per PR | Repos with CI | Enables precise rollback per-category |
| GD-4 | Risk escalation: permission/DB mutations/fan-in>5/routing/prior incidents | All tasks | references/risk-escalation.md |
| GD-5 | Human manual production verification is non-negotiable | All deploys | Cannot be replaced by CI alone |

---

## Architecture Fit Check (Step 3 — Critical)

**This step prevents the most expensive failure mode: building the right thing with the wrong architecture.**

Example failure: all technical gates passed (0 errors), but the entire architecture (NLP chatbot for a B2B tool) was wrong for the use case. Result: months of engineering work discarded.

Before writing any spec, verify:

1. Does the chosen architecture's core assumption hold for this use case?
2. Has this assumption been validated with real user behavior (not just technical tests)?
3. If the task is a new feature: what would make the architecture choice wrong?

If uncertain → escalate to stakeholder with specific concerns. Do NOT proceed to spec writing.

See: architecture-fit-check guide (not included in public pack — use the 3-question checklist in Architecture Fit Check section above)

---

## Maker-Checker Role Assignment

| Role | Entity | Responsibilities | Boundary |
|------|--------|-----------------|----------|
| **Spec Maker** | AI (e.g., Claude) | Read context → cross-reference → produce spec draft → iterate on findings | Cannot declare FINAL |
| **Spec Checker** | Different AI or person | Static + behavioral check → output BLOCKER list (not binary GO/NO-GO) | Cannot modify spec |
| **Code Maker** | AI agent (e.g., Claude Code) | Implement within In-Scope only → stop and report Out-of-Scope issues | Cannot modify DB mutation logic or expand scope |
| **Code Checker** | Different AI or person | Code review against spec → R1-R18 verification | Cannot modify code |
| **Final Authority** | Human stakeholder | Architecture direction → scope confirmation → FINAL declaration → merge/deploy | Only human who can declare GO |

---

## Risk Escalation Quick Reference

| Trigger | What Happens |
|---------|-------------|
| T1: Permission/security logic | 🔴 2-3 rounds of review, separate spec + code review |
| T2: Database INSERT/UPDATE/DELETE | 🔴 Final Authority authorization required per HR-6 |
| T3: Fan-in > 5 | 🟡 Note in Risks section, track in task tracker |
| T4: Routing layer changes | 🟡 Higher review density |
| T5: Prior incident on similar change | 🔴 Calibration test mandatory |

See: risk-escalation guide (not included in public pack — see Risk Escalation Quick Reference above)

---

## Evidence Block（Mandatory for every RCA / Spec / Analysis）

Every RCA, spec, and analysis must include an Evidence Block. Missing = spec rejected.

```
### Evidence Block
- Source code read: file + line number + summary (blank = violation)
- Real data queried: command + first 5 rows of result (blank = violation)
- Source of every number: source file or command (no source = violation)
- Query commands must be reproducible by the stakeholder
```

---

## BDD Acceptance Criteria Format

Every AC in APPROVAL_CHECKLIST must use Given-When-Then format with concrete data conditions and values:

```
Given: specific data conditions (with field values)
When:  operation
Then:  expected result (with numeric values)

Example:
  Given: inventory.SKU_A w1=0, w2=0, w3=80
         week_map w03.date = 2026-04-06
  When:  query SKU_A
  Then:  estimated_arrival = 2026-04-13, qty = 80
```

ACs involving data computation must include concrete field values and numbers. Non-data ACs (permission gates, routing, UI copy, architectural constraints) must have concrete identification conditions and mechanically verifiable expected results. ACs without mechanically verifiable conditions = violates HR-3.

---

## Ubiquitous Language Table（Required for cross-system specs）

When a spec spans multiple system layers, include a cross-system field mapping table:

| Business Concept | Definition | Source Field | DB Field | Code Variable |
|-----------------|------------|-------------|----------|---------------|
| (example) ETA | Nearest week with stock arrival date | arrival_wN | week_date | estimatedArrival |

Fields with different names but same semantics → must be mapped. Omission = data semantic confusion risk.

---

## Test Data Principles

| Scenario | Principle |
|----------|-----------|
| System boundary (cross storage/API) | Must use real schema + seed data |
| Single-function internal logic | Mocks acceptable |
| Platform cannot run tests | Step 2b real data query as substitute |
| Mock data format | Must be copied from real data, never guess field names/types/positions |

---

## Verification Layers

| Layer | Name | How | When |
|:-----:|------|-----|------|
| **A** | AI-Executable Rubric | Human/AI reads spec, marks PASS/FAIL per item | Always — `references/completeness-guard.md` |
| **B** | Executable Guards | Script/command outputs PASS/FAIL automatically | When available — *(not in public pack)* |

Layer A is always available. Layer B automates a subset of Layer A checks. See mechanical-verification guide (not in public pack) for the full verification depth ladder.

---

## File References

| File | Purpose |
|------|---------|
| **References** | |
| `references/decision-gate.md` | *(not in public pack)*  When and how to lock decisions (D-N format) |
| `references/executable-spec-criteria.md` | 8 mandatory fields for executable specs |
| `references/spec-review-checklist.md` | 18 review dimensions (R1-R18) for Checker |
| `references/trust-calibration.md` | *(not in public pack)* Calibration test design guide |
| `references/risk-escalation.md` | *(not in public pack)* 5 escalation triggers and actions |
| `references/mechanical-verification.md` | *(not in public pack)*  What can be automated vs needs human judgment |
| `references/anti-patterns.md` | *(not in public pack)*  6 failure modes with case studies |
| `references/close-out-requirements.md` | *(not in public pack)* Close-out report mandatory items + governance audit |
| `references/architecture-fit-check.md` | *(not in public pack)*  Architecture assumption validation guide |
| **Templates** | |
| `references/spec-template.md` | Spec skeleton (Scope → Decision Lock → Phase → Gate → Rollback) |
| `references/contract-triple-template.md` | INPUT + OUTPUT + APPROVAL skeleton |
| `references/decision-note-template.md` | *(not in public pack)*  D-N decision record format |
| `references/close-out-template.md` | Close-out report skeleton |
| `references/checker-review-prompt-template.md` | Checker review prompt with calibration slot |
| `references/d0-spec-template.md` | D0 simplified spec skeleton (Step 2b + Evidence Block + minimal sections) |
| `references/gate-quick-d0.md` | D0 gate guard (8 checks, replaces full checklist for D0) |
| **Guards** | |
| `references/completeness-guard.md` | AI-executable spec completeness rubric (31 checks; 23 if no CONTRACT/CQ) |
| `references/executable-guard-scripts.md` | *(not in public pack)* Automated guard script specs (Layer B) |
