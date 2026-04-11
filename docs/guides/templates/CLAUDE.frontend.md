# 前端规约（Vue3 + TypeScript）

> 这是一份模板，请根据你公司的实际情况裁剪后放到前端项目根目录的 `CLAUDE.md`。

## 技术栈约束
- Vue 3（**只用 Composition API**）
- 所有组件必须用 `<script setup lang="ts">`
- 严禁 Options API、严禁 `export default { ... }` 组件
- TypeScript 严格模式，`any` 需要写注释说明原因

---

## 类型系统

- Props 必须用 `defineProps<Props>()`，不用运行时声明
- Emits 必须用 `defineEmits<{...}>()`
- 所有 API 请求的返回类型必须来自 `src/types/api/*.ts`
- **禁止手写 API DTO 类型** —— 必须从后端 Swagger 生成（用 `/gen-ts-types` skill）

---

## 目录规约

- 组件：`src/components/`（通用）、`src/views/*/components/`（页面专属）
- API 层：`src/api/<模块>.ts`，统一用 `request` 封装
- 类型：`src/types/api/<模块>.ts`（自动生成，禁止手改）
- 状态：Pinia，`src/stores/<模块>.ts`

---

## Mock 规约（过渡期）

- **禁止在组件内硬编码 mock 数据**
- 如需临时 mock，放 `src/mocks/<模块>.ts`，留 TODO 标记何时删除
- 最终目标：后端 Knife4j → 生成 TS types → 前端直接用，零手动 mock

---

## 禁止模式

- 禁止 `v-html` 渲染用户输入
- 禁止直接修改 props
- 禁止在 setup 外使用 `useXxx` hook
- 禁止 Element Plus 组件的 `:deep` 样式穿透超过 2 层
- 禁止使用 `any`（除非写注释说明为什么）
- 禁止 `as unknown as T` 这种双重断言

---

## 代码风格

- 组件名用 PascalCase（`UserList.vue`，不是 `user-list.vue`）
- 事件名用 kebab-case（`@user-click`）
- 常量用 UPPER_SNAKE_CASE，放 `src/constants/`
- 函数优先用箭头函数，`const fn = () => {}`
- 响应式数据用 `ref` 优先于 `reactive`

---

## 交互行为要求

1. **改组件前先读完整个文件**，别改局部后整个样式坏掉
2. **改完自动验证 TS 类型**：执行 `pnpm vue-tsc --noEmit` 或 `npx tsc --noEmit`
3. **禁止主动升级依赖**：package.json 不要动
4. **禁止创建新的 util 文件**：优先复用 `src/utils/`
