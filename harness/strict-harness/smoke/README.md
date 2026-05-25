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

Future smoke should add nested-repo custody coverage only after that feature
exists in the public profile.
