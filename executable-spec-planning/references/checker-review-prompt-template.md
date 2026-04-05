# Checker Review Prompt — {Task Name}

> Send to an independent Checker (different AI or person from spec author).

---

## Instructions

You are reviewing an implementation specification for **{task name}**.

Your role is **independent Checker** — you did NOT write this spec.

### Files to Read

1. `{spec path}`
2. `{CONTRACT files if applicable}`
3. `{path to Maker's structural-completeness-checklist with evidence}` (D1+ mandatory)
4. `{relevant source files for cross-reference}`

### Review Dimensions (R1-R18)

> See `references/spec-review-checklist.md` for detailed R-dimension definitions.

**Structure (R1-R5)**: Scope completeness, Decision Lock integrity, Phase quality, Criteria precision, Rollback coverage.

**Content (R6-R11)**: Architecture consistency, Dependency tracing, CONTRACT completeness, Risk identification, Kill Switch, Governance audit.

**Cross-Reference (R12-R17)**: File↔Phase, Gate↔acceptance, CONTRACT↔implementation, Rollback↔deploy order, Risk↔triggers, Test↔mock boundaries.

**Bug-to-Gate (R18)**: If this is a bug fix, does the spec include a regression gate at the root-cause layer? If not, is an exemption documented?.

### Structural Review (DC-1 ~ DC-6)

In addition to the spec itself, you will receive the Maker's **Structural Completeness Checklist** with filled-in evidence. This checklist has 24 items across 6 domains. 12 items are **generative** — the Maker was required to produce specific content (actor lists, failure modes, test commands, etc.), not just check a box.

For each generative item, evaluate:

1. **Completeness**: Does the answer cover the full scope?
2. **Specificity**: Does the answer contain concrete details (status codes, timeout values)?
3. **Consistency with spec**: Does the answer match what's in the spec?
4. **Missing domains**: Are there domains marked N/A that shouldn't be?

For verification items, check whether the cited spec location supports the PASS claim.

**Version alignment check**: If the spec is v(N) but structural evidence references earlier content, report as BLOCKER.

Report structural findings in the same Findings table, with Location = "DC-N.N".

### Output Format

```markdown
## Findings

| # | Severity | Location | Finding | Suggested Fix |
|---|:--------:|----------|---------|--------------|
| F-1 | 🔴 BLOCKER | §N | {issue} | {fix} |
| F-2 | 🟡 WARNING | §N | {concern} | {suggestion} |

## Blocker Summary

| Total BLOCKERs | {N} |
| Recommendation | {If 0: 'recommend UNBLOCKED'; else: 'recommend BLOCKED'} |

> **Note**: Checker outputs blocker list and recommendation only. GO/NO-GO is declared by Final Authority.
```

Any 🔴 BLOCKER = recommend BLOCKED to Final Authority.

---

## Calibration Notice (high-risk only)

**This spec contains at least 1 intentionally placed design defect.**
If your review does not identify it, your review depth is insufficient.

Hint direction: Check consistency between §{X} and §{Y}.
