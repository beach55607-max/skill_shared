# AI Engineering Skills

Community-safe workflow and planning skills for Codex and Claude Code.

This repository contains two skill packs:

## Skill Packs

### 1. Boundary-First Multi-Repo Engineering

A boundary-first engineering workflow for multi-repo, multi-runtime, and contract-sensitive tasks.

- **Codex edition** — `codex/boundary-first-multi-repo-engineering/`
- **Claude Code edition** — `claude-code/boundary-first-multi-repo-engineering/`

**When to use:** Any task that may cross a repo, service, or contract boundary.
**When NOT to use:** Single-file scripts, typo fixes, formatting — anything with zero protected surface.

### 2. Executable Spec Planning (NEW)

A planning workflow that turns fuzzy requirements into executable specifications — specs that an AI agent can implement without ambiguity, and that can be verified mechanically after implementation.

- **Agent-agnostic** — `executable-spec-planning/` (works with both Claude Code and Codex)

**When to use:** New features, migrations, refactors, or any task handed to an AI agent for execution.
**When NOT to use:** Single-line fixes, doc edits, infra console operations.

**Key capabilities:**

- Architecture Fit Check before writing any spec (prevents building the right thing with the wrong architecture)
- Decision Lock Table with zero-TBD gate
- CONTRACT triple (INPUT + OUTPUT + APPROVAL) for information output tasks
- Scope Negative List to prevent AI scope creep
- Maker-Checker separation with trust calibration
- 25-check completeness guard (Layer A manual + Layer B executable scripts)
- Risk escalation triggers (permission/DB mutations/fan-in/routing/prior incidents)
- Governance audit (7 items) in close-out reports

## Quick Start

### Boundary-First Engineering

**Claude Code:** Copy `claude-code/.../CLAUDE.md` to your project root, copy `references/` to `.claude/boundary-first/`. Done — it auto-loads every conversation.

**Codex:** Copy `codex/.../` to `~/.codex/skills/boundary-first-multi-repo-engineering/`, restart Codex.

### Executable Spec Planning

**Claude Code:** Copy `executable-spec-planning/` to `.claude/skills/executable-spec-planning/`, or paste `SKILL.md` content into your project's `CLAUDE.md`.

**Codex:** Copy `executable-spec-planning/` to `~/.codex/skills/executable-spec-planning/`, restart Codex.

## Capability Map

```text
Decision Layer     D0-D3 severity classification
                   Implementation plan template
                   Maker-checker for D2/D3
                   ─────────────────────────────────
Boundary Layer     Owner / consumer identification
                   Cross-boundary contract model
                   Conflict resolution
                   Adapter selection (5 types + fallback)
                   ─────────────────────────────────
Verification Layer Mechanical verification (gates, guards, CI, GT, contract tests)
                   6-level verification depth ladder
                   One-side-only = partial, not pass
                   ─────────────────────────────────
Delivery Layer     Structured close-out template
                   Rollback stance mandatory for durable changes
                   File safety guardrail
                   Residual risk disclosure
```

---

## 中文說明

### 這是什麼

這是一套工程治理 workflow，目的是讓 AI coding agent 在動手改 code 之前，先把方向、邊界和風險想清楚。

如果你做過多 repo、前後端分離、admin tool、automation、browser extension 這類系統，你大概知道：真正昂貴的錯誤，往往不是 syntax error，而是 owner 判錯、contract 判錯、rollback 沒想、validation 驗錯地方。

這個 workflow 的核心想法：

- 先找真正的 owner repo 或 runtime
- 先看 contract 與 security surface
- 先判斷這次變更會不會碰到 durable state、rollback、observability
- 先決定需要多少儀式（D0 直接做，D3 要先確認才能動）
- 最後才開始改 code，而且要跑對深度的 validation

它也把 repo-local 規則（`CLAUDE.md`、`AGENTS.md`）視為高優先權威，並避免 agent 因為圖方便就自己刪檔、搬檔或大範圍覆寫。

### 這不是什麼

- 不是初學者 coding 教學
- 不是框架或 runtime
- 不是萬用 prompt pack
- 不是 repo-local 規則、tests、CI 的替代品

如果你的任務是單檔小腳本、沒有 protected surface、不碰 contract boundary，這套 workflow 會自動分類為 D0，不需要走完整儀式。

### 適合誰

- 在多 repo 專案工作的工程師
- 想讓 AI agent 不要一上來就改錯地方的人
- 需要做 review、debug、cross-repo analysis 的工程師
- 已經有經驗，但想把 preflight 和 validation 思路標準化的團隊

### 為什麼需要這個

因為很多 AI coding 的失敗，不是 syntax 錯誤。它們是：

