# CLI 模式与 SDK 架构 (CLI & SDK)

Claude Code 的入口层被设计成一种“双引擎”架构：既可以作为全功能的交互式终端应用（REPL），也可以作为无界面的库或批处理工具（Print Mode / SDK）。

## 1. 模式分发 (Mode Dispatcher)

在 `src/main.tsx` 和 `src/cli/` 中，系统会根据环境变量或命令行参数（如 `--print`，或管道输入）决定运行模式：

### 交互模式 (REPL Mode)
- 启动完整的 React/Ink 树。
- 接管终端的 `stdin` 和 `stdout`，进入全屏缓冲区（Alternate Screen）。
- 启动 TUI 的事件循环。

### 打印模式 / SDK 模式 (Print Mode)
- **无界面 (Headless)**：跳过所有的 React 渲染逻辑。
- **JSON-RPC 或纯文本**：将 `QueryEngine` 的 AsyncGenerator 输出直接流式写入 `stdout`。可以被配置为输出易于程序解析的 `ndjson` (Newline Delimited JSON)。
- **同步执行**：自动降权所有需要交互的环节（例如权限请求直接失败，除非配置了 Bypass 模式）。

## 2. Agent SDK 接口 (`src/entrypoints/agentSdkTypes.ts`)

- 此接口定义了如何将 Claude Code 的内部逻辑封装成一个标准的 npm 包供外部调用。
- **通信契约**：定义了 `SDKMessage` 类型，屏蔽了内部复杂的上下文管理和 TUI 特有的消息标记。
- **扩展性**：外部宿主（如 VS Code 插件、自动化测试平台）可以作为进程启动 Claude Code，并通过 STDIN/STDOUT 或 WebSocket 与其进行结构化通信，实现自己的 UI 呈现。

## 3. 标准化输入/输出
在 `cli/structuredIO.ts` 中，系统对终端底层的转义字符和控制码进行了剥离（Strip ANSI），确保在非交互模式下生成的日志是纯净的。这使得系统可以被直接编排进 Bash 脚本的管道流（Pipe）中。
