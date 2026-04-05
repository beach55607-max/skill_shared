---
name: adversarial-code-review
description: "Adversarial code review skill. Use whenever reviewing code, specs, PRs, or AI-generated output for correctness. Triggers on: 'review this code', 'check this PR', 'audit', 'verify implementation', 'is this correct', 'does this match spec', any code review request, any spec-vs-code verification, any AI output validation, or when the user asks to verify another AI reviewer's output (Claude, Codex, ChatGPT, etc.). Also use when the user says '確認', '佈署', '審查', 'review', or asks 'Claude 說的對嗎', 'Codex 說的對嗎', or 'AI 說的對嗎'. This skill encodes a review methodology distilled from 30+ real incidents where AI reviewers gave wrong answers."
---

# Adversarial Code Review

> **Role Mapping**: 本 skill 中的「PM」= Final Authority。若您的團隊無 PM 角色，請將 PM 讀作 designated Final Authority。

> **Core Principle**: 審查的目的不是確認「看起來對」，而是證明「無法被證偽」。
> 每一個 PASS 判定都需要正面證據 + 反證場景排除。沒有證據的 PASS = 審查失敗。

---

## 審查模式與強度

### 模式選擇

| 模式 | 使用時機 | 檢查內容 |
|------|---------|---------|
| **Code Mode** | 審查 code 改動、PR、AI 產出的 code | §2 Code Checklist（CL-1~CL-5），需要執行證據 |
| **Spec Mode** | 審查規格書、設計文件、架構提案 | §2-Spec Checklist（CL-S1~CL-S6），需要邏輯完整性證據 |
| **Release Gate Mode** | 部署前驗證 | 兩套 checklist + deploy 驗證 + 交叉驗證 |

### 強度選擇（對接 Boundary-First D0-D3）

| 強度 | 對應 | 什麼時候用 | 跑哪些章節 |
|------|------|-----------|-----------|
| **L1 Fast** | D0（無 protected surface） | 改 comment、UI copy、typo | §1 Q1+Q2 only，跳過 checklist |
| **L2 Standard** | D1（單 repo protected surface） | 一般 feature、bug fix | 完整 §1 + §2 + §3 + §6 同 pattern |
| **L3 Adversarial** | D2/D3（跨 repo contract、auth/HMAC、schema migration、durable write） | 跨 repo、D1/KV schema、HMAC、部署 | 完整 §0-§8，含反證存活制 + 同 pattern + deploy 驗證 |

---

## §0A 上下游對齊（Boundary-First → Executable Spec → Review）

- 若上游已有 `boundary-first-multi-repo-engineering` 輸出，**直接繼承** D0-D3、owner、consumer、surfaces touched、validation path；不要在 review 階段自己重造分類。
- 若上游已有 `executable-spec-planning` spec，**把 spec 視為 SSOT**，至少核對：Scope/Non-Scope、Decision Lock、CONTRACT（如適用）、Evidence Block、Ubiquitous Language Table、Code Quality Constraints、Rollback / Kill Switch、Final Authority 邊界。
- If upstream has a **Structural Completeness Checklist** (D1+), read the 12 generative answers as code review benchmarks. For each, verify the code actually implements what the Maker claimed to cover (auth actors, error scenarios, multi-store consistency, test coverage). Maker claimed but code didn't implement = P0 "spec-code gap".
- 若上游 artifact 缺失或互相矛盾，**BLOCKED** — 不是 `NO-GO candidate`，是硬停。要求補 spec / 補 preflight，回報 PM 等待決策。**不得用 reviewer 自己的猜測補齊**。
- 若 Phase Registry 顯示任何 Gate 被跳過且無 `WAIVED_BY_PM`，標記為 P0 finding：「Phase skip without PM authorization — violates UGP-2」。
- Reviewer 的責任是提出 finding 與 recommendation。最終 GO / NO-GO 由 Final Authority 宣告。
- **P0/P1 self-falsification 需 PM 驗證**：D2/D3 任務中，reviewer 的 P0/P1 findings 和 self-falsification 論點必須提交 PM 確認，不可自行結案。
> **Universal Gate Protocol**: 審查時必須檢查 Phase Registry 完整性。缺 Gate / 未授權 skip = P0。詳見 Universal Gate Protocol reference。

