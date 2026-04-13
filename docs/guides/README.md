# Claude Code 使用指南与企业落地手册

本目录收录了基于 `docs/architecture/` 架构文档反推出来的**实战用法**，从"读懂源码"到"在企业项目里真实落地"的全链路笔记。

> 本目录内容为研究与学习笔记，不代表 Anthropic 官方建议。

---

## 📚 文档索引

### 1. [架构学习路径](./01-architecture-learning.md)
按"从宏观到细节"的顺序，用架构图串讲 Claude Code 的内部工作原理。适合第一次接触源码的读者。

**核心内容**：
- 4 层宏观架构
- QueryEngine 查询生命周期
- 状态管理与单向数据流
- 多 Agent 协作（Coordinator）
- 上下文压缩 Snip
- 权限与沙箱
- 双引擎入口（REPL / SDK）
- 扩展机制（Plugins / Skills / MCP / Hooks）
- 远程桥接
- API 通信优化

### 2. [深度用户指南](./02-power-user-guide.md)
针对已经理解架构的用户，把内部机制转化为"可利用的杠杆"。

**核心内容**：
- Prompt Cache 榨干术
- CLAUDE.md 的正确用法（永久记忆，不是 README）
- `/clear` vs `/compact` 的决策
- 权限模式搭配策略
- 什么时候召唤 Sub-Agent
- Skills / Plugins / MCP / Hooks 的选型
- Print/SDK 模式的脚本化用法
- 成本控制
- Git 集成最佳实践
- 深度用户的典型一天

### 3. [企业级作战手册（Java + Dubbo + Vue3）](./03-enterprise-playbook.md)
### 4. [多 Agent 模式速查](./04-multi-agent-modes.md)
内置 Sub-Agent vs tmux 多面板 vs Background Worktree：什么时候用哪种、子 agent 做了什么怎么看。
针对"多 repo + Dubbo 微服务 + Vue3 前后端分离"的典型企业场景，**目标是让 1 人 + Claude Code ≈ 2 人**。

**核心内容**：
- 5 大痛点与应对策略
- 第一周基建清单
- 跨 repo 工作区搭建
- 5 天 AI 辅助完整需求流程
- Dubbo 接口变更 SOP
- 契约先行开发流程

---

## 🛠 模板文件

所有可直接复制到你自己项目的模板都在 [`templates/`](./templates/) 目录：

```
templates/
├── CLAUDE.workspace.md       # 工作区根目录 CLAUDE.md 模板（Java + Dubbo）
├── CLAUDE.frontend.md        # 前端 CLAUDE.md 模板（Vue3 + TS）
├── _index.backend.md         # 后端服务索引（_index.md）模板
├── settings.json             # .claude/settings.json 示例
├── hooks/
│   ├── guard-facade.sh       # 拦截 Dubbo Facade 接口签名改动
│   ├── guard-sit-db.sh       # 禁止写入 SIT 数据库配置
│   ├── guard-bash.sh         # 拦截高危 Shell 命令
│   └── format-and-lint.sh    # Edit 后自动 format + lint
└── skills/
    ├── locate.md             # /locate 跨 repo 代码定位
    ├── impact.md             # /impact Dubbo 影响分析
    ├── gen-ts-types.md       # /gen-ts-types 后端注解生成 TS 类型
    └── cross-repo-plan.md    # /cross-repo-plan 跨 repo 改造规划
```

---

## 🚀 快速上手

如果你是企业项目深度用户，按此顺序消化：

1. 读 [架构学习路径](./01-architecture-learning.md) 建立心智模型（1 小时）
2. 读 [深度用户指南](./02-power-user-guide.md) 了解机制利用技巧（1 小时）
3. 读 [企业作战手册](./03-enterprise-playbook.md) 学完整流程（1 小时）
4. 把 `templates/` 下的文件复制到你自己的工作区并按项目情况调整
5. 挑一个中等规模的真实需求试跑完整 5 天流程

---

## ⚠️ 免责声明

- 本仓库基于公开 npm 包与 source map 反向还原，仅供研究学习
- 架构文档和使用建议均为对源码的理解，不代表官方立场
- 模板文件需要根据你的实际技术栈微调后使用
