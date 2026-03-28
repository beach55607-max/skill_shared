# Implementation Plan Template

Use this template when the Decision Gate classifies the task as D1, D2, or D3. D0 tasks may skip it.

## When To Use

- **D1**: fill Assumption, Owner, Rollback stance. Other fields optional.
- **D2**: fill all fields. Producer and consumer impact plus validation plan are required.
- **D3**: fill all fields. User confirmation is required before implementation begins.

## Template

```markdown
## Implementation Plan

Severity: D1 / D2 / D3
Assumption: [what behavior is expected to change and why]
Owner: [repo or runtime layer that owns the change]
Consumer: [repo, caller, or downstream system affected]

### Contract Surface
- [request/response shapes, auth headers, schema fields, env bindings, storage keys, or message formats that change]
- [or "none" if no contract surface is affected]

### Security Surface
- [auth, signatures, secrets, durable writes, permissions, or host access affected]
- [or "none" if no security surface is affected]

### Validation Plan
- [specific commands on owner side]
- [specific commands on consumer side, if D2/D3]
- [strongest gate or integration path to run, if available]

### Rollback Stance
- [how to revert if the change fails]
- [or "no durable state change" if not applicable]
- [for D2/D3: staged rollout, dual-format transition, or compatibility window]

### Unknowns
- [anything that could not be verified before implementation]
- [or "none"]
```

## Rules

- Do not start implementation until the plan is stated. For D3, do not start until the user confirms.
- The plan does not need to be long. A D1 plan can be only a few lines.
- If the plan changes during implementation, update it before continuing.