- **owner 判錯** — 改了 caller，真正的 owner 在 producer
- **contract 判錯** — 以為是 UI 小改，其實是 shared contract migration
- **rollback 沒想** — durable write 寫到一半失敗，沒有回退路徑
- **validation 驗錯** — 只跑了 caller-side test，producer 那邊根本沒驗

這個 workflow 的用途，就是在 coding 之前先把這些風險拉到檯面上。

### 真實失敗模式

以下是這個 workflow 設計來防止的四種常見失敗。全部匿名化，不含任何內部細節。

#### 失敗模式 1：欄位型別小改，實際是 shared contract migration

**表面看起來：** 只是 caller 端多加一個 request 欄位，或把某個欄位從單值改成多值。看起來像前端小調整。

**真正痛點：** 真正的 owner 可能不是 caller，而是驗證與持久化這個欄位的 producer。一旦只改 caller，producer validation 拒收、storage 仍假設舊型別、其他 consumer 繼續送舊格式，開始出現 silent drift。

**如果沒有這個 workflow：** agent 只改 caller 端，跑過 caller-side test 就結束，把 cross-boundary change 誤當成 UI 小修。

**這個 workflow 怎麼攔：** 先找 system of record / owner，先檢查是不是 contract surface，producer / consumer 兩邊一起看，validation 不准只停在 caller-side。把任務重新定義成：這是不是一個 shared contract migration。

#### 失敗模式 2：簽章修正，實際會讓所有 consumer 同時失效

**表面看起來：** 只是調整一段驗證 / 簽章邏輯。diff 很小，看起來像局部 auth fix。

**真正痛點：** 這其實是 shared verification contract change。如果只有 producer 先改，所有依賴舊格式的 consumer 在部署後立刻失效，通常沒有安全的回退窗口。

**如果沒有這個 workflow：** agent 把任務當成單 repo 修補，只驗一邊，實際上線時整條整合鏈一起斷。

**這個 workflow 怎麼攔：** 列成 security surface + cross-boundary contract + high-risk validation task。強制思考哪些 consumer 會一起壞、是否需要 dual-format acceptance、是否需要 staged rollout、驗證要不要升級成雙邊與強 gate。

#### 失敗模式 3：admin bulk action，實際是 durable write 與 rollback 問題

**表面看起來：** 只是 admin console 多一個按鈕、多一條 API call、多一個批次動作。

**真正痛點：** 這可能是高風險 durable write。執行到一半失敗，系統會落在部分成功、部分失敗的中間狀態。沒有 rollback、fallback 或 blast-radius 控制時，問題不是功能壞掉，而是資料語意被破壞。

**如果沒有這個 workflow：** agent 先把入口接起來，覺得按鈕能按、API 能打就算完成，沒有先回答 partial failure 怎麼處理、資料會留下什麼中間態、可以怎麼回退。

**這個 workflow 怎麼攔：** 把任務判斷成 durable state change，要求在 coding 前先寫 rollback stance，把 bulk action 從 UI 功能升級成資料風險任務，validation 深度提高。避免把高風險資料操作偽裝成一般 CRUD 變更。

#### 失敗模式 4：extension 多一個權限，實際是 runtime boundary change

**表面看起來：** 只是多一個 extension permission，或 background message routing 多一個分支。看起來像單一檔案修改。

**真正痛點：** 這其實是 runtime boundary change。它可能同時影響使用者授權提示、content / background / popup 的 message flow、storage schema、runtime 行為。build 過了不等於安全。

**如果沒有這個 workflow：** agent 只改 manifest 或 background script，跑過 build 就宣告完成，沒有檢查是不是 permission surface、會不會改變 extension contexts 之間的 contract、需不需要 runtime smoke check。

**這個 workflow 怎麼攔：** 標成 permission surface + message-routing contract + runtime validation task。把任務從設定檔小改重新框成：這是一個跨執行期邊界的變更，build 成功不是充分證據。

### 這個 repo 裡有什麼

#### Codex 版

放在 `codex/boundary-first-multi-repo-engineering/`，包含 `SKILL.md`、`agents/openai.yaml`、`references/`。

安裝方式：把該資料夾複製到 `~/.codex/skills/boundary-first-multi-repo-engineering/`，重新啟動 Codex。

#### Claude Code 版

放在 `claude-code/boundary-first-multi-repo-engineering/`，包含 `CLAUDE.md`（入口）和 `references/`。

安裝方式：把 `CLAUDE.md` 複製到你的 project root，把 `references/` 複製到 `.claude/boundary-first/`。Claude Code 會自動載入 `CLAUDE.md`。

#### 我該選哪個版本

