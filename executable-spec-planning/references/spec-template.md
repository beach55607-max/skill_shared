# {Task Name} — Implementation Spec

> **Version**: v1.0
> **D0 tasks**: use `references/d0-spec-template.md` instead. This template is for D1+.
> **Date**: YYYY-MM-DD
> **Status**: ⬜ Draft / ⬜ Checker Reviewed / ⬜ Final Authority Approved (FINAL)
> **SSOT**: This document is the single source of truth for {task name}
> **Spec Author (Maker)**: {AI or person}
> **Checker**: {different AI or person — must differ from author per HR-2}

---

## 1. Scope

### In Scope

| Item | Description |
|------|-------------|
| {item 1} | {what it does, at what boundary} |

### Out of Scope

| Item | Reason | When to Address |
|------|--------|-----------------|
| {item 1} | {why not now} | {next sprint / separate ticket / never} |

### Negative List (Prohibitions)

| Area | Prohibition | Reason |
|------|------------|--------|
| DB mutations | No INSERT/UPDATE/DELETE structure changes without Final Authority auth | HR-6 |
| Rollback boundary | {what cannot be rolled back} | {reason} |
| Cross-team | {what must not change in consumer systems} | {reason} |

---

## 1.5 Evidence Block (Step 2b Output)

- **Source code read**: {file + line number + summary} (blank = violation)
- **Real data queried**: {command + first 5 rows of result} (blank = violation)
- **Source of every number**: {source file or command} (no source = violation)
- **Query commands must be reproducible by the stakeholder**

---

## 2. Decision Lock Table

| # | Problem | Options | Decision | Rationale | Reversibility |
|---|---------|---------|----------|-----------|:-------------:|
| D-1 | {design question} | A: {opt} / B: {opt} | {choice} | {specific reason} | High / Med / Low |

**Gate**: Zero TBD entries before implementation starts.

---

## 3. Architecture

### 3.1 Architecture Fit Check

| Item | Value |
|------|-------|
| **Core assumption** | {what must be true for this to work} |
| **Validation method** | {AI deliberation / user data / stakeholder decision} |
| **Result** | {confirmed / challenged / override} |

### 3.2 Before vs After

{Current state → target state}

### 3.3 Affected Files

| File | Change Type | Risk | Reason |
|------|:-----------:|:----:|--------|
| `path/file.js` | Modify | 🟡 | {why} |

### 3.4 Files NOT to Modify

| File | Reason |
|------|--------|
| `path/file.js` | {why} |

---

## 3.5 Ubiquitous Language Table (cross-system specs only, otherwise N/A)

| Business Concept | Definition | Source Field | DB Field | Code Variable |
|-----------------|------------|-------------|----------|---------------|
| {concept} | {definition} | {field} | {field} | {var} |

---

## 3.6 Code Quality Constraints

| # | Constraint | Rationale |
|---|-----------|-----------|
| CQ-1 | {Shared abstraction has stable consumer or explicit variation point?} | {reason} |
| CQ-2 | {Duplication / consolidation tradeoff documented?} | {reason} |
| CQ-3 | {New cross-module dependency surfaced to spec?} | {reason} |
| CQ-4 | {Mock boundary / real-data boundary explicit?} | {reason} |
| CQ-5 | {Observability / failure containment defined?} | {reason} |

> Single-module D0 changes: N/A. Required for cross-module / new abstraction / new dependency.

---

## 4. Phase Breakdown

### Phase 0: {Title}

- **Scope**: {what}
- **Files**: {list}
- **Risk**: 🟢
- **Gate**: {mechanically decidable PASS/FAIL}
- **Rollback**: {steps} — Time: < 2 min

### Phase 1: {Title}

- **Scope**: {what}
- **Files**: {list}
- **Risk**: 🟡
- **Gate**: {PASS/FAIL condition}
- **Rollback**: {steps} — Time: < 3 min

---

## 5. Acceptance Criteria

| # | Criterion | PASS Condition | Priority | Status |
|---|-----------|---------------|:--------:|:------:|
| AC-1 | {what} | {number / command / comparison} | 🔴 MUST | ⬜ |
| AC-2 | {what} | {number / command / comparison} | 🟡 SHOULD | ⬜ |

---

## 6. Rollback SOP

| Phase | Steps | Time Budget |
|-------|-------|:-----------:|
| P0 | {steps} | < 2 min |
| P1 | {steps} | < 3 min |

---

## 7. Kill Switch

| Mechanism | Activation | Effect |
|-----------|-----------|--------|
| {feature flag / config / env var} | {how} | {what happens} |

---

## 8. Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|:----------:|:------:|-----------|
| R-1 | {description} | H/M/L | H/M/L | {action} |

---

## 9. Governance Audit

| Principle | Status | Evidence |
|-----------|:------:|---------|
| Measurable | ⬜ | |
| Verifiable | ⬜ | |
| Auditable | ⬜ | |
| CONTRACT | ⬜ | |
| Rollback SOP | ⬜ | |
| Kill Switch | ⬜ | |
| Cost Cap | ⬜ | |
