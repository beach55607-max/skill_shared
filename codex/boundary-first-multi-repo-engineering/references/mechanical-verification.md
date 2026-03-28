# Mechanical Verification

This reference explains why this workflow relies on mechanical verification instead of narrative confidence, what mechanical verification means in practice, and how to use it effectively.

## Core Principle

**Prefer machine-checkable evidence over narrative confidence.**

"I checked and it looks fine" is not evidence. A passing gate command with a known scope is evidence.

The difference matters because:

- Narrative confidence scales with the engineer's attention span. Mechanical verification scales with the test suite.
- Narrative confidence degrades under fatigue, time pressure, and context switching. Mechanical verification does not.
- Narrative confidence cannot be audited after the fact. Mechanical verification produces a reproducible result.

This is not about distrust. It is about choosing the verification method that stays reliable when conditions are worst.

## What Counts As Mechanical Verification

### Guard Scripts

Small, focused scripts that check one invariant each.

Examples:

- architecture guard: ensures imports respect layer boundaries
- contract guard: ensures request/response shapes match a declared schema
- SQL safety guard: checks for dangerous SQL patterns (unqualified deletes, missing conflict targets)
- secret guard: scans for hardcoded credentials or tokens
- encoding guard: checks for unexpected character encoding issues

Guard scripts are fast, deterministic, and cheap to run. They catch regressions that unit tests do not cover because they check structural invariants, not functional behavior.

### Gate Commands

A gate bundles multiple checks into a single command that must pass before a change is considered verified.

Examples:

- `gate:quick` — lint + guards + fast tests. Use for routine changes.
- `gate:pr` — lint + guards + full tests + contract checks + build. Use when auth, persistence, schema, routes, or shared contracts are touched.

The value of a gate is that it removes judgment from the verification step. You do not decide which checks to run. The gate decides.

### CI Bundles

A CI bundle is a gate that runs in a continuous integration environment.

Examples:

- `npm run ci` — lint + tests + duplicate detection + build
- GitHub Actions / GitLab CI pipeline that runs gates on every push or PR

CI bundles add two things gates alone do not: they run in a clean environment (no local state leaks), and they produce an auditable record.

### Green Tests (GT)

GT refers to a repo's full test suite passing. "GT confirmed" means all tests pass, not just the ones near the changed code.

GT is the baseline. If GT fails, the change is not ready regardless of what narrative confidence says.

### Contract Tests

Tests that verify the shape and behavior of a shared boundary between two systems.

Examples:

- a test that asserts the request schema matches what the producer validates
- a test that asserts the response shape matches what the consumer parses
- a test that verifies signature computation matches between sender and receiver

Contract tests are the most valuable kind of mechanical verification for multi-repo work because they catch the exact class of failure this workflow is designed to prevent: silent drift between producer and consumer.

## Verification Depth Ladder

Not every change needs every level. Match depth to risk.

### Level 1: Lint + Unit Tests

Sufficient for: D0 changes with no protected surface. Cosmetic edits, comment changes, internal refactors that do not cross boundaries.

### Level 2: Guards + Narrowest Tests

Sufficient for: D0/D1 changes that touch production code but not protected surfaces. New internal logic, bug fixes in a single layer.

### Level 3: Gate (Quick)

Use for: D1 changes that touch a protected surface within one repo. Route changes, storage key changes, env binding changes.

### Level 4: Gate (Full / PR)

Use for: D1 high-risk and D2 changes. Auth, persistence, schema, routes, shared contracts, durable writes. This is the standard for anything that crosses a protected surface.

### Level 5: Cross-System Validation

Use for: D2/D3 changes that affect a shared contract. Run the strongest gate on the owner side AND the strongest gate on the consumer side. One-side-only validation is partial evidence, not a pass.

### Level 6: Staged Rollout Verification

Use for: D3 changes that cannot be safely verified in a single deployment. Auth format changes, schema migrations, breaking contract changes. Verify dual-format acceptance, run both old and new consumers against the new producer, confirm rollback path works.

## How To Build Gates In Your Own Repo

If your repo does not have gates yet, start with these steps:

### Step 1: Identify your invariants

What rules should never be broken? Examples:

- imports must respect layer boundaries
- no hardcoded secrets in source
- SQL must use conflict targets for upserts
- request/response shapes must match declared contracts

### Step 2: Write guard scripts

One script per invariant. Each script should:

- exit 0 if the invariant holds
- exit non-zero with a clear message if it does not
- run in under 5 seconds

### Step 3: Bundle into gates

Create two gate commands:

- `gate:quick` — lint + guards + fast tests (< 30 seconds)
- `gate:pr` — lint + guards + full tests + contract checks + build (< 5 minutes)

### Step 4: Wire into CI

Run `gate:pr` on every PR. Run `gate:quick` on every push.

### Step 5: Never stop at lint alone

Once gates exist, the rule is simple: if the repo has a gate, use it. Do not stop at lint or unit tests when a stronger mechanical check is available.

## Anti-Patterns

- **"I ran lint and it passed"** — lint checks syntax, not semantics. It does not verify architecture, contracts, or security.
- **"The tests near my change pass"** — narrowest tests verify local behavior. They do not verify that the change did not break something upstream or downstream.
- **"I read the code and it looks correct"** — reading is valuable for understanding, but it is not verification. Verification requires execution.
- **"The build succeeded"** — a build verifies compilation, not correctness. Many contract, auth, and data-integrity failures build successfully.
- **"I'll check it in staging"** — staging catches deployment issues, not contract drift. By the time you reach staging, the window for cheap fixes is gone.

## Connection To This Workflow

Mechanical verification is not a nice-to-have in this workflow. It is load-bearing.

- **Preflight Step 7** requires mapping the validation depth to the risk. The depth ladder above is what that mapping looks like in practice.
- **Decision Gate** uses verification availability to determine ceremony level. A repo with strong gates can verify D1/D2 changes mechanically. A repo without gates forces more manual review.
- **Close-out** requires stating which checks ran, which were skipped, and why. "No gate available" is a valid answer, but it must be stated explicitly — not hidden behind narrative confidence.
- **Constitution** states: "Prefer machine-checkable evidence over narrative confidence." This reference explains what that means in practice.
