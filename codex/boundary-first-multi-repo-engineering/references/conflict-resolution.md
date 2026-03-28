# Conflict Resolution

Use this reference when a task touches multiple repos or runtimes and their local rules or requirements conflict.

## When Conflicts Arise

- Two systems have different validation requirements for the same contract.
- A producer change is needed but the consumer system has a freeze or restriction.
- Local instructions in two systems give contradictory guidance.
- One system requires strict backward compatibility while another wants to remove deprecated fields.

## Resolution Order

1. **System of record takes priority on contract shape.** The system that owns persistence, auth, or policy defines the contract. The consumer adapts.
2. **Security constraints take priority over convenience.** If one system's rules are stricter on auth, permissions, or durable writes, follow the stricter rules.
3. **Owner instructions take priority for shared contracts.** If local instructions conflict on a shared surface, follow the owner system's instructions and flag the conflict to the user.
4. **Timing conflicts require staged changes.** If one side is frozen or restricted, prepare the consumer behind a feature flag, version check, or compatibility path until the producer can move.

## When To Escalate

Escalate to the user instead of making a judgment call when:

- Both systems have equally strong claims to ownership of a contract surface.
- The conflict involves auth or security boundaries where a wrong call could cause an outage.
- A staged rollout would require changes to more than two systems.
- The conflict is between a local rule and an explicit user request.

## Close-Out For Multi-System Conflicts

State clearly:

- which system's rules took priority and why
- what the other system still needs to do
- any temporary compatibility measures in place
- when those temporary measures should be removed
