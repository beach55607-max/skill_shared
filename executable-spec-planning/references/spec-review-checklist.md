# Spec Review Checklist (R1-R18)

## Overview

18 review dimensions for Checker evaluation. Output must be specific findings (BLOCKER list), not just a binary verdict.

Originally 7 dimensions; expanded to 18 after discovering that coarser criteria missed real issues.

## Review Dimensions

### Structure (R1-R5)

| # | Dimension | What to Check |
|---|-----------|--------------|
| R1 | Scope completeness | In-Scope and Out-of-Scope both exist and are specific |
| R2 | Decision Lock integrity | All D-N entries have Decision + Rationale, no TBD |
| R3 | Phase breakdown quality | Each Phase has scope, files, risk, gate, rollback |
| R4 | Acceptance criteria precision | Every criterion is mechanically decidable |
| R5 | Rollback coverage | Every Phase has rollback steps with time budget |

### Content (R6-R11)

| # | Dimension | What to Check |
|---|-----------|--------------|
| R6 | Architecture consistency | Before/After matches actual codebase state |
| R7 | Dependency tracing | Moved functions include dependency chains |
| R8 | CONTRACT completeness | INPUT fields have type + validation + fallback |
| R9 | Risk identification | Known blind spots documented |
| R10 | Kill Switch design | Mechanism exists and activatable without deploy |
| R11 | Governance audit | 7 items present with evidence paths |

### Cross-Reference (R12-R18)

| # | Dimension | What to Check |
|---|-----------|--------------|
| R12 | File list ↔ Phase consistency | Every affected file appears in a Phase |
| R13 | Gate ↔ acceptance alignment | Phase gates collectively cover all acceptance criteria |
| R14 | CONTRACT ↔ implementation path | INPUT fields map to actual data sources |
| R15 | Rollback ↔ deployment order | Rollback order is reverse of deployment |
| R16 | Risk rating ↔ escalation triggers | High-risk Phases match T1-T5 triggers |
| R17 | Test coverage ↔ mock boundaries | Criteria don't rely solely on mocked components |
| R18 | Bug-to-Gate closure | If bug fix: regression gate at root-cause layer, or exemption documented with reason, temporary control, owner, remediation date | HR-8 |

## Output Format

```markdown
## Findings

| # | Severity | Location | Finding | Suggested Fix |
|---|:--------:|----------|---------|--------------|
| F-1 | 🔴 BLOCKER | §N | {what's wrong} | {how to fix} |
| F-2 | 🟡 WARNING | §N | {concern} | {suggestion} |
| F-3 | 🟢 NOTE | §N | {observation} | {optional} |

## Recommendation: {UNBLOCKED / BLOCKED} ({reason})
```

**Rule**: Any 🔴 BLOCKER = recommend BLOCKED to Final Authority.
