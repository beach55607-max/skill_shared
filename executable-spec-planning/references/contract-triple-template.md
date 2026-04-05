# CONTRACT Triple — {Task Name}

> Required when task involves **information output** or **new data fields/sources**.

---

## Part 1: INPUT_CONTRACT

### MUST DO Preconditions

> Must be completed BEFORE implementation starts. If incomplete, implementation WILL fail.

| # | Precondition | Owner | Status |
|---|-------------|-------|:------:|
| PRE-1 | {what must be true} | {who} | ⬜ |

### Field Specification

| Field | Type | Source | Required? | Validation Rule | Empty Fallback | Anti-Hardcoding |
|-------|------|--------|:---------:|----------------|---------------|-----------------|
| {name} | string | {source} | Yes | {rule} | {default or error} | {strategy} |

### Payload Examples

**Full payload**:
```json
{ "field1": "value", "field2": 42 }
```

**Minimal payload**:
```json
{ "field1": "value" }
```

---

## Part 2: OUTPUT_CONTRACT

### Template Specification

| Template ID | When Used | Format |
|------------|-----------|--------|
| TPL-01 | {condition} | {format} |

### Degradation Behavior

| Missing Input | Output Behavior |
|--------------|----------------|
| {field missing} | {fallback / hide / error} |

---

## Part 3: APPROVAL_CHECKLIST

> Data computation ACs must use BDD Given-When-Then format:
> `Given:` specific data conditions (with field values), `When:` operation, `Then:` expected result (with numbers)
> Non-data ACs must have concrete identification conditions and mechanically verifiable expected results.

| # | Gate Item | PASS Condition | Priority | Status |
|---|----------|---------------|:--------:|:------:|
| I1 | {check} | {decidable condition} | 🔴 MUST | ⬜ |
| I2 | {check} | {condition} | 🟡 SHOULD | ⬜ |

**Gate**: All 🔴 MUST = PASS → proceed. Any 🔴 FAIL → stop.
