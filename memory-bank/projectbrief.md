---
name: project-brief
description: MES-RTM 实时制造执行系统前端的整体概述和核心目标
metadata:
  type: project
---

MES-RTM 是面向 SMT 产线的实时制造执行子系统**前端原型**，作为产品原型和前后端联调基础。

**核心功能模块**

- **Dashboard** — 数据概览看板
- **Kanban** — 生产看板展示
- **WorkOrder** — 工单调度（视图：WorkOrderView）
- **Production** — 批次投产、进站、出站、执行记录（视图：BatchDetailView、ExecutionView）
- **MaterialLot** — 上料齐套管理
- **Unloading** — 退料管理
- **Quality** — 质量巡检/检验
- **Device** — 设备监控
- **System** — 系统管理（用户、角色等）

**数据来源**：静态主数据只读来自 MES-MDM，动态业务数据由 RTM 自身产生。

**Why:** 作为产品原型 + 前后端联调基础，UI 迭代快，需求文档驱动开发。
**How to apply:** 修改视图组件时注意保持与后端 API 契约一致，新增功能前先确认 API 是否已就绪。
