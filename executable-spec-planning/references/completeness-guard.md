# Spec Completeness Guard

> Run BEFORE sending to Checker. Binary PASS/FAIL. Any FAIL = revise.

---

## Layer A: Manual Checklist (25 checks)

### Structure (S) — 10 checks

| # | Check | Verify | ⬜ |
|---|-------|--------|:--:|
| S-1 | In-Scope AND Out-of-Scope exist | Both sections present | |
| S-2 | Negative List covers DB/Rollback/cross-team | ≥3 prohibition entries | |
| S-3 | Decision Lock Table exists | D-1 or "Decision Lock" present | |
| S-4 | Zero TBD in Decision Lock | No "TBD" / "?" in D-N cells | |
| S-5 | ≥2 Phases | "Phase 0"/"Phase 1" present | |
| S-6 | Each Phase has risk rating | 🟢/🟡/🔴 per Phase | |
| S-7 | Each Phase has decidable gate | "Gate:" with number/command | |
| S-8 | Rollback SOP with time budget | "< N min" per Phase | |
| S-9 | Kill Switch exists | Mechanism described | |
| S-10 | Governance Audit (7 items) | 7-row audit table | |

### Content (C) — 5 checks

| # | Check | Verify | ⬜ |
|---|-------|--------|:--:|
| C-1 | Acceptance criteria decidable | Each ⬜ has number/command/threshold | |
| C-2 | No vague phrases | No "works correctly" / "acceptable" / "no regressions" | |
| C-3 | Affected files with change types | Table: path + New/Modify/Delete | |
| C-4 | Files NOT to modify list | Explicit prohibition list | |
| C-5 | Architecture Fit Check recorded | Assumption + validation + result (new features) | |

### CONTRACT (CT) — 6 checks (information output only)

| # | Check | Verify | ⬜ |
|---|-------|--------|:--:|
| CT-1 | INPUT_CONTRACT with fields | Type/source/validation per field | |
| CT-2 | MUST DO preconditions | Table with owner | |
| CT-3 | OUTPUT_CONTRACT exists | Format + examples | |
| CT-4 | APPROVAL_CHECKLIST | Gate items with PASS/FAIL | |
| CT-5 | Full + minimal payload examples | Two examples | |
| CT-6 | Degradation behavior | Missing-input handling | |

### Risk (RK) — 4 checks

| # | Check | Verify | ⬜ |
|---|-------|--------|:--:|
| RK-1 | Permission/security → risk ≥ 🟡 | Cross-ref affected files | |
| RK-2 | DB mutations → human auth | Authorization text present | |
| RK-3 | Fan-in > 5 → in Risks | Import count check | |
| RK-4 | ≥ 3 risk entries | Count rows | |

### Verdict

All PASS → send to Checker. Any FAIL → fix, re-run.

---

## Layer B: Executable Guard Scripts

Automates a subset of Layer A. Implement as shell/node scripts.

### B-1: Decision Lock (covers S-3, S-4)

```bash
grep -P "D-\d+" "$SPEC" | grep -iE "TBD|\?" && echo "FAIL" || echo "PASS"
```

### B-2: Criteria Decidability (covers C-1)

```bash
grep "⬜" "$SPEC" | while read -r line; do
  echo "$line" | grep -qP "\d+|[<>=]+|grep|wc|exit|PASS|FAIL" || echo "FAIL: $line"
done
```

### B-3: Vague Language (covers C-2)

```bash
grep -iP "works correctly|is acceptable|no regressions|looks good" "$SPEC" \
  && echo "FAIL" || echo "PASS"
```

### B-4: Section Existence (covers S-1, S-3, S-5, S-8, S-9, S-10)

```bash
for p in "In Scope" "Out of Scope" "Decision Lock" "Phase [01]" "Rollback" "Kill Switch" "Governance"; do
  grep -qi "$p" "$SPEC" || echo "FAIL: missing $p"
done
```

### B-5: CONTRACT Existence (covers CT-1, CT-3, CT-4)

```bash
for kw in INPUT_CONTRACT OUTPUT_CONTRACT APPROVAL_CHECKLIST; do
  grep -qi "$kw" "$SPEC" "$DIR"/*.md 2>/dev/null || echo "FAIL: missing $kw"
done
```

### B-6: Negative List (covers S-2)

```bash
grep -qiP "Negative List|Prohibition" "$SPEC" || echo "FAIL: no Negative List"
```

### B-7: File-Phase Cross-Reference (covers R12)

```bash
grep -oP '`[^`]+\.(js|ts|mjs)`' "$SPEC" | sort -u | while read -r f; do
  grep -q "$f" <(sed -n '/Phase/,/^---/p' "$SPEC") || echo "WARN: $f not in Phase"
done
```

---

## Implementation Roadmap

1. B-1, B-3, B-4 — pure grep, immediate value
2. B-2, B-5, B-6 — pattern matching
3. B-7 — needs markdown parsing
4. Integrate as `guard-spec-completeness` in CI
