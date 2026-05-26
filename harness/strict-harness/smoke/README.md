# Strict Harness Smoke Tests

Smoke verifies install shape and v1 fail-closed behavior:

```bash
.ai-dev/bin/ai-harness smoke
```

Current smoke covers:

- missing G4 packet fields
- `BASE_SHA` / `HEAD_SHA` mismatch
- `scope_files` / `actual_diff_files` mismatch
- reviewer unavailable
- full diff embedding with `embedded_truncated: false`
- command-based reviewer `PASS` normalization
- `full-review` blocks without a reviewer and passes with reviewer `PASS`
- pre-commit hook accepts staged files covered by a `CLOSED` / `PASS` G4 packet
- pre-commit hook rejects staged files outside packet `allowed_files`
- `run` wrapper creates a packet, captures evidence, and closes PASS on success
- pre-commit hook accepts staged changes produced by `run`
- `run` wrapper records failed verification as non-PASS
- D2/D3 G4 packets cannot close `DONE` + `PASS` without all three role evidence files
- D2/D3 G4 packets reject any role evidence status other than `PASS`
- D2/D3 `g4-role-run` blocks when no role command is configured
- D2/D3 `g4-role-run` can generate all required role evidence files
- D2/D3 `g4-role-run` blocks role commands that mutate code while reviewing
- D2/D3 G4 role evidence records and re-checks the source evidence hash
- D2/D3 G4 role evidence must be captured at the same HEAD that G4 closes
- D2 `run` wrapper leaves the packet open instead of fake-closing before role evidence
- D2 `run` wrapper can auto-run role evidence and close when `--role-cmd` is configured
- G5 packages can bind a closed G4 packet and expose its D-level / role-loop state
- nested repo custody keeps `.ai-dev/` artifacts under the workspace root
- nested repo custody binds G5 diffs to the child git repo through `--repo`
- nested repo custody installs and runs the hook against child repo staged files
