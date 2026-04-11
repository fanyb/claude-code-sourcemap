---
name: gen-ts-types
description: 从后端 Controller / Swagger 注解生成前端 TypeScript 类型
---

# /gen-ts-types —— 后端注解生成 TS 类型

用户会说类似：
- `/gen-ts-types service-export ExportController`
- `/gen-ts-types backend/service-user/.../UserController.java`

## 执行步骤

1. **定位后端 Controller 文件**及其所有 DTO（Request / Response）

2. **分析每个 DTO 类的字段**：
   - **类型映射**：
     - `Long` → `number`
     - `Integer` → `number`
     - `String` → `string`
     - `Boolean` → `boolean`
     - `BigDecimal` → `string`（避免精度丢失）
     - `LocalDateTime` / `Date` → `string`（ISO 格式）
     - `List<T>` → `T[]`
     - `Map<K, V>` → `Record<K, V>`
   - **嵌套对象递归处理**
   - 注意 `@JsonFormat`、`@JsonProperty` 注解改变字段名
   - `@NotNull` / required 字段不加 `?`，可选字段加 `?`

3. **生成前端类型文件**：

   路径：`frontend/<项目>/src/types/api/<模块>.ts`

   格式：
   ```typescript
   // ⚠️ 自动生成，勿手改。
   // 源: backend/service-export/.../ExportController.java
   // 生成时间: <yyyy-MM-dd HH:mm>
   // 生成工具: /gen-ts-types skill

   export interface ExportRequest {
     userId: number;
     format: 'CSV' | 'EXCEL';
     startDate?: string;
     endDate?: string;
   }

   export interface ExportResponse {
     jobId: string;
     status: 'PENDING' | 'RUNNING' | 'DONE' | 'FAILED';
     downloadUrl?: string;
   }

   export interface ExportApi {
     createExport: (req: ExportRequest) => Promise<ExportResponse>;
     queryExport: (jobId: string) => Promise<ExportResponse>;
   }
   ```

4. **生成对应的 API 调用函数**到 `src/api/<模块>.ts`：

   ```typescript
   import { request } from '@/utils/request';
   import type { ExportRequest, ExportResponse } from '@/types/api/export';

   export function createExport(req: ExportRequest) {
     return request.post<ExportResponse>('/api/export', req);
   }

   export function queryExport(jobId: string) {
     return request.get<ExportResponse>(`/api/export/${jobId}`);
   }
   ```

5. **如果已有同名类型文件**：
   - diff 出变更
   - 报告哪些字段新增 / 删除 / 改类型
   - 提示哪些前端页面可能受影响（grep 引用）

## 禁止

- 禁止同时改前端业务代码（**只**生成 types 和 api 层）
- 禁止删除旧字段（只标记 `@deprecated` 注释，保留字段）
- 禁止省略"自动生成"的注释头
- 禁止生成运行时代码之外的内容（不写文档、不写测试）

## 成功标准

- 前端组件可以 `import { ExportRequest } from '@/types/api/export'` 并直接用
- TS 编译通过（`npx tsc --noEmit`）
- 对比后端 DTO，字段数量和类型一一对应
