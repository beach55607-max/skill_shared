# {Task Name} — Close-out Report

> **Date**: YYYY-MM-DD
> **Spec Reference**: {link to implementation spec}
> **Duration**: {start date} → {end date}
> **Maker**: {who built it}
> **Claude Review Artifact**: {link or "N/A if Mode B"}
> **Codex Review Artifact**: {link or "BLOCKED(reason)" or "WAIVED_BY_PM(reason)"}
> **Final Authority**: {who approved it}

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

| Path | Why Attempted | Why Rejected | When |
|------|--------------|-------------|------|
| {approach} | {reason} | {what went wrong} | {phase} |

## 11. Traceability Matrix

| Ref Type | Ref ID | Planned In | Verified By | Evidence | Result |
|----------|--------|-----------|-------------|---------|:------:|
| AC | AC-1 | Spec §5 | {command or method} | {evidence source} | ⬜ |
| Gate | Phase-N Gate | Spec §4 | {command or method} | {evidence source} | ⬜ |
| Decision | D-N | Spec §2 | {review method} | {sign-off note} | ⬜ HELD / PASS |
| Regression Gate | RG-N | Close-out §9 | {verification command} | {evidence source} | ⬜ |
| Phase Gate | G[N] | UGP | {PM ACK ref} | {Gate output artifact} | ⬜ PASS / WAIVED |
| Structural | DC-N.N | Spec G2 | {Checker review} | {generative answers + Checker verdict} | ⬜ PASS / N/A(D0) |

> Every AC, every Phase Gate, every locked decision, every Regression Gate, and every Structural DC item must have corresponding verification evidence. Blank row = unverified.
> Structural row: D0 = N/A. D1+ must list the 12 generative items' final verdict.

---

## 11.5. Phase Registry (UGP — mandatory)

> See Universal Gate Protocol reference for format definition.

**Entry Point**: {Gate ID} ({PM-directed / Agent-proposed + PM-confirmed})
**Exit Point**: {Gate ID}
**Skipped by PM**: {Gate IDs skipped by PM directive, or "none"}

| Gate | Phase | Status | Evidence | PM ACK |
|------|-------|--------|----------|--------|
| I1 | Discovery | {PASS / SELF_CERTIFIED(evidence) / BLOCKED / SKIPPED_BY_PM / WAIVED_BY_PM(reason)} | {artifact} | {PM date + decision} |
| I2 | Concept Critique | {status} | {artifact} | {PM date + decision} |
| I3 | Canonicalize | {status} | {artifact} | {PM date + decision} |
| G0 | Classify + Preflight | {status} | {artifact} | {PM date + decision} |
| G1 | Architecture Fit | {status} | {artifact} | {PM date + decision} |
| G2 | Spec Lock | {status} | {artifact} | {PM date + decision} |
| G3 | Review Mode | {status} | {artifact} | {PM date + decision} |
| G4 | Implementation | {status} | {artifact} | {PM date + decision} |
| G5 | Adversarial Review | {status} | {artifact} | {PM date + decision} |
| G6 | Close-out | {status} | {artifact} | {PM date + decision} |

> Each Gate must be one of: PASS, SELF_CERTIFIED(evidence), BLOCKED, WAIVED_BY_PM(reason), SKIPPED_BY_PM. SKIPPED, N/A, optional, and blank are prohibited.

---

## 12. Governance Audit

> **Generative Audit (v2)**: Each item requires specific content, not just a checkbox. Cannot produce content = FAIL.

| # | Principle | Maker Must Answer | Evidence |
|---|-----------|------------------|----------|
| GA-1 | Measurable | **List each AC with its numeric threshold. No threshold = not delivered** | |
| GA-2 | Verifiable | **List each AC's verification command + actual execution result** | |
| GA-3 | Auditable | **List re-runnable tests/fixtures + commands. Can a third party reproduce in 5 minutes?** | |
| GA-4 | CONTRACT | **List INPUT_CONTRACT fields + OUTPUT_CONTRACT format + Checker verdict. Or explain why N/A** | |
| GA-5 | Rollback SOP | **List rollback steps per Phase + estimated time. Which paths were actually tested vs paper-only?** | |
| GA-6 | Kill Switch | **Describe trigger mechanism + behavior + whether deploy is needed. Or explain why acceptable without one** | |
| GA-7 | Cost Cap | **List resource consumption limits (API calls, DB rows, cache reads, etc.). What happens when exceeded?** | |
| GA-8 | Phase Compliance | **List every Gate's status + which were skipped + PM authorization reference. Any blank = FAIL** | |

## 13. Sign-off

| Role | Name/Entity | Date | Status |
|------|------------|------|:------:|
| Maker | {who} | {date} | ⬜ |
| Checker | {who} | {date} | ⬜ |
| Final Authority | {who} | {date} | ⬜ |