---

## §0 校準案例（Calibration Cases）

以下 10 個案例都是 **AI reviewer（含 Claude / Codex）曾經判斷錯誤** 的真實事件。審查前先讀這些案例校準直覺。

### Case 1: discontinued_status 大小寫（JOIN Key Mismatch）

- **AI reviewer 說**：「Database adapter 回傳 raw data，code 正確比對 discontinued_status」
- **實際發生**：Database stores `'NORMAL'`（大寫），code 比對 `'normal'`（小寫）→ 所有品項誤判為停產
- **根因**：Adapter 做 raw pass-through，沒有正規化層。test mock 用了 `'normal'`（跟 code 一致），所以 vitest PASS，但跟真實 database data不一致
- **教訓**：**Test mock 的值必須反映真實資料格式，不是用程式碼期望格式。** mock 跟 code 一致 ≠ mock 跟 production data 一致

### Case 2: KV Combo Snapshot vs Database Raw Data（資料語義混淆）

- **AI reviewer 說**：「database path 可以複用現有 cache combo 查詢邏輯」
- **實際發生**：cache combo 存的是 serverless script 預計算好的 materialized view（已含 fair share），Database stores的是 raw stock data → schemaVersion 不匹配 → 回傳 stale 預設值
- **根因**：同一個欄位名（`availableQty`），在 cache is computed output，在 database is raw input。審查者沒分辨「同名不同義」
- **教訓**：**同欄位名在不同資料來源可能有完全不同的語義。** 必須追蹤資料從 source → transform → consumer 的完整路徑

### Case 3: Q2d 誤判（追蹤深度不足）

- **AI reviewer 說**：「`acsErvSubsetDL` hardcode `modelType: 'ACS'`，是 hardcoding 隱患」
- **實際發生**：adapter 層有正確的 snake→camel 映射，`|| 'ACS'` 只是 defensive fallback
- **根因**：Review 只看到一層就下結論，沒追到 adapter 層的轉換邏輯
- **教訓**：**看到疑似問題時，必須往上下游各追至少一層再下結論。** 否則 false positive 會浪費修復時間

### Case 4: sync_batch_id Fallback 未行使

- **AI reviewer 說**：「sync_batch_id 一致性檢查已實作」
- **實際發生**：code 只 log mismatch，沒有真正 fallback 到 KV（spec 要求 fallback）。log 存在 ≠ 邏輯存在
- **根因**：`console.warn` 被當成「處理了」，但 warn 後繼續用 database result回覆使用者，完全沒有 fallback 分支
- **教訓**：**「有 log」≠「有處理」。** fallback 路徑必須有 code path 證據（if/else/return/throw），不是只有 log

### Case 5: KV Edge Cache 不被 KV.put() Invalidate

- **AI reviewer 說**：「更新 KV 值後，下次讀取就會拿到新值」
- **實際發生**：`cacheTtl: 86400` 的 edge cache 不被 `KV.put()` invalidate。舊值在其他 colo 繼續 serve 24hr
- **根因**：審查者把 KV 當成強一致性存儲，忽略 edge key-value store 的 eventually consistent 特性 + edge cache 獨立於 KV store
- **教訓**：**平台特性假設必須驗證。** edge key-value store、platform cache service、LINE API 等都有各自的 consistency model

### Case 6: scoringEngine.selectTop3() 不檢查 active 欄位

- **PM 決策文件說**：「selectTop3 會過濾 active=false 的 feature」
- **實際 code**：selectTop3 從 totalScore 排序取 top 3，完全沒有 `feature_master.active` 的 filter
- **根因**：PM 決策文件描述的是「應該做的事」，不是「已經做的事」
- **教訓**：**PM 決策文件 ≠ code ground truth。** 永遠要用 code 驗證文件，不是用文件驗證 code

### Case 7: vitest Mock database的語義陷阱

- **AI reviewer 說**：「vitest 全 PASS，ON CONFLICT 邏輯正確」
- **實際發生**：vitest mock database 只驗 JS 邏輯，不跑真實 SQL。PR#30 把 INSERT 改成 `ON CONFLICT(user_id) DO NOTHING`，mock PASS，但 production database的 UNIQUE constraint 是 `(code, role)` 不是 `(user_id)` → 資料靜默丟失
- **教訓**：**vitest mock 不驗 SQL 語義。** `ON CONFLICT` / `INSERT` / `UPDATE` / `DELETE` 的邏輯結構變更，必須拿 production schema（production schema inspection）交叉比對，不能只信 mock PASS

