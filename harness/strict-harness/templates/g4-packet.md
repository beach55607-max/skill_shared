# G4 Subtask Execution Packet

Use this template before a non-trivial AI coding subtask starts.

## D-Level

<!-- D0, D1, D2, or D3. D2/D3 require the G4 role loop before PASS closeout. -->

## Objective

<!-- What must be accomplished. -->

## Allowed Files

<!-- Exact files or directories the implementer may touch. -->

## Forbidden Scope

<!-- Files, directories, behaviors, or product areas that are out of scope. -->

## Verification Command

```bash
# command that must be run after implementation
```

## Stop Conditions

<!-- Conditions that require stopping instead of continuing. -->

## Required Roles

D2/D3 packets must record all three role evidence files before `DONE` + `PASS`
closeout:

- `implementer`
- `spec_reviewer`
- `quality_reviewer`

Each role evidence file must use a closed status:

- `PASS`
- `REJECTED`
- `NOT_CHECKED`
- `NEEDS_CONTEXT`
- `BLOCKED`

Only all three `PASS` role evidence files allow a D2/D3 G4 packet to close as
`DONE` + `PASS`. This role loop is internal maker-checker evidence; it does not
replace external G5 review.

## Return Status Contract

Allowed statuses:

- `DONE`
- `DONE_WITH_CONCERNS`
- `NEEDS_CONTEXT`
- `BLOCKED`

`DONE` requires passing verification evidence when the packet is closed.
