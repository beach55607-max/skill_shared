# Adapter: Automation Bot Or Sync Worker

Use this adapter for scheduled jobs, ETL pipelines, bots, chat workflows, and spreadsheet or document sync automation.

## Ownership

This runtime usually owns:

- orchestration and scheduling
- transforms between external and internal formats
- retry and idempotency behavior
- automation-side diagnostics and job outcomes

## Example Scenario

Example: a scheduled sync job pulls rows from an external source and writes normalized records downstream.
This adapter is primary when the hard part is transform correctness, retry safety, idempotency, or batch-side effects rather than a single UI or API surface.

## Protected Surfaces

Treat these as contract-sensitive:

- external API request and response mapping
- sync payload formats
- retry semantics
- batch write behavior
- message or document metadata that affects downstream processing

## Validation

- start with transform or parser-focused tests
- use dry-run or fixture-based validation when available
- run repo-standard lint and test
- add integration checks when external-system behavior is part of the contract

## Stop Conditions

Escalate when the task changes:

- idempotency assumptions
- destructive sync behavior
- retry policy with side effects
- external credentials or privileged scopes
