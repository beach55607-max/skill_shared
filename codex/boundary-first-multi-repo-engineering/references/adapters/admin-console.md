# Adapter: Admin Console

Use this adapter for internal dashboards, privileged review tools, moderation flows, and operator-driven sync or promotion work.

## Ownership

This runtime usually owns:

- operator-facing workflow logic
- review and approval surfaces
- privileged control paths
- admin-side coordination with backend services

## Example Scenario

Example: an admin dashboard adds a new bulk approve or review-promote action.
The admin surface owns the operator workflow and review states, but durable writes, audit behavior, and downstream compatibility may still belong to a backend or storage-owning system.

## Protected Surfaces

Treat these as contract-sensitive:

- role and permission checks
- schema setup or promotion flows
- sync or bulk action payloads
- audit-oriented metadata and review states

## Validation

- start with focused tests for the changed admin flow
- run repo-standard lint and test
- run the repo CI or build bundle when operator-visible behavior changes

## Stop Conditions

Escalate when the task changes:

- permission model assumptions
- bulk-write or destructive actions
- review state semantics
- backend contracts used by admin tooling
