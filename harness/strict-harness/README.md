# Strict Harness Profile

`strict-harness` is an optional workflow profile for teams that want a local,
machine-checkable guardrail around AI coding work.

It does not replace the skills in this toolkit. It adds a project-local runtime
under `.ai-dev/` so agents can leave packets, review evidence, and regression
smoke output in predictable locations.

## Install

```bash
bash install.sh --profile strict-harness --target /path/to/project
```

This creates:

```text
.ai-dev/
  bin/ai-harness
  runtime/
  gate-artifacts/
  harness/strict-harness/
```

Add `.ai-dev/bin` to `PATH`, or run the launcher by full path:

```bash
/path/to/project/.ai-dev/bin/ai-harness smoke
```

## Foundation Scope

This first public profile only installs the skeleton:

- project-local runtime and artifact directories
- `ai-harness smoke`
- templates for future G4 packets and G5 review packages
- explicit stubs for G4/G5 commands that are not implemented yet

The strict behavior will be added in later PRs. Until then, commands such as
`g4-start` and `g5-package` fail loudly instead of pretending the task passed.

## Non-Goals

This public profile does not depend on any private workspace:

- no company-specific paths
- no MCP Memory requirement
- no private runtime directory
- no global block board
- no nested-repo custody rules in v1
