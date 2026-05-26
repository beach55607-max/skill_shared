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

If the runtime should live at a workspace root while the actual code lives in a
nested git repo, bind the review repo explicitly:

```bash
bash install.sh --profile strict-harness --target /path/to/workspace --repo service
bash install.sh --profile strict-harness --hooks --target /path/to/workspace --repo service
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

This public profile provides a strict workflow for one review repo per command.
By default the review repo is the target project. For nested repos, pass
`--repo <path>` so git SHA, diffs, staged files, and hooks are bound to the
actual child repo while `.ai-dev/` remains under the target workspace.

- project-local runtime and artifact directories
- nested repo custody through `--repo`
- `ai-harness smoke`
- `ai-harness run`
- `ai-harness g4-start`
- `ai-harness g4-status`
- `ai-harness g4-role-evidence`
- `ai-harness g4-role-run`
- `ai-harness g4-close`
- `ai-harness g5-package`
- `ai-harness g5-review`
- `ai-harness full-review`
- `ai-harness install-hooks`
- templates for G4 packets, G4 role evidence, and G5 review packages

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
  --d-level D1 \
  --objective "fix login retry bug" \
  --allowed src/login.ts \
  --forbidden "auth schema, unrelated UI" \
  --verify "npm test -- login" \
  --stop "schema change required"
```

D2/D3 packets require the G4 internal role loop before `DONE` + `PASS`
closeout. All three role evidence files must be `PASS`:

```bash
.ai-dev/bin/ai-harness g4-start \
  --d-level D2 \
  --objective "change API contract" \
  --allowed src/api.ts \
  --forbidden "auth schema" \
  --verify "npm test -- api" \
  --stop "schema change required"

.ai-dev/bin/ai-harness g4-role-evidence \
  --packet g4-20260525T010203Z \
  --role implementer \
  --status PASS \
  --evidence evidence/implementer.md

.ai-dev/bin/ai-harness g4-role-evidence \
  --packet g4-20260525T010203Z \
  --role spec_reviewer \
  --status PASS \
  --evidence evidence/spec-reviewer.md

.ai-dev/bin/ai-harness g4-role-evidence \
  --packet g4-20260525T010203Z \
  --role quality_reviewer \
  --status PASS \
  --evidence evidence/quality-reviewer.md
```

You can also let a command-based role runner generate all three role evidence
files:

```bash
AI_G4_ROLE_CMD='codex exec -- "$(cat {prompt})"' \
  .ai-dev/bin/ai-harness g4-role-run \
    --packet g4-20260525T010203Z
```

The role runner writes a role prompt that includes the packet plus committed,
staged, and unstaged diffs for the packet's allowed files. It records stdout,
stderr, exit code, working-tree diff hash, and HEAD before/after the role
command. If the command is unavailable, does not output a valid `STATUS: ...`,
or mutates code while acting as a reviewer, the role evidence is recorded as a
non-PASS state and `g4-close DONE/PASS` stays blocked.

`run` can also auto-run the D2/D3 role loop after implementation and
verification pass:

```bash
.ai-dev/bin/ai-harness run \
  --d-level D2 \
  --objective "change API contract" \
  --allowed src/api.ts \
  --forbidden "auth schema" \
  --verify "npm test -- api" \
  --stop "schema change required" \
  --command "codex exec 'change the API contract'" \
  --role-cmd 'codex exec -- "$(cat {prompt})"'
```

The role loop is internal maker-checker evidence only. It does not replace G5
external review.

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
  --packet g4-20260525T010203Z \
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
For closed-loop D2/D3 work, pass `--packet` so the review package binds to a
closed G4 packet whose role loop has already passed.

Install the optional repo-local pre-commit hook:

```bash
.ai-dev/bin/ai-harness install-hooks
```

For a nested review repo, add `--repo service` to `run`, `g4-start`,
`g4-close`, `g5-package`, `full-review`, and `install-hooks`.

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
- no multi-repo fan-out orchestration in v1; bind one review repo per command
