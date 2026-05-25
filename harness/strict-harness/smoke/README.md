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

Future smoke should add coverage for hook integration and nested-repo custody
only after those features exist in the public profile.
