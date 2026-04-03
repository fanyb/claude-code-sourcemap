# 成本追踪与预算控制 (Cost Tracking)

作为直接调用大语言模型 API 的工具，Claude Code 内置了非常细致的账单与 Token 消耗追踪系统。

## 1. 核心模块：`cost-tracker.ts`

### Token 统计 (Token Accounting)
- 在每一次 API 响应返回时，系统会解析响应头或响应体中的 `usage` 对象（包括 `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`）。
- 在流式传输断开时，系统会估算已消耗的输出 Token。

### 美元成本计算 (USD Calculation)
- 系统在 `utils/modelCost.ts` 中维护了一张最新的模型定价表（涵盖 Opus, Sonnet, Haiku 等）。
- 结合缓存命中率，精确计算本次查询所消耗的美元金额。

## 2. 会话预算 (Session Budget)

- 用户可以通过配置或 CLI 参数设置单次会话或单个任务的硬性预算（例如：`--max-budget 1.0`）。
- **`QueryEngine` 监控**：在每一轮查询（Turn）结束时，如果检测到累积成本超过阈值，系统会通过抛出特定的 `BudgetExceededError` 强制停止循环。
- **UI 预警**：当成本接近阈值时，`CostThresholdDialog` 会在终端中间弹出一个显眼的警告，要求用户确认是否继续消耗额度。

## 3. 全局统计
- `saveCurrentSessionCosts` 会将会话成本写入本地的统计文件，供 `/cost` 或 `/stats` 等命令生成详细的使用报表，帮助开发者掌控长期的 API 开销。
