# Structural Completeness Checklist (Guard)

> Catches **omissions** rather than **errors**. Run at G2 (Spec Lock), after the completeness guard.
> Each item asks not "is it correct?" but "has this domain been considered?"

## Design Rationale

The completeness guard (`completeness-guard.md`) verifies artifact existence (does the spec have a Rollback section? Does the Decision Lock have TBD entries?).
This checklist verifies **domain coverage** — has the spec addressed the critical domains that must be handled?

Origin lesson: a spec that passed all structural and multi-reviewer gates still missed authentication, executable tests, HTTP semantics, and multi-store consistency. Root cause: every reviewer assumed "someone else will handle it" or "the platform handles it." No mechanism forced the question "does the spec address this domain?"

**v2 design (generative items)**: 12 high-lethality checks are **generative** — the Maker cannot just check a box but must produce specific content from the spec. If the Maker cannot produce the content, the spec has a gap. All checks require evidence. Completed evidence is sent alongside the spec to the independent Checker.

## Applicability

| D-level | How to Execute |
|---------|---------------|
| D0 | Not required (use `gate-quick-d0.md`) |
| D1 | Full execution, N/A requires justification |
| D2/D3 | Full execution, N/A not accepted (unless justified and PM-confirmed) |

## Execution Sequence

```
completeness-guard.md (31 checks: artifact existence) → PASS
                ↓
structural-completeness-checklist.md (this file: domain coverage) → PASS
                ↓
Send Maker's generative answers + evidence together with spec to Checker
(Checker reviews spec + structural evidence simultaneously, see checker-review-prompt-template.md §Structural Review)
```

## Fill Rules

| Type | Marker | Rule |
|------|--------|------|
| Generative (G) | GEN | Maker must write specific content in the Evidence column (actor lists, failure modes, test commands, etc.). Cannot produce content = FAIL. "See spec section X" pointer-style answers are NOT accepted — the content must be written out directly |
| Verification (V) | VER | Maker provides a one-line evidence pointer to the specific spec location + summary. Blank = FAIL |
| N/A | — | Must include justification. D2/D3 N/A requires PM confirmation |

**Key constraint**: Generative items do not accept "see spec section X" — the content must be written directly in the Evidence column. This forces the Maker to face whether they can actually produce the answer from the spec. If they can only point to a spec paragraph but cannot state the specifics, it reveals a self-review blind spot.

**Version alignment rule**: If the spec is revised due to Checker findings, all affected GEN generative answers must be re-filled. Structural evidence version must be >= spec version. The Checker receiving mismatched versions = automatic BLOCKER.

---

## DC-1: Authentication & Authorization

| # | Type | Check | Maker Must Answer | Evidence |
|---|:----:|-------|-------------------|----------|
| DC-1.1 | GEN | Who can call this service/API? | **List all actors + the specific behavior when each actor lacks permission (response code, error message, redirect target)** | |
| DC-1.2 | VER | Authentication method explicitly defined? | Point to the authentication mechanism definition in spec + summary | |
| DC-1.3 | VER | Role-by-operation matrix exists? | Point to the matrix location in spec + summary | |
| DC-1.4 | VER | Justification for no authentication? | Point to the declaration in spec + summary | |
| DC-1.5 | GEN | CORS policy defined? | **List allowed origins, allowed methods, credentials setting. If not an HTTP API, explain why N/A** | |

**Omission signal**: The entire spec never mentions authentication/authorization = DC-1.1 automatic FAIL (not N/A).

## DC-2: Error Handling Strategy

| # | Type | Check | Maker Must Answer | Evidence |
|---|:----:|-------|-------------------|----------|
| DC-2.1 | GEN | Error scenario coverage complete? | **List the top 3 failure modes per endpoint/operation (including trigger condition, handling path, what the user sees)** | |
| DC-2.2 | VER | Each error scenario has a corresponding handling path? | Point to error handling definition in spec + summary | |
| DC-2.3 | GEN | Error responses follow protocol semantics? | **List each error scenario's corresponding HTTP status code / error flag / protocol response format, and explain why that code was chosen** | |
| DC-2.4 | GEN | Timeout and fallback semantics defined? | **List each external dependency's timeout value + behavior on timeout (retry? fallback? abort?) + fallback trigger condition and response content** | |
| DC-2.5 | GEN | Silent failure risks identified? | **List all catch blocks / error suppression points. For each: what is swallowed, why it is acceptable, how it is observable (log? metric?)** | |

**Omission signal**: Spec only describes the happy path with no error scenarios = DC-2.1 automatic FAIL.

## DC-3: Multi-Store Consistency

> Applicable when: the service involves 2+ storage layers (DB + cache, primary DB + secondary store, etc.)

