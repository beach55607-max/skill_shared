---
name: executable-spec-planning
description: "Use when producing an implementation spec, migration plan, or any deliverable handed to an AI agent for execution. Triggers: 'write a spec', 'plan the migration', 'design this', tasks with new data fields, new API endpoints, cross-module changes, or permission/security logic. Skip for single-line fixes, doc edits, or infra console commands."
---

# Executable Spec Planning

Help AI and human collaborators go from a fuzzy requirement to an **executable specification** — one that can be implemented without clarifying questions, and verified mechanically after implementation.

**Core insight**: A spec becomes "executable" not when the document looks complete, but when every decision that affects implementation has an owner, a recorded rationale, and a verification method.

---

## When to Use

ANY of these:

1. **Information output** — new messages, API responses, report formats
2. **New data fields / sources** — new tables, external data, cache keys
3. **Cross-module changes** — 3+ files across different directories
4. **Permission / security logic** — auth, rate limiting, role-based access
5. **Handed to AI agent for execution** — the spec IS the prompt
6. **Stakeholder requests** — "write a spec", "plan the migration"

## When NOT to Use

- Single-line fix, no architectural impact
- Doc-only edits
- Infra console ops
- Pure brainstorming

## D0 Fast Path

If ALL true → skip CONTRACT / Architecture Fit / Checker loop:

- D0 severity, no protected surface
- No information output
- No cross-repo impact
- No DB mutation changes
- ≤ 3 affected files

Still required on D0: Scope/Non-Scope, Phases, PASS/FAIL criteria, Rollback.

---

## Core Flow

```
1. Stakeholder gives requirement
2. Read project context, identify affected modules + dependencies
3. Architecture Fit Check — does the approach's core assumption hold?
   → If uncertain: STOP, escalate to stakeholder
4. Produce Spec v1 (use template below)
   → Run completeness check (§ Completeness Guard)
5. Send to independent Checker (different AI or person — HR-2)
   → High-risk? Embed calibration test (§ Trust Calibration)
6. GO → produce execution prompt referencing spec as SSOT
   NO-GO → fix findings → resubmit (loop)
7. Stakeholder merges + deploys + manual production verify
8. Close-out report with governance audit
```

---

## Hard Rules (7)

Any violation = spec rejected.

| # | Rule | Why |
|---|------|-----|
| **HR-1** | Information output tasks → CONTRACT (INPUT + OUTPUT + APPROVAL) before logic code | Missing contract → interface mismatch |
| **HR-2** | Maker ≠ Checker — writer and reviewer must differ | Same-context review misses systematic blind spots |
| **HR-3** | Every acceptance item must be mechanically decidable (number / command / threshold) | "Works correctly" cannot be verified |
| **HR-4** | Decision Lock Table complete (zero TBD) before implementation | Unlocked choices → implementation diverges |
| **HR-5** | Declaration ≠ Behavior — every claim needs artifact evidence | Documents ≠ reality; always verify against actual state |
| **HR-6** | DB mutation logic changes (INSERT/UPDATE/DELETE) require explicit human authorization | AI agents may "improve" mutation logic with catastrophic results |
| **HR-7** | Red light = full stop — test failure stops all progress | Cascading failures are cheaper to prevent than debug |

---

## Architecture Fit Check (Step 3)

**Prevents the most expensive failure: building the right thing with the wrong architecture.**

Real case: all technical gates passed (0 errors), but the architecture (NLP chatbot for B2B tool) was wrong for users who needed deterministic menus. Months of work discarded.

Before writing any spec:

1. What is this architecture's core assumption about user behavior or system interaction?
2. Has that assumption been validated? (AI reasoning ≠ evidence; user behavior = evidence)
3. What would make the architecture choice wrong?

If uncertain → escalate with specific concerns. Do NOT proceed to spec writing.

---

## Trust Calibration (Step 5, high-risk only)

Embed a **known defect** in the spec before sending to Checker. If the Checker doesn't find it, their GO verdict cannot be trusted.

Good calibration defects:
- Function name in §2 doesn't match dispatch key in §5
- File in "affected files" missing from Phase breakdown
- CONTRACT field name inconsistent between INPUT and OUTPUT

