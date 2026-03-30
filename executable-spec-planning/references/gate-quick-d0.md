# gate:quick — D0 Guard

> D0-specific gate. Pass this guard + Final Authority sign-off = D0 ready for close-out.

## Applicability

- D0 ONLY — NONE of "When to Use" #1/#2/#3/#4 active
- No DB mutations, ≤ 3 files affected

## Required Checks (all must PASS)

| # | Check | How to Verify | Result |
|---|-------|--------------|:------:|
| Q-1 | Step 2b Evidence Block completed | Source code + real data + number sources all non-blank | ⬜ |
| Q-2 | Scope: In-Scope + Out-of-Scope exist | Grep both sections | ⬜ |
| Q-3 | Phase breakdown with gate + rollback per phase | PASS/FAIL condition + time budget | ⬜ |
| Q-4 | All ACs mechanically decidable (data computation ACs must use BDD Given-When-Then) | Each ⬜ has number/command/comparison | ⬜ |
| Q-5 | Rollback SOP with time budget < 5 min | Concrete steps + time | ⬜ |
| Q-6 | Cross-system spec: Ubiquitous Language Table filled | Table or explicit N/A | ⬜ |
| Q-7 | Available tests executed | Lint + test output or "no tests available" declaration | ⬜ |
| Q-8 | Bug fix includes regression gate or explicit exemption (HR-8) | Has gate or states why + owner + remediation date (non-bug-fix: N/A) | ⬜ |

## Exempt (not required for D0)

| Item | Reason |
|------|--------|
| CONTRACT triple (CT-1~CT-6) | D0 has no information output |
| Architecture Fit Check (C-5) | D0 has no protected surface |
| Independent Checker (HR-2) | D0 exempted |
| Decision Lock Table | D0 typically has one obvious approach |

## Verdict

| Condition | Result |
|-----------|:------:|
| All Q-1~Q-8 PASS? | ⬜ |
| **Ready for Final Authority sign-off?** | **⬜ YES / ⬜ NO** |

**NO** → fix FAIL items → re-run.
**YES** → Final Authority sign-off → implement → close-out.
