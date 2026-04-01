# AI Engineering Skills

給 AI coding agent 用的工程治理 skill（Claude Code、Codex、ChatGPT 皆適用）。

核心哲學：**修 bug 不算完成，必須留下下次能擋住同類錯誤的 gate。** 每一次錯誤都應該沉澱成新的防線，讓系統越做越強。

四套 skill 覆蓋 AI 輔助開發的完整生命週期——從發想到交付，每一步都有 stakeholder checkpoint，形成閉環：

```text
  發想            →     決定            →        規劃          →       施工         →       驗證
 ┌──────────────┐  ┌──────────────┐   ┌──────────────────┐   ┌──────────────┐   ┌──────────────────┐
 │ Brainstorming │  │ Boundary-     │   │ Executable Spec  │   │ (你的 AI     │   │ Adversarial Code │
 │ Capture       │─>│ First         │──>│ Planning         │──>│  agent)      │──>│ Review           │
 │ (cw-*)        │  │ Engineering   │   │                  │   │              │   │                  │
 └──────────────┘  └──────────────┘   └──────────────────┘   └──────────────┘   └──────────────────┘
  什麼方向？        誰負責？             要做什麼？               改 code            AI 做對了嗎？
  合理嗎？          什麼會壞？           驗收標準是什麼？                            用證據證明。
  資料從哪來？      怎麼回滾？           不做什麼？

       ▲                                                                              │
       │                    Regression Gate 回饋迴路                                    │
       └────────────────── 驗證 / Incident 發現 → 沉澱為新 gate ──────────────────────┘
```

**v2025.04.01 新增**: Brainstorming Capture skill（含 Discovery Gate）— 讓 AI 在動手前先把方向想清楚，stakeholder 確認後才進入工程。

---

## 什麼時候用哪一套 — 決策樹

```text
你有一個任務
│
├─ 是瑣碎修改？（typo、comment、排版）
│  └─ 直接做，不需要 skill。(D0)
│
├─ 是新功能或新產品？方向還沒確定？
│  └─ 是 → 先用 Brainstorming Capture
│         多方向發想，stakeholder 確認方向後再進工程。
│         如果概念已確定，可跳過直接進 Boundary-First 或 Spec Planning。
│
├─ 會跨 repo、跨服務、或改到 contract？
│  └─ 是 → 先用 Boundary-First
│         確認 owner、consumer、contract 風險、rollback 策略。
│         再決定是否也需要 Spec Planning 和/或 Adversarial Review。
│
├─ 需要先寫 spec 再施工？
│  （新功能、遷移、重構、多 phase 工作）
│  └─ 是 → 用 Executable Spec Planning
│         寫出有 Decision Lock、驗收標準、scope 邊界的 spec。
│         如果跨 repo，可搭配 Boundary-First。
│
├─ 在審查 AI 產出的 code、PR、或 spec？
│  └─ 是 → 用 Adversarial Code Review
│         選模式（Code / Spec / Release Gate）
│         和強度（L1 Fast / L2 Standard / L3 Adversarial）。
│
└─ 以上都有？
   └─ 組合使用。典型全生命週期：
      Boundary-First (決定) → Spec Planning (規劃) → AI 施工 → Adversarial Review (驗證)
```

### 常見組合

| 場景 | 使用哪幾套 | 為什麼 |
|------|-----------|--------|
| 小 bug fix，單 repo | Adversarial Review (L1 Fast) | 驗證修復正確 + 確認 regression gate (HR-8) |
| 新功能，方向未定 | Brainstorming → Spec Planning → Adversarial Review (L2) | 先發想再規劃再驗證 |
| 新功能，方向已定 | Spec Planning → Adversarial Review (L2) | 先規劃再驗證 |
| Schema 遷移，跨 repo | Boundary-First → Spec Planning → Adversarial Review (L3) | 完整生命週期 |
| 全新產品，跨 repo | Brainstorming → Boundary-First → Spec Planning → Adversarial Review (L3) | 完整四層 |
| 審查別人的 PR | Adversarial Review (L2 Code Mode) | 用證據驗證 |
| 審查設計文件 | Adversarial Review (L2 Spec Mode) | 檢查完整性和一致性 |
| 部署前驗證 | Adversarial Review (L3 Release Gate) | 完整 execution-layer audit |

---

## End-to-End 示例：完整生命週期（10 Gate 閉環）

> 場景：為 SaaS 平台建立「內部知識庫搜尋系統」。使用者可以用自然語言搜尋公司的政策文件、操作手冊、FAQ。涉及新 API endpoint、搜尋索引、和前端搜尋介面。從零開始，方向未定。

### G-1: Discovery（Brainstorming Capture）

