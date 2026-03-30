# Conflict Resolution

Use this reference when a task touches multiple repos and their local rules or requirements conflict.

## When Conflicts Arise

- Two repos have different validation requirements for the same contract.
- A producer change is needed but the consumer repo has a freeze or restriction.
- Local instructions in two repos give contradictory guidance.
- One repo requires strict backward compatibility while another requires cleaning up deprecated fields.

## Resolution Order

1. **System of record takes priority on contract shape.** The repo that owns persistence, auth, or policy defines the contract. The consumer adapts.
2. **Security constraints take priority over convenience.** If one repo's rules are stricter on auth, permissions, or durable writes, follow the stricter rules.
3. **Owner repo instructions take priority for shared contracts.** If repo-local instructions in two repos conflict on a shared surface, follow the owner repo's instructions and flag the conflict to the user.
4. **Timing conflicts require staged changes.** If one repo is frozen or restricted, prepare the consumer-side code behind a feature flag or version check. Coordinate the producer change for when the freeze lifts.

## When To Escalate

Escalate to the user instead of making a judgment call when:

- Both repos have equally strong claims to ownership of a contract surface.
- The conflict involves auth or security boundaries where a wrong call could cause an outage.
- A staged rollout would require changes to more than two systems.
- The conflict is between a repo-local rule and an explicit user request (the user request wins, but confirm the intent).

## Close-Out For Multi-Repo Conflicts

State clearly:

- Which repo's rules took priority and why.
- What the other repo needs to do to complete the change.
- Any temporary compatibility measures in place (dual-read, feature flags, version checks).
- When the temporary measures should be removed.
