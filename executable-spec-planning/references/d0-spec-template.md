# {Task Name} — D0 Simplified Spec

> **Applicability**: D0 only — NONE of "When to Use" #1/#2/#3/#4 active, no DB mutations, ≤ 3 files.
> **Version**: v1.0
> **Date**: YYYY-MM-DD
> **Status**: ⬜ Draft / ⬜ Final Authority Approved (FINAL)
> **Author**: {who}
> **Note**: D0 exempts independent Checker (HR-2), CONTRACT triple, and Architecture Fit Check.

---

## 1. Scope

### In Scope

| Item | Description |
|------|-------------|
| {item} | {what} |

### Out of Scope

| Item | Reason |
|------|--------|
| {item} | {why not now} |

---

## 2. Evidence Block

- **Source code read**: {file + line number + summary} (blank = violation)
- **Real data queried**: {command + first 5 rows of result} (blank = violation)
- **Source of every number**: {source file or command} (no source = violation)
- **Query commands must be reproducible by the stakeholder**

---

## 3. Phase Breakdown

### Phase 0: {Title}

- **Scope**: {what}
- **Files**: {list, ≤ 3}
- **Risk**: 🟢/🟡
- **Gate**: {mechanically decidable PASS/FAIL}
- **Rollback**: {steps} — Time: < 2 min

---

## 4. Acceptance Criteria

| # | Criterion | PASS Condition | Priority | Status |
|---|-----------|---------------|:--------:|:------:|
| AC-1 | {what} | {number / command / comparison} | 🔴 MUST | ⬜ |

> Data computation ACs: use BDD Given-When-Then format with concrete field values.
> Non-data ACs: concrete identification conditions + mechanically verifiable expected results.

---

## 5. Rollback SOP

| Phase | Steps | Time Budget |
|-------|-------|:-----------:|
| P0 | {steps} | < 2 min |

---

## 6. Ubiquitous Language Table (cross-system only, otherwise N/A)

| Business Concept | Definition | Source Field | DB Field | Code Variable |
|-----------------|------------|-------------|----------|---------------|
| {concept} | {definition} | {field} | {field} | {var} |

> Single-system D0 changes: write `N/A — single system, no cross-system field mapping needed`.

---

## 7. Bug-to-Gate Notes (HR-8) — write N/A if not a bug fix

| Bug / Failure Mode | Gate Type | Layer | Verification |
|-------------------|-----------|-------|-------------|
| {description or N/A} | {test / guard / monitor / N/A} | {layer or N/A} | {method or N/A} |

**If no gate yet (P2/P3 only):**

| Exemption Reason | Temporary Control | Owner | Remediation Date |
|-----------------|-------------------|-------|-----------------|
| {why no gate now} | {temporary control measure} | {who} | {YYYY-MM-DD} |

---

## Sign-off

| Role | Entity | Date | Status |
|------|--------|------|:------:|
| Author | | | ⬜ |
| Final Authority | | | ⬜ |