### Case 8: Serverless Script Ghost Code

- **AI reviewer 說**：「Script function已更新，重新執行即可」
- **實際發生**：Script editor 畫面顯示新 code，但執行環境跑的是 cached 舊版。`deploy push` 沒加 `--force` 被 skip，或 push 成功但 runtime 仍用舊版
- **教訓**：**Script deployment狀態不可信。** 解法：`Hotfix` 檔案（字母序最後載入，強制覆蓋函式定義）。驗證方式：在函式開頭加 `Logger.log('v2_TIMESTAMP')` 確認 runtime 版本

### Case 9: PowerShell UTF-8 Corruption

- **AI reviewer 說**：「用 PowerShell `-replace` 批次修改中文檔案內容」
- **實際發生**：`-replace` + `Set-Content` 預設 encoding 不是 UTF-8，中文字元被破壞成 mojibake
- **教訓**：**任何涉及中文字元的檔案操作，禁用 PowerShell inline 指令。** 必須用 file-based Node.js script（`fs.readFileSync / writeFileSync` with `'utf8'`）

### Case 10: Serverless Script Date toISOString() UTC 偏移

- **AI reviewer 說**：「`val.toISOString().split('T')[0]` 可以把 Date 轉成 YYYY-MM-DD」
- **實際發生**：The platform `getValues()` 回傳的 Date 是 Asia/Taipei 時區（UTC+8）。`toISOString()` 轉 UTC，midnight `2026-02-01 00:00 +08:00` 變成 `2026-01-31T16:00:00.000Z`，`.split('T')[0]` = `2026-01-31` — **日期差一天**
- **Subagent review 說**：「`instanceof Date` is standard pattern, low risk」→ 標 🟡 放過
- **根因**：reviewer 只看了 type check 是否正確，沒追問「轉換後的值對不對」。平台時區行為是隱性假設
- **教訓**：**Date → string 必須用 timezone-aware 方法（如 `Utilities.formatDate(date, 'Asia/Taipei', 'yyyy-MM-dd')`），禁用 `toISOString()`。** 審查時看到 `toISOString()` 就要追問：「這個 Date 是哪個時區？轉 UTC 後值還對嗎？」

---

## §1 四問必答（Four Mandatory Questions）

**每一個審查項目都必須回答以下 4 個問題，缺一不可：**

### Q1: 正面證據（Positive Evidence）

> 「你的 PASS 判定基於什麼具體 code 行號 / test case / log output？」

- 必須引用具體檔案路徑 + 行號或函式名
- 「看了 code 覺得對」不算證據
- 沒有行號引用的 PASS = 自動降級為 🟡 UNVERIFIED

### Q2: 反證場景（Falsification Scenario）

> 「什麼情境下這段 code 會產出錯誤結果？你驗證了這些場景嗎？」

- 列出至少 2 個可能出錯的邊界條件
- 如果無法想到任何反證場景 → 說明為什麼（可能是純函數 / 窮舉 test）
- Case 1/2 都是反證場景沒被想到的案例

### Q3: 邊界資料驗證（Boundary Data Validation）

> 「你用什麼真實資料 / golden test / 手算計算驗證了正確性？」

- mock data PASS ≠ production data PASS（Case 1 教訓）
- 涉及數值計算時，必須手算至少 1 筆，**附算式和結果**
- 涉及 JOIN / 查詢時，必須列出 key 的真實值和匹配邏輯

### Q4: 路徑行使證據（Path Execution Evidence）

> 「fallback / error / edge-case 的 code path 有被行使過嗎？證據？」

- log 存在 ≠ 路徑被行使（Case 4 教訓）
- test 覆蓋 happy path ≠ error path 被測試
- 如果沒有行使證據 → 🟡 UNVERIFIED，不是 ✅ PASS

---

## §2 五類 Checklist