| 情境 | 建議 |
|------|------|
| 你用 OpenAI Codex | Codex 版 |
| 你用 Anthropic Claude Code | Claude Code 版 |
| 你兩個都用 | 兩個都裝，它們可以並存 |
| 你想要最完整的治理流程 | Claude Code 版（多了 Decision Gate、Implementation Plan Template、Fallback Adapter、Conflict Resolution） |
| 你想要輕量起步 | Codex 版（核心方法論一樣，儀式較輕） |

#### Claude Code 版比 Codex 版多了什麼

- Decision Gate (D0-D3) 變更嚴重度分級
- Decision tree 取代 keyword list 的 owner selection
- 每個 adapter 內建 Common Mistake Scenario 示範
- cross-boundary-contracts 有 3 個具體匿名化範例
- Implementation Plan Template（D1/D2/D3 施工前固定格式）
- Fallback adapter（無 adapter 匹配時的指引）
- Conflict resolution（多 repo 規則衝突時的解決策略）
- Maker-checker 最小證據定義
- Close-out 結構化模板

兩個版本都包含相同的 5 個泛用 adapters：backend service、frontend app、admin console、automation bot or sync worker、browser extension。

### 怎麼使用

#### Codex

顯式呼叫：

```text
Use $boundary-first-multi-repo-engineering to do a read-only preflight for a frontend change that may alter a backend request payload. Identify the owner boundary, contract risk, security surface, and required validation.
```

隱式使用：

```text
I need to review a change that touches a frontend app, a backend route, and extension storage. Do a read-only boundary analysis first, then tell me which system is the owner and what validation depth is appropriate.
```

#### Claude Code

Claude Code 會自動載入 project root 的 `CLAUDE.md`，不需要顯式呼叫。開始任何工程任務時，workflow 會自動執行 Decision Gate 和 Preflight。

### 公開版的設計原則

這個 repository 是公開版，刻意保留的是方法論，不是任何公司內部拓樸。

它會教你怎麼想：

- owner boundary
- producer / consumer relationship
- contract risk
- validation depth
- rollback stance
- change severity

但不會帶入任何內部 repo 名稱、私有驗證指令、公司流程或內部架構細節。

---

## English

### What This Is

A boundary-first engineering workflow for multi-repo, multi-runtime, and contract-sensitive tasks.

The goal is simple: help AI coding agents get the direction right before they start changing code.

In multi-repo systems — frontend/backend splits, admin tools, automation flows, and browser extensions — the most expensive mistakes are usually not syntax mistakes. The real failures come from changing the wrong repo, assuming the wrong owner, missing a contract boundary, or validating the wrong thing.

This workflow encourages a more deliberate engineering starting point:

- identify the true owner repo or runtime first
- inspect contract and security surfaces before editing
- think about durable state, rollback, and observability early
- classify change severity and match ceremony to risk
- choose validation depth based on risk, not convenience

It also treats repo-local instructions (`CLAUDE.md`, `AGENTS.md`) as higher authority and prevents the agent from deleting, moving, or broadly overwriting files just to simplify the task.

### What This Is Not

- Not a beginner coding tutorial
- Not a framework or runtime
- Not a generic prompt pack for all tasks
- Not a substitute for repo-local rules, tests, or CI

If your task is a single-file script with no protected surface and no contract boundary, this workflow classifies it as D0 and requires minimal ceremony.

### Who This Is For

- Engineers working across multiple repositories
- People who want AI agents to stop editing the first file they see
- Engineers doing review, debugging, or cross-repo analysis
- Teams that want a more consistent preflight and validation mindset

### Why This Exists

Because many AI coding failures are not syntax failures. They are ownership failures, contract failures, rollback failures, and validation failures.

The purpose of this workflow is to surface those risks before coding starts.

### Real Failure Patterns

These are the four failure patterns this workflow was designed to prevent. All anonymized, no internal details.

#### Pattern 1: A small payload change that is actually a shared contract migration

**What it looks like:** A caller adds one request field, or changes a field from a scalar to a multi-value shape. It looks like a small frontend update.

**The real pain point:** The real owner may not be the caller. It may be the producer that validates and persists the field. If only the caller changes, producer-side validation rejects the new shape, storage still assumes the old type, and other consumers keep sending the old format, creating silent drift.

**Without this workflow:** An agent updates only the caller side, stops after caller-side tests pass, and misclassifies the task as a UI tweak.

**How this workflow prevents it:** Identifies the system of record, classifies the change as a contract surface, inspects both producer and consumer, and prevents validation from stopping at the caller side only. Reframes the task as: is this actually a shared contract migration?

#### Pattern 2: An auth fix that would break every consumer at once

