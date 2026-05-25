# G5 Review Evidence Package

Use this template to bind review claims to actual code evidence.

## Review Binding

- `BASE_SHA`:
- `HEAD_SHA`:
- `scope_files`:
- `actual_diff_files`:
- `full_diff_hash`:
- `embedded_truncated`: false

## Per-File Diff Hashes

| File | Diff Hash |
|------|-----------|
|      |           |

## Reviewer Anti-Trust Rule

The reviewer must not trust the implementer report. Review must inspect the
actual diff, relevant code, and stated spec. Anything not checked must be marked
`NOT_CHECKED`, `UNCERTAIN`, or `OUT_OF_SCOPE`.

## Reviewer Verdict

Allowed statuses:

- `PASS`
- `REJECT`
- `BLOCKED`
- `UNCERTAIN`
