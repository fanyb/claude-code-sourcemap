# Claude Code 架构文档总览 (Architecture Index)

这是一份关于 Claude Code 源码内部工作原理的详尽架构文档集。为了方便查阅，我们将这 23 份架构文档按照逻辑模块进行了分类整理。

## 1. 核心概览 (Core Overview)
这部分文档提供了高视角的架构切面，适合初次接触源码的开发者。
- [架构概览与逻辑分层](./overview.md)
- [状态管理与单一数据流 (AppState)](./state_management.md)
- [CLI 模式与 Agent SDK 双引擎架构](./cli_and_sdk.md)

## 2. 启动与基础架构 (Initialization & Foundation)
这部分详细说明了系统是如何从冷启动到准备好接收用户输入的。
- [系统启动流程与环境预热](./initialization.md)
- [高性能 API 通信与网络优化](./api_and_networking.md)

## 3. AI 引擎与任务调度 (AI Engine & Scheduling)
这部分是系统的“大脑”，描述了 AI 如何思考、如何管理记忆以及如何分解任务。
- [AI 查询闭环生命周期 (Query Engine)](./query_lifecycle.md)
- [上下文注入与历史消息压缩 (Compaction)](./context_and_memory.md)
- [记忆目录与持久化知识库 (MemDir)](./memory_directory.md)
- [多 Agent 协作与协调器模式 (Coordinator)](./coordinator_and_agents.md)
- [任务管理与生命周期流转 (Tasks)](./task_management.md)

## 4. 工具与扩展能力 (Tools & Extensibility)
这部分描述了 Claude Code 如何与外部世界互动以及如何扩展其能力。
- [AI 工具定义模式与权限模型](./tools_and_permissions.md)
- [MCP 协议集成与多传输层实现](./mcp.md)
- [插件与技能扩展机制 (Plugins & Skills)](./plugins_and_skills.md)

## 5. 开发辅助与环境感知 (Developer Assistance)
这部分文档展示了 AI 是如何理解代码和开发环境的。
- [Git 差异感知与版本控制集成](./git_and_vcs.md)
- [LSP 集成与语义级代码分析](./lsp_and_analysis.md)

## 6. 终端与交互界面 (TUI & Interaction)
这部分描述了丰富的终端用户界面是如何实现的。
- [React/Ink 驱动的终端渲染与交互](./tui_and_repl.md)
- [快捷键管理与终端 Vim 模式](./keyboard_and_vim.md)
- [实验性语音交互机制 (Voice Mode)](./voice_interaction.md)
- [Companion UI、动画与气泡彩蛋 (Buddy)](./companion_ui.md)
- [远程桥接与多端同步控制 (Bridge)](./bridge_and_remote.md)

## 7. 安全、合规与诊断 (Security, Tracking & Diagnostics)
这部分展示了该工具是如何在生产级环境保障安全、监控性能并计费的。
- [沙箱隔离与危险命令拦截分类器](./security_and_sandbox.md)
- [Token 统计、成本追踪与预算控制](./cost_tracking.md)
- [基于 OpenTelemetry 的遥测与诊断机制](./telemetry_and_diagnostics.md)