**What it looks like:** A small change to signing or verification logic. The diff is small, so it looks like a local auth fix.

**The real pain point:** This is often a shared verification contract change. If only the producer changes first, every consumer depending on the old format may fail immediately after deployment, often with no safe rollback window.

**Without this workflow:** An agent treats the task like a single-repo patch, validates only one side, and breaks an entire integration chain at release time.

**How this workflow prevents it:** Classifies the task as a security surface, cross-boundary contract, and high-risk validation task. Forces the agent to consider which consumers fail together, whether dual-format acceptance is needed, whether staged rollout is required, and whether validation must escalate to both sides.

#### Pattern 3: A bulk action that is actually a durable write with no rollback

**What it looks like:** A new button, one more API call, or one more bulk action in an admin or automation flow.

**The real pain point:** This may be a high-risk durable write. If the operation fails halfway, the system is left in a partially updated state. Without rollback, fallback, or blast-radius controls, the failure is not just one broken feature — it is broken data semantics.

**Without this workflow:** An agent connects the entry point and stops once the button works or the API responds, without answering how partial failure is handled or how the change can be rolled back.

**How this workflow prevents it:** Treats the task as a durable state change, requires a rollback stance before coding, escalates validation depth beyond unit tests. Prevents a high-risk data operation from being disguised as routine CRUD work.

#### Pattern 4: One more extension permission that is actually a runtime boundary change

**What it looks like:** One more extension permission, or one more branch in background message routing. It looks like a single-file change.

**The real pain point:** This is usually a runtime boundary change. It can affect user consent, message flow across extension contexts, storage schema, and runtime behavior. A passing build does not prove the change is safe.

**Without this workflow:** An agent updates only the manifest or background script, passes the build, and declares success without checking permission surfaces, message-routing contracts, or runtime smoke paths.

**How this workflow prevents it:** Classifies the task as a permission surface, message-routing contract, and runtime validation task. Reframes the work from a small config edit into a change across runtime boundaries where a successful build is not enough evidence.

### What Is In This Repository

#### Codex Edition

Lives in `codex/boundary-first-multi-repo-engineering/`. Contains `SKILL.md`, `agents/openai.yaml`, and `references/`.

Install: copy the folder to `~/.codex/skills/boundary-first-multi-repo-engineering/`, then restart Codex.

#### Claude Code Edition

Lives in `claude-code/boundary-first-multi-repo-engineering/`. Contains `CLAUDE.md` (entry point) and `references/`.

Install: copy `CLAUDE.md` to your project root, copy `references/` to `.claude/boundary-first/`. Claude Code auto-loads `CLAUDE.md`.

#### Which Edition Should I Use

| Situation | Recommendation |
|-----------|----------------|
| You use OpenAI Codex | Codex edition |
| You use Anthropic Claude Code | Claude Code edition |
| You use both | Install both, they coexist |
| You want the most complete governance | Claude Code edition (adds Decision Gate, Implementation Plan, Fallback Adapter, Conflict Resolution) |
| You want a lighter starting point | Codex edition (same core methodology, lighter ceremony) |

#### What Claude Code Edition Adds

- Decision Gate (D0-D3) severity classification
- Decision tree instead of keyword list for owner selection
- Common Mistake Scenario in each adapter
- 3 concrete anonymized examples in cross-boundary-contracts
- Implementation Plan Template (fixed pre-implementation format for D1/D2/D3)
- Fallback adapter for unmatched system types
- Conflict resolution for multi-repo rule conflicts
- Maker-checker minimum evidence definition
- Structured close-out template

Both editions share the same 5 generic adapters: backend service, frontend app, admin console, automation bot, browser extension.

### Example Prompts

#### Codex

```text
Use $boundary-first-multi-repo-engineering to do a read-only preflight for a frontend change that may alter a backend request payload. Identify the owner boundary, contract risk, security surface, and required validation.
```

#### Claude Code

Claude Code auto-loads `CLAUDE.md` from the project root. The workflow runs automatically when you start any engineering task. No explicit invocation needed.

### Public-Safe Design

This repository is intentionally public-safe. It keeps the method, not the internal topology.

It focuses on:

- owner boundaries
- producer and consumer relationships
- contract risk
- validation depth
- rollback stance
- change severity classification

And it intentionally avoids:

- company-specific repo names
- internal architecture details
- private validation commands
- organization-specific processes

### Platform Packaging

This repository ships two platform-specific packages:

- `codex/boundary-first-multi-repo-engineering/` — for OpenAI Codex
- `claude-code/boundary-first-multi-repo-engineering/` — for Anthropic Claude Code

That layout keeps each platform's entry-point format separate while sharing the same methodology.
