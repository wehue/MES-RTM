---
name: system-patterns
description: 项目架构约定、设计模式和关键决策
metadata:
  type: project
---

**架构模式**

- `src/api/` — 所有 API 接口定义（user、workOrder、batch、production 等）
- `src/stores/` — Pinia 状态（user.js 管理登录态和用户功能权限）
- `src/views/` — 页面级视图组件，按业务模块分目录
- `src/components/` — 可复用组件
- `src/layouts/` — 布局组件
- `src/utils/` — 工具函数和常量（constants.js 管理角色、权限码等）
- `src/composables/` — 组合式函数

**关键约定**

1. **用户登录态**：token 存在 Pinia store，页面刷新后通过 `fetchCurrentFunctions()` 恢复功能权限
2. **角色权限**：`ROLES` 常量 + `PERMISSION_CODES` 控制菜单和按钮可见性
3. **API 契约**：前后端联调时以 `src/api/` 下的接口定义为准，修改后端需同步更新
4. **常量集中管理**：角色、权限码等统一定义在 `src/utils/constants.js`，不硬编码在组件中

**近期架构决策**

- 2026-08：移除用户注册功能，注册改为后端/管理员操作，前端只保留登录入口
- 登录页移除模式切换（登录/注册 tab），改为单一登录面板，UI 升级
