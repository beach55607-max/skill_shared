# Universal Gate Protocol

> 從發想到交付的完整閉環治理系統。
> 每一個 Gate 都是 stakeholder checkpoint — Agent 不能自行通過、跳過、或降級任何 Gate。

## 設計原則

1. **閉環 = 必經 + 可選入口。** 任何 Gate 都可以是入口，但入口之後的 Gate 不可跳過。
2. **入口由 stakeholder 決定，不是 Agent。** Agent 可以建議入口，stakeholder 確認。
3. **狀態制（5 態）。** 每個 Gate 只能是 `PASS`、`SELF_CERTIFIED(evidence)`、`BLOCKED`、`WAIVED_BY_PM(reason)`、`SKIPPED_BY_PM`。禁止 `SKIPPED`（無 stakeholder 授權）、`N/A`、`optional`。
4. **只升不降。** Review mode 由最高風險 surface 決定，降級只能用 `WAIVED_BY_PM`。
5. **fail-closed。** 任何 Gate 缺證據、reviewer 缺席、artifact 缺鏈 → `BLOCKED` 回 stakeholder，不得繼續。
6. **比例原則。** Gate 深度匹配風險等級。D0 用快速通道，D3 用完整儀式。過度儀式 = 幻覺壓力 = 形式化。

---

## 防幻覺設計

> **核心矛盾**: Gate 越嚴格 → AI 越沒有合法出路 → 幻覺壓力越大 → Gate 變成擺設。
> 解法不是降低標準，是**提供合法的快速通道和壓力釋放閥**。

### 分級 Gate 深度（比例原則）

| D-level | 需要 stakeholder 停等的 Gate | 可 Self-Certify 的 Gate | 說明 |
|---------|--------------------|-----------------------|------|
| **D0** | G0（分類確認）、G6（close-out） | G1~G5 可 self-certify with evidence | typo / comment / 小改動不需要每步停等 |
| **D1** | G0、G2（spec）、G5（review）、G6 | G1、G3、G4 可 self-certify | 單 repo protected surface，關鍵決策點停等 |
| **D2** | G0~G6 全部 | 無 | 跨 repo contract，每步都要 stakeholder |
| **D3** | G0~G6 全部 | 無 | 高風險，每步都要 stakeholder |

### Self-Certify（自證）機制

D0/D1 的低風險 Gate 可以由 Agent 自行通過，但必須：

1. **提供機械證據**（不是敘述性「我看了，沒問題」）
2. **在 Phase Registry 標記 `SELF_CERTIFIED(evidence)`**（不是 `PASS`）
3. **stakeholder 在 G6 Close-out 時一次性審查所有 Self-Certified Gate**

```
| Gate | Status | Evidence |
|------|--------|----------|
| G1 | SELF_CERTIFIED | Architecture: 修改現有 handler，無新架構。evidence: 改動 ≤ 3 files, 無新 import |
| G4 | SELF_CERTIFIED | gate:pr PASS（指令: npm run gate:pr, 結果: 0 failures） |
```

**Self-Certify 的紅線**：以下情況不可 self-certify，必須停等 stakeholder：
- 任何 D2/D3 Gate
- G0（分類決定後續所有深度，必須 stakeholder 確認）
- G6（最終簽核，必須 stakeholder）
- Agent 對該 Gate 有不確定性時

### 合法壓力釋放閥

| 場景 | 舊規則（會造成幻覺） | 新規則（合法出路） |
|------|--------------------|--------------------|
| stakeholder 沒回覆 | 「必須等」→ AI 假裝收到 APPROVED | 輸出 `⏳ WAITING — G[N] 等待 stakeholder 回覆` 然後**真的停下來** |
| 這個 Gate 對任務不適用 | 禁止 N/A → AI 硬掰理由 PASS | 用 `WAIVE REQUEST` 說明不適用原因，stakeholder 秒回 WAIVED |
| Codex 環境壞了 | 「必須跑」→ AI 編造 output | `BLOCKED` 回 stakeholder + 建議 Mode B 替代方案 |
| D0 小改動 10 Gate 太重 | 每步停等 → AI 隨便填 | D0 只停 G0 + G6，中間 self-certify |
| 不確定 D-level | 分錯被罵 → AI 傾向分低 | Agent 可說「建議 D1，但可能是 D0，請 stakeholder 判定」|

