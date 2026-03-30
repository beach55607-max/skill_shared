# Code Quality Reference

## Core Principle

High-quality code is not "zero duplication at all costs." It means clear boundaries, visible dependencies, credible validation, and failures that can be contained.

## CQ-1 Shared Abstraction Threshold

- Extract shared code only when there are **at least 2 stable consumers** or an **explicit variation point**.
- If there is only one caller or the behavior is still changing quickly, local duplication is often safer than a bad abstraction.

## CQ-2 Semantic Duplication Stance

- Do not merge semantically different paths just to satisfy DRY.
- Intentional duplication is allowed, but the spec must say it is a deliberate tradeoff.

## CQ-3 Dependency Visibility

- When introducing a cross-module dependency, the spec must state:
  - where the dependency appears
  - which phase introduces it
  - who owns the dependency
- Hidden dependencies are not allowed.

## CQ-4 Testability Boundary

- Boundary layers (Sheet / DB / KV / API / router / auth) should be validated with real schema, real data shape, or golden tests whenever possible.
- Pure internal logic may use mocks, but mock format must come from real data, not guesses.

## CQ-5 Observability / Failure Containment

- New behavior that can fail should define:
  - normal vs debug-only logging
  - timeout / retry / fallback stance
  - kill switch or rollback path
- If not applicable, mark `N/A` and explain why.

## Allowed Strictness Markers

- `N/A`: not applicable for this task
- `UNKNOWN`: evidence missing, do not guess
- `ESCALATE`: requires Final Authority or upstream owner decision

A strict version should demand grounded decisions, not fabricated completeness.
