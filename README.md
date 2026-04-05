# AI Dev Toolkit

給 AI coding agent 用的工程治理 skill（Claude Code、Codex、ChatGPT 皆適用）。

## 三行安裝

```bash
git clone https://github.com/beach55607-max/ai-dev-toolkit && cd ai-dev-toolkit
bash install.sh --target /path/to/your/project        # Claude Code
bash install.sh --codex --target /path/to/your/project # Codex
```

支援選裝（`--skill 1 3`）、移除（`--uninstall`）、列表（`--list`）。詳見下方 [Quick Start](#quick-start)。

---

核心哲學：**修 bug 不算完成，必須留下下次能擋住同類錯誤的 gate。** 每一次錯誤都應該沉澱成新的防線，讓系統越做越強。

五套 skill 覆蓋 AI 輔助開發的完整生命週期——從發想到交付，每一步都有 stakeholder checkpoint，形成閉環：

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

**v2025.04.04 新增**: 三 AI 角色分離（Maker / Checker / Gate）+ Reviewer Disclosure + Evidence Matrix + 機械強制偵測。
**v2025.04.01 新增**: Brainstorming Capture skill（含 Discovery Gate）— 讓 AI 在動手前先把方向想清楚，stakeholder 確認後才進入工程。

## 三 AI 角色分離（v2025.04.04）

```text
Maker (主 AI)  ──寫 code/spec──→  Checker (獨立 AI)  ──找 bug──→  Gate (獨立 AI)  ──稽核 evidence──→  Stakeholder
   產出者              獨立 QA              獨立稽核            最終決策
   不審自己             不受 Maker 假設影響     不做業務判斷          可 override Gate
```

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

### I1: Discovery（Brainstorming Capture）

```text
Stakeholder: "我想讓員工可以用自然語言搜尋公司內部的文件，
             不用記文件編號或精確關鍵字。"

Agent 輸出：

📋 GATE I1 Discovery
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

### I2: Concept Critique（評估可行性）

```text
Agent 對選定方向做 5 項必檢：

📋 GATE I2 Concept Critique
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

Agent 修正後重新提交 I2 → Stakeholder **APPROVED**

### I3: Canonicalize（定稿）

```text
Agent 把 I1 發想 + I2 評估結果寫成 canonical spec：

📋 GATE I3 Canonicalize
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
- Validation: I2 確認批次匯入足夠（文件更新頻率低，每日同步）
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
  | 加權公式            | keyword 0.7 + semantic 0.3 | I2 stakeholder 決定  |
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
7 Phase Full Review Pipeline:

Phase 1: 收集變更範圍（12 files）
Phase 2 (Claude subagent) + Phase 3 (Codex) 並行：

Claude findings:
  F-01 (🔴): 搜尋 API 沒有 rate limit，惡意使用者可以 DDoS 搜尋索引
  F-02 (🟡): embedding API 呼叫沒有 timeout，fallback 分支沒有測試覆蓋

Codex findings:
  F-01 (🔴): 同上 rate limit 問題（共識 = 高信度，必修）
  F-03 (🟡): 摘要 highlight 邏輯在 CJK 字元斷詞有 bug

Phase 2.5: Runtime Spot Check (E1 Evidence)
  | # | Command              | Expected    | Actual      | PASS/FAIL |
  |---|----------------------|-------------|-------------|-----------|
  | 1 | npm test             | 0 failures  | 0 failures  | PASS      |
  | 2 | curl search API      | < 2s        | 1.2s        | PASS      |
  | 3 | grep rate_limit code | ≥1 match    | 0 matches   | FAIL → F-01 confirmed |

Phase 4: 修復 F-01 + F-02 + F-03
Phase 4.5: Gate AI review → PASS (D2 建議執行，evidence 鏈完整)
Phase 5: regression scan → 0 新問題

📋 GATE G5 Adversarial Review
- Claude: 1 P0 (fixed), 1 P1 (fixed)
- Codex: 1 P0 (fixed), 1 P1 (fixed)
- Consensus: F-01 rate limit (fixed)
- Runtime E1: 3/3 verified
- Gate AI: PASS

🏷️ Disclosure:
- Search API: CHECKED(E1: curl + npm test)
- Indexing pipeline: NOT_CHECKED(separate service, will verify in staging)

🚦 Stakeholder: APPROVED
```

### G6: Close-Out

```text
📋 GATE G6 Close-out

## Phase Registry
| Gate | Phase | Status | Evidence | Stakeholder ACK |
|------|-------|--------|----------|-----------------|
| I1 | Discovery | PASS | 3 directions explored | APPROVED |
| I2 | Concept Critique | PASS | 5/5 checked, 2 REVISED | APPROVED |
| I3 | Canonicalize | PASS | knowledge-search-spec-v1.md | APPROVED |
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
- 沒考慮「搜尋無結果」的 UX → 使用者看到空白頁就離開（I2 功能完整性該攔住）
- 搜尋延遲 5 秒但沒人測過 SLA → 使用者回去用舊系統（I2 UX 合理性該攔住）
- 加權公式隨意設定 → 精確查找反而排在後面（I2 CHALLENGE 該挑戰的）
- 7 輪 stakeholder 手動修正，其中 4 輪本應在概念評估就被發現

UGP 的價值：stakeholder 在 I2 花 10 分鐘 REVISE，省掉後面 2+ 小時的迭代。
```

---

## 這個 repo 有四套 skill

**Skill 0: Brainstorming Capture (cw-brainstorming)** `v2025.04.01 NEW` — 讓 AI agent 在動手前先把方向想清楚。用最小紀錄捕捉發想，不過度展開、不混淆來源、不限制創意自由。產品/功能任務含 Discovery Gate (I1)，stakeholder 確認方向後才能進入工程。

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
- Discovery Gate (I1) for product/feature tasks — stakeholder checkpoint before engineering begins
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
- **Reviewer Disclosure Overlay** — 4 tags closed set (CHECKED / NOT_CHECKED / UNCERTAIN / OUT_OF_SCOPE) `v2025.04.04 NEW`
- **Gate-by-Gate Evidence Matrix** — 10 Gate × 3 D-level minimum evidence levels (E1 mechanical > E2 external AI > E3 self-claim) `v2025.04.04 NEW`
- **AI Role Matrix** — Maker / Checker / Gate separation with D-level activation table `v2025.04.04 NEW`
- **Mechanical D0 detection** — script-based D0 disqualification (cannot self-classify as D0) `v2025.04.04 NEW`

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
- **Layer 0 Runtime Spot Check** — at least 3 reproducible E1 evidence before review `v2025.04.04 NEW`
- **Evidence grading** (E1 mechanical > E2 external AI > E3 self-claim) integrated into §7 audit `v2025.04.04 NEW`
- **Full Review 4→7 Phase** — added Phase 2.5 Runtime Spot Check + Phase 4.5 Gate + regression re-run rule `v2025.04.04 UPDATED`

---

## Quick Start

### 一鍵安裝（推薦）

```bash
# Clone
git clone https://github.com/beach55607-max/ai-dev-toolkit
cd ai-dev-toolkit

# 安裝全部到你的專案（Claude Code）
bash install.sh --target /path/to/your/project

# 安裝全部（Codex）
bash install.sh --codex --target /path/to/your/project

# 只裝你要的
bash install.sh --skill 1 3 --target /path/to/your/project  # Boundary-First + Adversarial Review

# 看有哪些可裝
bash install.sh --list

# 移除
bash install.sh --uninstall --target /path/to/your/project
```

### 手動安裝

如果不想用腳本，手動 copy 也可以：

| Skill | Claude Code | Codex |
|-------|------------|-------|
| 0: Brainstorming | `cp -r cw-brainstorming/ .claude/skills/` | `cp -r cw-brainstorming/ .codex/skills/` |
| 1: Boundary-First | `cp -r claude-code/boundary-first-multi-repo-engineering/ .claude/skills/` | `cp -r codex/boundary-first-multi-repo-engineering/ .codex/skills/` |
| 2: Spec Planning | `cp -r executable-spec-planning/ .claude/skills/` | `cp -r executable-spec-planning/ .codex/skills/` |
| 3: Adversarial Review | `cp -r adversarial-code-review/ .claude/skills/` | `cp -r adversarial-code-review/ .codex/skills/` |
| 4: USP Brainstorm | `cp -r usp-brainstorm/ .claude/skills/` | `cp -r usp-brainstorm/ .codex/skills/` |

**ChatGPT / 其他 LLM:** 把對應 `SKILL.md` 的內容貼進對話開頭即可。

See [adversarial-code-review/README.md](adversarial-code-review/README.md) for detailed usage guide and examples.

---

## Capability Map

```text
+-- Brainstorming Capture (NEW v2025.04.01) --------------------+
| Capture Layer      Minimal capture with source tagging         |
|                    Preserve vagueness, multiple options coexist |
|                    <AI> tags for suggestions, <hidden> for internal |
| Gate Layer         Discovery Gate (I1) for product/feature    |
|                    Dual-path brainstorming (avoid blind spots)  |
|                    Stakeholder checkpoint before engineering    |
+---------------------------------------------------------------+

+-- Boundary-First Engineering ---------------------------------+
| Decision Layer     D0-D3 severity classification              |
|                    Implementation plan template                |
|                    Maker-checker for D2/D3                     |
| Gate Layer         Universal Gate Protocol (10 Gates, I1~G6)  |  v04.01
|                    Proportionality principle (D0 fast / D3 full)|  v04.01
|                    Anti-hallucination (self-certify w/ evidence)|  v04.01
|                    Phase Registry in close-out (10 Gates)       |  v04.01
| Disclosure Layer   Reviewer Disclosure Overlay (4 tags closed)  |  NEW
|                    Evidence Matrix (10 Gate × 3 D-level min)    |  NEW
| Role Layer         Maker / Checker / Gate separation            |  NEW
|                    D-level activation matrix                    |  NEW
|                    Gate ≠ Stakeholder (advisor, not authority)   |  NEW
|                    Mechanical D0 disqualification detection      |  NEW
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
| Gate Layer         Phase Registry audit (missing = P0)         |  v04.01
|                    BLOCKED on missing preflight (not NO-GO)    |  v04.01
|                    Full Review pipeline (7 Phase, dual AI)      |  UPDATED
| Evidence Layer     Layer 0 Runtime Spot Check (≥3 E1 evidence) |  NEW
|                    Evidence grading: E1 > E2 > E3               |  NEW
| Trust Layer        Final Authority can embed known bugs to test reviewer   |
|                    Honest disclosure of unverified items        |
|                    Reviewer Disclosure tags (closed set of 4)   |  NEW
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

## Related: MCP Memory Server

If your AI agent also needs **persistent semantic memory** across sessions, check out [mcp-memory-server](https://github.com/beach55607-max/mcp-memory-server) -- a Cloudflare Workers-based MCP server for saving and searching knowledge by meaning. Works with all the same platforms (Claude, ChatGPT, Gemini CLI, Cursor, VS Code, etc.).

---

## Repository Structure

```text
ai-dev-toolkit/
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

## Glossary（名詞解釋）

| 縮寫 / 術語 | 全名 | 白話 |
|------------|------|------|
| **UGP** | Universal Gate Protocol（通用閘門協議） | 10 Gate 閉環：AI 做每一步都要 stakeholder 點頭，不能自己跑完全程 |
| **Gate** | 閘門 | 一個 stakeholder checkpoint。AI 完成自檢後停下來，等 stakeholder 說 APPROVED 才能走下一步 |
| **I1 ~ I3** | 發想階段 Gate | I1 Discovery（發想）→ I2 Concept Critique（評估）→ I3 Canonicalize（定稿） |
| **G0 ~ G6** | 工程階段 Gate | G0 分類 → G1 架構 → G2 規格鎖定 → G3 審查模式 → G4 實作 → G5 審查 → G6 結案 |
| **D0 ~ D3** | Decision Level（風險等級） | D0 改 typo → D3 改權限/schema。越高越嚴格 |
| **Phase Registry** | 閘門登記表 | Close-out 必填的 10 Gate 完整紀錄，每行有 status + evidence + stakeholder ACK |
| **SELF_CERTIFIED** | 自證通過 | D0/D1 低風險 Gate，AI 附機械證據自己過，stakeholder 在 G6 統一審查 |
| **WAIVED_BY_PM** | Stakeholder 授權跳過 | Gate 在入口之後被 stakeholder 明確授權跳過（跟 Agent 自己跳不同） |
| **SKIPPED_BY_PM** | Stakeholder 指定不需要 | Gate 在入口之前，stakeholder 指定從後面開始 |
| **BLOCKED** | 硬停 | Gate 過不了，需要修正或 stakeholder 決策 |
| **HR** | Hard Rule | 違反 = spec rejected。目前 10 條（HR-1 ~ HR-10） |
| **GA** | Governance Audit | Close-out 的 8 項治理稽核（GA-1 ~ GA-8） |
| **AP** | Anti-Pattern | 已知的失敗模式。目前 7 個（AP-1 ~ AP-7） |
| **SSOT** | Single Source of Truth | 唯一真相來源。spec 和治理檔案各有指定的 SSOT |
| **Maker** | 產出者 | 寫 code/spec 的主要 AI。不審自己的產出 |
| **Checker** | 審查者 | 獨立審查 Maker 產出的 AI（獨立 context，不受 Maker 假設影響） |
| **Gate** | 稽核者 | 判斷 evidence 鏈是否完整的獨立 AI。Gate ≠ stakeholder，stakeholder 可 override |
| **Disclosure** | 審查揭露 | 每個 Gate reviewer 必須附的誠實揭露 tag（4 tags closed set） |
| **E1 / E2 / E3** | Evidence 等級 | E1 機械（可重跑指令）> E2 外部 AI 審查 > E3 自我宣稱。高風險 Gate 不接受純 E3 |
| **Mode A / Mode B** | 審查模式 | Mode A = Maker + Checker + Gate 三角色。Mode B = Maker 單審（需 stakeholder 授權） |
| **Evidence Block** | 證據區塊 | Spec 必附：讀了什麼 code、查了什麼真實資料、每個數字的出處 |
| **CONTRACT triple** | 合約三件組 | INPUT CONTRACT + OUTPUT CONTRACT + APPROVAL CHECKLIST |
| **BDD AC** | Given-When-Then 驗收標準 | 含具體欄位值和數值的可機械驗證驗收條件 |
| **Final Authority** | 最終決策者 | 唯一能宣告 GO 的人（通常是 product owner 或 tech lead） |

---

## Version History

### v2025.04.04 — 三角色分離 + 機械強制 + 誠實揭露

基於治理升級 spec v3.1（經 4 輪 Checker review），解決三個核心問題：球員兼裁判（同一 AI 寫又審）、靜默跳過（reviewer 沒檢查也不說）、自我宣稱混過（「我看了沒問題」就算 evidence）。

**新增 Protocol:**
- **Reviewer Disclosure Overlay** — 4 tags closed set（CHECKED / NOT_CHECKED / UNCERTAIN / OUT_OF_SCOPE），reviewer 必須對檢查範圍做誠實揭露。不進 Phase Registry，供 stakeholder 在 G6 統一審查
- **Gate-by-Gate Evidence Matrix** — 10 Gate × 3 D-level 最低 evidence 等級（E1 機械 > E2 外部 AI > E3 自我宣稱），高風險 Gate 不接受純 E3
- **AI Role Matrix** — Maker / Checker / Gate 三角色分離 + D-level 啟用矩陣。Gate ≠ stakeholder（advisor, not authority）。D3 強制獨立 AI Gate
- **Mechanical D0 Detection** — script 機械偵測 D0 失格信號（FILES / SQL / SECURITY / NEW_DATA / INFO_OUTPUT / CROSS_MODULE），Agent 不可自行說「我覺得是 D0」

**修改:**
- Adversarial Code Review §7: 5 層 → 6 層（加 Layer 0 Runtime Spot Check + Evidence 分級引用）
- Full Review Pipeline: 4 Phase → 7 Phase（加 Phase 2.5 Runtime Spot Check + Phase 4.5 Gate + regression re-run rule）
- Full Review Codex CLI 格式修正（`codex exec -c 'approval_policy="on-failure"'`）
- Decision Gate: 加 Mechanical Classification Aid + D0_DISQUALIFIED 不可降回規則

### v2025.04.01 — Universal Gate Protocol + Brainstorming Capture

基於一個真實案例的 900+ 則訊息審計：AI agent 在功能開發中自行跳過概念評估和設計審查階段，導致 7 輪 stakeholder 手動迭代（其中 4 輪本應被跳過的階段攔住）。根因：pipeline 是開環的 — agent 在每一步都可以選「對自己最快」的路，沒有機制要求它停下來讓 stakeholder 在成本最低的時候介入。

**新增 Skill:**
- **Brainstorming Capture (cw-brainstorming)** — 發想層 skill，含 Discovery Gate (I1)，防止 AI 跳過發想直接動工

**新增 Protocol:**
- **Universal Gate Protocol (UGP)** — 10 Gate 閉環（I1 Discovery → G6 Close-out），每步都有 stakeholder checkpoint
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
