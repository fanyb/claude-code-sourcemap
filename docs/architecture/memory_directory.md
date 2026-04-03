# 记忆目录与知识库 (Memory Directory)

为了让 Claude Code 在长期参与一个项目时变得越来越“聪明”，系统引入了持久化的记忆目录系统（位于 `src/memdir/` 和相关的 `CLAUDE.md` 解析中）。

## 1. `CLAUDE.md` 解析与注入
- 项目根目录的 `CLAUDE.md` 扮演了“项目系统提示词”的角色。
- 系统会在 `queryContext.ts` 中将其内容与默认的 System Prompt 拼接，确保模型在每次交互中都遵守团队约定的代码风格、构建命令或架构规范。

## 2. 自动记忆 (Auto-Memory / MemDir)

这是一个更高级的功能，允许模型主动在磁盘上记录上下文。
- **机制**：通过覆盖或配置特定的记忆路径，模型被赋予调用特定读写工具的权限，它会在这些目录中以 Markdown 格式写入它对代码库的理解、遗留 Bug 记录或 TODO 事项。
- **加载策略**：在会话初始化的 `fetchSystemPromptParts` 阶段，如果检测到记忆目录存在，系统会将这些文件的内容转化为特定的上下文块（Context Blocks），让模型“回忆”起之前的发现。

## 3. 历史对话快照 (History Snaps)

与长期的项目知识库不同，单次会话的上下文需要应对 Token 窗口的限制。
- `history.ts` 结合 `services/compact/` 中的压缩机制，不断将最久远的消息转化为提炼过的摘要（Summary）。
- 这种机制在保持“记忆”的语义相关性的同时，大幅降低了 API 调用的成本和首包延迟。
