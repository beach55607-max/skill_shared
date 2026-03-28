# {Task Name} — Implementation Spec

> **Version**: v1.0 | **Date**: YYYY-MM-DD
> **Status**: ⬜ Draft / ⬜ Checker Reviewed / ⬜ Stakeholder Approved (FINAL)
> **SSOT**: This document is the single source of truth for {task name}
> **Maker**: {who wrote it} | **Checker**: {who reviews — must differ from Maker}

---

## 1. Scope

### In Scope

| Item | Description |
|------|-------------|
| {item} | {what, at what boundary} |

### Out of Scope

| Item | Reason | When to Address |
|------|--------|-----------------|
| {item} | {why not now} | {timeline} |

### Negative List (Prohibitions)

| Area | Prohibition | Reason |
|------|------------|--------|
| DB mutations | No INSERT/UPDATE/DELETE structure changes without human auth | HR-6 |
| Rollback | {what cannot be rolled back} | {reason} |
| Cross-team | {what must not change in consumer systems} | {reason} |

---

## 2. Decision Lock Table

| # | Problem | Options | Decision | Rationale | Reversibility |
|---|---------|---------|----------|-----------|:-------------:|
| D-1 | {question} | A: / B: | {choice} | {specific reason} | High/Med/Low |

**Gate**: Zero TBD entries before implementation.

---

## 3. Architecture

### 3.1 Fit Check

| Item | Value |
|------|-------|
| Core assumption | {what must be true} |
| Validation | {method + result} |

### 3.2 Affected Files

| File | Change | Risk |
|------|:------:|:----:|
| `path` | Modify | 🟡 |

### 3.3 Files NOT to Modify

| File | Reason |
|------|--------|
| `path` | {why} |

---

## 4. Phases

### Phase 0: {Title}

- **Scope**: {what}
- **Files**: {list}
- **Risk**: 🟢
- **Gate**: {mechanically decidable}
- **Rollback**: {steps} — < 2 min

### Phase 1: {Title}

- **Scope**: {what}
- **Files**: {list}
- **Risk**: 🟡
- **Gate**: {PASS/FAIL condition}
- **Rollback**: {steps} — < 3 min

---

## 5. Acceptance Criteria

| # | Criterion | PASS Condition | Priority | Status |
|---|-----------|---------------|:--------:|:------:|
| AC-1 | {what} | {number / command / comparison} | 🔴 MUST | ⬜ |
| AC-2 | {what} | {measurable condition} | 🟡 SHOULD | ⬜ |

---

## 6. Rollback SOP

| Phase | Steps | Time |
|-------|-------|:----:|
| P0 | {steps} | < 2m |
| P1 | {steps} | < 3m |

---

## 7. Kill Switch

| Mechanism | Activation | Effect |
|-----------|-----------|--------|
| {flag/config/env} | {how} | {what happens} |

---

## 8. Risks

| # | Risk | L | I | Mitigation |
|---|------|:-:|:-:|-----------|
| R-1 | {desc} | M | H | {action} |

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

---

## CONTRACT Triple (if information output)

### INPUT_CONTRACT

**Preconditions (MUST DO before implementation)**:

| # | Precondition | Owner | Status |
|---|-------------|-------|:------:|
| PRE-1 | {what} | {who} | ⬜ |

**Fields**:

| Field | Type | Source | Required | Validation | Fallback |
|-------|------|--------|:--------:|-----------|---------|
| {name} | string | {source} | Yes | {rule} | {default} |

### OUTPUT_CONTRACT

| Template | When | Format |
|----------|------|--------|
| TPL-01 | {condition} | {format} |

**Degradation**: {what happens when input missing}

### APPROVAL_CHECKLIST

| # | Gate | PASS Condition | Status |
|---|------|---------------|:------:|
| G-1 | {check} | {decidable} | ⬜ |