### CL-1: SQL / D1 查詢

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | JOIN key 的欄位 + 大小寫是否一致？ | Case 1: `'NORMAL'` vs `'normal'` |
| 2 | `ON CONFLICT` 的 constraint name 是否對應正確的 UNIQUE index？ | PR#30: 有了 constraint 但沒注意語義變更 |
| 3 | `.prepare()` 的參數是否為 string literal？ | guard-sql-safety: 動態 SQL = injection 風險 |
| 4 | WHERE 條件是否覆蓋所有必要欄位？ | 缺 `discontinued_status != 'discontinued'` → 回傳停產品項 |
| 5 | 批次查詢的 `IN (?)` 是否正確展開？ | D1 不支援陣列參數，必須展開為 `IN (?,?,?)` |
| 6 | NULL 處理：`column = ?` 不匹配 NULL，要用 `IS NULL` | 遺漏 NULL 值 → 查無結果但不報錯 |
| 7 | `ON CONFLICT` / `INSERT` / `UPDATE` / `DELETE` 邏輯變更是否比對 production schema？ | Case 7: mock PASS 但 constraint name 對不上 production UNIQUE index |

### CL-2: KV / Storage Key

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | Key prefix 是否有 namespace 衝突？ | `inv:combo:` vs `inv:unit:` 邊界偵測 |
| 2 | `cacheTtl` 設定後，edge cache 不會被新 put 清除 | Case 5: edge cache 獨立於 store |
| 3 | `wrangler kv` 指令是否加了 `--remote`？ | 預設操作 local storage |
| 4 | Key 格式變更時，舊格式的 key 怎麼處理？ | 新舊 key 並存和過渡讀取邏輯 |
| 5 | Feature flag 的 fallback chain：FLAGS_KV → config → hardcode | 確認 fallback 各層基底正確 |
| 6 | PowerShell 操作含中文的檔案/KV value？ | Case 9: `-replace` / `Set-Content` 破壞 UTF-8 中文 |

### CL-3: 資料語義（Data Semantics）

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 同欄位名在不同來源是否同定義？ | Case 2: `availableQty` KV=computed, D1=raw |
| 2 | Adapter 層是否正規化所有 enum/status 值？ | Case 1: raw pass-through |
| 3 | 數值的單位和精度是否一致？ | 整數 vs 浮點、TWD vs USD |
| 4 | 時間欄位的格式和時區？ | ISO 8601 + UTC vs Asia/Taipei |
| 5 | Mock 的值是否反映真實資料格式？ | Case 1: mock='normal' 但 D1='NORMAL' |
| 6 | 計算公式是否跟 spec / server-side script一致？ | GT-22 fair share 手算驗證 |
| 7 | Script deployment後 runtime 是否真的跑新版？ | Case 8: editor 顯示新 code 但 runtime 跑 cached 舊版 |

### CL-4: Fallback / Error Handling

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | Error path 是否有具體處理（不是只 log）？ | Case 4: log mismatch but no fallback |
| 2 | fallback 後的回傳值 caller 有 null check？ | fallback 回傳 null 但 caller 沒 null check |
| 3 | try-catch 是否 swallow 了重要錯誤？ | `catch(e) {}` 靜默吞錯 |
| 4 | timeout 是否有上限？超時後的行為？ | LINE reply 5 秒限制、serverless 6-minute limit |
| 5 | Circuit breaker / kill switch 是否可行使？ | KV key 存在 ≠ code 有讀取和判斷邏輯 |
| 6 | Rollback 指令是否可在 < 60 秒內執行？ | `wrangler kv key put` 秒級 vs code deploy 分鐘級 |
| 7 | Bug 已修，但是否留下 regression gate？若沒有，是否有合理豁免？ | HR-8: 修了但沒 gate = 只是人類短期記住，gate 要加在根因層 |

### CL-5: 跨 Phase 時間相依

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 當前 phase 的 workaround，後續 phase 會不會失效？ | KV write-through 在 Phase 5 被拔掉，依賴 KV 的 path 失效 |
| 2 | Feature flag 的生命週期移除是否有 spec？ | flag 從 KV→D1 切換但沒有 rollback 路徑 |
| 3 | 防禦機制在依賴被拔後是否仍有效？ | Phase 5 後只剩 L6 oracle |
| 4 | test mock 是否在 schema 變更後 stale？ | DDL 加了欄位但 test fixture 沒更新 |
| 5 | Server-side script code vs worker-side code是否同步更新？ | 一邊改了 API contract，另一邊沒跟 |

