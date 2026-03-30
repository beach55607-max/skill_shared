# Calibration Cases — Full Details

Read these before your first adversarial review. All are **real incidents where AI reviewers gave wrong answers**, anonymized to remove internal details.

---

## Case 1: Enum Case Mismatch (JOIN Key Mismatch)

- **AI Said**: "Adapter returns raw data, code correctly compares status field"
- **Reality**: Database stores `'ACTIVE'` (uppercase), code compares against `'active'` (lowercase) → all items misclassified as inactive
- **Root Cause**: Adapter does raw pass-through with no normalization layer. Test mock used `'active'` (matching code expectation), so unit tests PASS, but mock doesn't match real database values
- **Lesson**: **Test mock values must reflect production data format, not code expectations.** Mock matching code ≠ mock matching production data

**What the reviewer should have done**: Asked "what does the real database store for this field?" instead of trusting mock data format.

---

## Case 2: Same Field Name, Different Semantics

- **AI Said**: "New data path can reuse existing query logic from cache layer"
- **Reality**: Cache stores pre-computed materialized view (output of calculation). New data source stores raw input data. Same field name (`availableQty`), completely different meaning → returns stale/wrong values
- **Root Cause**: Reviewer saw same field name and assumed same semantics. Didn't trace the data lineage from source → transform → consumer
- **Lesson**: **Same field name in different data sources can have completely different definitions.** Must trace data from source → transform → consumer

**What the reviewer should have done**: Asked "is this field raw input or computed output in each data source?"

---

## Case 3: Tracing Depth Insufficient (False Positive)

- **AI Said**: "`|| 'DEFAULT_TYPE'` is a hardcoding risk that should be removed"
- **Reality**: Upstream adapter layer already handles the mapping correctly. `|| 'DEFAULT_TYPE'` is purely a defensive fallback that never fires in production
- **Root Cause**: Reviewer looked at one layer of code and concluded. Didn't trace upstream to see the adapter already handles it
- **Lesson**: **When you see a suspicious pattern, trace at least one layer UP and one layer DOWN before concluding.** Otherwise false positives waste fix time

**What the reviewer should have done**: Followed the call chain upstream to see where the value actually originates.

---

## Case 4: Log Exists ≠ Handling Exists

- **AI Said**: "Consistency check for batch_id is implemented"
- **Reality**: Code only `console.warn`s the mismatch, then continues using the mismatched data to serve the user. Spec required a fallback to cached data on mismatch. Log exists but no branching logic
- **Root Cause**: `console.warn` was treated as "handling." But warn + continue ≠ warn + fallback
- **Lesson**: **"Has log" ≠ "Has handling."** Fallback paths require code path evidence: if/else/return/throw after the log

**What the reviewer should have done**: Checked what happens on the line AFTER the log statement. Is there a branch, or does execution continue?

---

## Case 5: Platform Consistency Model Assumption

- **AI Said**: "After updating cache value, next read will return the new value"
- **Reality**: Platform uses eventually consistent caching. Edge cache with 24h TTL is NOT invalidated by store writes. Old values continue being served from other edge locations for up to 24 hours
- **Root Cause**: AI assumed strong consistency (write → immediate read-your-writes). Platform actually has eventual consistency + independent edge cache layer
- **Lesson**: **Platform consistency model must be verified, not assumed.** Different platforms (Cloudflare KV, Redis Cluster, DynamoDB, GAS CacheService) have different consistency guarantees

**What the reviewer should have done**: Checked the platform documentation for consistency model and cache invalidation behavior.

---

## Case 6: Spec Describes Intent, Not Implementation

- **AI Said**: "Spec says feature X is filtered out, so the code handles it"
- **Reality**: Code has no such filter. Spec described what SHOULD happen, not what HAS been implemented. Reviewer used spec to confirm code instead of using code to verify spec
- **Root Cause**: Causal reversal — reviewer read spec first, then looked at code seeking confirmation instead of seeking contradiction
- **Lesson**: **Always verify code against spec, never spec against code.** PM decision documents describe intent ("should do"), not state ("has done")

