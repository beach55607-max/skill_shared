# G4 Role Evidence

Use this template for D2/D3 G4 role-loop evidence.

## Packet

<!-- G4 packet id or path. -->

## Role

Allowed roles:

- `implementer`
- `spec_reviewer`
- `quality_reviewer`

## Status

Allowed statuses:

- `PASS`
- `REJECTED`
- `NOT_CHECKED`
- `NEEDS_CONTEXT`
- `BLOCKED`

## Evidence File

<!-- Path to the role's evidence file. The file must exist. The CLI records and re-checks its content hash. -->

## Evidence HEAD

The CLI records the review repo `HEAD` when role evidence is created. `g4-close`
requires every role evidence file to match the close HEAD.

## Notes

<!-- Short note explaining what was checked, or why the role did not PASS. -->

Only D2/D3 packets require role evidence. All three roles must be `PASS` before
the packet can close as `DONE` + `PASS`.
