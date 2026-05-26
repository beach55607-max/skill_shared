---
name: strict-harness-workflow
description: Use when a coding, refactor, build, packaging, test-fix, or automation task should run through the local ai-dev-toolkit strict harness instead of direct edits. Trigger when the user mentions strict harness, harness, packet, G4, G5, role evidence, D1/D2/D3, "防假完成", "do this under harness", or when `.ai-dev/bin/ai-harness` exists and the task is D1+ implementation work. Do not use for pure discussion, trivial D0 text edits, or when the project has not installed strict-harness unless the user asks how to install it.
---

# Strict Harness Workflow

Use this skill to invoke the project-local strict harness from natural language.

The harness is the machine. This skill is the instruction layer that tells the
agent when and how to call it.

## Preconditions

Before claiming strict-harness compliance, verify:

1. `.ai-dev/bin/ai-harness` exists in the project root, or a project-local
   `ai-harness` is on `PATH`.
2. The task has an executable verification command.
3. Allowed and forbidden scope can be stated concretely.

If the harness is missing, do not fake compliance. Tell the user to install:

```bash
bash install.sh --profile strict-harness --target /path/to/project
```

## Classification

- **D0**: typo, comments, docs-only, tiny local edits with no protected surface.
  Direct edits are acceptable unless the user explicitly asks for harness.
- **D1**: normal implementation in one repo. Use strict harness.
- **D2/D3**: contract, auth, schema, permissions, destructive writes,
  cross-boundary behavior, packaging/release, or high-risk automation. Use
  strict harness with the G4 role loop.

## Preferred Path: `ai-harness run`

For D1+ implementation, wrap the actual implementation command:

```bash
.ai-dev/bin/ai-harness run \
  --d-level D1 \
  --objective "short concrete objective" \
  --allowed "path/or/dir,another/path" \
  --forbidden "secrets,unrelated features,unowned files" \
  --verify "exact verification command" \
  --stop "missing dependency, unclear target, unsafe credential need" \
  --command "codex exec 'perform the implementation task'"
```

For D2/D3, add a role runner command:

```bash
.ai-dev/bin/ai-harness run \
  --d-level D2 \
  --objective "short concrete objective" \
  --allowed "path/or/dir,another/path" \
  --forbidden "secrets,unrelated features,unowned files" \
  --verify "exact verification command" \
  --stop "missing dependency, unclear target, unsafe credential need" \
  --command "codex exec 'perform the implementation task'" \
  --role-cmd 'codex exec -- "$(cat {prompt})"'
```

Use the local agent CLI actually available in the environment:

- Codex: `codex exec ...`
- Claude: `claude ...`
- Gemini or another CLI: use its equivalent non-interactive command

Do not invent a provider. If no provider CLI is available for `--command`, use
manual packet mode.

## Manual Packet Mode

Use this when the current agent will make edits directly instead of spawning a
provider command.

1. Start the packet:

```bash
.ai-dev/bin/ai-harness g4-start \
  --d-level D1 \
  --objective "short concrete objective" \
  --allowed "path/or/dir" \
  --forbidden "secrets,unrelated files" \
  --verify "exact verification command" \
  --stop "conditions that require stopping"
```

2. Make only the allowed edits.
3. Run the verification command and save evidence to a file.
4. For D2/D3, run role evidence before close:

```bash
AI_G4_ROLE_CMD='codex exec -- "$(cat {prompt})"' \
  .ai-dev/bin/ai-harness g4-role-run --packet <packet-id-or-path>
```

5. Close the packet:

```bash
.ai-dev/bin/ai-harness g4-close \
  --packet <packet-id-or-path> \
  --return-status DONE \
  --verification-status PASS \
  --verification-evidence path/to/verify.log
```

If role evidence, verification evidence, packet scope, or HEAD binding is
missing, report `BLOCKED`; do not claim PASS.

## G5 Review

When an external review is required, package the actual diff and send it through
the reviewer adapter:

```bash
AI_REVIEWER_CMD="codex review {package}" \
  .ai-dev/bin/ai-harness full-review \
    --packet <closed-g4-packet> \
    --base <base-sha-or-ref> \
    --head HEAD \
    --scope "path/or/dir"
```

Role evidence is internal maker-checker evidence. It never replaces external G5
review when G5 is required.

## Nested Repo

If `.ai-dev/` lives at a workspace root but the code is in a child git repo, add
`--repo <child-repo>` to `run`, `g4-start`, `g4-close`, `g5-package`,
`full-review`, and `install-hooks`.

Example:

```bash
.ai-dev/bin/ai-harness run \
  --repo service \
  --objective "fix service retry bug" \
  --allowed "src/retry.ts" \
  --forbidden "secrets,unrelated services" \
  --verify "npm test -- retry" \
  --stop "contract change required" \
  --command "codex exec 'fix service retry bug'"
```

## Closeout

In the final response, report:

- packet id/path
- D-level
- verification command and result
- role runner result for D2/D3
- G5 review result if run
- any `BLOCKED`, `UNCERTAIN`, `NOT_CHECKED`, or bypassed area
