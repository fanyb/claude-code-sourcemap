# 任务管理与生命周期 (Task Management)

在 Coordinator 模式或复杂查询下，Claude Code 需要并发或串行地执行多个任务。`src/tasks/` 目录定义了这套任务抽象系统。

## 1. 任务的抽象分类

### `LocalAgentTask`
- 运行在与主进程相同的 Node.js 实例中。
- 拥有独立的状态机和消息队列。
- 通常用于处理那些不适合被拆分到外部进程的紧密耦合任务。

### `InProcessTeammateTask`
- 代表一个平行的“虚拟同事”。它可以与主线程交替进行发言和工作。
- 共享同一个文件系统缓存，但拥有隔离的 `QueryEngine`，因此不会因为主线程的思考中断而停止。

### `RemoteAgentTask`
- 当通过桥接连接到其他机器（如远程开发服务器）时，任务会被序列化并通过 Bridge API 发送，在远程环境执行完毕后同步状态回来。

## 2. 状态流转 (State Transitions)

每个任务（Task）都遵循严格的生命周期：
1. **Queued (排队)**: 任务已创建，等待调度器分配资源。
2. **Running (执行中)**: Agent 正在思考或调用工具。
3. **Suspended/Awaiting (挂起)**: Agent 需要用户权限确认或外部输入。
4. **Completed/Failed (结束)**: 任务成功返回结果或因错误终止。

## 3. UI 映射 (Task View)

- 在 `REPL.tsx` 中，`TaskListV2` 组件会监听全局状态树中 `tasks` 节点的变更。
- 任务的层次结构被渲染为一个可折叠的树状视图（类似 IDE 中的构建任务面板），用户可以直观地看到哪个子 Agent 正在执行哪个子任务。