```text
Stakeholder: "我想讓員工可以用自然語言搜尋公司內部的文件，
             不用記文件編號或精確關鍵字。"

Agent 輸出：

📋 GATE G-1 Discovery
- 功能方向:
  1. 全文搜尋（Elasticsearch / Meilisearch，keyword + fuzzy match）
  2. 語意搜尋（embedding + vector DB，理解「意思」不只是「字面」）
  3. 混合式（keyword 先篩 + embedding 重新排序）
- 雙路互博: Agent A 提 3 方向 / Agent B 提 2 方向，交集為混合式
- 開放問題:
  - 文件格式？（PDF / Word / Markdown / 混合）
  - 搜尋結果要不要顯示相關段落摘要？
  - 權限控制？（全員可搜 vs 依部門分權）

🚦 Stakeholder REVIEW — APPROVED / REVISE / REJECT
```

Stakeholder: **APPROVED**（選方向 3 混合式，需顯示段落摘要，第一版先不做權限控制）

### G-2: Concept Critique（評估可行性）

```text
Agent 對選定方向做 5 項必檢：

📋 GATE G-2 Concept Critique
- 業務合理性: PASS — 內部搜尋降低人工查找時間，ROI 明確
- 功能完整性: BLOCKED — 缺「搜尋無結果」的處理（要顯示什麼？推薦相關分類？）
- UX 合理性: BLOCKED — 如果搜尋延遲 > 3 秒，使用者會回去用舊的文件編號查找
- 技術可行性: PASS — embedding model 可用 API，不需自建 GPU
- 資料來源: PASS — 內部文件已有結構化儲存（SharePoint），可批次匯入

⚠️ CHALLENGE: 混合式搜尋的排序公式是什麼？keyword score 跟 semantic score 怎麼加權？
             權重設錯會讓「精確查找」反而排在後面。

🚦 Stakeholder REVIEW — APPROVED / REVISE / REJECT
```

Stakeholder: **REVISE**（加「無結果」引導、設定 2 秒 SLA、加權公式先用 keyword 70% + semantic 30%）

Agent 修正後重新提交 G-2 → Stakeholder **APPROVED**

### G-3: Canonicalize（定稿）

```text
Agent 把 G-1 發想 + G-2 評估結果寫成 canonical spec：

📋 GATE G-3 Canonicalize
- Canonical doc: knowledge-search-spec-v1.md
- 資料來源: SharePoint 批次匯入 → 搜尋索引（不 hardcode 文件內容）
- Scope In: 混合搜尋、段落摘要、無結果引導、2 秒 SLA
- Scope Out: 權限控制（v2）、自動文件更新（v2）、多語言（v2）

🚦 Stakeholder REVIEW — APPROVED / REVISE / REJECT
```

Stakeholder: **APPROVED**

### G0: Classify + Preflight（Boundary-First）

```text
📋 GATE G0 Classify + Preflight
- D-level: D2（跨 repo contract — search API + frontend consumer + indexing pipeline）
- Owner: backend-service repo, search layer
- Consumer: frontend-app repo, admin indexing tool
- Protected surfaces: 搜尋索引 schema、API response shape、embedding model contract
- Rollback: 索引可重建，feature flag 可關閉搜尋功能回到舊的文件列表頁

🚦 Stakeholder REVIEW — APPROVED / OVERRIDE to D[N]
```

Stakeholder: **APPROVED D2**

### G1: Architecture Fit

```text
📋 GATE G1 Architecture Fit
- Core assumption: 混合搜尋（keyword + embedding），不需即時索引
- Validation: G-2 確認批次匯入足夠（文件更新頻率低，每日同步）
- Data layer: 搜尋索引由 indexing pipeline 建立，不 hardcode

🚦 Stakeholder REVIEW — APPROVED / REVISE
```

Stakeholder: **APPROVED**

### G2: Spec Lock（Executable Spec Planning）

```text
Spec v1 產出（節錄）：

- Decision Lock Table:
  | 決策               | 選擇                     | 理由                    |
  |--------------------|-------------------------|------------------------|
  | 搜尋引擎            | Meilisearch + OpenAI    | 開源 + 可控成本          |
  | 加權公式            | keyword 0.7 + semantic 0.3 | G-2 stakeholder 決定  |
  | 摘要長度            | 最多 200 字 highlight    | UX research 建議        |

- 驗收標準（BDD）：
  Given: 文件庫含 500 篇政策文件
  When:  使用者搜尋「出差報銷流程」
  Then:  前 3 筆結果含「差旅費報銷管理辦法」，回應 < 2 秒，
         每筆結果含相關段落摘要（≤ 200 字，關鍵字高亮）

- Checker review: 1 blocker resolved → UNBLOCKED

📋 GATE G2 Spec Lock
- Spec: v1.2 (post-checker)
- Decision Lock: all locked
🚦 Stakeholder (Final Authority): GO
```

### G3: Review Mode Lock

```text
📋 GATE G3 Review Mode
- Risk: D2 → Mode A forced（dual AI review）
🚦 Stakeholder: APPROVED
```

### G4: Implementation Done

