# Executable Spec Criteria

## What Makes a Spec "Executable"

A specification is **executable** when an AI agent or developer can implement it without asking clarifying questions, AND the result can be verified mechanically after implementation.

A spec that is "complete-looking" but fails either condition is **fake-complete** — see anti-patterns.md AP-1.

## 8 Mandatory Fields

### 1. Scope / Non-Scope

What the task DOES and explicitly DOES NOT do. Non-scope prevents scope creep.

The negative list must cover at least:

- Database mutation logic changes (prohibited unless human-authorized)
- Rollback boundary (blast radius if reverted)
- Cross-repo/cross-team impact

### 2. Decision Lock Table

All design choices with alternatives: `D-N: Problem / Options / Decision / Rationale`. Gate: zero TBD entries.

### 3. INPUT / OUTPUT CONTRACT

For information-output tasks: field names, types, validation rules, example payloads (full + minimal), and MUST DO preconditions.

### 4. Phase / Step Breakdown

Each phase: scope boundary, files touched, risk rating (🟢/🟡/🔴), independent gate, rollback path.

### 5. Acceptance Criteria (PASS/FAIL)

Every item must be **mechanically decidable**.

**Good**: `test suite: N PASS, 0 FAIL` / `grep -r "hardcoded" src/ | wc -l = 0`
**Bad**: "Feature works correctly" / "Performance is acceptable"

### 6. Rollback SOP

Each phase: documented rollback path with time budget (typically ≤5 min).

### 7. Kill Switch

At least one mechanism to disable the feature without full rollback (feature flag, config threshold, env var).

### 8. Governance Audit Block

7 items: Measurable / Verifiable / Auditable / CONTRACT / Rollback SOP / Kill Switch / Cost Cap.

## What Disqualifies a Spec (NO-GO)

1. **Decision Lock has TBD entries** → implementation will diverge
2. **No CONTRACT** for information-output task → interface mismatch
3. **Acceptance criteria are subjective** → cannot verify
4. **No Rollback SOP** → cannot recover
5. **Affected test list not inventoried** → regression risk is a black box

## Additional Mandatory Requirements

The following are enforced by SKILL.md and verified by the spec-completeness-checklist:

| # | Requirement | Where Defined | Where Checked |
|---|-----------|--------------|--------------|
| 9 | Evidence Block (Step 2b output: source code + real data + number sources) | SKILL.md Core Flow Step 2b | NR-1, Q-1 |
| 10 | BDD Given-When-Then format for data-computation ACs | SKILL.md BDD AC section | NR-2 |
| 11 | Ubiquitous Language Table (cross-system specs) | SKILL.md UL Table section | NR-3, Q-6 |
| 12 | Code Quality Constraints (cross-module / new abstraction) | SKILL.md, template §3.6 | CQ-1, CQ-2 |
| 13 | Bug-to-Gate Closure (HR-8: regression gate or documented exemption) | SKILL.md HR-8, close-out §9 | RK-5, Q-8, R18 |