### 誠實揭露 > 完美答案

在任何 Gate 格式中，Agent 可以（且應該）加入誠實揭露：

```
📋 GATE G2 Spec Lock
- Spec version: v1
- Checker: Codex — findings: 2 blockers resolved
- Decision Lock: all locked

⚠️ 誠實揭露:
- I2 Concept Critique 時我沒有想到某些邊緣場景，是 stakeholder 後來補的
- 排序邏輯我選了「由貴到便宜」但沒有挑戰過業務合理性

🚦 PM REVIEW — APPROVED / REVISE / REJECT
```

**誠實揭露不會被懲罰。** 沒揭露但後來被發現 = 比揭露了更嚴重。

---

## 10 Gate 定義

### 發想階段（I1 ~ I3）

#### I1: Discovery（發想）

- **觸發**: 從零開始的新功能、新產品、新方向
- **執行**: `cw-brainstorming` 視角 — 多選項並列，雙路互博（Claude + Codex 各提一組方向）
- **產出**: 功能方向清單、多選項並列、開放問題
- **Gate 格式**:
  ```
  📋 GATE I1 Discovery
  - 功能方向: [列出]
  - 雙路互博: Claude [N] 項 / Codex [N] 項（或 WAIVED_BY_PM）
  - 開放問題: [列出]

  🚦 PM REVIEW — APPROVED / REVISE / REJECT
  ```
- **stakeholder 決策**: 選定方向、縮減範圍、或要求重新發想

#### I2: Concept Critique（概念評估）

- **觸發**: I1 PASS 後自動進入，或 stakeholder 指定「概念已有，從 I2 開始」
- **執行**: `cw-story-critique` 視角 — 對選定方向做結構性挑戰
- **必檢清單**:
  - [ ] 業務合理性 — 這個設計對業務端有沒有負面影響？
  - [ ] 功能完整性 — 有沒有漏掉的選項或場景？
  - [ ] UX 合理性 — 使用者看到會不會產生錯誤理解或不想使用？
  - [ ] 技術可行性 — 前端跑得動嗎？資料量合理嗎？
  - [ ] 資料來源 — 資料從哪來？會不會變？該 hardcode 還是從 API 讀？
- **Gate 格式**:
  ```
  📋 GATE I2 Concept Critique
  - 業務合理性: [PASS/BLOCKED + 理由]
  - 功能完整性: [PASS/BLOCKED + 理由]
  - UX 合理性: [PASS/BLOCKED + 理由]
  - 技術可行性: [PASS/BLOCKED + 理由]
  - 資料來源: [PASS/BLOCKED + 理由]

  ⚠️ CHALLENGE: [Agent 自己提出的反面挑戰]

  🚦 PM REVIEW — APPROVED / REVISE / REJECT
  ```

#### I3: Canonicalize（定稿）

- **觸發**: I2 PASS 後自動進入，或 stakeholder 指定「已有完整 spec，從 I3 開始」
- **執行**: `cw-official-docs` 視角 — 把發想和評估結果寫成 canonical spec / SSOT
- **必含**:
  - 資料來源聲明（hardcode / database / key-value store / API / spreadsheet）
  - 功能範圍定稿（In-Scope / Out-of-Scope）
  - 設計決策記錄（從 I1/I2 帶入）
- **Gate 格式**:
  ```
  📋 GATE I3 Canonicalize
  - Canonical doc: [檔案路徑或 artifact ID]
  - 資料來源: [宣告]
  - Scope: [In / Out 列表]

  🚦 PM REVIEW — APPROVED / REVISE / REJECT
  ```
