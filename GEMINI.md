# Claude Code (非官方源码还原版)

本项目是 Anthropic 的 **Claude Code** CLI（版本 2.1.88）的非官方还原版。它是通过对 `@anthropic-ai/claude-code` npm 发布包进行 source map 分析和源码提取而重建的。

## 项目概览

Claude Code 允许用户直接在终端中与 Claude 交互，以理解代码库、编辑文件并自动化工作流。它拥有一个基于 React 和 Ink 构建的丰富 TUI（终端用户界面）。

### 核心技术栈
- **TypeScript**: 核心编程语言。
- **React & Ink**: 驱动交互式终端 UI。
- **Commander.js**: 处理 CLI 参数解析。
- **MCP (Model Context Protocol)**: 通过外部工具服务器扩展 Claude 的能力。
- **Node.js/Bun**: 目标运行时环境。

## 核心架构

源码位于 `restored-src/src/` 目录下。

### 入口点
- `main.tsx`: 主入口文件。负责 CLI 初始化、参数解析，并分发至交互式 REPL 模式或非交互式 "print" 模式。

### 命令系统 (`src/commands/`)
命令是用户手动触发的操作（例如：`/commit`, `/review`, `/config`）。
- 在 `src/commands.ts` 中注册。
- 实现代码分布在 `src/commands/` 目录下的各个模块中。

### 工具系统 (`src/tools/`)
工具是 Claude 可以调用的能力（例如：`Bash`, `FileEdit`, `Grep`）。
- 在 `src/tools.ts` 中注册。
- 继承自 `src/Tool.ts` 中定义的 `Tool` 基类或接口。
- Claude 根据用户请求自主选择并执行这些工具。

### 服务层 (`src/services/`)
核心逻辑与外部集成：
- `api/`: 与 Anthropic API 通信。
- `mcp/`: MCP 客户端实现及服务器管理。
- `analytics/`: 遥测和事件日志记录。
- `lsp/`: 语言服务器协议（LSP）集成。

### 状态管理 (`src/state/`)
- 使用自定义 Store 和 Context Provider 管理应用状态，包括对话历史、当前项目上下文和工具状态。

## 目录结构要点

```text
restored-src/src/
├── main.tsx              # CLI 入口
├── tools/                # AI 工具实现 (Bash, Edit 等)
├── commands/             # 斜杠命令实现 (/commit, /review)
├── services/             # API、MCP 及内部服务
├── components/           # 基于 Ink 的 React 组件
├── context/              # React Context 提供者
├── utils/                # 工具函数 (Git, Auth, Env, Platform 等)
├── state/                # 应用状态管理
├── assistant/            # 助手模式 (KAIROS) 逻辑
├── coordinator/          # 多 Agent 协调模式
└── plugins/              # 插件系统
```

## 开发与运行

由于本项目是源码还原版，根目录下缺少原始的构建脚本。基于现有内容推断：

- **编译**: 项目使用 TypeScript。需要使用 `tsc`、`esbuild` 或 `bun` 来编译源码。
- **运行**:
  - 原始入口: `node package/cli.js`
  - 从源码运行 (需要编译): `tsx restored-src/src/main.tsx` 或 `bun restored-src/src/main.tsx`。
- **依赖**: 依赖项可从导入语句推断（lodash-es, chalk, commander, react, ink 等）。注意 `package/package.json` 是针对发布包的，缺少完整的 devDependencies。

## 关键开发约定

- **副作用管理**: 关键的初始化副作用（如遥测、性能分析器）通常放置在主文件的顶部。
- **特性开关 (Feature Flags)**: 广泛使用 `feature('FLAG_NAME')` 来控制条件逻辑和实验性功能。
- **权限控制**: 拥有一套完善的权限系统 (`src/utils/permissions/`)，用于监管工具执行，特别是涉及 `Bash` 或 `FileEdit` 等敏感操作时。
- **平台支持**: 在 `src/utils/platform.ts` 和各工具实现中，针对 macOS、Linux 和 Windows 进行了明确的适配。
