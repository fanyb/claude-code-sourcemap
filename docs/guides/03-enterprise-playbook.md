# 企业级作战手册：Java + Dubbo + Vue3

目标：**一人 + Claude Code ≈ 前端一人 + 后端一人**

适用场景：多 repo（过渡 monorepo）+ Java 8 + Dubbo 微服务 + Vue3 + TS 前后端分离。

---

## 一、战略总纲

**不可能真的一个人从头到尾干完两个人的活，但可以把"80% 体力活交给 Claude，自己只做 20% 关键判断"**。

### 必须人干的 20%
1. 需求拆解 + 架构决策
2. Dubbo 接口契约的最终拍板
3. PR review 的最终把关
4. 和产品 / 测试的沟通

### 可以交给 Claude 的 80%
- 跨 repo 找代码
- 跨 repo 搜影响面
- 契约生成 + TS 类型同步
- TDD 风格的单测
- 各 repo 内的具体实现

---

## 二、5 大痛点与应对策略

### 🔴 雷 1：接口直接改，没版本管理
**风险**：改 Facade 签名后上游 consumer 没同步升 jar，线上才炸。

**对策**：
- CLAUDE.md 硬规则："禁止修改任何已存在 Facade 方法签名"
- 改接口前强制跑 `/impact` 跨 repo 搜 consumer
- `guard-facade.sh` hook 二次拦截

### 🔴 雷 2：前端 mock 数据 = 契约漂移
**风险**：后端改字段前端不知道，前端 mock 的字段后端没给。

**对策**：
- 新功能强制"契约先行"流程
- `/gen-ts-types` skill 从后端注解生成 TS 类型
- 前端去掉手写 mock 这一步

### 🔴 雷 3：直连 SIT MySQL 跑测试
**风险**：多人并发污染数据、Claude 可能脏写 SIT。

**对策**：
- 禁止 Claude 在 Auto 模式下执行连 SIT 的命令
- `guard-sit-db.sh` hook 拦截
- 渐进引入 Testcontainers，本地容器跑单测

### 🟡 雷 4：没有一键启动脚本
**对策**：
- 让 Claude 帮你写 `docker-compose.yml`（MySQL + Redis + ZK + Apollo）
- 加 `scripts/start-local.sh`
- 回报最高的基建，第一周做完

### 🟡 雷 5：前端 Vue3 + TS 无规范
**对策**：
- 专用前端 CLAUDE.md
- 强制 `<script setup>` + Composition API
- PostToolUse hook：改完 .vue/.ts 自动 `eslint --fix` + `vue-tsc`

---

## 三、第一周基建清单（按 ROI 排序）

| Day | 任务 | 投入 | 解锁能力 |
|---|---|---|---|
| **1** | 根 CLAUDE.md（Java） + 前端 CLAUDE.md | 3h | 基础护栏 |
| **1** | 建 `workspace/` 目录，clone 相关 repo | 1h | 跨 repo 检索 |
| **2** | 3 个 hook 脚本 | 2h | 防止改坏 Facade / 连 SIT |
| **2** | `/locate` 和 `/impact` 两个 skill | 1h | 痛点 A + B |
| **3** | Knife4j 接入 + `/gen-ts-types` skill | 3h | 痛点 C |
| **4** | 一键启动 docker-compose | 4h | 自动跑起服务 |
| **5** | Testcontainers（试点一个服务） | 半天 | 痛点 D |

**Day1-2 必须做完**，否则后面都是手动活。

---

## 四、跨 repo 工作区

手动搭一个"伪 monorepo"工作区：

```
~/work/claude-workspace/
├── CLAUDE.md                    ← 工作区级规约
├── .claude/
│   ├── settings.json
│   ├── hooks/
│   │   ├── guard-facade.sh
│   │   ├── guard-sit-db.sh
│   │   ├── guard-bash.sh
│   │   └── format-and-lint.sh
│   └── skills/
│       ├── locate.md
│       ├── impact.md
│       ├── gen-ts-types.md
│       └── cross-repo-plan.md
├── backend/
│   ├── service-user/            ← git clone 过来
│   ├── service-order/
│   ├── service-export/
│   ├── gateway/
│   └── _index.md                ← 手写的服务索引
├── frontend/
│   ├── web-admin/
│   └── web-portal/
└── docs/
    └── contracts/               ← OpenAPI 契约文件
```

**关键动作**：`cd ~/work/claude-workspace && claude` —— 从工作区根目录启动。Glob / Grep 能横跨所有 repo。

所有模板文件见 [`templates/`](./templates/)。

---

## 五、5 天 AI 辅助完整需求流程

以"给后台加一个用户数据导出功能"为例，涉及 3 个服务 + 网关 + 前端：

### Day 1：需求拆解 + 定位 + 规划（AI 70% / 你 30%）

```
你：  读产品需求，脑子里列出大致涉及的服务
Claude：
  /locate 用户导出相关代码
  → sub-agent 跨 repo 搜索
  /cross-repo-plan 新增用户数据导出功能
  → 输出完整改造计划
你：  审查计划，修正
```

**产出**：`workspace/docs/plan-export.md`

### Day 2：后端契约先行（AI 60% / 你 40%）

