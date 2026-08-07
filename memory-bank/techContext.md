---
name: tech-context
description: 技术栈、依赖、环境配置
metadata:
  type: project
---

**技术栈**

| 类型 | 技术 |
| --- | --- |
| 前端框架 | Vue 3 |
| 构建工具 | Vite 8 |
| UI 组件 | Element Plus 2.14 |
| 状态管理 | Pinia 3 |
| 路由 | Vue Router 5 |
| 图表 | ECharts 6 + vue-echarts 8 |
| 请求 | Axios |
| 样式 | SCSS |

**运行环境**

- Node.js ^20.19.0 或 >=22.12.0
- 包管理器：npm（项目中同时有 pnpm-lock.yaml，但当前使用 npm 开发）
- 开发端口：3000（vite.config.js 配置）

**包管理**

- `package.json` + `package-lock.json` — 主依赖
- `pnpm-lock.yaml` — 历史遗留，可忽略

**Why:** 统一使用 npm 避免 lock 文件冲突，保持构建环境一致。
**How to apply:** 安装依赖用 `npm install`，不要用 pnpm，防止 lock 文件不一致。
