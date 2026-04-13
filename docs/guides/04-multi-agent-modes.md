# 多 Agent 模式速查

三种"多 Agent"玩法，选对场景用对方式。

---

## 三种方式一览

```
方式 1：内置 Sub-Agent（同进程）         方式 2：tmux 多面板（多进程）
┌──────────┐                            ┌──────┐ ┌──────┐ ┌──────┐
│ claude   │                            │claude│ │claude│ │claude│
│  ├ main  │ ← 共享内存                 │ pane1│ │ pane2│ │ pane3│
│  ├ sub-A │   自动汇总结果              └──────┘ └──────┘ └──────┘
│  └ sub-B │                             彼此完全独立，你当协调器
└──────────┘

方式 3：Background Agent + Worktree（进程级隔离）
┌──────────┐
│ claude   │ ← 主进程自动 spawn 子进程
│  ├ main  │   git worktree 隔离文件
│  └─► bg  │   邮箱通信 + 自动清理
└──────────┘
```

| 维度 | 内置 Sub-Agent | tmux 多面板 | Background + Worktree |
|---|---|---|---|
| 隔离 | 轻（同进程） | 重（独立进程） | 中（独立进程 + git worktree） |
| 通信 | 自动返回结果 | 你手动复制粘贴 | 邮箱系统 |
| 文件 | 共享目录 | 各自目录 | 自动隔离分支 |
| 适合 | 短任务、搜索、分析 | 并行独立开发 | 长任务、危险实验 |

---

## 什么场景用什么

| 场景 | 推荐方式 |
|---|---|
| 跨 repo 搜索 / 影响分析 | **内置 Sub-Agent** |
| 写单测 / 生成类型 | **内置 Sub-Agent** |
| 契约确定后前后端并行写代码 | **tmux 两面板** |
| 3 个互不依赖的 repo 各自改 | **tmux 多面板** |
| 大重构、不确定会不会搞坏 | **Background + Worktree** |
| 试验性方案、想随时丢弃 | **Background + Worktree** |

---

## tmux 快速搭建

```bash
tmux new-session -s work -d
tmux send-keys -t work 'cd ~/work/service-user && claude' Enter
tmux split-window -h -t work
tmux send-keys -t work 'cd ~/work/frontend && claude' Enter
tmux attach -t work
```

**核心注意**：面板之间的 Claude 互不知道对方存在，你需要手动同步信息（"那边的接口签名是 xxx，你按这个来"）。

---

## 子 Agent 做了什么？怎么看

| 层级 | 看什么 | 怎么看 |
|---|---|---|
| 实时 | 进度 pill（底部） | 每 30 秒自动更新一句摘要 |
| 完成后 | 结论文本 + 工具调用次数 | 自动返回到主对话 |
| 详细 | 完整执行过程 | Teammate view 展开 |
| 事后 | 全部历史 | `~/.claude/projects/.../subagents/agent-*.jsonl` |
| 文件改动 | git diff | 最可靠，看实际改了什么 |

**日常原则**：看结论 + `git diff` 抽查。高危操作自己验证。

---

## 推荐的组合打法（Dubbo 微服务场景）

```
阶段 1 规划：内置 Sub-Agent 并行探索 → 汇总计划
阶段 2 改 API jar：单 session
阶段 3 业务 + 前端：tmux 两面板并行
阶段 4 联调收尾：单 session
```

**铁律**：契约没定好之前不要开 tmux 并行，否则返工。