```
cd backend/service-export && claude

1. Claude 写 Controller + DTO + Knife4j 注解（不写实现）
2. 启动服务，打开 Knife4j 页面肉眼验证
3. /gen-ts-types service-export ExportController
   → 前端 types 文件生成
4. /impact UserFacade.findByTier
   → 确认上游 Facade 是否需要改
```

**产出**：空实现 Controller + 前端 types + Swagger 页面

### Day 3：后端实现 + 单测（AI 80% / 你 20%）

```
你：  "按 TDD 写，先写测试的所有场景（正常、用户不存在、导出失败），
       都应该失败"
Claude：写测试 → 跑 → 全红

你：  "现在实现让测试变绿，一次一个方法"
Claude：逐个实现，每完成一个跑一次测试

你：  "/commit 按 conventional commits 规范"
```

**关键**：Dubbo 调用用 `@MockBean` 模拟。

### Day 4：前端实现（AI 75% / 你 25%）

```
cd frontend/web-admin && claude

你："根据 src/types/api/export.ts 的类型，实现导出页面"
Claude：
  - 生成 src/api/export.ts
  - 生成 src/views/export/ExportPage.vue
  - 用 Pinia 管状态
每改一个文件 hook 自动跑 eslint --fix

联调验证：本地起后端 + 前端 dev 指向本地 + 肉眼点一遍
```

### Day 5：网关 + 收尾 + PR（AI 50% / 你 50%）

```
- 网关加路由（你亲自加，可能要走审批）
- Sub-agent 跑 self-review
- Claude 写每个 repo 的 PR 描述
- 你逐个 PR 提交、找人 review
```

### 对比

- **之前**：前端 1 人 + 后端 1 人，1~4 周
- **之后**：你 1 人 + Claude，**快的话 1 周、慢的话 2 周**

---

## 六、Dubbo 接口变更 SOP

**必须按以下顺序**：

1. 跑 `/impact <FacadeName.methodName>` 输出 consumer 清单
2. 如果有 consumer：
   - 禁止改原方法签名
   - 新增 `methodV2`
   - 老方法保留，加 `@Deprecated(since="yyyy-MM-dd")`，内部 delegate 给 v2
3. 如果没有 consumer：可直接改，但 PR 描述写明"确认无下游"
4. 改完手动发版到私服（Claude 禁止执行 `mvn deploy`）

---

## 七、契约先行开发流程

```
┌─────────────────────┐
│ 1. 后端写 Controller │  ← Swagger / Knife4j 注解完整
│    + DTO + 注解     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. /gen-ts-types    │  ← 生成 src/types/api/*.ts
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌─────────┐
│后端实现 │ │前端实现 │  ← 并行，基于同一份类型
│+ 单测   │ │+ 组件   │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           ▼
┌─────────────────────┐
│     联调 + PR       │
└─────────────────────┘
```

**关键**：绝对不允许前端手写 DTO 类型。类型文件顶部注释"自动生成，勿手改"。

---

## 八、针对痛点的速查

### 痛点 A：代码定位
- **核心**：`/locate` + `backend/_index.md` 服务地图
- **禁忌**：不要让 Claude 盲目 ls 一堆 repo

### 痛点 B：Dubbo 影响分析
- **核心**：`/impact` skill + `guard-facade.sh` hook 双保险
- **进阶**：在 `_index.md` 里手动维护"Facade 被谁调"

### 痛点 C：前后端联调
- **核心**：契约先行 + `/gen-ts-types`
- **关键动作**：砍掉"前端手写 mock"
- **过渡期**：没有 Knife4j 时 Claude 也能从手写 Controller 提取 TS 类型

### 痛点 D：单测
- **优先策略**：TDD 比补救式写测靠谱 10 倍
- **Dubbo Mock 模板**：
  ```java
  @SpringBootTest
  class ExportServiceTest {
      @MockBean UserFacade userFacade;
      @Autowired ExportService exportService;

      @Test
      void should_export_when_user_has_orders() {
          when(userFacade.findById(1L)).thenReturn(mockUser());
          ExportResult r = exportService.export(1L);
          assertThat(r.status()).isEqualTo("SUCCESS");
      }
  }
  ```
- **Testcontainers 试点**：挑一个写入少的服务先引入
- **禁令**：Claude 不能连 SIT DB（hook 已拦）

### 痛点 G：跨 repo 改造
- **核心**：`/cross-repo-plan` 先规划，再一个 repo 一个 session 实施
- **铁律**：**永远不要让一个 Claude session 同时改两个 repo**
- **顺序**：API module → provider → 发版 → consumer 升依赖 → 前端 → 网关

---

## 九、落地节奏建议

- **本周**：Day 1-2 基建
- **下周**：挑一个中等规模的真实需求试跑完整 5 天流程
- **第 3 周起**：Claude Code 作为默认工作流
- **一个月后**：评估"一人干两人活"的可行性

---

## 十、模板文件索引

所有可直接复制的模板在 [`templates/`](./templates/)：

- [`CLAUDE.workspace.md`](./templates/CLAUDE.workspace.md) - 工作区根目录规约
- [`CLAUDE.frontend.md`](./templates/CLAUDE.frontend.md) - 前端规约
- [`_index.backend.md`](./templates/_index.backend.md) - 后端服务索引
- [`settings.json`](./templates/settings.json) - hooks 配置
- [`hooks/`](./templates/hooks/) - 4 个 hook 脚本
- [`skills/`](./templates/skills/) - 4 个 skill 定义
