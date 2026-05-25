# Strict Harness Profile

`strict-harness` is an optional workflow profile for teams that want a local,
machine-checkable guardrail around AI coding work.

It does not replace the skills in this toolkit. It adds a project-local runtime
under `.ai-dev/` so agents can leave packets, review evidence, and regression
smoke output in predictable locations.

## Install

```bash
bash install.sh --profile strict-harness --target /path/to/project
```

This creates:

```text
.ai-dev/
  bin/ai-harness
  runtime/
  gate-artifacts/
  harness/strict-harness/
```

The installer also adds `.ai-dev/` to the target repo's local
`.git/info/exclude` when the target is a git repository. It does not modify
tracked `.gitignore`.

Add `.ai-dev/bin` to `PATH`, or run the launcher by full path:

```bash
/path/to/project/.ai-dev/bin/ai-harness smoke
```

## v1 Scope

This public profile provides a single-repo strict workflow:

- project-local runtime and artifact directories
- `ai-harness smoke`
- `ai-harness run`
- `ai-harness g4-start`
- `ai-harness g4-status`
- `ai-harness g4-close`
- `ai-harness g5-package`
- `ai-harness g5-review`
- `ai-harness full-review`
- `ai-harness install-hooks`
- templates for G4 packets and G5 review packages

The harness is intentionally fail-closed: missing packet fields, invalid
base/head bindings, empty diffs, scope mismatches, and unavailable reviewers
block instead of passing silently.

## Commands

Run an implementation command inside the wrapper:

```bash
.ai-dev/bin/ai-harness run \
  --objective "fix login retry bug" \
  --allowed src/login.ts \
  --forbidden "auth schema, unrelated UI" \
  --verify "npm test -- login" \
  --stop "schema change required" \
  --command "codex exec 'fix the login retry bug'"
```

`run` creates a G4 packet, executes the implementation command, runs the
verification command, writes evidence logs under `.ai-dev/runtime/run-evidence/`,
and closes the packet. If implementation or verification fails, the packet is
closed with a non-PASS status instead of being left open or falsely passed.

Create a G4 packet before implementation:

```bash
.ai-dev/bin/ai-harness g4-start \
  --objective "fix login retry bug" \
  --allowed src/login.ts \
  --forbidden "auth schema, unrelated UI" \
  --verify "npm test -- login" \
  --stop "schema change required"
```

Close the packet after verification:

```bash
.ai-dev/bin/ai-harness g4-close \
  --packet g4-20260525T010203Z \
  --return-status DONE \
  --verification-status PASS \
  --verification-evidence verify.log
```

Create a G5 review evidence package:

```bash
.ai-dev/bin/ai-harness g5-package \
  --base main \
  --head HEAD \
  --scope src/login.ts
```

Run a command-based reviewer adapter:

```bash
AI_REVIEWER_CMD="codex review {package}" \
  .ai-dev/bin/ai-harness g5-review --package .ai-dev/gate-artifacts/review-packages/g5-review-*.md
```

Reviewer commands must output one of:

- `PASS`
- `REJECT`
- `BLOCKED`
- `UNCERTAIN`

If no reviewer is configured, `g5-review` returns `BLOCKED`.

Create the package and run the reviewer in one step:

```bash
AI_REVIEWER_CMD="codex review {package}" \
  .ai-dev/bin/ai-harness full-review \
    --base main \
    --head HEAD \
    --scope src/login.ts
```

`full-review` returns the same normalized exit codes as `g5-review`.

Install the optional repo-local pre-commit hook:

```bash
.ai-dev/bin/ai-harness install-hooks
```

The hook checks staged files before commit:

- there must be a latest `CLOSED` / `PASS` G4 packet
- every staged file must be covered by that packet's `allowed_files`
- staged files outside the packet are blocked

To replace an existing unmanaged hook:

```bash
.ai-dev/bin/ai-harness install-hooks --force
```

Emergency bypass is explicit:

```bash
AI_HARNESS_SKIP=1 git commit -m "..."
```

Use bypass only when you are intentionally accepting that the commit did not
pass the local strict-harness pre-commit check.

## Non-Goals

This public profile does not depend on any private workspace:

- no company-specific paths
- no external memory service requirement
- no private runtime directory
- no global block board
- no nested-repo custody rules in v1
