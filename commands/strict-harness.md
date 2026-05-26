---
description: Run a task through strict harness
argument-hint: <task description>
allowed-tools: [Read, Glob, Grep, Bash, Edit, MultiEdit, Write]
---

# Strict Harness

The user invoked `/strict-harness` with:

```text
$ARGUMENTS
```

Treat `$ARGUMENTS` as the implementation task.

## Required behavior

Use the local strict harness. Do not execute a D1+ coding task directly.

1. Verify `.ai-dev/bin/ai-harness` exists in the current project, or that
   `ai-harness` is available on `PATH`.
2. If the harness is missing, stop and tell the user to install:

```bash
bash install.sh --profile strict-harness --target /path/to/project
```

3. Classify the task:
   - D0: trivial typo/comment/docs-only; direct edit is allowed only if the
     user did not explicitly request harness.
   - D1: normal single-repo implementation; use `ai-harness run`.
   - D2/D3: contract/auth/schema/permissions/release/packaging/high-risk
     automation; use `ai-harness run` with `--role-cmd`.
4. Build a concrete `ai-harness run` command with:
   - `--objective`
   - `--allowed`
   - `--forbidden`
   - `--verify`
   - `--stop`
   - `--command`
5. If D2/D3, add a role runner command. Example:

```bash
--role-cmd 'codex exec -- "$(cat {prompt})"'
```

6. If no provider CLI is available for `--command`, use manual packet mode:
   `g4-start`, make edits, run verification, `g4-role-run` for D2/D3, then
   `g4-close`.
7. If external review is required, run `full-review` with the closed G4 packet.

## Guardrails

- Do not claim strict-harness PASS without a packet and verification evidence.
- Do not treat role evidence as external G5 review.
- If packet scope, verification command, role evidence, or reviewer command is
  unclear, stop and ask for the missing detail.
- If working in a nested repo, add `--repo <child-repo>` to harness commands.

## Closeout

Report the packet path, D-level, verification result, role runner result for
D2/D3, and G5 result if run.
