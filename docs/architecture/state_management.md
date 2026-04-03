# 状态管理与数据流 (State Management & Data Flow)

Claude Code 作为一个高性能的 TUI 应用，其状态管理逻辑既要保证 AI 引擎的异步执行，又要保证终端界面的实时响应。

## 1. 核心状态存储 (`AppStateStore`)

整个应用的全局状态封装在 `AppStateStore`（位于 `src/state/`）中。它扮演了类似于 Redux 存储的角色：
- **AppState**: 包含消息历史、当前工具进度、权限模式、用户信息和成本统计等。
- **状态同步**：通过自定义的 `setAppState` 和 `getAppState` 方法进行更新。

## 2. 单一事实来源 (Single Source of Truth)

为了防止逻辑层与视图层产生冲突，所有的状态更新都遵循以下流动：
1. **Action 发起**：例如 `QueryEngine` 生成了一个新的 Token。
2. **State 更新**：调用 `setAppState` 更新消息数组。
3. **Reactive 通知**：React 的 Context Provider 感知到状态变化，触发相关子组件（如 `Messages`）的重新渲染。
4. **TUI 呈现**：Ink 将最新的 React 树转化为 ANSI 指令，实时绘制到终端屏幕。

## 3. 异步状态管理

由于 AI 响应和工具执行是异步的，状态管理面临并发挑战：
- **乐观更新**：用户输入后，界面立即展示消息，不等待 API 响应。
- **流式追加**：Token 级别地追加到现有消息上，利用 `useDeferredValue` 或类似的机制来防止频繁渲染导致的界面卡顿。

## 4. 状态持久化 (Persistence)

部分状态不仅存在于内存中，还会被同步到磁盘：
- **Transcript (对话记录)**：每轮对话结束后自动保存。
- **Settings (全局设置)**：如 API 密钥、偏好模型、权限白名单。
- **Session Metadata**: 包括最后一次互动的上下文和工作目录。

## 5. 跨层级状态共享

- **Context Provider**: 系统使用了多个层级的 Context（如 `QueryContext`, `NotificationContext`），允许底层的 UI 组件直接访问或修改核心状态，而无需层层传递 Props。
- **Telemetry Hooks**: 状态变化的同时，会自动触发相关的遥测逻辑，记录系统性能。