- **I3 產出 = 工程 pipeline 的 input**

---

### 工程階段（G0 ~ G6）

#### G0: Classify + Preflight

- **觸發**: I3 PASS 後自動進入，或 stakeholder 指定「純工程改動，從 G0 開始」
- **執行**: boundary-first decision-gate.md 分類（D0/D1/D2/D3）+ 8 步 Preflight
- **關鍵**: Agent 提出 D-level + 證據，stakeholder 確認或 override
- **Gate 格式**:
  ```
  📋 GATE G0 Classify + Preflight
  - D-level: [D0/D1/D2/D3] + 證據: [引用 decision flow 哪個分支]
  - Owner: [repo + layer]
  - Consumer: [affected repos/callers]
  - Surfaces: [列出 protected surfaces]
  - Rollback stance: [方案]

  🚦 PM REVIEW — APPROVED / OVERRIDE to D[N] / REVISE
  ```

#### G1: Architecture Fit

- **觸發**: G0 PASS 後
- **執行**: Architecture Fit Check（executable-spec-planning Step 3）
- **D0 不再自動豁免**: D0 仍須提供一行聲明:「Architecture assumption: [X]. No new architecture needed because [Y].」
- **D1+**: 完整 Architecture Fit Check artifact
- **必檢（D1+ 全做，D0 至少回答資料層）**:
  - [ ] Core assumption — 架構的核心假設是什麼？什麼情況下會失效？
  - [ ] 資料層 — 資料從哪讀？會不會變？如果會變，hardcode 就違反 SSOT。
  - [ ] 耦合度 — 改一筆資料需要幾步？如果 > 2 步（改 code → build → deploy），考慮從 API/DB 讀取。
  - [ ] 資料量 — 資料量多大？前端/邊緣環境跑得動嗎？
- **Gate 格式**:
  ```
  📋 GATE G1 Architecture Fit
  - Core assumption: [X]
  - Validation: [how confirmed]
  - Data layer: [hardcode / database / key-value store / API — 帶理由]
  - 資料會變嗎: [是 → 不可 hardcode / 否 → hardcode 可接受]
  - 改一筆資料需要幾步: [N 步 — 如果 > 2 步需說明為什麼可接受]

  🚦 stakeholder REVIEW — APPROVED / REVISE / REJECT
  ```

#### G2: Spec Lock

- **觸發**: G1 PASS 後
- **執行**: Produce Spec v1 + Checker review（executable-spec-planning Steps 4-5）
- **Gate 格式**:
  ```
  📋 GATE G2 Spec Lock
  - Spec version: [vN]
  - Checker: [entity] — findings: [N blockers / N resolved]
  - Decision Lock: [all locked / N TBD remaining]

  🚦 PM REVIEW (Final Authority) — APPROVED (= GO) / REVISE / REJECT
  ```

#### G3: Review Mode Lock

- **觸發**: G2 PASS 後，開始實作前
- **執行**: 根據最高風險 surface 自動決定 review mode
- **規則**:
  - D0 無 protected surface → Mode B（Claude 單審）可接受，但需 stakeholder ACK
  - D1 protected surface → Mode A（Claude + Codex 雙審）為預設
  - D2/D3 → Mode A 強制，不可降級
  - **降級只能用 `WAIVED_BY_PM(reason)`**
- **Gate 格式**:
  ```
  📋 GATE G3 Review Mode Lock
  - Risk level: [D0/D1/D2/D3]
  - Review mode: [Mode A / Mode B]
  - 降級: [無 / WAIVED_BY_PM(reason)]

  🚦 PM REVIEW — APPROVED / REVISE
  ```

#### G4: Implementation Done

