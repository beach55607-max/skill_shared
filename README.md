# Boundary-First Multi-Repo Engineering

Community-safe Codex skill for multi-repo engineering work.

This repository currently packages the Codex edition of the skill.
Other platform-specific editions can live alongside it later.

## 中文說明

### 這是什麼

這是一個給 Codex 用的 skill，目的是幫工程任務先做對方向，再開始改程式。

目前這個 repo 先封裝的是 Codex 版本，之後也可以在同一個 repo 底下並列其他平台版本。

如果你做過多 repo、前後端分離、admin tool、automation、browser extension 這類系統，你大概會知道：真正容易出事的地方，通常不是「程式不會寫」，而是「一開始就改錯 repo、看錯 owner、漏掉 contract、驗錯地方」。

這個 skill 的核心想法很簡單：

- 先找真正的 owner repo 或 runtime
- 先看 contract 與 security surface
- 先判斷這次變更會不會碰到 durable state、rollback、observability
- 最後才決定要不要改，以及該跑多深的 validation

你可以把它理解成一個先釐清方向與邊界的起手式。不是一上來就寫 code，而是先把方向、邊界和風險看清楚。

### 適合誰

這份 skill 很適合：

- 剛開始碰多 repo 專案的工程師
- 想讓 Codex 不要一上來就改錯地方的人
- 需要做 review、debug、cross-repo analysis 的工程師
- 已經有經驗，但想把 preflight 和 validation 思路標準化的人

### 它會怎麼幫你

這個 skill 會引導 Codex 先做下面幾件事：

1. 先分類這次變更是 UI、API、auth、schema、automation、observability，還是 migration。
2. 找出真正的 owner repo 或 runtime，而不是只看第一個看到的 caller。
3. 檢查 contract surface，像是 request shape、response shape、schema fields、message formats。
4. 檢查 security surface，像是 auth、permissions、secrets、host access、durable writes。
5. 想清楚 rollback 風險，避免改完才發現資料格式或流程無法回退。
6. 決定 observability 與 debug 策略，避免把 noisy logging 直接灌進正常路徑。
7. 選對 validation depth，不要只跑 lint 就以為安全。

這套流程的重點不是讓回答變長，而是讓你少踩高成本的坑。

### 實際案例

#### 案例 1：你以為只是前端 payload 小調整

情境：前端想把送去後端的 request payload 多加一個欄位，或把某個欄位從 string 改成 array。

很多 agent 看到這種需求，第一反應會是直接去改前端 form、mapper、API client，然後跑一下前端 test 就結束。

這個 skill 會先提醒你：

- 真正的 owner 很可能不是 frontend，而是 backend route 或 shared contract
- 這不是單純 UI 變更，而是 contract 變更
- 要一起看 producer 跟 consumer
- validation 不能只停在 caller-side test

換句話說，它會把「看起來只是改一個欄位」的任務，重新框成一個有邊界的 engineering task。

#### 案例 2：你以為只是 extension 多一個權限

情境：browser extension 需要新加一個 `host_permissions`，或者 background message routing 要多一條分支。

沒有 preflight 的情況下，agent 很容易只改 `manifest.json` 或 background script，然後覺得 build 過了就沒事。

這個 skill 會先檢查：

- 這是不是 permission surface
- 會不會影響 content script、background、storage schema、message passing
- 是否需要 runtime smoke check，而不是只跑 unit test

這種情況最有價值的地方在於，它會逼 agent 承認「這不是單一檔案改動」，而是 runtime boundary 變更。

#### 案例 3：你以為只是 admin 工具多一個 bulk action

情境：admin console 或 automation flow 需要新增一個批次同步、批次更新、或 review/promote 動作。

一般 agent 常見的做法是先把 UI 按鈕和 API call 接上，但忽略：

- 這是不是 durable write
- 有沒有 rollback 策略
- schema 或 review state 會不會被影響
- 驗證是不是要拉高到 integration / gate level

這個 skill 在這種任務上的價值，不是讓 code 寫更快，而是避免把「高風險變更」偽裝成「一般 CRUD 修改」。

### 這個 repo 裡有什麼

目前的 Codex skill 放在：

- `codex/boundary-first-multi-repo-engineering/`

這個資料夾裡包含：

- `SKILL.md`
- `agents/openai.yaml`
- `references/`

目前內建的泛用 adapters 有：

- backend service
- frontend app
- admin console
- automation bot or sync worker
- browser extension

### 怎麼安裝

把下面這個資料夾複製到你的 Codex skills 目錄：

- `codex/boundary-first-multi-repo-engineering/`

常見路徑會是：

- `~/.codex/skills/boundary-first-multi-repo-engineering/`

複製完之後，重新啟動 Codex。

### 怎麼使用

顯式呼叫：

```text
Use $boundary-first-multi-repo-engineering to do a read-only preflight for a frontend change that may alter a backend request payload. Identify the owner boundary, contract risk, security surface, and required validation.
```

隱式使用：

```text
I need to review a change that touches a frontend app, a backend route, and extension storage. Do a read-only boundary analysis first, then tell me which system is the owner and what validation depth is appropriate.
```

