# Owner Selection

Use this reference when a short user request does not name the target repo or runtime clearly.

## Decision Tree

### Step 1: Explicit Path

Did the user name a specific file or path?

- YES: the owner is the repo containing that file. Go to Step 4.
- NO: go to Step 2.

### Step 2: Responsibility Check

Use this order before relying on domain clues:

1. If one system owns persistence, auth, or schema enforcement, start there.
2. If one system only assembles inputs and another validates or stores them, the validating or storing system owns the shared contract.
3. If the wire format does not change and only user interaction, rendering, or local state changes, the frontend or caller usually owns the task.
4. If the task changes operator workflows, review states, or privileged bulk actions, the admin surface usually owns the workflow while the backend still owns the contract.

If the answer is clear, go to Step 4. Otherwise, go to Step 3.

### Step 3: Domain Match

Match by task domain to select an adapter:

- API routes, handlers, webhooks, queues, persistence -> backend-service adapter
- Pages, components, UI state, forms, client-side composition -> frontend-app adapter
- Operator workflows, moderation, promotions, review flows -> admin-console adapter
- Scheduled jobs, ETL, bots, sync, spreadsheet automation -> automation-bot adapter
- Manifest, content scripts, extension storage, background logic -> browser-extension adapter
- None of the above -> read `fallback-adapter.md`

### Step 4: Identify Consumers

For the identified owner:

1. Which other systems call, depend on, or parse output from this owner?
2. Read local instructions for every touched system before editing.
3. If the task crosses a contract boundary, also read `cross-boundary-contracts.md`.

## Ambiguous Ownership

When ownership is ambiguous, prefer the system that owns validation, persistence, auth, or policy. The system that enforces rules is the owner; the system that assembles inputs is the caller.

## When Several Systems Are Involved

1. Identify the system of record.
2. Identify the producer that defines the contract.
3. Identify the consumer that will break if the contract changes.
4. Read the local rules for every touched system before editing.

If two systems have conflicting rules, read `conflict-resolution.md`.

## First Files To Read

- `CLAUDE.md` or `AGENTS.md` (repo-local instructions)
- `package.json` or equivalent project manifest
- The nearest spec or design note
- The current owner file for routes, schema, or config
- The closest tests that already exercise the area