- **觸發**: 實作完成後
- **執行**: 跑 repo 的 mechanical verification（gate:pr / npm run ci / lint+test+build）
- **Gate 格式**:
  ```
  📋 GATE G4 Implementation Done
  - Gate command: [executed command]
  - Result: [PASS / FAIL + details]
  - Files changed: [N files, list]

  🚦 PM REVIEW — APPROVED / REVISE
  ```

#### G5: Adversarial Review

- **觸發**: G4 PASS 後
- **執行**: /full-review（Mode A）或 /adversarial-review（Mode B，需 G3 已鎖定）
- **規則**:
  - P0/P1 必須修完才能 PASS
  - P2 可記入 residual risk
  - Codex 不可用 = **BLOCKED 回 stakeholder**，不是靜默跳過
  - 缺 preflight artifact = **BLOCKED**，不是 NO-GO candidate
- **Gate 格式**:
  ```
  📋 GATE G5 Adversarial Review
  - Claude findings: [N P0 / N P1 / N P2]
  - Codex findings: [N P0 / N P1 / N P2] 或 BLOCKED(reason)
  - Consensus issues: [列出]
  - Unresolved P0/P1: [0 = PASS / N = BLOCKED]

  🚦 PM REVIEW — APPROVED / REVISE
  ```

#### G6: Close-out

- **觸發**: G5 PASS 後
- **執行**: 填寫 close-out report，含 Phase Registry
- **必填**: Phase Registry（10 Gate 全列）、Governance Audit（含 GA-8 Phase Compliance）
- **Gate 格式**:
  ```
  📋 GATE G6 Close-out
  - Phase Registry: [完整 / 缺 N 項]
  - Governance Audit: [N/N PASS]
  - Residual risk: [列出]

  🚦 PM SIGN-OFF — SIGNED / REVISE
  ```

---

## 入口選擇規則

| 場景 | 入口 | 跳過的 Gate | stakeholder 怎麼說 |
|------|------|------------|----------|
| 從零開始做新功能 | **I1** | 無 | 「從 I1 開始」 |
| stakeholder 已有概念，要評估 | **I2** | I1 | 「概念已定，從 I2 開始」 |
| stakeholder 已有完整 spec | **G0** | I1~I3 | 「spec 在 X，從 G0 開始」 |
| 純 bug fix / 小改動 | **G0** | I1~I3 | 正常 D0 流程 |
| stakeholder 只要發想不動工 | **I1 → I2 止** | I3~G6 | 「只到 I2，不進工程」 |
| stakeholder 只要 review 現有 code | **G5 單跑** | 全部 | 「只跑 adversarial review」 |

**入口之前的 Gate**: 狀態為 `SKIPPED_BY_PM`（stakeholder 指定跳過，非 Agent 決定）。
**入口之後的 Gate**: 不可跳過，只能 `WAIVED_BY_PM(reason)`。

---

## Phase Registry 格式

每次任務的 close-out 必須包含完整的 Phase Registry：

```markdown
## Phase Registry

**Entry Point**: [Gate ID]（[stakeholder 指定 / Agent 建議 + stakeholder 確認]）
**Exit Point**: [Gate ID]
**Skipped by PM**: [Gate IDs — stakeholder 指定跳過的前段 Gate]

| Gate | Phase | Status | Evidence | PM ACK |
|------|-------|--------|----------|--------|
| I1 | Discovery | SKIPPED_BY_PM | stakeholder 指定從 I2 開始 | PM YYYY-MM-DD |
| I2 | Concept Critique | PASS | 5/5 checks passed | PM YYYY-MM-DD APPROVED |
| I3 | Canonicalize | PASS | spec-v1.md | PM YYYY-MM-DD APPROVED |
| G0 | Classify + Preflight | PASS | D1 + evidence | PM YYYY-MM-DD APPROVED |
| G1 | Architecture Fit | PASS | assumption confirmed | PM YYYY-MM-DD APPROVED |
| G2 | Spec Lock | PASS | spec-v1.2 final | PM YYYY-MM-DD APPROVED |
| G3 | Review Mode | PASS | Mode A locked | PM YYYY-MM-DD APPROVED |
| G4 | Implementation | PASS | gate:pr PASS | PM YYYY-MM-DD APPROVED |
| G5 | Adversarial Review | PASS | 0 P0, 0 P1 | PM YYYY-MM-DD APPROVED |
| G6 | Close-out | PASS | Registry complete | PM YYYY-MM-DD APPROVED |
```

