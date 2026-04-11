# Claude Code 深度用户指南

把架构层面的机制翻译成"你能用的杠杆"。每一条都有源码依据。

---

## 一、榨干 Prompt Cache —— 省 80% Token

**机制**：System Prompt 的静态部分被放在最前面来最大化 Anthropic API 的 prefix cache 命中。

**打法**：
- **一个目录只开一个长 session**。每次冷启动都要重新注入工具定义 + 目录结构 + CLAUDE.md。
- **不要频繁改 CLAUDE.md**。一改就使整个会话的 cache 失效。
- **不要在对话中间塞大文件**。让它用 Read 工具自己读，走另一条路径。
- **斜杠命令优于自然语言重复**：`/commit`、`/review` 走 cache 路径。

---

## 二、CLAUDE.md 是"永久记忆"，不是"README"

**机制**：CLAUDE.md 在**每一次请求**都被自动注入。它不是文档，是**长期注入的 system prompt 片段**。

**高价值内容清单**（按 ROI 排序）：
1. 测试 / 构建 / lint 命令
2. 模块边界（目录用途）
3. 代码风格的"反例"
4. 你的个人口味
5. 项目特殊陷阱

**反模式**：
- 不要放大段项目背景介绍
- 不要放完整 API schema
- 不要超过 2K token

---

## 三、主动管理上下文窗口

**机制**：`/compact` 是有损压缩，摘要会丢细节；`/clear` 是彻底重置。

**决策树**：
```
当前任务和之前任务相关？
├── 是 → 继续，快到 token 上限才 /compact
└── 否 → 立即 /clear
```

**经验法则**：
- 切换任务 = `/clear`
- 一个任务超过 200k tokens 还没完 → 用 Coordinator 模式拆
- AI 开始"忘事"、重复问 → 是 Snip 过了，该 `/clear`

---

## 四、权限模式的真实用法

| 场景 | 模式 | 原因 |
|---|---|---|
| 重构/大改 | **Prompt** | 需要看每一步 |
| 跑测试/查资料/只读探索 | **Auto** | 分类器会拦 rm -rf |
| CI / 脚本自动化 | **Bypass + Docker sandbox** | 隔离 + 全信任 |
| 第一次用某个 repo | **Prompt** | 先建立信任 |

**隐藏技巧**：在 CLAUDE.md 里写规则比权限系统更细粒度。

---

## 五、什么时候召唤 Sub-Agent

**机制**：每个 sub-agent 是独立 QueryEngine + 独立消息历史 → 上下文不污染主对话。

**最佳场景**：
1. 大面积搜索 / 探索 → sub-agent 吐 1000 字摘要
2. 并行独立任务
3. 不想看的脏活（跑测试、分析日志、grep 成吨文件）

**反模式**：
- 不要用 sub-agent 做"连续调试"
- 不要嵌套 sub-agent 超过 2 层
- sub-agent 返回的结论要验证一次

---

## 六、Skills / Plugins / MCP / Hooks 选型

```
稳定性    扩展深度     上手成本
──────────────────────────────
Skills   ↑高       ↓浅       ↓ 几分钟 (纯 md)
Hooks    →中       →中       → 熟 json
MCP      →中       ↑深       ↑ 要启服务
Plugins  ↓低       ↑↑深      ↑↑ 要写 TS
```

**选型指南**：
- **"每次都想让它做 X"** → Skill
- **"某个操作前后必须做 Y"** → Hook
- **"需要接外部系统"** → MCP
- **"要改 Claude Code 本身行为"** → Plugin

---

## 七、Hooks 是被低估的杠杆

**高价值 hook 模板**：

1. **PostToolUse (Edit) → 自动 lint**
   - Edit 完自动跑 eslint/prettier → 反馈给 Claude → 下一步它就看到错误自己修

2. **PreToolUse (Bash) → 命令白名单**
   - 把个人安全偏好代码化（禁 git push --force 等）

3. **SessionStart → 自动 warmup**
   - 启动时自动跑 git status + git log → 写入 context

---

## 八、Print/SDK 模式当脚本用

```bash
# 批量生成 commit message
git diff | claude -p "生成符合规范的 commit message"

# 代码审查进 CI
claude -p "审查这个 diff 的安全问题" < pr.diff > review.md

# 定时任务
claude -p --output-format=json "总结今天的 git log" | jq ...

# 串联多个 Agent
claude -p "规划重构步骤" | claude -p "执行第一步"
```

---

## 九、成本控制

- **设预算**：`--cost-limit` 硬顶
- **用对模型**：规划阶段用强模型，体力活切 Haiku
- **定期看 `/cost`**：知道钱花在哪
- **避免"友情聊天"**：每一句话都是完整 prompt + 上下文的费用

---

## 十、Git 集成最佳姿势

1. **小步提交**：Claude 完成一个 unit 就 `/commit`
2. **Worktree 做危险实验**：主工作区不受影响
3. **`/review` 跑在 PR 前**：抓跨文件问题
4. **永远不用 `--no-verify`**

---

## 十一、反模式清单

- ❌ 每次都 `claude` 冷启动
- ❌ 把 README 塞进 CLAUDE.md
- ❌ 用自然语言描述复杂操作（能用 `/command` 就用）
- ❌ 在 Auto 模式下做不熟悉的 repo
- ❌ 让它一次改 10 个文件
- ❌ 看到它跑偏不中断
- ❌ 依赖它记住"上次说过"
- ❌ 出错就 `/clear` 重来

---

## 十二、一个典型的"深度用户"一天

```text
早上:
  cd ~/project
  claude                    # 启动，自动吃掉 CLAUDE.md + git diff
  /model sonnet              # 默认省钱
  "今天要做 X，先看看 feat/x 分支进度"

中午任务切换:
  /clear                    # 重置上下文
  /model opus                # 切强模型做规划
  "规划下一步重构 auth 模块"
  → 让它吐出 plan
  /model sonnet              # 切回省钱模式执行

下午大活:
  "用 sub-agent 并行改 A/B/C 三个文件，改完跑 pnpm test"
  → 自己去泡咖啡，hook 自动 lint
  /commit                   # 分别提交

晚上 CI:
  claude -p --output-format=json \
    "审查 HEAD~5..HEAD 的安全问题" > audit.json
```
