# API 通信与网络架构 (API & Networking)

Claude Code 的网络层负责与 Anthropic API 及其他远程服务进行高效、安全的数据交换。它不仅是一个简单的 HTTP 客户端，还包含了一系列针对延迟和可靠性的优化。

## 1. 核心通信流

### 流式响应 (Streaming)
- **实现**：基于 `EventSource` / Server-Sent Events (SSE)。
- **实时性**：模型生成的每一个 Token 都会立即通过网络流式传输到本地，并触发 TUI 的重绘。
- **中断支持**：支持通过 AbortSignal 立即切断 HTTP 连接，防止在用户取消任务后继续消耗 Token。

### 自动重试与错误分类
- **重试策略**：针对 `5xx` 错误、网络超时和特定的 429 (Rate Limit) 错误实施指数退避重试。
- **错误分类**：将 API 错误细分为“可重试”和“终态错误”，并根据错误类型（如 `prompt_too_long`）触发相应的本地压缩逻辑。

## 2. 网络优化技术

### 预连接 (Preconnect)
- **逻辑**：在用户开始输入时（或在初始化阶段），提前建立与 API 服务器的 TCP 和 TLS 握手。
- **收益**：将首包延迟 (TTFT) 降低 100-200ms。

### 全球网络支持
- **代理支持**：内置对 `HTTP_PROXY`, `HTTPS_PROXY` 的支持。
- **CA 证书管理**：允许用户配置额外的 CA 证书（`NODE_EXTRA_CA_CERTS`），以适应复杂的公司网络环境。
- **mTLS 安全**：支持相互 TLS 认证，用于高安全要求的企业环境。

## 3. 请求管理

### 成本追踪 (Cost Tracking)
- **Token 计数**：在每次 API 返回后，实时解析响应头中的 `usage` 字段。
- **预算管控**：在 `QueryEngine` 层面维护一个会话级的预算计数器，超过用户设定的阈值时强制停止。

### 缓存键 (Cache Keying)
- **Prompt Caching**：通过精心构建 System Prompt 的顺序（将静态的工具定义放在前面），最大化 Anthropic API 的 Prompt 缓存命中率，从而显著降低成本和延迟。
