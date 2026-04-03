# 终端交互与 TUI 渲染架构 (TUI & REPL)

Claude Code 拥有一个极具交互性的终端界面，这主要归功于它对 `React` 和 `Ink` 的深度集成。

## 1. 技术栈：React in Terminal

传统的 CLI 通常是顺序输出文本，而 Claude Code 像现代 Web 应用一样工作：
- **React**: 用于管理组件状态、副作用和声明式 UI。
- **Ink**: 将 React 组件树渲染为 ANSI 转义序列，从而在终端中实现布局、颜色和交互。
- **Yoga (CSS Layout)**: Ink 使用 Yoga 引擎（Flexbox）进行布局，使得在终端中实现响应式设计成为可能。

## 2. REPL 核心循环

`restored-src/src/screens/REPL.tsx` 是整个界面的调度中心：

### 状态驱动 (State-Driven)
- **消息流**：从 `QueryEngine` 获取流式消息，并将其存储在 `messages` 数组中。
- **自动滚动**：当 AI 正在思考或输出时，界面会自动向下滚动以显示最新内容。
- **虚拟化列表**：通过 `VirtualMessageList` 仅渲染屏幕可见的消息，从而在拥有数千条历史消息的长会话中保持极高性能。

## 3. 关键交互组件

### PromptInput (输入框)
- 支持多行编辑、命令补全（Slash Commands）。
- **Vim 模式**：可选的键盘绑定模式。
- **History**：集成了本地 Shell 历史和 Claude 专有的对话历史。

### PermissionRequest (权限弹窗)
- 当工具需要授权时，UI 会“暂停”主循环并弹出一个交互式对话框。
- 用户可以点击（通过鼠标支持）或使用快捷键选择“允许”、“拒绝”或“始终允许”。

### Streaming Thinking (流式思考)
- 实时展示 AI 的思考过程（Thinking blocks），并伴随微小的动画提示（Spinner）。

## 4. 性能优化

- **AnimatedTerminalTitle**：将终端标题的动画逻辑（如旋转的小图标）抽离为独立组件，避免动画每一帧都触发整个 `REPL` 树的重绘。
- **Memoization**: 大量使用 `useMemo` 和 `useCallback` 来减少不必要的 ANSI 重绘。

## 5. 跨终端支持

- **Terminal Size Sensing**: 通过 `useTerminalSize` 监听窗口缩放，并动态调整布局（如在小屏幕下折叠详细信息）。
- **Mouse Support**: 在支持的终端（如 iTerm2, Kitty）中支持鼠标点击和滚动。
