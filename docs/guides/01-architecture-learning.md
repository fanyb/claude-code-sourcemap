# Claude Code 架构学习路径

基于 `docs/architecture/` 的 20 份架构文档，按"从宏观到细节"的顺序串讲。读完这一份就能建立整个项目的心智模型。

---

## 第 0 步：项目定位

`claude-code-sourcemap` 是一个**非官方**研究仓库，通过 npm 包 `@anthropic-ai/claude-code@2.1.88` 的 `cli.js.map` 反向提取出 TypeScript 源码（约 1884 个 `.ts/.tsx` 文件），全部还原在 `restored-src/src/` 下。

```
claude-code-sourcemap/
├── README.md              # 项目来源与声明
├── docs/architecture/     # 20 份架构文档
├── docs/guides/           # 本目录：学习与落地手册
├── restored-src/src/      # 还原的源码（可对照阅读）
└── package/cli.js.map     # 原始 sourcemap
```

---

## 第 1 步：4 层宏观架构

整个项目最重要的一张图：

```text
+-----------------------------------------------------------------------+
| 1. 界面与交互层 (Interface & Interaction)                              |
|    TUI (React/Ink) · REPL · Vim · 语音 · 远程桥接 Bridge               |
+----------------------------------+------------------------------------+
                                   | Events / SDKMessages
+----------------------------------v------------------------------------+
| 2. 调度与编排层 (Orchestration)                                        |
|    QueryEngine(思考循环) · Coordinator(多Agent) · AppState             |
|    Tasks · Compaction · MemDir                                        |
+-------------------------+----------------------------+----------------+
                          | Tool Calls                 | Data
+-------------------------v----------------------------v----------------+
| 3. 核心能力层 (Capabilities)                                           |
|    Bash/Edit/Read 工具 · MCP 协议 · /命令系统                          |
|    Git 感知 · LSP 语义分析                                             |
+-------------------------+----------------------------+----------------+
                          | System Calls               | Telemetry
+-------------------------v----------------------------v----------------+
| 4. 基础设施与安全层 (Bedrock)                                          |
|    Permissions · Docker Sandbox · API 重试 · OTEL · Cost              |
+-----------------------------------------------------------------------+
```

**学习要点**：自上而下是"眼 → 脑 → 手 → 骨"。任何一个功能都可以往这 4 层对号入座。

> 详细文档：[`docs/architecture/overview.md`](../architecture/overview.md)

---

## 第 2 步：大脑 —— 查询生命周期

这是整个项目最核心的循环：

```text
[用户输入]
    │
    ▼
processUserInput()   ← 先识别 /commit, /review 等斜杠命令
    │
    ▼
fetchSystemPromptParts()   ← 组装 System Prompt（工具定义+上下文）
    │
    ▼
query() 循环 ◄─────────────────────────┐
    │                                   │
    ▼                                   │
模型推理 (API)                          │
    │                                   │
 ┌──┴──┐                                │
 │     │                                │
文字   工具调用                          │
 │     │                                │
 ▼     ▼                                │
结束  权限检查 → 工具执行 → 结果反馈 ───┘
```

**关键类**（`restored-src/src/`）：
- `QueryEngine.ts` —— 持有 `mutableMessages` 和 `AbortController`，通过 AsyncGenerator 流式输出 `SDKMessage`
- `query.ts` —— 封装 Anthropic SDK 调用、重试、Token 统计
- `processUserInput.ts` —— 本地命令预处理

**三个核心状态**：Thinking → ToolUsing → Compacting

> 详细文档：[`docs/architecture/query_lifecycle.md`](../architecture/query_lifecycle.md)

---

## 第 3 步：状态流（单一事实来源）

```text
Action (QueryEngine 生成 Token)
       │
       ▼
setAppState()  ← 单一事实来源 AppStateStore (类 Redux)
       │
       ▼
Context Provider 通知
       │
       ▼
React 组件重渲染
       │
       ▼
Ink → ANSI 转义 → 终端绘制
```

**持久化的内容**：Transcript（对话）、Settings（密钥/模型/白名单）、Session Metadata。所以 `claude --resume` 能恢复上下文。

> 详细文档：[`docs/architecture/state_management.md`](../architecture/state_management.md)

---

## 第 4 步：多 Agent 协作

```text
[用户: 重构 A 和 B 模块]
        │
        ▼
   Coordinator   ← 主 Agent，不能直接用 Bash/Edit
        │
   ┌────┼────┬────────┐
   ▼    ▼    ▼        ▼
 SubA  SubB  SubC  (各自独立的 QueryEngine 实例)
 改A   改B   跑测试
   │    │    │
   └────┼────┘
        ▼
   Coordinator (汇总 → 回用户)
```

**关键设计**：
- 每个子 Agent 有独立的消息历史（防止上下文爆炸）
- 继承父 Agent 的权限配置
- 子 Agent 失败不崩溃父 Agent

