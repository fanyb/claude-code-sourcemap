---
name: cross-repo-plan
description: 为跨多个 repo 的需求生成改造计划
---

# /cross-repo-plan —— 跨 repo 改造规划

用户会说类似：
- `/cross-repo-plan 给用户增加导出历史订单功能`
- `/cross-repo-plan 新增会员等级体系`

## 执行步骤

1. **读 `backend/_index.md`** 理解服务拓扑

2. **派生 sub-agent 并行分析**：
   - 哪几个服务需要改
   - 每个服务改什么（不写代码，只写意图）
   - 跨服务调用关系会不会变
   - 新增 DB 表 / 字段 / 索引

3. **输出结构化计划**：

   ```markdown
   # 改造计划：<需求标题>

   ## 需求理解
   <用 3 句话复述，让用户确认你理解对了>

   ## 影响服务（按改造顺序）

   1. **service-user**（提供新 Facade 方法）
      - 变更：新增 `UserFacade.listExportableUsers()`
      - api 模块：新增方法签名
      - provider：新增实现
      - 风险：低（纯新增方法）

   2. **service-order**（无变更，只被调用）

   3. **service-export**（新业务，新增 Controller + Service）
      - 变更：新增 `ExportController`、`ExportService`、`ExportJobWorker`
      - 依赖：`UserFacade`、`OrderFacade`
      - DB：新增 `export_job` 表
      - 风险：中（新业务，需要完整单测）

   4. **gateway**（新增路由）
      - 路由：`POST /api/v1/export`
      - 鉴权：沿用现有 AuthFilter

   5. **frontend/web-admin**（新增导出页面）
      - 新增 `src/views/export/`
      - 新增 Pinia store
      - 新增 API 调用层

   ## 改造顺序（严格按此 commit 顺序）

   - **Step 1**: service-user api 模块新增接口（单 commit）
   - **Step 2**: service-user provider 实现（单 commit，单独 PR）
   - **Step 3**: service-user 发版到私服 SNAPSHOT（手动）
   - **Step 4**: service-export 依赖升级 + 业务实现（单 PR）
     - Step 4.1: DB migration
     - Step 4.2: Controller + DTO + Swagger 注解
     - Step 4.3: Service 实现 + 单测（TDD）
     - Step 4.4: Worker 实现 + 单测
   - **Step 5**: gateway 路由配置（单 commit）
   - **Step 6**: 前端契约类型（`/gen-ts-types` 生成） + 页面实现（单 PR）

   ## 契约清单

   - **后端 DTO**：`ExportRequest`、`ExportResponse`、`ExportJobDTO`
   - **前端 types**：`src/types/api/export.ts`（待 `/gen-ts-types` 生成）
   - **Dubbo Facade**：`UserFacade.listExportableUsers()`（新增）

   ## 风险 & 需要确认的事项

   1. `listExportableUsers` 是否需要分页？默认上限？
   2. 导出文件格式只支持 CSV 还是也要 Excel？
   3. 新增 gateway 路由需要走审批吗？
   4. export_job 表的清理策略（TTL）？
   5. 用户 tier 判断走 Redis 缓存还是实时查 DB？

   ## 预估工作量

   | 阶段 | 人工时间 | AI 辅助时间 |
   |---|---|---|
   | 设计 + 规划 | 2h | 0.5h |
   | 后端实现 + 单测 | 2d | 1d |
   | 前端实现 | 1d | 0.5d |
   | 联调 + 修复 | 1d | 0.5d |
   | 合计 | ~5d | ~2.5d |
   ```

4. **最后必须追问用户**：

   > 请确认以下事项后我再开始实施：
   > 1. 改造顺序是否合理？
   > 2. 上面列的"需要确认的事项"你的答案是？
   > 3. 有没有遗漏的服务？
   >
   > 我**不会**在你确认前执行任何修改。

## 禁止

- 禁止自动开始写任何代码
- 禁止在一个 session 里同时改多个 repo（规划后要分多个 session 实施）
- 禁止跳过"需要确认的事项"直接给方案
- 禁止遗漏任何已知 consumer（必须配合 `/impact` 双重验证）

## 成功标准

用户读完后，应该能够：
1. 指出计划中不对的地方（说明他真的读懂了）
2. 答出所有"需要确认的事项"
3. 决定是全部执行、部分执行还是推翻重来