| # | Type | Check | Maker Must Answer | Evidence |
|---|:----:|-------|-------------------|----------|
| DC-3.1 | GEN | All storage layers identified? | **List all storage layers involved + data content per layer + which layer is SSOT + sync mechanism between layers** | |
| DC-3.2 | VER | SSOT declaration exists? | Point to the SSOT declaration in spec + summary | |
| DC-3.3 | GEN | Partial success handling strategy? | **Describe the concrete scenario: layer A write succeeds but layer B fails — what does the system do? (cleanup / compensation / retry / tolerate inconsistency + eventual consistency strategy)** | |
| DC-3.4 | GEN | Delete operations consistent across layers? | **List the complete delete flow steps, mark which storage layer each step touches, explain handling when any step fails** | |

**Omission signal**: Multiple storage layers involved but spec only mentions writes/deletes for one layer = DC-3.1 automatic FAIL.
**N/A condition**: Service involves only a single storage layer.

## DC-4: Test Strategy

| # | Type | Check | Maker Must Answer | Evidence |
|---|:----:|-------|-------------------|----------|
| DC-4.1 | GEN | Executable tests exist and are not empty shells? | **List test commands + expected output format for each. If using curl instead of a test framework, explain why + how repeatability is ensured** | |
| DC-4.2 | GEN | Test scope maps to feature scope? | **List each In-Scope feature with its corresponding test name and what it verifies. Features without a corresponding test = gap** | |
| DC-4.3 | GEN | Edge cases have a test plan? | **List at least 3 edge cases + test method for each (empty input, oversized input, concurrency, timezone, encoding, etc.)** | |
| DC-4.4 | VER | Cross-repo contract test planned? | Point to contract test strategy in spec + summary | |

**Omission signal**: Spec never mentions testing = DC-4.1 automatic FAIL. Gold-set or eval data exists but is not wired into executable tests = FAIL.

## DC-5: Observability

> Applicable when: D1+ and involves a production service

| # | Type | Check | Maker Must Answer | Evidence |
|---|:----:|-------|-------------------|----------|
| DC-5.1 | VER | Logging strategy defined? | Point to logging definition in spec + summary (what to log, what not to log, format) | |
| DC-5.2 | VER | Cross-system tracing defined? | Point to traceId / correlation ID definition in spec + summary | |
| DC-5.3 | VER | Alert conditions defined? | Point to SLA / alert threshold in spec + summary | |

**N/A condition**: D0 and not a production service.

## DC-6: Dependency Safety

> Applicable when: called by 3+ upstream consumers, or provides an external API

| # | Type | Check | Maker Must Answer | Evidence |
|---|:----:|-------|-------------------|----------|
| DC-6.1 | VER | All upstream consumers identified? | Point to consumer list in spec + summary | |
| DC-6.2 | VER | Backward compatibility strategy declared? | Point to compatibility strategy in spec + summary | |
| DC-6.3 | VER | API versioning? | Point to versioning strategy in spec + summary | |

**N/A condition**: Internal tool, no external consumers.

---

## Summary

| Category | Total | Generative GEN | Verification VER | PASS | FAIL | N/A |
|----------|:-----:|:--------------:|:----------------:|:----:|:----:|:---:|
| DC-1: Authentication & Authorization | 5 | 2 | 3 | | | |
| DC-2: Error Handling Strategy | 5 | 4 | 1 | | | |
| DC-3: Multi-Store Consistency | 4 | 3 | 1 | | | |
| DC-4: Test Strategy | 4 | 3 | 1 | | | |
| DC-5: Observability | 3 | 0 | 3 | | | |
| DC-6: Dependency Safety | 3 | 0 | 3 | | | |
| **Total** | **24** | **12** | **12** | | | |

## Verdict

| Condition | Result |
|-----------|:------:|
| All GEN generative items have specific content (not pointer-style)? | |
| All VER verification items have evidence? | |
| DC-1 all PASS (or justified N/A)? | |
| DC-2 all PASS? | |
| DC-3 all PASS (or N/A for single storage layer)? | |
| DC-4 all PASS? | |
| DC-5 all PASS (or N/A)? | |
| DC-6 all PASS (or N/A)? | |
| **Domain coverage complete?** | **YES / NO** |

**NO** → Identify FAIL items, add to spec → re-run.
**YES** → Merge completeness-guard results + this checklist's generative answers, send together to Checker review.

---

## Division of Responsibility with Other Guards

| Dimension | completeness-guard (G2) | This Checklist (G2) | Adversarial Review (G5) |
|-----------|------------------------|---------------------|------------------------|
| Timing | Pre-implementation | Pre-implementation | Post-implementation |
| Input | Spec document | Spec document | Code diff |
| Question asked | Does this section exist? | Has this domain been considered? Can Maker produce specific content? | How does this code break? |
| Catches | Format gaps | Omissions + self-deception | Commission errors |
| Example | Spec has no Rollback section | Spec mentions auth but Maker cannot list specific actors | Auth logic is implemented incorrectly |
| Executor | Maker self-assessment | Maker generates → **independent Checker evaluates** | Independent reviewer |
