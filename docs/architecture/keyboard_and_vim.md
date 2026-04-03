# 快捷键与 Vim 模式架构 (Keyboard & Vim Mode)

作为一个重度终端应用，Claude Code 必须提供类似于原生终端编辑器的输入体验。

## 1. 快捷键管理系统 (`keybindings/`)

### 全局与上下文快捷键
- **`GlobalKeybindingHandlers`**: 拦截如退出 (`Ctrl+C`), 切换面板, 全局历史翻页等操作。
- **`CommandKeybindingHandlers`**: 与当前聚焦的输入框或虚拟列表强绑定的快捷键。

### 事件派发机制
- Ink 提供的 `useInput` 被深度封装，以便在不同的组件间正确冒泡或阻止按键事件。例如：如果在 `VirtualMessageList` 中按 `j`/`k` 是滚动消息，在 `PromptInput` 中则是输入字母。

## 2. Vim 模式 (`vim/`)

### 状态机 (State Machine)
- 实现了 Vim 编辑器的一个子集（普通模式、插入模式、可视模式）。
- 跟踪操作符（如 `d`, `y`, `c`）和动作（Motions, 如 `w`, `b`, `$`, `0`）。

### 文本缓冲区 (Text Buffer)
- 当开启 Vim 模式时，`PromptInput` 内部的 `Cursor` 和 `Value` 状态交由 Vim 引擎接管。
- 支持从剪贴板寄存器中拉取文本，或将剪切的文本放入操作系统的剪贴板。

## 3. 实现细节

由于 JavaScript 在终端中捕捉所有 ANSI 按键序列存在一定局限性（如无法完美区分 `Tab` 和 `Ctrl+I`），按键系统在底层维护了一个映射表，并在 `src/utils/platform.ts` 中针对 Windows/Linux/macOS 终端模拟器的不同行为进行了标准化。