### 公開版的設計原則

這個 repository 是公開版，所以我刻意保留的是方法論，不是任何公司內部拓樸。

也就是說，它會教你怎麼想：

- owner boundary
- producer / consumer relationship
- contract risk
- validation depth

但不會帶入任何內部 repo 名稱、私有驗證指令、公司流程或內部架構細節。

如果你想讓 Codex 在動手前先把方向、邊界和風險想清楚，這份 skill 就是往這個用途設計的。

## English

### What This Is

This is a Codex skill for multi-repo engineering work.

The goal is simple: help Codex get the direction right before it starts changing code.

In multi-repo systems, frontend/backend splits, admin tools, automation flows, and browser extensions, the most expensive mistakes usually are not syntax mistakes. The real failures come from changing the wrong repo, assuming the wrong owner, missing a contract boundary, or validating the wrong thing.

This skill encourages a more deliberate engineering starting point:

- identify the true owner repo or runtime first
- inspect contract and security surfaces before editing
- think about durable state, rollback, and observability early
- choose validation depth based on risk, not convenience

In short: do not start with code. Start with boundaries.

### Who This Is For

This skill is a good fit for:

- engineers who are new to multi-repo work
- people who want Codex to stop editing the first file it sees
- engineers doing review, debugging, or cross-repo analysis
- teams that want a more consistent preflight and validation mindset

### How It Helps

The skill guides Codex through a boundary-first workflow:

1. Classify the change as UI, API, auth, schema, automation, observability, or migration.
2. Identify the true owner repo or runtime, not just the nearest caller.
3. Check contract surfaces such as request shape, response shape, schema fields, and message formats.
4. Check security surfaces such as auth, permissions, secrets, host access, and durable writes.
5. Think through rollback risk before changing data or shared behavior.
6. Design observability and debug behavior instead of sprinkling noisy logs everywhere.
7. Choose the right validation depth instead of stopping at lint alone.

The goal is not to make answers longer. The goal is to reduce high-cost mistakes.

### Practical Scenarios

#### Scenario 1: It looks like a small frontend payload change

Situation: a frontend flow needs one extra request field, or a field changes from string to array.

Many agents will immediately update the form, the mapper, and the API client, then stop after a frontend test passes.

This skill pushes a different line of thinking:

- the true owner may be the backend route or shared contract, not the frontend
- this is not just a UI change, it is a contract change
- producer and consumer both need inspection
- validation should not stop at caller-side tests

In other words, it reframes “just one field change” into a bounded engineering task.

#### Scenario 2: It looks like just one more extension permission

Situation: a browser extension needs a new `host_permissions` entry, or the background message routing needs one more branch.

Without preflight, an agent may only update `manifest.json` or the background script and assume a successful build is enough.

This skill first checks:

- whether this is a permission surface
- whether it affects content scripts, background logic, storage schema, or message passing
- whether runtime smoke checks are needed instead of only unit tests

The value here is that it forces the agent to recognize a runtime boundary change, not just a single-file edit.

#### Scenario 3: It looks like just one more admin bulk action

Situation: an admin console or automation flow needs a new bulk sync, bulk update, or review/promote action.

A common agent mistake is to wire up the button and API call but skip the harder questions:

- is this a durable write
- what is the rollback path
- does it affect schema or review-state meaning
- should validation move up to integration or gate level

In this kind of task, the value of the skill is not faster code generation. It is preventing a high-risk change from being treated like routine CRUD work.

### What Is In This Repository

The actual skill lives in:

- `boundary-first-multi-repo-engineering/`

That folder contains:

- `SKILL.md`
- `agents/openai.yaml`
- `references/`

The current generic adapters cover:

- backend service
- frontend app
- admin console
- automation bot or sync worker
- browser extension

### Install

Copy this folder into your Codex skills directory:

- `boundary-first-multi-repo-engineering/`

A typical destination is:

- `~/.codex/skills/boundary-first-multi-repo-engineering/`

Then restart Codex.

### Example Prompts

Explicit invocation:

```text
Use $boundary-first-multi-repo-engineering to do a read-only preflight for a frontend change that may alter a backend request payload. Identify the owner boundary, contract risk, security surface, and required validation.
```

Implicit usage:

```text
I need to review a change that touches a frontend app, a backend route, and extension storage. Do a read-only boundary analysis first, then tell me which system is the owner and what validation depth is appropriate.
```

### Public Version Design

This repository is intentionally public-safe.

It keeps the method, not the internal topology.

That means it focuses on:

- owner boundaries
- producer and consumer relationships
- contract risk
- validation depth

And it intentionally avoids:

- company-specific repo names
- internal architecture details
- private validation commands
- organization-specific processes

If you want Codex to think through direction, boundaries, and risk before making changes, this skill is built for that purpose.

### Platform Packaging

This repository currently ships the Codex package here:

- `codex/boundary-first-multi-repo-engineering/`

That layout keeps room for future platform-specific variants in the same repository without mixing entry-point formats together.