---

## §2-Spec: 規格書審查 Checklist（Spec Mode 使用）

### CL-S1: 需求完整性

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 邊界條件是否定義？（空、零、最大、單筆） | 「支援批次處理」— batch = 0 時怎麼辦？ |
| 2 | 例外情境是否列舉？ | 只描述 happy path |
| 3 | 未定義行為是否明確標出？ | 隱含的「不會發生」假設 |
| 4 | 驗收標準是否可機械判定？ | 「功能正常」不是可測試的標準 |
| 5 | Scope 邊界是否明確？什麼不在 scope 內？ | AI agent scope creep |

### CL-S2: 內部一致性

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 各章節的數字是否一致？ | §3 說「≤4 次查詢」但 §5 暗示 N 次 |
| 2 | 狀態轉換是否完整？（每個狀態都有定義的出口） | status 有 active/inactive 但沒有重新啟用路徑 |
| 3 | 時序 / 順序假設是否明確？ | 假設系統 A 完成後系統 B 才讀取 |
| 4 | 術語是否全文一致？ | 「使用者」vs「會員」vs「帳號」混用 |

### CL-S3: 可實作性

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 是否有模糊動詞？（「處理」、「管理」、「支援」） | 實作者不知道要做什麼 |
| 2 | 隱性依賴是否浮出？ | 需要某個 spec 沒提到的系統的資料 |
| 3 | 效能宣稱是否有數學支撐？ | 「改善效能」— 改善多少？怎麼量？ |
| 4 | 每個 phase 是否定義 rollback？ | Phase 3 失敗時沒有回復路徑 |

### CL-S4: 資料契約

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 欄位名、型別、可 null 性是否定義？ | 「回傳使用者資料」— 哪些欄位？可 null？ |
| 2 | 跨系統欄位語義是否對齊？ | 同欄位名不同意思（Case 2 pattern） |
| 3 | Enum 值是否窮舉 + 正規化？ | 大小寫不一致（Case 1 pattern） |
| 4 | Breaking change 是否有 schema migration 路徑？ | 新增欄位但 consumer 沒更新 |

### CL-S5: 安全 / 權限 / 狀態機

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 角色 × 操作矩陣是否定義？ | 「admin 可以管理」— 管理什麼？ |
| 2 | Auth/簽章格式 sender 和 receiver 是否一致？ | HMAC canonical format drift |
| 3 | Durable write 是否有 rollback stance？ | 批次刪除沒有 undo 路徑 |
| 4 | 狀態轉換是否有授權閘門？ | 任何使用者都能轉換任何狀態 |

### CL-S6: Code Quality Constraints

| # | 檢查項 | 典型錯誤 |
|---|--------|---------|
| 1 | 共用抽象是否有穩定 consumer 或明確 variation point？ | 只有單一 caller 也硬抽 shared util |
| 2 | duplication / consolidation 的 tradeoff 是否有明寫？ | 為了 DRY 把不同語義流程硬合併 |
| 3 | 新跨模組依賴是否浮出到 spec？ | code 依賴了 spec 沒列出的 module |
| 4 | mock boundary / real-data boundary 是否明確？ | 只寫「測試會補」但沒說哪些要用真實資料 |
| 5 | observability / failure containment 是否定義？ | 新路徑上線後沒有 timeout / fallback / kill switch 說明 |

---

## §3 六條 Anti-Pattern（禁止的審查行為）

### AP-1: 「看起來對」速蓋

- :x: 「這段 code 看起來正確」
- :white_check_mark: 「這段 code 在 `file.js:L42` 做了 X，與 spec §3.2 要求的 Y 一致。反證場景 Z 由 test case TC-05 覆蓋。」

### AP-2: 信任 mock 等於信任 production

- :x: 「vitest 全 PASS 所以邏輯正確」
- :white_check_mark: 「vitest PASS 證明 code 跟 mock 一致。但需要驗證 mock 的值是否反映 production database/KV 的實際格式（Case 1 教訓）。」

### AP-3: 用文件驗證 code（因果反置）

