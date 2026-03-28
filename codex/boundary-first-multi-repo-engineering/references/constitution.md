# Constitution

Use this reference to keep the skill aligned with the local codebase instead of replacing it.

## Purpose

This skill exists to improve engineering judgment for multi-repo and multi-runtime work.
It should tighten boundary reasoning, not override repo-local truth.

## Order Of Authority

Follow this order:

1. Explicit user request
2. Repo-local instructions such as `AGENTS.md`, specs, and guardrails
3. Executable checks such as tests, gates, builds, and CI definitions
4. This skill's workflow and references

If local rules conflict with this skill, follow the local rules and explain the conflict.

When two touched systems have local rules that conflict with each other, prefer the system-of-record's rules for shared contract behavior, keep the consumer compatible where possible, and escalate breaking tradeoffs to the user.

## Boundary-First Principle

Before editing, identify:

- the system of record
- the caller or consumer
- the contract boundary between them
- the high-risk surfaces affected by the change

Do not start implementation while the owner boundary is still implicit.

## Protected Surfaces

Treat the following as design-time boundaries:

- auth or signature behavior
- route names and request or response shapes
- schema fields and null semantics
- env bindings and feature flags
- storage keys and durable writes
- permissions, host access, or message channels
- observability fields that downstream systems rely on

## Finish Criteria

A task is not done just because code compiles.
Finish only when owner, risk surface, validation evidence, and residual risk are clear enough for another engineer to review quickly.
