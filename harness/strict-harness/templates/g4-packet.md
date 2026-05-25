# G4 Subtask Execution Packet

Use this template before a non-trivial AI coding subtask starts.

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

## Return Status Contract

Allowed statuses:

- `DONE`
- `DONE_WITH_CONCERNS`
- `NEEDS_CONTEXT`
- `BLOCKED`

`DONE` requires passing verification evidence when the packet is closed.
