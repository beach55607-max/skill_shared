# Strict Harness Smoke Tests

Foundation smoke verifies install shape only:

```bash
.ai-dev/bin/ai-harness smoke
```

Future smoke tests should fail closed for:

- missing G4 packet fields
- truncated review diff
- `BASE_SHA` / `HEAD_SHA` mismatch
- reviewer unavailable
- block scope leaking across unrelated work
