# Boundary-First Multi-Repo Engineering

Community-safe Codex skill for multi-repo engineering work.

## 中文說明

### 這是什麼

這是一個給 Codex 用的 skill，目的是幫工程任務先做對方向，再開始改程式。

如果你做過多 repo、前後端分離、admin tool、automation、browser extension 這類系統，你大概會知道：真正容易出事的地方，通常不是「程式不會寫」，而是「一開始就改錯 repo、看錯 owner、漏掉 contract、驗錯地方」。

這個 skill 的核心想法很簡單：

- 先找真正的 owner repo 或 runtime
- 先看 contract 與 security surface
- 先判斷這次變更會不會碰到 durable state、rollback、observability
- 最後才決定要不要改，以及該跑多深的 validation

你可以把它理解成一個比較有資深工程師味道的起手式。不是一上來就寫 code，而是先把邊界看清楚。

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

### 這個 repo 裡有什麼

實際的 skill 放在：

- `boundary-first-multi-repo-engineering/`

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

- `boundary-first-multi-repo-engineering/`

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

如果你想把 Codex 從「會寫程式」提升到「比較像資深工程師在帶方向」，這份 skill 就是往那個方向設計的。

## English

### What This Is

This is a Codex skill for multi-repo engineering work.

The goal is simple: help Codex get the direction right before it starts changing code.

In multi-repo systems, frontend/backend splits, admin tools, automation flows, and browser extensions, the most expensive mistakes usually are not syntax mistakes. The real failures come from changing the wrong repo, assuming the wrong owner, missing a contract boundary, or validating the wrong thing.

This skill teaches a more senior-engineer style starting point:

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

If you want Codex to behave less like a fast code generator and more like a careful senior engineer doing preflight first, this skill is built for that direction.