---

## 狀態制（五態）

| 狀態 | 意義 | 誰決定 | 適用 D-level |
|------|------|--------|-------------|
| `PASS` | Gate 通過，stakeholder 確認 | Agent 提出 + stakeholder APPROVED | 全部 |
| `SELF_CERTIFIED(evidence)` | Gate 通過，Agent 自證 + 機械證據 | Agent 自行（stakeholder 在 G6 統一審查） | D0/D1 限定 Gate |
| `BLOCKED` | Gate 未通過，需修正或決策 | Agent 或 stakeholder 判定 | 全部 |
| `WAIVED_BY_PM(reason)` | Gate 在入口之後被 stakeholder 授權跳過 | 僅 stakeholder 可授權 | 全部 |
| `SKIPPED_BY_PM` | Gate 在入口之前，stakeholder 指定不需要 | 僅 stakeholder 可指定入口 | 全部 |

**禁止出現**: `SKIPPED`（無 stakeholder 授權的跳過）、`N/A`、`optional`、空白。

**Self-Certify 的紅線**（不可 self-certify，必須停等 stakeholder）：
- 任何 D2/D3 Gate
- G0（分類決定後續深度）和 G6（最終簽核）— 任何 D-level
- Agent 對該 Gate 有不確定性時
- 誠實揭露有未驗證項目時

---

## Reviewer Disclosure Overlay

> 每個 Gate 的 reviewer 必須對其檢查範圍做誠實揭露。Disclosure 是 overlay，不改變五態，不進 Phase Registry。

### Disclosure Tags（closed set）

以下四個 tag 是完整且封閉的集合。**不得新增其他 disclosure tag。**

| Tag | 意義 | 使用時機 |
|-----|------|---------|
| `CHECKED(evidence)` | 已檢查，附 evidence | reviewer 實際驗證過此項目 |
| `NOT_CHECKED(reason)` | 未檢查，附理由 | reviewer 未能或未及檢查此項目 |
| `UNCERTAIN(question)` | 不確定，附問題 | reviewer 檢查了但無法判斷正確性 |
| `OUT_OF_SCOPE(reason)` | 不在此 reviewer 審查範圍 | 該項目屬於另一角色的責任 |

### 規則

1. **Disclosure 不進 Phase Registry。** Phase Registry 只記錄五態（PASS / SELF_CERTIFIED / BLOCKED / WAIVED_BY_PM / SKIPPED_BY_PM）。Disclosure 附在各 Gate 的 review output 中，供 stakeholder 在 G6 統一審查。
2. **每個 Gate output 必須附 disclosure。** 沒有 disclosure = BLOCKED。
3. **`NOT_CHECKED` 不等於 BLOCKED。** 未檢查但 stakeholder 可接受的項目，Gate 仍可 PASS。Stakeholder 在 G6 審查所有 `NOT_CHECKED` 理由。
4. **`NOT_CHECKED` 不得用於逃避檢查。** 如果 reviewer 有能力檢查但選擇不檢查，必須說明理由。Stakeholder 有權要求補檢。

---

## Gate-by-Gate Evidence Matrix

> 每個 Gate 在不同 D-level 下需要的最低 evidence 等級。

### Evidence 等級定義