- :x: 「spec 說要檢查 active 欄位，所以 code 應該有」
- :white_check_mark: 「spec 說要檢查 active 欄位。我搜尋了 `selectTop3` 函式，沒有找到 `active` 相關的 filter。這是 spec-code gap。」（Case 6 教訓）

### AP-4: Log 存在 = 處理存在

- :x: 「有 `console.warn('batch_id mismatch')` 所以有處理」
- :white_check_mark: 「`console.warn` 在 L55，但 L56 繼續用 database result回覆。沒有 if/else 分支走 fallback KV path。」（Case 4 教訓）

### AP-5: 停在第一層就下結論

- :x: 「`|| 'ACS'` 是 hardcoding 隱患」
- :white_check_mark: 「`|| 'ACS'` 出現在 L30。往下追：caller 在 adapter.js:L88 已做 `row.model_type` → camelCase 映射。`|| 'ACS'` 是 defensive fallback，不是 hardcoding。」（Case 3 教訓）

### AP-6: 平台假設不驗證

- :x: 「KV.put 後下次讀取就是新值」
- :white_check_mark: 「Cloudflare cache is eventually consistent。cacheTtl=86400 的 edge cache 不被 KV.put invalidate（LD-17 incident）。需要 versioned key prefix 或短 TTL 過渡。」（Case 5 教訓）

---

## §4 判定等級定義

| 等級 | 符號 | 定義 | 條件 |
|------|------|------|------|
| FAIL | :red_circle: | 確認有 Bug 或 spec-code gap | 有具體 code 行號 + 可重現場景 |
| UNVERIFIED | :yellow_circle: | 無法確認正確性 | Q1~Q4 任一無法回答、或缺乏 production 驗證 |
| PASS | :white_check_mark: | 確認正確 | Q1~Q4 全部有正面證據 + 反證場景排除 |
| N/A | :black_medium_square: | 不適用 | 該 checklist 項目在此 context 不相關 |

**升降級規則**：

- :yellow_circle: 可以降級為 :red_circle:（找到具體反證）
- :yellow_circle: 可以升級為 :white_check_mark:（補上 Q1~Q4 證據）
- :white_check_mark: 不可以回到 :yellow_circle:（除非發現新反證）
- 任何有 :red_circle: 的 review → 整體建議 NO-GO

---

## §5 反證存活制（Self-Falsification）

找到問題後，**花同等力氣嘗試推翻自己的 finding**：

1. 對每個 :red_circle: finding，嘗試構造「其實沒問題」的論證
2. 如果能成功推翻 → 降級為 :yellow_circle: 或移除
3. 如果推翻不了 → 維持 :red_circle:，並記錄推翻嘗試作為額外證據
4. 對每個 :white_check_mark:，問自己：「Case 1~10 的哪個模式可能在這裡重演？」

**目的**：防止過度報告（找太多低價值 finding 湊數）和漏報（自我確認偏誤）。

---

## §6 同 Pattern 擴散搜尋

修一個 bug 或找到一個問題時，問：

1. **「還有哪裡有同樣的 pattern？」** — 同一個 adapter 的其他欄位？同一種 JOIN 的其他查詢？
2. **「這個假設還在哪裡被使用？」** — 如果 mock 格式錯了，其他 test 的 mock 也可能錯
3. **「這個 workaround 會影響誰？」** — 如果加了 `.toLowerCase()`，下游期待大寫的地方會壞嗎？

有 repo / shell access 時：用 `rg` / `grep` 搜尋。只有貼文或受限審查時：明確列出建議搜尋指令，請 PM 或作者手動執行。

---

## §7 Execution-Layer Audit（6 層，Release Gate 或有 repo access 時使用）

來源：derived from internal release-audit iterations — PM 升級後的 v2 Audit Prompt

### Evidence 分級（引用 UGP Gate-by-Gate Evidence Matrix）

| 等級 | 名稱 | 定義 | §7 對應 |
|------|------|------|---------|
| **E1** | 機械 / Runtime | 可重跑的指令輸出 | Layer 0, 1, 2 |
| **E2** | 外部 AI 審查 | 獨立 AI（非 Maker）的判斷 | Layer 3（Codex/Gemini review） |
| **E3** | 自我宣稱 | Maker 自己的敘述性判斷 | 僅 D0 低風險項目可接受 |