> 详细文档：[`docs/architecture/coordinator_and_agents.md`](../architecture/coordinator_and_agents.md)

---

## 第 5 步：上下文压缩 Snip

```text
原始消息流 (接近 Token 上限)
        │
        ▼
 ┌──────────────────┐
 │ 1. 内容清理       │  ← 删大文件/图片/冗余工具输出
 │ 2. 语义摘要       │  ← 调用模型生成摘要
 │ 3. 插入边界 Msg   │  ← SystemCompactBoundaryMessage
 │ 4. 保留摘要+新对话│
 └──────────────────┘
        │
        ▼
紧凑后的消息流
```

**另外两个技巧**：
- **Micro-compacting**：工具结果行级/字段级截断
- **CLAUDE.md**：写入的规则作为"永久记忆"自动注入

> 详细文档：[`docs/architecture/context_and_memory.md`](../architecture/context_and_memory.md)

---

## 第 6 步：安全边界

```text
AI 想执行 Bash 命令
        │
        ▼
权限模式？
        ├── Prompt   → 弹窗让用户批准
        ├── Auto     → 危险命令分类器
        │                 │
        │                 ├── 匹配 rm -rf / mkfs / SSH keys
        │                 │      └─> 降级为 Prompt
        │                 └── 通过 → 直接执行
        └── Bypass   → CI/CD 模式全放行
        │
        ▼
可选：路由到 Docker Sandbox
        │
        ▼
真实执行
```

> 详细文档：[`docs/architecture/security_and_sandbox.md`](../architecture/security_and_sandbox.md)

---

## 第 7 步：双引擎入口

```text
             main.tsx
                │
       ┌────────┴────────┐
       ▼                 ▼
   REPL 模式          Print/SDK 模式
   (交互)             (--print, 管道)
       │                 │
  全屏 React/Ink     跳过 UI
  TUI 事件循环       纯 ndjson 输出
                    权限自动降级
```

**关键洞察**：Claude Code 既是一个 App，也是一个 Library。同一个 `QueryEngine` 可以被 VS Code 插件、自动化测试、CI 脚本调用。

> 详细文档：[`docs/architecture/cli_and_sdk.md`](../architecture/cli_and_sdk.md)

---

## 第 8 步：扩展机制

```text
扩展方式       │ 本质           │ 位置
─────────────┼───────────────┼─────────────
Plugins      │ JS/TS 模块     │ --plugin-dir
             │ 注册命令/工具  │
Skills       │ Prompt 片段    │ ~/.claude/skills/
             │ 动态能力描述   │
MCP Servers  │ 独立进程/网络  │ 动态连接
             │ 标准协议       │
Hooks        │ 生命周期钩子   │ Pre/Post Tool Use, Session
```

> 详细文档：[`docs/architecture/plugins_and_skills.md`](../architecture/plugins_and_skills.md)

---

## 第 9 步：远程桥接

```text
 本地终端                 中继服务器              手机/Web
    │                        │                      │
QueryEngine ──SDKMessage──► Bridge API ──WS/SSE──► 远程 UI
    ▲                        │                      │
    │                      JWT + Work Secret        │
    └─────── 指令回流 ────────────────────────────── ┘
           (允许工具调用 / 切换模式)
```

> 详细文档：[`docs/architecture/bridge_and_remote.md`](../architecture/bridge_and_remote.md)

---

## 第 10 步：API 通信优化

三个性能要点：
1. **Preconnect**：用户输入时提前建立 TLS 握手，首包延迟 -100~200ms
2. **Prompt Caching**：静态工具定义放前面，最大化 Anthropic API 缓存命中
3. **SSE 流式 + AbortSignal**：中断即刻释放连接，不浪费 Token

> 详细文档：[`docs/architecture/api_and_networking.md`](../architecture/api_and_networking.md)

---

## 建议的阅读顺序

| 顺序 | 文档 | 理由 |
|---|---|---|
| 1 | `overview.md` | 建立宏观心智模型 |
| 2 | `query_lifecycle.md` | 核心循环（大脑） |
| 3 | `state_management.md` | 单向数据流 |
| 4 | `cli_and_sdk.md` | 双引擎入口 |
| 5 | `context_and_memory.md` | 压缩与记忆 |
| 6 | `coordinator_and_agents.md` | 多 Agent 进阶 |
| 7 | `security_and_sandbox.md` | 安全机制 |
| 8 | `plugins_and_skills.md` | 扩展系统 |
| 9 | `tui_and_repl.md` | 界面层 |
| 10 | `git_and_vcs.md` / `lsp_and_analysis.md` | 环境感知 |
| 11 | `api_and_networking.md` / `cost_tracking.md` | 基础设施 |
| 12 | `bridge_and_remote.md` / `voice_interaction.md` / `companion_ui.md` | 边缘玩法 |

**对照阅读**：每份文档读完，配合打开 `restored-src/src/` 里对应的目录，架构图 + 真实代码，学习效率最高。