```text
AI agent 根據 spec 實作。跑 gate:pr。

📋 GATE G4 Implementation
- Gate: gate:pr PASS (backend) + build PASS (frontend) + indexing pipeline test PASS
- Files: 12 files changed
🚦 Stakeholder: APPROVED
```

### G5: Adversarial Review（Full Review Pipeline）

```text
Phase 2 (Claude) + Phase 3 (Codex) 並行：

Claude findings:
  F-01 (🔴): 搜尋 API 沒有 rate limit，惡意使用者可以 DDoS 搜尋索引
  F-02 (🟡): embedding API 呼叫沒有 timeout，失敗時 fallback 到純 keyword
             但 fallback 分支沒有被測試覆蓋

Codex findings:
  F-01 (🔴): 同上 rate limit 問題（共識 = 高信度，必修）
  F-03 (🟡): 摘要 highlight 邏輯在 CJK 字元斷詞有 bug

修復 F-01 + F-02 + F-03 → Phase 5 regression scan → 0 新問題

📋 GATE G5 Adversarial Review
- Claude: 1 P0 (fixed), 1 P1 (fixed)
- Codex: 1 P0 (fixed), 1 P1 (fixed)
- Consensus: F-01 rate limit (fixed)
🚦 Stakeholder: APPROVED
```

### G6: Close-Out

```text
📋 GATE G6 Close-out

## Phase Registry
| Gate | Phase | Status | Evidence | Stakeholder ACK |
|------|-------|--------|----------|-----------------|
| G-1 | Discovery | PASS | 3 directions explored | APPROVED |
| G-2 | Concept Critique | PASS | 5/5 checked, 2 REVISED | APPROVED |
| G-3 | Canonicalize | PASS | knowledge-search-spec-v1.md | APPROVED |
| G0 | Classify | PASS | D2 confirmed | APPROVED |
| G1 | Arch Fit | PASS | hybrid search, batch index | APPROVED |
| G2 | Spec Lock | PASS | spec-v1.2, 0 blockers | GO |
| G3 | Review Mode | PASS | Mode A (dual) | APPROVED |
| G4 | Implementation | PASS | gate:pr PASS ×3 | APPROVED |
| G5 | Review | PASS | 1 P0 + 2 P1 fixed | APPROVED |
| G6 | Close-out | PASS | Registry complete | APPROVED |

## Governance Audit
| # | Principle | Status |
|---|-----------|--------|
| GA-1 | Measurable | ✅ (< 2s SLA, top-3 precision) |
| GA-2 | Verifiable | ✅ (BDD test + load test) |
| GA-3 | Auditable | ✅ (test suite re-runnable) |
| GA-4 | CONTRACT | ✅ (search API response schema) |
| GA-5 | Rollback SOP | ✅ (feature flag + index rebuild) |
| GA-6 | Kill Switch | ✅ (feature flag: search_enabled) |
| GA-7 | Cost Cap | ✅ (embedding API < $50/month) |
| GA-8 | Phase Compliance | ✅ (10/10 Gates PASS) |

Regression Gate: rate limit integration test + CJK highlight edge case test
Residual risk: 多語言搜尋 (P2, deferred to v2)

🚦 Stakeholder SIGN-OFF: APPROVED
```

### 對比：如果沒有 UGP 會怎樣？

```text
真實案例：AI agent 在概念評估階段自行跳過，一句話就直接開始寫 code。結果：
- 沒考慮「搜尋無結果」的 UX → 使用者看到空白頁就離開（G-2 功能完整性該攔住）
- 搜尋延遲 5 秒但沒人測過 SLA → 使用者回去用舊系統（G-2 UX 合理性該攔住）
- 加權公式隨意設定 → 精確查找反而排在後面（G-2 CHALLENGE 該挑戰的）
- 7 輪 stakeholder 手動修正，其中 4 輪本應在概念評估就被發現

UGP 的價值：stakeholder 在 G-2 花 10 分鐘 REVISE，省掉後面 2+ 小時的迭代。
```

---

## 這個 repo 有四套 skill

**Skill 0: Brainstorming Capture (cw-brainstorming)** `v2025.04.01 NEW` — 讓 AI agent 在動手前先把方向想清楚。用最小紀錄捕捉發想，不過度展開、不混淆來源、不限制創意自由。產品/功能任務含 Discovery Gate (G-1)，stakeholder 確認方向後才能進入工程。

**Skill 1: Boundary-First Engineering** — 讓 AI agent 在改 code 之前，先把 owner、boundary、contract、rollback 想清楚。適合多 repo、跨服務、跨 runtime 的工程任務。

**Skill 2: Executable Spec Planning** — 讓 AI 從模糊需求走到可執行規格書（spec），確保每個影響施工的決策都有主人、有紀錄、有驗證方式。含 Evidence Block、BDD 驗收標準、Bug-to-Gate 閉環。適合新功能、遷移、重構、任何要交給 AI agent 執行的任務。

