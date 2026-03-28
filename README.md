# Boundary-First Multi-Repo Engineering

社群可公開分享的 Codex skill，專門用在多 repo 工程工作流。  
Community-safe Codex skill for multi-repo engineering work.

這個 skill 會幫助 Codex 先判斷：
This skill helps Codex reason about:

- owner repo 或 runtime
- owner repo or runtime
- producer 與 consumer 的邊界
- producer and consumer boundaries
- contract 與 security surfaces
- contract and security surfaces
- durable state 的 rollback 風險
- rollback risk for durable state
- 與風險相符的 validation depth
- validation depth that matches risk

它適合用在會跨越 frontend、backend、admin、automation、browser extension 等邊界的任務。  
It is designed for cases where a task may cross frontend, backend, admin, automation, or browser-extension boundaries.

## 倉庫結構 | Repository Layout

實際的 skill 放在：
The actual skill lives in:

- `boundary-first-multi-repo-engineering/`

這個資料夾包含：
That folder contains:

- `SKILL.md`
- `agents/openai.yaml`
- `references/`

## 這個 Skill 做什麼 | What The Skill Does

這個 skill 強調 boundary-first workflow：  
The skill encourages a boundary-first workflow:

1. 分類這次變更  
   Identify the change class.
2. 找出真正的 owner repo 或 runtime  
   Identify the true owner repo or runtime.
3. 檢查 contract surfaces  
   Check contract surfaces.
4. 檢查 security 與 permission surfaces  
   Check security and permission surfaces.
5. 檢查 durable state 與 rollback 風險  
   Check durable state and rollback risk.
6. 設計 observability 與 debug 行為  
   Design observability and debug behavior.
7. 選擇符合風險的 validation depth  
   Choose the right validation depth.
8. 在高風險 stop conditions 前先停下來  
   Pause on stop conditions before coding.

## 安裝方式 | Install

把下面這個資料夾複製到你的 Codex skills 目錄：  
Copy the folder below into your Codex skills directory:

- `boundary-first-multi-repo-engineering/`

常見的目的地路徑：  
Typical destination:

- `~/.codex/skills/boundary-first-multi-repo-engineering/`

接著重新啟動 Codex。  
Then restart Codex.

## 範例 Prompt | Example Prompts

顯式呼叫：  
Explicit invocation:

```text
Use $boundary-first-multi-repo-engineering to do a read-only preflight for a frontend change that may alter a backend request payload. Identify the owner boundary, contract risk, security surface, and required validation.
```

隱式觸發：  
Implicit invocation:

```text
I need to review a change that touches a frontend app, a backend route, and extension storage. Do a read-only boundary analysis first, then tell me which system is the owner and what validation depth is appropriate.
```

## 內含的 Adapter | Included Adapters

這個 skill 目前包含以下泛用 adapter：  
The skill currently includes generic adapters for:

- backend service
- frontend app
- admin console
- automation bot or sync worker
- browser extension

## 備註 | Notes

- 這個 repository 刻意避開公司內部 repo 名稱、內部架構細節與私有驗證指令。  
  This repository intentionally avoids company-specific repo names, internal architecture, or private validation commands.
- 公開版保留的是方法論，不是內部拓樸。  
  The public skill keeps the method, not the internal topology.