**What the reviewer should have done**: Searched the codebase for the actual filter function and verified its implementation independently.

---

## Case 7: Test Mock Doesn't Validate SQL Semantics

- **AI Said**: "All tests pass, conflict handling logic is correct"
- **Reality**: Test framework mocks the database layer, only validating JavaScript logic. PR changed INSERT to `ON CONFLICT(user_id) DO NOTHING`, tests PASS. But production database's UNIQUE constraint is on `(code, role)`, not `(user_id)` → data silently lost
- **Root Cause**: Test mocks validate "does the JS code call the right functions with the right arguments" but NOT "does the SQL do what you think against the real schema"
- **Lesson**: **Test mocks don't validate SQL semantics.** Schema-affecting changes (ON CONFLICT, ALTER TABLE, CREATE INDEX) must be verified against production schema, not just mock PASS

**What the reviewer should have done**: Checked the actual database schema (`PRAGMA table_info` / `\d table` / schema migration files) to verify constraint names match.

---

## Case 8: Deployment State Cannot Be Trusted

- **AI Said**: "Function is updated, just re-execute"
- **Reality**: Editor/IDE shows new code, but runtime environment is executing cached old version. Deploy command was silently skipped or succeeded but runtime cache wasn't refreshed
- **Root Cause**: Assumed that seeing new code in editor = new code running in production. Many platforms (GAS, serverless, edge workers) have deployment caches that can desync from source
- **Lesson**: **Deployment state must be verified at runtime, not assumed from editor state.** Add version markers (timestamp log, version endpoint) to confirm what's actually running

**What the reviewer should have done**: Verified deployment by checking runtime output (version log, health endpoint) rather than trusting the editor view.

---

## Case 9: PowerShell UTF-8 Corruption

- **AI Said**: "Use PowerShell `-replace` to batch-modify file contents containing non-ASCII characters"
- **Reality**: PowerShell `-replace` + `Set-Content` default encoding is NOT UTF-8. Non-ASCII characters (CJK, accented, emoji) get corrupted into mojibake
- **Root Cause**: AI assumed PowerShell string operations preserve encoding. PowerShell's default output encoding varies by version and locale, and `Set-Content` does not default to UTF-8 on all systems
- **Lesson**: **Any file operation involving non-ASCII characters must NOT use PowerShell inline commands.** Use file-based scripts with explicit encoding (e.g., Node.js `fs.readFileSync/writeFileSync` with `'utf8'`, Python `open(..., encoding='utf-8')`)

**What the reviewer should have done**: Asked "what encoding does this tool use by default?" before approving any file-write operation on non-ASCII content.

---

## Case 10: Date Timezone Offset in Server-Side JavaScript

- **AI Said**: "`val.toISOString().split('T')[0]` correctly converts Date to YYYY-MM-DD"
- **Reality**: Server-side runtime returns Date objects in local timezone (e.g., UTC+8). `toISOString()` converts to UTC. A midnight date `2026-02-01 00:00 +08:00` becomes `2026-01-31T16:00:00.000Z`, producing `2026-01-31` — **date is off by one day**
- **Root Cause**: Reviewer checked that `instanceof Date` is correct and the split logic is standard. Didn't question "what timezone is this Date in?" Platform timezone behavior is an implicit assumption
- **Lesson**: **Date → string conversion must account for timezone.** In server-side environments, use explicit timezone-aware formatting (e.g., `Intl.DateTimeFormat`, `Utilities.formatDate(date, 'Asia/Taipei', 'yyyy-MM-dd')`) instead of `toISOString()`

**What the reviewer should have done**: Asked "what timezone is this Date object in? Will UTC conversion shift the date?"

---

## How to Add Your Own Cases

Track incidents where an AI reviewer gave a wrong answer and add them here:

```markdown
### Case N: [Short Title]

- **AI Said**: [direct quote of what the AI claimed]
- **Reality**: [what actually happened, with specifics]
- **Root Cause**: [why the AI got it wrong]
- **Lesson**: **[one-line principle in bold]**

**What the reviewer should have done**: [correct review approach]
```

The best cases come from production incidents, not hypothetical scenarios.