| 等級 | 名稱 | 定義 | 範例 |
|------|------|------|------|
| **E1** | 機械 / Runtime | 可重跑的指令輸出 | script output, `npm test` output, `curl` response, `grep` count |
| **E2** | 外部 AI 審查 | 獨立 AI（非 Maker）的判斷 | Codex review output, Gemini Gate verdict |
| **E3** | 自我宣稱 | Maker 自己的敘述性判斷 | 「我讀了，邏輯正確」、「架構合理」 |

**信度排序**: E1 > E2 > E3。高 D-level 的關鍵 Gate 不接受純 E3。

### 10 Gate × 3 D-level 最低 Evidence 表

| Gate | D0 最低 | D1 最低 | D2/D3 最低 |
|------|---------|---------|-----------|
| I1 Discovery | E3（多選項並列即可） | E3（多選項並列即可） | E2（需雙路互博） |
| I2 Concept Critique | E3（checklist 自評） | E2（需 Checker 或 stakeholder 挑戰） | E2（需 Checker 獨立 critique） |
| I3 Canonicalize | E3（spec 文件存在） | E3（spec + Checker review） | E2（spec + Checker + stakeholder 逐項確認） |
| G0 Classify + Preflight | E1（mechanical detection output） | E1（mechanical detection output） | E1（mechanical detection output） |
| G1 Architecture Fit | E3（一行聲明） | E3（完整 Arch Fit Check） | E2（Arch Fit Check + Checker 確認） |
| G2 Spec Lock | E3（spec 存在 + Decision Lock） | E2（Checker review 0 BLOCKED） | E2（Checker review 0 BLOCKED + stakeholder 逐項） |
| G3 Review Mode | E3（宣告 Mode） | E3（宣告 Mode + stakeholder ACK） | E3（宣告 Mode A 強制） |
| G4 Implementation | E1（gate command output） | E1（gate command output） | E1（gate command output + cross-ref check） |
| G5 Adversarial Review | E3（self-review） | E2（independent subagent + Checker） | E2（subagent + Checker + independent Gate） |
| G6 Close-out | E3（Phase Registry 完整） | E3（Phase Registry + stakeholder 審查 NOT_CHECKED） | E2（Phase Registry + Checker confirm + stakeholder sign-off） |

**讀法**: 表格中的等級是**最低要求**。提供更高等級永遠可以。E1 滿足任何位置。

---

## AI 角色與 D-level 啟用矩陣

> 定義三個 AI 角色的責任邊界和啟用條件。

### 角色定義

| 角色 | 責任 | 誰 | 核心原則 |
|------|------|-----|---------|
| **Maker** | 撰寫 code / spec / 文件 | 主要 AI agent（如 Claude） | 產出者，不審查自己的產出 |
| **Checker** | 獨立審查 Maker 產出 | 獨立 AI（如 Codex / 另一個 subagent） | 獨立 context，不受 Maker 假設影響 |
| **Gate** | 判斷 evidence 鏈是否完整 | 獨立 AI reviewer（如 Gemini） | **Gate REJECT 不是最終判決** — stakeholder 可 override |

### Gate ≠ Stakeholder

- Gate（獨立 AI reviewer）是 stakeholder 的**顧問**，不是 stakeholder 本身。
- Gate REJECT = 建議 stakeholder 不要通過，但 stakeholder 可以用 `OVERRIDE(reason)` 推翻。
- Gate PASS = 建議 stakeholder 通過，stakeholder 仍可 REVISE 或 REJECT。
- **AI Gate 的職責是確保 evidence 完整性，不是做業務判斷。** 業務判斷永遠是 stakeholder。

### D-level 啟用矩陣

| D-level | Maker | Checker | Gate |
|---------|-------|---------|------|
| **D0** | Main AI | 不需要（self-certify） | 不需要 |
| **D1** | Main AI | Independent AI（G2 Spec + G5 Review） | 不需要（stakeholder 直接判） |
| **D2** | Main AI | Independent AI（每個 Gate） | Independent Gate AI（建議） |
| **D3** | Main AI | Independent AI（每個 Gate） | **Independent Gate AI（強制）** — D3 必須有獨立 AI Gate |