詳見 UGP § Gate-by-Gate Evidence Matrix。

### Layer 定義

| Layer | 做什麼 | 方法 | 抓什麼 |
|:-----:|--------|------|--------|
| **0** | **Runtime Spot Check** | **執行** 至少 3 個可重跑指令（bash/curl/grep/test） | 宣稱 vs 實際不一致 |
| 1 | Static Check | **執行** eslint / grep / 特定欄位掃描 / SQL injection scan | 語法 + 殘留引用 |
| 2 | Behavioral Check | **執行** vitest（targeted + 全量）/ D1 `PRAGMA` | mock 層正確性 + schema 對齊 |
| 3 | Code Review | **讀取** 變更檔案 → 逐項比對 spec | spec-code gap |
| 4 | 交叉影響 | **執行** `git diff` + `grep` 確認未改動檔案 + 殘留引用 | 副作用 + scope creep |
| 5 | 測試品質 | **讀取** test 檔 → 比對 Gate 覆蓋率 | 測試盲區 |

**PM 信任測試做法**：在 prompt 裡埋 2 個已知 Bug（如「BLACKLIST_KEYWORDS 沒改」+「INSERT 欄位映射錯」），看 reviewer agent（如 Codex）能不能獨立抓到。抓不到 → 報告可信度打折。

**Hard Rule**：Layer 1~2 是「執行」不是「讀」— 必須有指令輸出證據，不是「我看了覺得沒問題」。

---

## §8 輸出格式模板

```markdown
# Adversarial Code Review Report

## Meta
- **Reviewer**: [Codex / Claude / ChatGPT / Human]
- **Target**: [PR# / 檔案 / 規格書]
- **Date**: YYYY-MM-DD
- **Mode**: Code / Spec / Release Gate
- **Intensity**: L1 Fast (D0) / L2 Standard (D1) / L3 Adversarial (D2/D3)
- **Overall Recommendation**: 🔴 NO-GO / 🟡 CONDITIONAL-GO / ✅ GO

## Findings

### [F-01] [標題]
- **等級**: 🔴 / 🟡 / ✅
- **位置**: `file.js:L42-L55` / `spec §3.2`
- **描述**: [具體問題]
- **Q1 正面證據**: [code 行號 / test case]
- **Q2 反證場景**: [什麼情境會出錯]
- **Q3 資料驗證**: [用什麼資料驗證 / 手算結果]
- **Q4 路徑行使**: [fallback 是否被測試]
- **反證存活** (L3): [嘗試推翻此 finding 的結果]
- **同 pattern** (L2+): [其他地方有無同樣問題]
- **建議修復**: [具體方案]

### [F-02] ...

## Checklist Summary

### Code Mode（Code 審查時填）
| Checklist | ✅ | 🔴 | 🟡 | ⬛ |
|-----------|:--:|:--:|:--:|:--:|
| CL-1 SQL/D1 | | | | |
| CL-2 KV/Storage | | | | |
| CL-3 Data Semantics | | | | |
| CL-4 Fallback/Error | | | | |
| CL-5 Cross-Phase | | | | |

### Spec Mode（Spec 審查時填）
| Checklist | ✅ | 🔴 | 🟡 | ⬛ |
|-----------|:--:|:--:|:--:|:--:|
| CL-S1 需求完整性 | | | | |
| CL-S2 內部一致性 | | | | |
| CL-S3 可實作性 | | | | |
| CL-S4 資料契約 | | | | |
| CL-S5 安全/權限/狀態機 | | | | |
| CL-S6 Code Quality Constraints | | | | |

## Execution Evidence（Code Mode L2+ 必填）

| # | 指令 / 動作 | 輸出摘要 | Reviewer 結論 |
|---|------------|---------|--------------|
| 1 | [e.g. `npx vitest run src/features/combo.test.ts`] | [PASS/FAIL + 關鍵數字] | [證明什麼 / 不能證明什麼] |
| 2 | [e.g. `grep -rn 'ON CONFLICT' src/`] | [找到 N 處，列出] | [跟 production schema 對齊 / 不對齊] |
| 3 | [e.g. `database CLI query --remote "PRAGMA index_list('users')"`] | [constraint 名稱] | [跟 code 一致 / 不一致] |

若無法執行（例如只有貼文、無 repo / shell access），填「N/A — 建議 PM 手動執行以下指令：[指令]」。

## PM 信任測試（如適用）
- **已知 Bug 1**: [PM 是否埋了已知 bug？找到了嗎？]
- **已知 Bug 2**: [同上]
- **信任度判定規則**:
  - 2/2 找到 → 報告可信度 HIGH
  - 1/2 找到 → 報告可信度 MEDIUM，建議第二位 reviewer 補審
  - 0/2 找到 → 報告可信度 LOW，整份報告需要重做或由 PM 親審

## Deploy 驗證 Checklist（Release Gate mode）

| Step | 指令 / 動作 | 預期結果 |
|------|------------|---------|
| 1 | Deploy | `wrangler deploy --env=...` |
| 2 | 觸發測試場景 | [用什麼查詢 / 什麼資料] |
| 3 | 驗證 log | [哪個 log key，預期什麼值] |
| 4 | 交叉驗證 | [比較兩條獨立路徑，值必須一致] |

## 對接 Boundary-First Close-Out（D1+ 時填）
- **Decision level**: D0 / D1 / D2 / D3
- **Owner**: [repo and layer]
- **Consumer**: [repo or caller affected]
- **Surfaces touched**: [contract / auth / schema / storage / permission]
- **Executable spec**: [path or N/A]
- **Locked artifacts checked**: [Scope / Decision Lock / CONTRACT / Evidence Block / UL Table / CQ / Rollback / Kill Switch]
- **Rollback stance**: [rollback path, fallback, or blast-radius control]

## Reviewer 誠實揭露
- **沒有驗證的部分**: [誠實列出]
- **做了哪些假設**: [列出]
- **建議下一步**: [需要誰用什麼方式補驗證]
```