**Skill 3: Adversarial Code Review** — 讓 AI reviewer 用證偽法審查 code 和規格書，而不是表面確認「看起來對」。從 30+ 個 AI reviewer 真實判斷錯誤的案例中提煉出方法論。包含 13 個真實攔截案例的 before/after 對照。

### 為什麼需要這四套

因為 AI coding 最昂貴的失敗，不是語法錯誤：

- **Brainstorming Capture 防的是**：AI 跳過發想直接動工、stakeholder 沒確認方向就寫 code、功能缺陷到 deploy 後才發現
- **Boundary-First 防的是**：owner 判錯、contract 判錯、rollback 沒想、validation 驗錯地方
- **Spec Planning 防的是**：spec 假完整、AI 超出 scope 自主決策、架構方向選錯但 gate 全過、AI 幻覺（沒讀真實資料就動手）、bug 修了但沒留防線
- **Adversarial Review 防的是**：AI reviewer 橡皮圖章（「看起來對」就 PASS）、mock PASS ≠ production PASS、log 存在 ≠ 處理存在、平台特性假設不驗證

這四套可以獨立使用，也可以組合。完整四層流程：先用 Brainstorming 發想方向 → Boundary-First 判斷 owner 和風險 → Spec Planning 寫出可執行的規格書 → Adversarial Review 驗證 AI 的實作。入口由 stakeholder 決定，可以從任一層開始。

### 適合誰

- 在多 repo 專案工作的工程師
- 想讓 AI agent 不要一上來就改錯地方的人
- 需要在寫 code 之前先把 spec 想清楚的人
- 想讓 AI review 不只是蓋橡皮圖章的人
- 已經有經驗，但想把 preflight、spec、validation 思路標準化的團隊

### 這不是什麼

- 不是初學者 coding 教學
- 不是框架或 runtime
- 不是萬用 prompt pack
- 不是 repo-local 規則、tests、CI 的替代品

如果你的任務是單檔小腳本、沒有 protected surface、不碰 contract boundary，workflow 會自動分類為 D0，不需要走完整儀式。

### 公開版的設計原則

這個 repository 刻意保留方法論，不帶入任何內部拓樸（即你的 repo 之間怎麼連、誰呼叫誰、實際的服務架構）。

它會教你怎麼想：owner boundary、contract risk、validation depth、rollback stance、decision lock、architecture fit、scope negative list、mechanical verification、falsification-first review。

但不會帶入任何內部 repo 名稱、私有驗證指令、公司流程或內部架構細節。

---

## English Summary

> Decision tree, common combinations, and end-to-end example are in the Chinese section above. The diagrams and code blocks are language-neutral.

### When to Use Which Skill

```text
You have a task
│
├─ Is it a trivial edit? (typo, comment, formatting)
│  └─ Just do it. No skill needed. (D0)
│
├─ Is it a new feature or product? Direction not yet decided?
│  └─ YES → Start with Brainstorming Capture
│           Explore directions, get stakeholder alignment.
│           If concept is already decided, skip to Boundary-First or Spec Planning.
│
├─ Does it cross a repo, service, or contract boundary?
│  └─ YES → Start with Boundary-First Engineering
│           Identify owner, consumer, contract risk, rollback stance.
│           Then decide if you also need Spec Planning and/or Adversarial Review.
│
├─ Does it need a spec before implementation?
│  (new feature, migration, refactor, multi-phase work)
│  └─ YES → Use Executable Spec Planning
│           Write the spec with Decision Lock, acceptance criteria, scope boundary.
│           Optional: also use Boundary-First if multi-repo.
│
├─ Are you reviewing AI-generated code, a PR, or a spec?
│  └─ YES → Use Adversarial Code Review
│           Select mode (Code / Spec / Release Gate)
│           and intensity (L1 Fast / L2 Standard / L3 Adversarial).
│
└─ Multiple of the above?
   └─ Combine them. Typical full-cycle:
      Brainstorming (discover) → Boundary-First (decide) → Spec Planning (plan)
      → AI builds → Adversarial Review (verify)
```

### Common Combinations

| Scenario | Skills to Use | Why |
|----------|--------------|-----|
| Small bug fix, single repo | Adversarial Review (L1 Fast) | Verify fix + confirm regression gate (HR-8) |
| New feature, direction undecided | Brainstorming → Spec Planning → Adversarial Review (L2) | Discover first, plan, verify |
| New feature, direction decided | Spec Planning → Adversarial Review (L2) | Plan first, verify after |
| Schema migration, multi-repo | Boundary-First → Spec Planning → Adversarial Review (L3) | Full lifecycle |
| New product, multi-repo | Brainstorming → Boundary-First → Spec Planning → Adversarial Review (L3) | Full four-layer |
| Reviewing someone else's PR | Adversarial Review (L2 Code Mode) | Verify with evidence |
| Reviewing a design doc | Adversarial Review (L2 Spec Mode) | Check completeness and consistency |
| Pre-deploy verification | Adversarial Review (L3 Release Gate) | Full execution-layer audit |

