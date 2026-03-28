# Adapter: Backend Service

Use this adapter for API routes, auth, persistence, validation, queue handlers, or webhook work.

## Ownership

This runtime usually owns:

- request validation
- policy enforcement
- persistence
- shared backend contracts
- privileged write behavior

## Example Scenario

Example: a frontend wants to add a new request field or change a field from string to array.
Even if the first visible edit is in a mapper or API client, this adapter becomes primary when the backend route owns validation, defaults, persistence, or compatibility rules.

## Protected Surfaces

Treat these as contract-sensitive:

- routes and error envelopes
- auth headers, tokens, or signatures
- schema fields and null semantics
- storage keys and durable writes
- metadata that downstream systems persist or parse

## Validation

- start with route or handler-focused tests
- run repo-standard lint and test
- run the stronger gate or build path when auth, persistence, or shared contracts change

Do not stop at caller-side validation when the backend enforces schema, auth, or storage behavior.

## Stop Conditions

Escalate when the task changes:

- auth or signature behavior
- destructive write flows
- schema migrations
- route names consumed by other systems
