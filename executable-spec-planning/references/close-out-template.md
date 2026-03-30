# {Task Name} — Close-out Report

> **Date**: YYYY-MM-DD
> **Spec Reference**: {link}
> **Maker**: {who} | **Checker**: {who} | **Final Authority**: {who}

---

## 1. Executive Summary

{1-3 sentences}

## 2. Scope (Delivered / Not Delivered)

## 3. Timeline

| Date | Event |
|------|-------|

## 4. Deliverables

| # | Artifact | Purpose |
|---|---------|---------|

## 5. Decision Lock Table (Final)

| # | Problem | Decision | Status |
|---|---------|----------|:------:|

## 6. Metrics (Before/After)

| Metric | Before | After | Delta |
|--------|:------:|:-----:|:-----:|

## 7. Known Residuals

| # | Issue | Severity | Ticket | Why Deferred |
|---|-------|:--------:|--------|-------------|

## 8. Lessons Learned

| # | Discovery | Response |
|---|-----------|----------|

## 9. Regression Gate (HR-8)

| # | Bug / Failure Mode | Gate Type | Layer | Verification | Owner |
|---|-------------------|-----------|-------|-------------|-------|
| RG-1 | {bug description} | {test / checklist / guard / monitor / assertion / schema check} | {unit / integration / golden / CONTRACT / lint / runtime} | {verification command or method} | {who maintains} |

> P0/P1, cross-system, auth/DB/schema/repeated incident: missing gate = BLOCKER.
> P2/P3 local bugs: "no gate yet" is allowed, but must state why, temporary control, owner, and remediation date.
> Gate must target the **root cause layer**, not the symptom layer.

**If no gate yet (P2/P3 only):**

| Exemption Reason | Temporary Control | Owner | Remediation Date |
|-----------------|-------------------|-------|-----------------|
| {why no gate now} | {temporary control measure} | {who} | {YYYY-MM-DD} |

---

## 10. Rejected Paths (Optional)

| Path | Why Attempted | Why Rejected |
|------|--------------|-------------|

## 11. Governance Audit

| Principle | Status | Evidence |
|-----------|:------:|---------|
| Measurable | ⬜ | |
| Verifiable | ⬜ | |
| Auditable | ⬜ | |
| CONTRACT | ⬜ | |
| Rollback SOP | ⬜ | |
| Kill Switch | ⬜ | |
| Cost Cap | ⬜ | |

## 12. Sign-off

| Role | Entity | Date | Status |
|------|--------|------|:------:|
| Maker | | | ⬜ |
| Checker | | | ⬜ |
| Final Authority | | | ⬜ |
