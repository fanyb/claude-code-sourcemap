# Companion UI 与彩蛋 (Buddy / Sprite)

在纯文本的终端应用中，为了增加趣味性和用户粘性，Claude Code 实现了一个轻量级的 ASCII/Unicode 动画渲染系统，主要位于 `src/buddy/` 目录。

## 1. Companion Sprite

### 架构设计
- **精灵表 (Sprites)**: 利用预定义的 ASCII 艺术帧（Frame）序列。
- **状态机**: 伴侣（Buddy）有多种状态：待机（Idle）、思考中（Thinking）、庆祝（Success）、报错（Error）。
- **动画循环**: 利用 React 的 `useEffect` 和 `setInterval` 在终端的特定区域（通常是右上角或输入框旁边）周期性地刷新字符帧。

## 2. 气泡提示 (Floating Bubble)

- 除了单纯的动画，Buddy 还能以“对话气泡”的形式输出轻量级的提示或系统通知（如“网络重连中...”）。
- 这些通知不会干扰主消息历史列表，属于“短暂的视觉指示”。

## 3. 性能考量

- 为了防止高频的重新渲染导致终端卡顿，动画帧率通常被限制在 1-5 FPS。
- 并且在启用了实验性的高性能特性或在配置较低的环境中，该模块会被静默移除（Dead Code Elimination），不参与编译。
