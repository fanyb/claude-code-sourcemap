# 后端服务索引（模板）

> 这是一份模板，放到工作区 `backend/_index.md`。
> 手动维护这份文件 = 给 Claude 的"服务地图"，每次跨 repo 改造它都会读。
> 投入 30 分钟写一次，省下每次盲目搜索的时间。

---

## service-user（用户中心）
- **职责**：用户 CRUD、登录、会话管理
- **API 包**：`com.xxx.user.api`
- **Dubbo Provider**：`UserFacade`、`AuthFacade`
- **数据库**：`user_db`
- **谁在调**：`service-order`、`service-export`、`gateway`
- **核心入口**：
  - REST：`UserController.java`
  - Dubbo：`UserFacadeImpl.java`
- **注意**：该服务有大量历史代码，新功能放 `com.xxx.user.biz.v2.*` 下

---

## service-order（订单）
- **职责**：订单全生命周期、支付回调
- **API 包**：`com.xxx.order.api`
- **Dubbo Provider**：`OrderFacade`、`PaymentFacade`
- **数据库**：`order_db`
- **谁在调**：`service-export`、`gateway`、`service-report`
- **核心入口**：
  - REST：`OrderController.java`
  - Dubbo：`OrderFacadeImpl.java`
- **注意**：订单状态机在 `OrderStateMachine.java`，修改前务必读完

---

## service-export（数据导出，示例新业务）
- **职责**：异步导出任务、生成 CSV/Excel
- **API 包**：`com.xxx.export.api`
- **Dubbo Consumer**：`UserFacade`、`OrderFacade`
- **Dubbo Provider**：`ExportFacade`
- **数据库**：`export_db`（导出任务表）
- **依赖**：OSS（文件存储）、邮件服务
- **核心入口**：
  - REST：`ExportController.java`
  - Worker：`ExportJobWorker.java`

---

## gateway（自研网关）
- **路由注册**：`./conf/routes.yml`
- **鉴权**：`./src/main/java/.../filter/AuthFilter.java`
- **新增路由文档**：`docs/add-route.md`
- **注意**：路由变更需要运维审批

---

## Facade 调用关系矩阵

| 被调 ↓ / 调用方 → | service-user | service-order | service-export | gateway |
|---|---|---|---|---|
| UserFacade |  | ✓ | ✓ | ✓ |
| AuthFacade |  |  |  | ✓ |
| OrderFacade |  |  | ✓ | ✓ |
| PaymentFacade |  |  |  | ✓ |
| ExportFacade |  |  |  | ✓ |

---

## 跨服务约定

- **所有 Facade 方法签名一旦发布不允许修改**，只能新增 `methodV2`
- **DTO 字段新增必须有默认值**，兼容老版本 consumer
- **删除字段必须走两次发版**：第一次标 `@Deprecated`，第二次才能删
- **新增 consumer 必须在本表中登记**
