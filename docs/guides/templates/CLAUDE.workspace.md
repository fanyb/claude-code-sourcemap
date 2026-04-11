# Claude Code 工作区规约（Java + Dubbo + Vue3）

> 这是一份模板，请根据你公司的实际情况裁剪后放到工作区根目录的 `CLAUDE.md`。

## 工作区说明
本目录是跨 repo 工作区，通过符号链接/clone 汇总了多个 repo：
- `backend/service-*` Java 8 + Spring Boot + Dubbo
- `frontend/web-*` Vue3 + TypeScript

服务全景见 `backend/_index.md`，任何跨服务改造前先读它。

---

## 🔴 绝对禁区（Hook 也会拦，你别试）
1. 禁止修改任何 `**/api/**/*Facade.java` 的已存在方法签名
   → 需要变更时，新增 `methodV2` 并给老方法加 `@Deprecated(since="当前日期")`
2. 禁止修改 `*.sql`、`db/migration/**` 下已提交的迁移文件
3. 禁止改 `pom.xml` 里的父 pom 版本 / 新增依赖（必须人批准）
4. 禁止修改任何指向 SIT 环境的配置（`*.sit.yml`、`application-sit.*`）
5. 禁止执行 `mvn deploy`、`git push`、任何 `kubectl` / `helm` 命令

---

## Java 编码规约

### 语言限制（Java 8）
- **目标 Java 版本：1.8**，禁止使用：
  - `var` 局部变量推断
  - `record`、`sealed class`、`switch expression`
  - `List.of()`、`Map.of()`（用 Guava 的 `ImmutableList` / `ImmutableMap`）
  - `Optional.orElseThrow()` 无参版（1.8 只有带参的）
- 禁止 Stream 链式超过 3 步
- 禁止 lambda 嵌套超过 2 层

### 分层规约
- `Controller / DubboProvider → Service → Manager → DAO`
- 禁止跨层调用
- Service 之间禁止相互注入，必须通过 Manager 层或 Dubbo Facade

### Dubbo 规约
- 所有对外暴露的 RPC 必须通过 `*-api` 模块的 Facade 接口
- 新增 RPC 方法时：
  1. 先在 api 模块加接口方法
  2. 在 provider 实现
  3. `mvn install` 到本地，consumer 通过 SNAPSHOT 依赖
  4. 正式发布前必须升版本号
- DTO 必须实现 `Serializable`，字段必须给默认值，禁止用 `@Builder` 的 `toBuilder`
- `@DubboReference` 必须加 `timeout`、`retries=0`（写操作）

### 异常处理
- 业务异常继承 `BusinessException`，禁止 `throw new RuntimeException`
- Dubbo Facade 方法抛异常必须用 `BizException`（跨服务可序列化）
- 禁止 catch Exception 后只 log 不处理

### 审计与日志
- 所有写操作必须在 Service 层调 `AuditLog.record(...)`
- 日志格式：`[traceId][userId] action=xxx detail=...`
- 禁止 `e.printStackTrace()`，用 `log.error("msg", e)`

---

## Dubbo 接口变更 SOP

当你需要修改任何 Facade 接口时，**必须按以下顺序执行**：

1. 先运行 `/impact <FacadeName.methodName>` 跑影响分析
2. 如果有 consumer：
   - 禁止改原方法签名
   - 新增 `methodV2`
   - 老方法保留，加 `@Deprecated(since="yyyy-MM-dd")`，内部 delegate 给 v2
3. 如果没有 consumer：可以直接改，PR 描述里写明"确认无下游"
4. 改完等人确认，不要自动 install 到私服

---

## 测试规约

### 单测
- 新增业务逻辑必须有单测，覆盖率 ≥ 70%
- JUnit 5 + Mockito + AssertJ
- 禁止连真实数据库（SIT MySQL 绝对禁止）
- DAO 层测试用 H2 或 Testcontainers
- Dubbo Consumer 测试用 `@MockBean` 模拟 Facade

### 测试模板
参考 `backend/service-user/.../UserServiceTest.java`，所有新单测按这个结构写。

---

## 项目命令速查
- 构建：`mvn clean install -DskipTests`
- 单测：`mvn test -pl <module>`
- 启动服务：`mvn spring-boot:run -pl <module>`
- 本地依赖：`cd infra && docker-compose up -d`
- Lint：`mvn spotless:apply`

---

## 交互行为要求

1. **改代码前必须先定位**：不要猜文件路径，用 Grep 或 `/locate`
2. **跨 repo 操作必须先出计划**：涉及多个服务时，先输出完整步骤清单等确认
3. **一次只改一个逻辑单元**：一个 method、一个 class，改完停下来
4. **禁止主动运行 `mvn install`**：除非明确要求
5. **禁止主动 git commit / push**：用 `/commit` 让它做
6. **不确定的时候宁可问，不要瞎猜**
7. **不要主动加 JavaDoc / 注释**，除非要求或逻辑确实绕
