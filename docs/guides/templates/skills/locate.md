---
name: locate
description: 跨 repo 定位功能代码，避免手动翻仓库
---

# /locate —— 跨 repo 代码定位

用户会说类似：
- `/locate 用户的登录逻辑`
- `/locate 订单创建接口`
- `/locate 导出任务状态查询`

## 执行步骤

1. **先读 `backend/_index.md`**，根据关键词推断可能涉及的服务
2. **派生 sub-agent 并行搜索**候选服务（不超过 3 个并发）：
   - Grep 关键词（中文注释、方法名、类名）
   - 读 Controller / Facade 入口层的文件列表
   - 识别可能的调用链

3. **每个 sub-agent 的输出格式**：
   ```
   服务：service-xxx
   可能的入口：com.xxx.Controller.login()  (文件:行号)
   相关文件（按调用链）：
     1. LoginController.java:45
     2. LoginService.java:78
     3. UserDAO.java:120
   ```

4. **主对话只汇总结论**，不要塞文件内容

5. **最后问用户**："要我深入看哪几个？"，等待指示，不要自动展开

## 禁止

- 不要直接读所有候选文件的完整内容
- 不要超过 3 个 sub-agent 并行
- 不要自动 Edit 任何文件
- 不要在这一步做修改决策

## 成功标准

用户读完你的输出，应该能在 1 分钟内决定下一步去哪个文件。