### Fallback 規則

| 情況 | Fallback |
|------|---------|
| Checker AI 不可用 | BLOCKED → stakeholder 決定替代方案或 WAIVED_BY_PM |
| Gate AI 不可用（D2 建議） | stakeholder 直接判，不需要 AI Gate |
| Gate AI 不可用（D3 強制） | BLOCKED → stakeholder 必須找替代 AI Gate 或 WAIVED_BY_PM(reason)。不可靜默跳過 |
| Stakeholder 不回覆 | WAITING — 真的停下來，不假裝收到 APPROVED |

---

## Hard Rules

| # | Rule |
|---|------|
| UGP-1 | **入口由 stakeholder 決定。** Agent 建議入口 + 理由，stakeholder 確認。Agent 不得自行決定入口。 |
| UGP-2 | **入口之後的 Gate 不可跳過。** 跳過需 `WAIVED_BY_PM(reason)`，Agent 必須發 WAIVE REQUEST 並等待。 |
| UGP-3 | **Gate 深度匹配風險（比例原則）。** D0：G0 + G6 必須停等 stakeholder，G1~G5 可 `SELF_CERTIFIED(evidence)`。D1：G0 + G2(Spec Lock) + G5(Review) + G6 必須停等 stakeholder，G1 + G3 + G4 可 self-certify。D2/D3：每個 Gate 必須停等 stakeholder，無 self-certify。Agent 有不確定性時，任何 D-level 都應停等 stakeholder。 |
| UGP-4 | **Review mode 只升不降。** D2/D3 強制 Mode A。D0/D1 的 Mode B 需 stakeholder ACK。降級需 WAIVED_BY_PM。 |
| UGP-5 | **fail-closed。** Codex 不可用、preflight 缺失、artifact 缺鏈 → BLOCKED 回 stakeholder，不得靜默跳過或繼續。 |
| UGP-6 | **Phase Registry 必填。** Close-out 必須包含完整的 10-Gate Phase Registry。缺項 = close-out rejected。 |
| UGP-7 | **終點需宣告。** stakeholder 可指定只跑部分 Gate（如「只到 I2」）。Agent 不得自動從發想滑進工程。 |

---

## WAIVE REQUEST 格式

Agent 認為某個 Gate 可以簡化或跳過時，必須發出 WAIVE REQUEST：

```
⚠️ WAIVE REQUEST — [Gate ID]
理由: [為什麼認為可以跳過]
風險: [跳過的風險是什麼]
替代: [有沒有替代控制措施]

🚦 PM: WAIVED(reason) / DENIED
```

stakeholder 回覆 `WAIVED(reason)` 後，Phase Registry 記錄 `WAIVED_BY_PM(reason)`。
stakeholder 回覆 `DENIED` 後，Agent 必須正常執行該 Gate。

---

## 與既有 workflow 的整合

| 既有元素 | 整合方式 |
|---------|---------|
| boundary-first decision-gate.md | G0 的執行內容 |
| boundary-first constitution.md | UGP rules 補充 constitution Hard Rules |
| executable-spec-planning Core Flow | Steps 1-8 對應 G0-G6，前接 I1~I3 |
| adversarial-code-review | G5 的執行內容 |
| full-review / adversarial-review | G5 的執行命令 |
| close-out-template.md | G6 的執行內容，加入 Phase Registry |
| cw-brainstorming | I1 的執行內容 |
| cw-story-critique | I2 的執行內容 |
| cw-official-docs | I3 的執行內容 |

---

## 來源

此協議基於 a product calculator tool 的 a 900+ message audit of a real feature build，經 Claude + Codex 雙路對抗性審查後設計。

**核心教訓**: 開環 pipeline 的失敗模式不是「少了某一道檢查」，是「Agent 在每一步都可以選對自己最快的路，沒有機制要求它停下來讓 stakeholder 在成本最低的時候介入」。