---

## Skill Packs

### 0. Brainstorming Capture (cw-brainstorming) `v2025.04.01 NEW`

A brainstorming capture skill for creative and product ideation. Records ideas with minimal elaboration, preserves creative freedom, and prevents AI agents from skipping the ideation phase.

- **Agent-agnostic** — `cw-brainstorming/` (works with Claude Code, Codex, or any LLM)

**When to use:** New feature ideation, product direction exploration, UX concept brainstorming, story/worldbuilding exploration — any open-ended "what should we build?" discussion.
**When NOT to use:** Direction is already decided — go straight to Spec Planning.

**Key capabilities:**

- Minimal capture with source tagging (`<AI>` for AI suggestions, `<hidden>` for internal-only info)
- Preserves vagueness — doesn't resolve contradictions or force premature decisions
- Discovery Gate (G-1) for product/feature tasks — stakeholder checkpoint before engineering begins
- Dual-path brainstorming to avoid homogeneous blind spots
- Composable with other skills (brainstorm → evaluate → spec → review)
- Anti-pattern prevention: blocks AI from auto-sliding from ideation into implementation

### 1. Boundary-First Multi-Repo Engineering

A boundary-first engineering workflow for multi-repo, multi-runtime, and contract-sensitive tasks.

- **Codex edition** — `codex/boundary-first-multi-repo-engineering/`
- **Claude Code edition** — `claude-code/boundary-first-multi-repo-engineering/`

**When to use:** Any task that may cross a repo, service, or contract boundary.
**When NOT to use:** Single-file scripts, typo fixes, formatting — anything with zero protected surface.

**Key capabilities:**

- D0-D3 severity classification with decision gate
- **Universal Gate Protocol (UGP)** — 10-Gate closed-loop with stakeholder checkpoints `v2025.04.01 NEW`
- **Proportionality principle** — D0/D1 low-risk gates can self-certify; D2/D3 every gate stops `v2025.04.01 NEW`
- **Anti-hallucination design** — legitimate fast paths prevent AI from fabricating evidence `v2025.04.01 NEW`
- Owner / consumer identification and cross-boundary contract model
- Adapter selection (5 types + fallback)
- Mechanical verification depth ladder
- Structured close-out with mandatory rollback stance + **Phase Registry (10 Gates)** `v2025.04.01 NEW`
- Maker-checker for D2/D3

### 2. Executable Spec Planning

A planning workflow that turns fuzzy requirements into executable specifications — specs that an AI agent can implement without ambiguity, and that can be verified mechanically after implementation.

- **Agent-agnostic** — `executable-spec-planning/` (works with both Claude Code and Codex)

**When to use:** New features, migrations, refactors, or any task handed to an AI agent for execution.
**When NOT to use:** Single-line fixes, doc edits, infra console operations.

**Key capabilities:**

- Architecture Fit Check before writing any spec
- Decision Lock Table with zero-TBD gate
- CONTRACT triple (INPUT + OUTPUT + APPROVAL) for information output tasks
- Scope Negative List to prevent AI scope creep
- Maker-Checker separation with trust calibration
- Evidence Block — forces reading real data before writing spec (anti-hallucination)
- BDD Given-When-Then acceptance criteria with concrete field values
- Ubiquitous Language Table for cross-system field mapping
- D0 fast path with dedicated template and gate (`gate-quick-d0`)
- Bug-to-Gate Closure (HR-8) — every confirmed bug must leave a regression gate
- 31-check completeness guard (Layer A manual; Layer B executable scripts concept included, scripts not bundled in public pack)
- Risk escalation triggers (permission/DB mutations/fan-in/routing/prior incidents)
- Governance audit (8 items) in close-out reports — **including GA-8 Phase Compliance** `v2025.04.01 NEW`
- **HR-9 (Governance Audit mandatory)** and **HR-10 (Phase transitions require stakeholder ACK)** `v2025.04.01 NEW`
- **10-Gate Phase Registry** in close-out — every gate tracked with status + evidence + stakeholder ACK `v2025.04.01 NEW`
- **7 anti-patterns** with real case studies (including AP-7 Phase Skip) `v2025.04.01 NEW`
- **Full Review Pipeline** (`full-review.md`) — dual AI review with fail-closed Codex handling `v2025.04.01 NEW`

### 3. Adversarial Code Review

A falsification-first code and spec review skill that forces AI reviewers to prove correctness instead of rubber-stamping "looks good." Distilled from 30+ real incidents where AI reviewers (including Claude, GPT, Codex) gave wrong answers.

- **Agent-agnostic** — `adversarial-code-review/` (works with Claude Code, Codex, ChatGPT, or any LLM)

**When to use:** Any code review, spec review, PR review, or AI output validation.
**When NOT to use:** You trust the output and don't need verification.

**Key capabilities:**