Add to Checker prompt:

> **This spec contains at least 1 intentionally placed design defect.** If your review does not identify it, your review depth is insufficient. Hint: check consistency between §X and §Y.

| Result | Trust | Action |
|--------|:-----:|--------|
| Found calibration + real issues | High | Accept verdict |
| Found calibration only | Medium | Accept with caution |
| Missed calibration | Low | Reject, re-review with different Checker |

---

## Risk Escalation Triggers

| Trigger | Action |
|---------|--------|
| T1: Permission / security logic | 🔴 2-3 review rounds, separate spec + code review |
| T2: DB INSERT/UPDATE/DELETE | 🔴 Human auth required (HR-6) |
| T3: Fan-in > 5 importers | 🟡 Note in Risks, track in task tracker |
| T4: Routing layer changes | 🟡 Higher review density |
| T5: Prior incident on similar change | 🔴 Calibration test mandatory |

**Impact topology**: when choosing between fix routes, evaluate by **impact surface area**, not code change size. A 1-line change touching schema (6-7 files cascade) is more dangerous than a 3-file src-only change.

---

## Maker-Checker Roles

| Role | Entity | Boundary |
|------|--------|----------|
| Spec Maker | AI (e.g., Claude) | Cannot declare FINAL |
| Spec Checker | Different AI or person | Cannot modify spec; outputs BLOCKER list |
| Code Maker | AI agent | Implement In-Scope only; stop and report Out-of-Scope |
| Code Checker | Different AI or person | Review against spec |
| Final Authority | Human stakeholder | Only one who can declare GO |

---

## Anti-Patterns (6)

| # | Pattern | Signal | Key Fix |
|---|---------|--------|---------|
| AP-1 | **Fake completeness** | All sections present but criteria vague ("works correctly") | Each criterion must be PASS/FAIL in <60s by a stranger |
| AP-2 | **Validation false safety** | CI green but production breaks (tests mock the DB) | Identify what each mock hides; add contract guards |
| AP-3 | **Owner/contract/rollback gap** | Feature ships but nobody knows I/O contract or rollback | Add owner, CONTRACT, rollback as mandatory fields |
| AP-4 | **Document-behavior divergence** | Process doc says 4 stages, only 3 produce artifacts | Update doc to match reality, or enforce with gate |
| AP-5 | **AI scope creep** | Agent autonomously "fixes" code outside spec boundary | Explicit MAY/MUST-NOT-MODIFY file lists in prompt |
| AP-6 | **Cascading review debt** | Small unreviewed changes accumulate, baseline drifts | Behavior changes always need Checker (HR-2) |

---

## Verification Layers

| Layer | Name | How |
|:-----:|------|-----|
| **A** | Manual Checklist | Human/AI reads spec, marks PASS/FAIL — always available |
| **B** | Executable Guards | Script outputs PASS/FAIL — automates subset of Layer A |

See `references/completeness-guard.md` for the 25-check Layer A checklist and Layer B script specs.

---

## Governance Audit (7 items — required in close-out)

| # | Principle | What to Verify |
|---|-----------|---------------|
| GA-1 | Measurable | Numeric thresholds exist |
| GA-2 | Verifiable | PASS/FAIL determinable by command |
| GA-3 | Auditable | Tests/fixtures re-runnable |
| GA-4 | CONTRACT | Triple exists and reviewed |
| GA-5 | Rollback SOP | Steps per Phase with time budget |
| GA-6 | Kill Switch | Feature disableable without full rollback |
| GA-7 | Cost Cap | Resource usage bounded |

---

## Platform Installation

**Claude Code**: Copy this folder to `.claude/skills/executable-spec-planning/`, or copy `SKILL.md` content into your project's `CLAUDE.md`.

**Codex**: Copy this folder to `~/.codex/skills/executable-spec-planning/`, restart Codex.

**Both**: Works as-is. The skill is agent-agnostic — the flow is the same regardless of which AI does Maker vs Checker.

---

## File Map

```
executable-spec-planning/
├── SKILL.md                              ← you are here
└── references/
    ├── spec-template.md                  ← implementation spec skeleton
    └── completeness-guard.md             ← 25-check GO/NO-GO + Layer B guard specs
```
