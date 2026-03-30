# Spec Completeness Checklist (Guard — Layer A)

> **D0 tasks**: use `references/gate-quick-d0.md` instead of this checklist.
> **D1+ tasks**: run this full checklist BEFORE sending spec to Checker. Every item is binary PASS/FAIL. Any FAIL = revise.

---

## Structure Checks (S)

| # | Check | How to Verify | Result |
|---|-------|--------------|:------:|
| S-1 | In-Scope AND Out-of-Scope sections exist | Grep for both | ⬜ |
| S-2 | Negative List with DB/Rollback/cross-team entries | ≥3 prohibition entries | ⬜ |
| S-3 | Decision Lock Table exists | Grep "D-1" or "Decision Lock" | ⬜ |
| S-4 | Decision Lock has zero TBD entries | No "TBD" / "?" in D-N cells | ⬜ |
| S-5 | Phase breakdown ≥2 phases | Grep "Phase 0"/"Phase 1" | ⬜ |
| S-6 | Each Phase has risk rating | 🟢/🟡/🔴 per Phase | ⬜ |
| S-7 | Each Phase has mechanically decidable gate | "Gate:" with number/command | ⬜ |
| S-8 | Rollback SOP with time budget per Phase | "< N min" per Phase | ⬜ |
| S-9 | Kill Switch exists | Mechanism described | ⬜ |
| S-10 | Governance Audit (7 items) | 7-row audit table | ⬜ |

## Content Quality (C)

| # | Check | How to Verify | Result |
|---|-------|--------------|:------:|
| C-1 | Acceptance criteria mechanically decidable | Each ⬜ has number/command/threshold | ⬜ |
| C-2 | No vague phrases ("works correctly", "acceptable") | Scan for blocklist phrases | ⬜ |
| C-3 | Affected files list with change types | Table of paths + New/Modify/Delete | ⬜ |
| C-4 | Files NOT to modify list exists | Explicit prohibition list | ⬜ |
| C-5 | Architecture Fit Check recorded (new features) | Core assumption + validation + result | ⬜ |

## New Rule Checks (NR)

| # | Check | How to Verify | Applicability | Result |
|---|-------|--------------|---------------|:------:|
| NR-1 | Evidence Block completed | Source code + real data + number sources all non-blank | All | ⬜ |
| NR-2 | Data computation ACs use BDD Given-When-Then | Given/When/Then with concrete field values and numbers | Data computation ACs only | ⬜ |
| NR-3 | Ubiquitous Language Table filled | Table or explicit N/A | Cross-system only | ⬜ |

## CONTRACT (CT) — if information output OR new data fields/sources

| # | Check | How to Verify | Result |
|---|-------|--------------|:------:|
| CT-1 | INPUT_CONTRACT with field spec | Fields have type/source/validation | ⬜ |
| CT-2 | MUST DO preconditions | Precondition table with owner | ⬜ |
| CT-3 | OUTPUT_CONTRACT exists | Format + examples | ⬜ |
| CT-4 | APPROVAL_CHECKLIST | Gate items with PASS/FAIL | ⬜ |
| CT-5 | Full AND minimal payload examples | Two JSON examples | ⬜ |
| CT-6 | Degradation behavior defined | Missing-input handling | ⬜ |

## Code Quality (CQ) — cross-module or new abstraction

| # | Check | How to Verify | Result |
|---|-------|--------------|:------:|
| CQ-1 | Code Quality Constraints section exists | ≥ 1 CQ entry or explicit N/A | ⬜ |
| CQ-2 | Mock/real-data boundary documented | CQ-4 filled or N/A | ⬜ |

## Risk (RK)

| # | Check | How to Verify | Result |
|---|-------|--------------|:------:|
| RK-1 | Permission/security → risk ≥ 🟡 | Cross-ref affected files | ⬜ |
| RK-2 | DB mutations → Final Authority authorization documented | Authorization text present | ⬜ |
| RK-3 | Fan-in > 5 → noted in Risks | Import count check | ⬜ |
| RK-5 | Bug fix includes regression gate or explicit exemption | Close-out has Regression Gate section, or states why + owner + remediation date | ⬜ |
| RK-4 | Risks section ≥ 3 entries | Count rows | ⬜ |

---

## Summary

| Category | Total | PASS | FAIL |
|----------|:-----:|:----:|:----:|
| Structure (S) | 10 | | |
| Content (C) | 5 | | |
| CONTRACT (CT) | 6 or N/A | | |
| Code Quality (CQ) | 2 or N/A | | |
| Risk (RK) | 5 | | |
| **Total** | **31** (or 23 if no CONTRACT + no CQ if no CONTRACT, or use gate-quick-d0.md for D0) | | |

## Verdict

All categories PASS? → **YES**: send to Checker. **NO**: fix FAIL items, re-run.