- 10 calibration cases from real AI reviewer failures (not hypothetical)
- Three review modes: Code / Spec / Release Gate
- Three intensity levels: L1 Fast / L2 Standard / L3 Adversarial
- Four mandatory questions per finding (positive evidence, falsification, boundary data, path execution)
- Self-falsification: reviewer must attempt to disprove own findings
- Same-pattern expansion: "where else does this bug exist?"
- 6 anti-patterns that prohibit common AI reviewer shortcuts
- Trust calibration: embed known bugs to test reviewer depth
- Execution evidence table: reviewers must show command output, not just opinions
- Dual checklists: 5 code-focused + 6 spec-focused (including CL-S6 Code Quality Constraints)
- Bug-to-Gate check: review 不只確認這次修好，還確認同類錯誤下次會被 gate 擋住——這是系統記憶的形成方式
- 13 real-world catches documented with before/after comparisons

---

## Quick Start

### Brainstorming Capture `NEW`

**Claude Code:** Copy `cw-brainstorming/` to `.claude/skills/cw-brainstorming/`.

**Codex / ChatGPT / any LLM:** Paste `SKILL.md` content at the start of your brainstorming conversation.

### Boundary-First Engineering

**Claude Code (skill 方式):** Copy `claude-code/boundary-first-multi-repo-engineering/` to `.claude/skills/boundary-first-multi-repo-engineering/`. 包內提供 `SKILL.md`（有 frontmatter）供上傳使用。

**Claude Code (CLAUDE.md 方式):** 把 `CLAUDE.md` 的內容貼進專案根目錄的 `CLAUDE.md`，並把 `references/` 複製到同層。

**Codex:** Copy `codex/.../` to `~/.codex/skills/boundary-first-multi-repo-engineering/`, restart Codex.

### Executable Spec Planning

**Claude Code:** Copy `executable-spec-planning/` to `.claude/skills/executable-spec-planning/`, or paste `SKILL.md` content into your project's `CLAUDE.md`.

**Codex:** Copy `executable-spec-planning/` to `~/.codex/skills/executable-spec-planning/`, restart Codex.

### Adversarial Code Review

**Claude Code:** Copy `adversarial-code-review/` to `.claude/skills/adversarial-code-review/`.

**Codex / ChatGPT / any LLM:** Paste `SKILL.md` content at the start of your review conversation.

See [adversarial-code-review/README.md](adversarial-code-review/README.md) for detailed usage guide and examples.

---

## Capability Map

```text
+-- Brainstorming Capture (NEW v2025.04.01) --------------------+
| Capture Layer      Minimal capture with source tagging         |
|                    Preserve vagueness, multiple options coexist |
|                    <AI> tags for suggestions, <hidden> for internal |
| Gate Layer         Discovery Gate (G-1) for product/feature    |
|                    Dual-path brainstorming (avoid blind spots)  |
|                    Stakeholder checkpoint before engineering    |
+---------------------------------------------------------------+

+-- Boundary-First Engineering ---------------------------------+
| Decision Layer     D0-D3 severity classification              |
|                    Implementation plan template                |
|                    Maker-checker for D2/D3                     |
| Gate Layer         Universal Gate Protocol (10 Gates, G-1~G6)  |  NEW
|                    Proportionality principle (D0 fast / D3 full)|  NEW
|                    Anti-hallucination (self-certify w/ evidence)|  NEW
|                    Phase Registry in close-out (10 Gates)       |  NEW
| Boundary Layer     Owner / consumer identification            |
|                    Cross-boundary contract model               |
|                    Conflict resolution                         |
|                    Adapter selection (5 types + fallback)      |
| Verification Layer Mechanical verification depth ladder       |
|                    One-side-only = partial, not pass           |
| Delivery Layer     Structured close-out template              |
|                    Rollback stance mandatory                   |
+---------------------------------------------------------------+

+-- Executable Spec Planning -----------------------------------+
| Pre-Spec Layer     Architecture Fit Check (D0: one-line stmt)  |  UPDATED
|                    Step 2b: Query Actual Data (anti-hallucin) |
|                    Evidence Block (source + data + numbers)    |
|                    D0 fast path with dedicated gate            |
| Spec Layer         Decision Lock Table (zero TBD gate)        |
|                    CONTRACT triple (INPUT+OUTPUT+APPROVAL)     |
|                    Scope Negative List                         |
|                    Phase breakdown with rollback per phase     |
| Review Layer       Maker != Checker separation                |
|                    Trust calibration (embed known defect)      |
|                    R1-R18 review dimensions (incl Bug-to-Gate) |
| Guard Layer        31-check completeness (Layer A manual)      |
|                    Layer B guard scripts (concept; not bundled)|
|                    7 anti-patterns (incl AP-7 Phase Skip)      |  NEW
| Close-out Layer    Governance audit (8 items, incl GA-8)       |  UPDATED
|                    Phase Registry (10 Gates)                    |  NEW
|                    Regression Gate section (HR-8)              |
|                    HR-9 mandatory audit + HR-10 phase ACK       |  NEW
|                    Before/After metrics + rejected paths       |
+---------------------------------------------------------------+

+-- Adversarial Code Review -----------------------------------+
| Calibration Layer  10 real AI-reviewer failure cases           |
|                    Pattern matching before review starts      |
| Mode Layer         Code Mode (execution evidence)             |
|                    Spec Mode (logical completeness)            |
|                    Release Gate Mode (both + deploy verify)    |
| Intensity Layer    L1 Fast (low risk, minimal ceremony)       |
|                    L2 Standard (normal feature work)           |
|                    L3 Adversarial (cross-service, auth, schema)|
| Question Layer     Q1 Positive evidence (cite code lines)     |
|                    Q2 Falsification scenario (try to break it) |
|                    Q3 Boundary data (real data, not mock)      |
|                    Q4 Path execution (was fallback exercised?) |
| Spec Layer         CL-S1~S6 (incl Code Quality Constraints)   |
| Guard Layer        7 anti-patterns (prohibited shortcuts)      |  UPDATED
|                    Self-falsification (disprove own findings)   |
|                    Same-pattern expansion (grep for siblings)   |
| Gate Layer         Phase Registry audit (missing = P0)         |  NEW
|                    BLOCKED on missing preflight (not NO-GO)    |  NEW
|                    Full Review pipeline (dual AI review)        |  NEW
| Trust Layer        Final Authority can embed known bugs to test reviewer   |
|                    Honest disclosure of unverified items        |
+---------------------------------------------------------------+
```

