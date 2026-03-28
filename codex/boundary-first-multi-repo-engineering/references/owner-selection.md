# Owner Selection

Use this reference when a short user request does not name the target repo or runtime clearly.

## Primary Signals

- Prefer an explicit path or filename when the user gives one.
- Prefer the repo of the file already open in the IDE when the task names that file.
- Prefer the system that owns validation, persistence, auth, or runtime policy over the caller that only assembles inputs.
- Prefer the repo named in the closest spec when the request is phrased by phase or feature instead of filename.

## Decision Order

Use this order before relying on naming clues:

1. If one system owns persistence, auth, or schema enforcement, start there.
2. If one system only assembles inputs and another validates or stores them, the validating or storing system owns the shared contract.
3. If the wire format does not change and only user interaction, rendering, or local state changes, the frontend or caller usually owns the task.
4. If the task changes operator workflows, review states, or privileged bulk actions, the admin surface usually owns the workflow while the backend still owns the contract.
5. If no adapter matches well, run the full preflight anyway, state the assumed system type, and document why no adapter fit cleanly.

## Fast Ownership Map

### Backend Service

Typical owner of:

- API routes
- persistence
- validation and policy enforcement
- webhook handling
- queue or worker execution

Secondary clues:

- `route`
- `handler`
- `service`
- `repository`
- `database`
- `auth`
- `queue`
- `webhook`

### Frontend App

Typical owner of:

- page flows
- client-side composition
- UI state
- frontend environment wiring
- API client usage

Secondary clues:

- `page`
- `component`
- `store`
- `view`
- `form`
- `Vite`
- `Next.js`
- `React`

### Admin Console

Typical owner of:

- back-office operations
- schema setup or review flows
- moderation or promotion screens
- privileged operator actions

Secondary clues:

- `admin`
- `review`
- `promote`
- `moderation`
- `backoffice`
- `dashboard`

### Automation Bot Or Sync Worker

Typical owner of:

- scheduled sync
- bot or chat workflows
- ETL or batch jobs
- spreadsheet or document automation

Secondary clues:

- `cron`
- `sync`
- `bot`
- `worker`
- `sheet`
- `batch`
- `job`

### Browser Extension

Typical owner of:

- manifest permissions
- content scripts
- background logic
- extension storage
- message passing between extension contexts

Secondary clues:

- `manifest.json`
- `content script`
- `background`
- `service worker`
- `storage`
- `host_permissions`

## When Several Systems Are Involved

Use this order:

1. Identify the system of record.
2. Identify the producer that defines the contract.
3. Identify the consumer that will break if the contract changes.
4. Read the local rules for every touched system before editing.

If no listed system fits well, choose the system that owns validation, persistence, or runtime policy and record the mismatch explicitly in the final summary.

## First Files To Read

- `AGENTS.md`
- `package.json`
- the nearest spec or design note
- the current owner file for routes, schema, or config
- the closest tests that already exercise the area
