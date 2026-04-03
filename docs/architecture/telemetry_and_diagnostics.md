# 遥测、诊断与日志架构 (Telemetry & Diagnostics)

Claude Code 的遥测系统旨在平衡“产品改进”与“用户隐私”。它使用现代的 OpenTelemetry 栈来监控性能和错误。

## 1. 核心技术栈
- **OpenTelemetry (OTEL)**：作为标准化的遥测框架，处理指标（Metrics）、追踪（Traces）和日志（Logs）。
- **GrowthBook**: 用于功能开关 (Feature Flags) 和 A/B 测试，动态控制遙测采集的频率和范围。
- **Perfetto**: 支持生成详细的跟踪文件，用于深度的性能调优。

## 2. 遥测分类

### 业务事件 (Analytics)
- **记录内容**：命令的使用频率（例如 `/commit`）、工具的调用成功率、任务的持续时间。
- **隐私保护**：通过 `metadata.ts` 严格过滤敏感信息。所有的文件路径、代码片段在进入遥测管道前都会被脱敏。

### 性能指标 (Metrics)
- **关键指标**：首包延迟 (TTFT)、每秒 Token 数 (TPS)、每轮对话的成本、TUI 的帧率 (FPS)。

### 错误报告 (Error Reporting)
- **分级处理**：区分内部异常（TelemetrySafeError）和普通错误。
- **上下文关联**：在错误发生时，自动附带非敏感的上下文（如操作系统版本、模型名称），帮助开发者快速定位问题。

## 3. 诊断与恢复

### 本地日志 (Diag Logs)
- 即使不开启远程遥测，系统也会在本地维护一份诊断日志（No PII），方便用户在遇到问题时进行排查。
- **位置**：通常存放在系统的缓存目录中（如 `~/.claude/logs`）。

### 崩溃恢复
- 通过会话快照机制，系统可以在异常退出后通过 `conversationRecovery.ts` 恢复状态。