---

## Real Failure Patterns

All anonymized, no internal details. These are the failure modes these skills were designed to prevent.

### Boundary-First Prevents

**Pattern 1: Payload change = shared contract migration.** Agent updates only the caller; producer rejects; silent drift. Boundary-First finds the real owner and validates both sides.

**Pattern 2: Auth fix = every consumer breaks.** Agent patches one side; entire integration chain fails at deploy. Boundary-First forces dual-side thinking and staged rollout consideration.

**Pattern 3: Bulk action = durable write without rollback.** Agent makes the button work; partial failure corrupts data. Boundary-First escalates to durable-state risk and requires rollback stance.

**Pattern 4: Extension permission = runtime boundary change.** Agent updates manifest, build passes, declared done. Boundary-First classifies as permission surface — build is not sufficient evidence.

### Spec Planning Prevents

**Pattern 5: Wrong architecture, all gates pass.** Team builds NLP chatbot for B2B tool. Zero errors, but users need deterministic menus. Months discarded. Spec Planning checks architecture fit before writing a single line of spec.

**Pattern 6: Fake-complete spec.** Spec has right sections but criteria say "works correctly." Cannot determine PASS/FAIL. Spec Planning's 31-check guard enforces mechanically decidable criteria.

**Pattern 7: AI scope creep.** Agent autonomously "improves" SQL INSERT logic outside spec scope. CI passes (DB mocked). Production breaks. Spec Planning's Negative List + HR-6 prohibit unauthorized mutation changes.

**Pattern 8: Untrustworthy reviewer.** Checker says GO but only checked surface structure. Spec Planning's trust calibration embeds known defects to verify actual review depth.

### Adversarial Review Prevents

**Pattern 9: "All tests pass so it's correct."** Test mock uses lowercase; production stores uppercase. Mock PASS ≠ production PASS. Adversarial Review's Q3 requires real data validation.

**Pattern 10: "Fallback is implemented."** Code only logs warning, no branching. Log exists ≠ handling exists. Adversarial Review's Q4 requires code path evidence.

**Pattern 11: "Cache write = immediate read consistency."** Platform uses eventual consistency; edge cache not invalidated. Adversarial Review's AP-6 prohibits assuming platform behavior.

**Pattern 12: "Hardcoded default = code smell."** Upstream adapter handles it; default is defensive fallback. Adversarial Review's AP-5 requires tracing up and down before concluding.

**Pattern 13: "I checked the linter output."** Reviewer checked warningCount but not errorCount. 3 undefined-variable errors missed. Adversarial Review's Execution Evidence table requires pasting actual command output.

See [adversarial-code-review/examples/real-world-catches.md](adversarial-code-review/examples/real-world-catches.md) for 13 detailed before/after case studies.

---

## Repository Structure