---

## §9 使用流程

### L1 Fast（D0）
```
1. 回答 §1 Q1+Q2
2. 檢查 §3 Anti-Pattern
3. 輸出簡短判定
```

### L2 Standard（D1）
```
1. 選擇模式（Code / Spec），若已有 boundary-first / executable spec，先讀上游 artifact
2. 逐項走 §2 對應 Checklist → 標記 🔴/🟡/✅/⬛
3. 若為 Code Mode：至少提供 1 項 execution evidence（test output / grep result / schema check / log evidence 其一）
4. 每個 🟡 和 ✅ → 回答 §1 四問必答
5. 每個 finding → §6 同 pattern 擴散搜尋
6. 檢查是否觸犯 §3 六條 Anti-Pattern
7. 用 §8 模板輸出報告
8. 誠實揭露未驗證的部分
```

### L3 Adversarial（D2/D3）
```
1. 選擇模式（Code / Spec / Release Gate），先讀 boundary-first 分類與 executable spec（若存在）
2. 讀 §0 校準案例（10 個）→ 校準審查直覺
3. 逐項走 §2 對應 Checklist → 標記 🔴/🟡/✅/⬛
   - Release Gate: 跑兩套 Checklist（Code + Spec）
4. 每個 🟡 和 ✅ → 回答 §1 四問必答
5. 每個 🔴 → §5 反證存活制（嘗試推翻自己）
6. 每個 finding → §6 同 pattern 擴散搜尋
7. 檢查是否觸犯 §3 六條 Anti-Pattern
8. Release Gate: 走 §7 五層審查
9. 用 §8 模板輸出報告（含 Boundary-First Close-Out）
10. 誠實揭露未驗證的部分
```

**Hard Rule**：

- 審查者不得同時是 code 作者（Maker-Checker 分離）
- 任何 🔴 → 整體建議 NO-GO，不得以「其他都 PASS」覆蓋
- PM 可能埋已知 Bug 做信任測試 → 如果已知 Bug 沒被找到，整份報告信度降級
- 「沒有問題」不是合法的審查結論 → 至少要列出「我驗證了什麼」和「我沒驗證什麼」
- D2/D3 的 review 報告必須包含 Boundary-First Close-Out 欄位
- 上游 preflight / spec 若缺失，不得自行補假設當作已驗證事實
