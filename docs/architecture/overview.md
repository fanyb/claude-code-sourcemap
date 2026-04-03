# Claude Code 核心架构蓝图 (System Overview)

Claude Code 是一个生产级的终端 AI 助手，其架构设计兼顾了极致的交互体验 (TUI)、深度的环境感知 (Git/LSP) 以及高度的安全隔离 (Permissions/Sandbox)。

## 1. 核心架构模型 (The 4-Layer Model)

系统的核心可以抽象为四个相互协作的层次：

```text
+-----------------------------------------------------------------------+
| 1. 界面与交互层 (Interface & Interaction)                              |
|    - TUI (React/Ink), REPL 循环, Vim 模式, 语音交互, 远程桥接 (Bridge)     |
+----------------------------------+------------------------------------+
                                   | (Events / SDKMessages)
+----------------------------------v------------------------------------+
| 2. 调度与编排层 (Orchestration & Logic)                                 |
|    - QueryEngine (思考循环), Coordinator (多 Agent 协作), AppState (状态) |
|    - 任务管理 (Tasks), 历史压缩 (Compaction), 记忆管理 (MemDir)           |
+-------------------------+----------------------------+----------------+
                          | (Tool Calls)               | (Data)
+-------------------------v----------------------------v----------------+
| 3. 核心能力层 (Core Capabilities)                                       |
|    - 内置工具 (Bash, Edit, Read), MCP 协议 (插件化工具), 命令系统 (/xxx)   |
|    - 环境感知 (Git 差异, LSP 语义分析, 目录结构)                          |
+-------------------------+----------------------------+----------------+
                          | (System Calls)             | (Telemetry)
+-------------------------v----------------------------v----------------+
| 4. 基础设施与安全层 (Infrastructure & Security)                         |
|    - 权限管控系统 (Permissions), 沙箱隔离 (Docker), API 通信与重试        |
|    - 遥测诊断 (OTEL), 成本追踪 (Cost), 启动预热 (Profiler)               |
+-----------------------------------------------------------------------+
```

## 2. 核心模块演进说明

### 交互层 (The TUI & Bridge)
系统不仅仅是一个简单的命令行工具，它是一个“混合渲染器”。它利用 React/Ink 渲染终端 UI，并通过 **Bridge 架构** 实现了 TUI 状态与远程 Web/移动端的高度同步。

### 调度层 (The Brain)
**QueryEngine** 是系统的逻辑枢纽。它通过 AsyncGenerator 驱动了“思考-执行-反馈”的闭环。在复杂场景下，**Coordinator** 会派生出多个 **Sub-Agents** 并行工作，每个 Agent 都有隔离的任务生命周期。

### 能力层 (The Tools)
Claude Code 将“操作”与“理解”解耦。通过 **MCP 协议**，AI 可以动态发现并调用任何外部工具。同时，通过 **LSP 深度集成**，AI 拥有了超越纯文本的“语义级代码理解力”。

### 基础设施层 (The Bedrock)
为了确保生产安全，所有的工具执行都必须经过 **Permission System** 的过滤。系统内置了危险命令分类器，并在 Auto 模式下提供实时安全评估。同时，通过 **OpenTelemetry** 确保了在大规模部署下的可维护性。

## 3. 架构文档索引

我们对以上所有关键点进行了专题拆解，请参考以下详细文档进行深入研究：

- **核心架构**: [状态管理](./state_management.md) | [初始化流程](./initialization.md) | [CLI 与 SDK 双模式](./cli_and_sdk.md)
- **智能调度**: [查询生命周期](./query_lifecycle.md) | [多 Agent 协作](./coordinator_and_agents.md) | [任务管理](./task_management.md)
- **上下文**: [压缩与记忆](./context_and_memory.md) | [项目知识库](./memory_directory.md)
- **扩展与协议**: [工具与权限](./tools_and_permissions.md) | [MCP 协议](./mcp.md) | [插件系统](./plugins_and_skills.md)
- **环境感知**: [Git 深度整合](./git_and_vcs.md) | [LSP 语义分析](./lsp_and_analysis.md)
- **交互细节**: [TUI 渲染](./tui_and_repl.md) | [Vim 与快捷键](./keyboard_and_vim.md) | [语音交互](./voice_interaction.md) | [远程桥接](./bridge_and_remote.md)
- **安全与运营**: [沙箱与安全隔离](./security_and_sandbox.md) | [成本与预算](./cost_tracking.md) | [网络与代理](./api_and_networking.md) | [遥测诊断](./telemetry_and_diagnostics.md)