```text
skill_shared/
├── README.md                                            <- You are here
├── cw-brainstorming/                                    <- Brainstorming capture (NEW v2025.04.01)
│   └── SKILL.md
├── usp-brainstorm/                                      <- USP brainstorming (competitive positioning)
│   └── SKILL.md
├── claude-code/boundary-first-multi-repo-engineering/   <- Claude Code edition
│   ├── CLAUDE.md                                        <- For pasting into project CLAUDE.md
│   ├── SKILL.md                                         <- For uploading as Claude Code skill
│   └── references/
│       ├── universal-gate-protocol.md                   <- UGP (NEW v2025.04.01)
│       ├── constitution.md
│       ├── decision-gate.md
│       ├── owner-selection.md
│       ├── cross-boundary-contracts.md
│       ├── mechanical-verification.md
│       ├── security-and-gates.md
│       ├── architecture-and-observability.md
│       ├── validation-matrix.md
│       ├── conflict-resolution.md
│       ├── implementation-plan-template.md
│       ├── fallback-adapter.md
│       └── adapters/                                    <- 5 system-type adapters
│           ├── backend-service.md
│           ├── frontend-app.md
│           ├── admin-console.md
│           ├── automation-bot.md
│           └── browser-extension.md
├── codex/boundary-first-multi-repo-engineering/         <- Codex edition
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   └── references/
│       ├── universal-gate-protocol.md                   <- UGP (NEW v2025.04.01)
│       ├── preflight-protocol.md
│       ├── constitution.md
│       ├── decision-gate.md
│       ├── owner-selection.md
│       ├── cross-boundary-contracts.md
│       ├── mechanical-verification.md
│       ├── security-and-gates.md
│       ├── architecture-and-observability.md
│       ├── validation-matrix.md
│       ├── conflict-resolution.md
│       ├── implementation-plan-template.md
│       ├── fallback-adapter.md
│       └── adapters/                                    <- 5 system-type adapters
├── executable-spec-planning/                            <- Agent-agnostic planning
│   ├── SKILL.md
│   └── references/
│       ├── spec-template.md
│       ├── completeness-guard.md
│       ├── d0-spec-template.md
│       ├── gate-quick-d0.md
│       ├── checker-review-prompt-template.md
│       ├── contract-triple-template.md
│       ├── close-out-template.md
│       ├── anti-patterns.md                             <- 7 failure modes (NEW v2025.04.01)
│       ├── spec-review-checklist.md
│       ├── executable-spec-criteria.md
│       └── code-quality.md
└── adversarial-code-review/                             <- Agent-agnostic review
    ├── README.md
    ├── SKILL.md
    ├── adversarial-review.md
    ├── full-review.md                                   <- Dual review pipeline (NEW v2025.04.01)
    ├── references/
    │   └── calibration-cases.md
    └── examples/
        ├── example-code-review.md
        ├── example-spec-review.md
        └── real-world-catches.md
```

---

## Version History

### v2025.04.01 — Universal Gate Protocol + Brainstorming Capture

基於一個真實案例的 900+ 則訊息審計：AI agent 在功能開發中自行跳過概念評估和設計審查階段，導致 7 輪 stakeholder 手動迭代（其中 4 輪本應被跳過的階段攔住）。根因：pipeline 是開環的 — agent 在每一步都可以選「對自己最快」的路，沒有機制要求它停下來讓 stakeholder 在成本最低的時候介入。

**新增 Skill:**
- **Brainstorming Capture (cw-brainstorming)** — 發想層 skill，含 Discovery Gate (G-1)，防止 AI 跳過發想直接動工

**新增 Protocol:**
- **Universal Gate Protocol (UGP)** — 10 Gate 閉環（G-1 Discovery → G6 Close-out），每步都有 stakeholder checkpoint
- **比例原則** — D0/D1 低風險 Gate 可自證（防幻覺），D2/D3 每步停等
- **5 狀態制** — PASS / SELF_CERTIFIED(evidence) / BLOCKED / WAIVED_BY_PM(reason) / SKIPPED_BY_PM
- **Phase Registry** — close-out 必填 10 Gate 完整紀錄，缺項 = rejected

**新增 Hard Rules:**
- **HR-9** — Governance Audit (含 GA-8 Phase Compliance) mandatory
- **HR-10** — Phase transitions require stakeholder ACK

**新增 Anti-Pattern:**
- **AP-7 Phase Skip** — agent 自行跳過 workflow phase 的失敗模式

**新增 Review Pipeline:**
- **Full Review** (`full-review.md`) — Claude + Codex 雙路審查 + fail-closed Codex handling

**修改:**
- 所有 SKILL.md 加入 UGP gate 引用
- Close-out template 加入 Phase Registry + GA-8
- Decision gate 加入 stakeholder ACK 步驟
- Constitution 加入 phase transition + phase skipping hard rules
- D0 Architecture Fit Check 從「可跳過」改為「需一行聲明」

**閉環補強（結案審查後追加）:**
- **G1 Hardcode 防線** — G1 Gate 新增必檢：「資料會變嗎？」「改一筆要幾步？」> 2 步 = 不可 hardcode
- **CW 分類需 stakeholder ACK** — Agent 不可自行判定「這是純創作不用走 UGP」，需 stakeholder 確認
- **SSOT-first Hard Rule** — 工作流治理檔案有指定的 SSOT repo，禁止先改副本再回填

### v2025.03.30 — Initial Release

三套核心 skill：Boundary-First Engineering + Executable Spec Planning + Adversarial Code Review。

---

## License

MIT. Use freely, adapt to your stack, share your calibration cases with the community.
