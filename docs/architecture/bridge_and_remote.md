# 远程桥接架构 (Remote Bridge)

Claude Code 包含了一套复杂的远程控制系统（主要位于 `src/bridge/`），允许用户在不直接接触终端的情况下，通过手机或网页与本地运行的 Claude 实例进行交互。

## 1. 核心原理：信令与 I/O 转发

远程桥接将本地的 CLI 抽象为一个“环境”（Environment），并将其输入输出通过中继服务器转发到远程客户端。

### 通信层
- **Bridge API**: 基于 REST 和 WebSocket/SSE 的混合通信。
- **Work Secret**: 每一个远程会话都有一个唯一的加密密钥，用于生成配对链接和 QR 码。
- **JWT 认证**: 使用 JSON Web Tokens 确保只有授权的设备可以访问本地终端。

## 2. 架构组件

- **ReplBridge**: 核心控制器，负责监听本地消息（SDKMessage）并将其推送到远程，同时接收远程指令并注入到本地的输入流中。
- **HybridTransport**: 一种特殊的 I/O 传输层，能够同时向本地 TUI 和远程 Bridge 发送输出，实现“双端同步”。
- **Control Plane**: 处理非文本指令，如切换权限模式（onSetPermissionMode）、设置模型（onSetModel）或中断请求（onInterrupt）。

## 3. 安全性设计

- **Trusted Device**: 只有经过配对的“受信任设备”才能发送写操作指令。
- **权限降级**: 当处于远程模式时，某些高危操作（如直接修改系统配置）可能会受到额外的权限限制。
- **本地优先**: 本地终端始终拥有最高优先级，用户可以随时在本地按下快捷键切断所有远程连接。

## 4. 典型工作流

1. 用户在终端运行 `/remote`。
2. 系统生成一个 `Work Secret` 并展示包含认证信息的 QR 码。
3. 用户手机扫码，通过 Bridge API 完成握手。
4. 本地 `ReplBridge` 开始将所有 `QueryEngine` 的输出实时同步到手机。
5. 用户在手机上点击“允许”工具调用，指令通过 Bridge 返回本地执行。
