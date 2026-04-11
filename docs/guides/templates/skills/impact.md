---
name: impact
description: 分析 Dubbo Facade 方法变更的影响面
---

# /impact —— Dubbo 影响分析

用户会说类似：
- `/impact UserFacade.getUserById`
- `/impact UserFacade`（整个接口）
- `/impact OrderFacade.createOrder`

## 执行步骤

1. **确认目标**：解析用户输入的 Facade 和方法名

2. **跨所有 `backend/` repo 搜索**：
   - Grep `@DubboReference.*<FacadeName>` 找 consumer 声明
   - Grep `<FacadeName>` 的 import 语句
   - Grep 方法名的具体调用点
   - 派生 sub-agent 并行搜索多个 repo

3. **输出影响清单**（markdown 表格）：

   ```markdown
   # /impact 报告：UserFacade.getUserById

   ## 影响的 Consumer

   | Consumer 服务 | 文件 | 行号 | 调用方式 | 风险等级 |
   |---|---|---|---|---|
   | service-order | OrderServiceImpl.java | 156 | 同步调用 | 🔴 高 |
   | service-export | ExportWorker.java | 89 | 异步批量 | 🟡 中 |
   | gateway | UserRouter.java | 34 | 转发入口 | 🔴 高 |

   ## 调用频次估算
   - 生产日均调用量：依据链路追踪数据（需人工查）
   - 是否在关键路径：🔴 是（登录链路必经）
   ```

4. **给出变更建议**：

   - 如果 consumer 数 > 0：
     - **必须新增 methodV2，禁止改原方法签名**
     - 列出 methodV2 的建议实现
     - 老方法 delegate 给 v2 的代码
     - 每个 consumer 的迁移改动点

   - 如果 consumer 数 = 0：
     - 可以直接改
     - 但要提示用户：生产数据可能有历史请求带旧字段

5. **最后追加一句**："请确认是否按此方案执行，我不会自动修改任何文件。"

## 禁止

- 不要自动执行任何修改
- 不要跳过任何 repo（宁可多搜不可漏搜）
- 不要只靠 import 判断，必须同时看 @DubboReference / `dubbo:reference` XML 配置
- 不要假设"没搜到就是没有"——提示用户：内部系统可能用反射调用

## 成功标准

用户读完报告后，能做出以下 3 选 1 决策：
1. 新增 methodV2（有 consumer）
2. 直接改（无 consumer + 明确确认）
3. 放弃改动（影响面过大，换方案）
