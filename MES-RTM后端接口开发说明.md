# MES-RTM 后端接口开发说明

> 本文档基于当前 `MES-RTM-end` 前端原型与操作逻辑整理，目标是给后端开发提供完整的一期接口清单、字段说明、状态流转和业务校验规则。  ****
> 当前前端可视为产品经理完成的可交互原型，后端需按本文档补齐真实数据、权限、流转事务和接口响应。

## 1. 一期范围与边界

### 1.1 一期需要实现

- 登录、当前用户、角色权限、消息通知。
- 首页驾驶舱、看板中心、生产进度、产线状态、质量趋势只读展示接口。
- 工单管理：查询、新建、释放、暂停、恢复、关闭、详情、导出、打印任务单。
- 批次管理：查询、创建批次、投产、暂停、恢复、锁定、解锁、详情、批次流转记录。
- 上料管理：待上料批次、批次 BOM 上料任务、上料扫码保存、BOM 齐套校验。
- 进站操作：待进站批次、进站上下文、设备绑定、提交进站。
- 出站操作：可出站批次、普通工序出站、SPI/AOI 检测工序出站、强制出站、批次锁定、生成维修任务。
- 维修管理：维修任务列表、提交维修结果、回流待进站或关闭批次。
- 批次跟踪：批次基础信息、工序流转记录、上料记录、维修记录、导出追溯报告。
- 设备监控：设备列表、设备详情、故障提报、保养确认、OEE 查询。

### 1.2 一期暂不实现

- 独立的质量管理模块页面暂不做，包括质量阈值管理、质量拦截管理的完整 CRUD。
- MDM 主数据维护不在 RTM 中实现。产品、BOM、工艺路线、设备、产线、参数模板、用户、角色、功能权限均由 MES-MDM 维护，MES-RTM 只读使用。
- 复杂报表设计器、审批流引擎、电子签名、外部 ERP/PLM 双向同步暂不做。

### 1.3 质量相关说明

虽然独立质量管理模块一期不做，但当前生产闭环必须保留以下质量能力：

- SPI/AOI 出站时按产品阈值判断通过率。
- 低于阈值时允许强制出站或批次锁定。
- 普通工序出站产生不良时可生成维修任务。
- 维修完成后批次回到当前工序待进站，或转报废关闭。

## 2. 统一接口规范

### 2.1 基础路径

```text
Base URL: /api
Content-Type: application/json;charset=UTF-8
Authorization: Bearer <token>
```

### 2.2 统一响应结构

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

分页响应：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

### 2.3 错误码建议


| code | 含义                     |
| ---- | ---------------------- |
| 0    | 成功                     |
| 400  | 参数错误                   |
| 401  | 未登录或 token 失效          |
| 403  | 无权限                    |
| 404  | 资源不存在                  |
| 409  | 状态冲突，如当前状态不允许操作        |
| 422  | 业务校验失败，如 BOM 未齐套、数量不匹配 |
| 500  | 服务端异常                  |


### 2.4 字段命名

- 接口字段建议统一使用 `camelCase`。
- 数据库字段可沿用 `smt_mes.sql` 中的 PascalCase / SQL 命名，由后端进行 DTO 映射。
- 主键同时建议返回业务编号和数据库 ID，例如 `id` / `workOrderId` / `workOrderCode`。

### 2.5 通用审计字段

所有写操作建议落库以下字段：


| 字段           | 类型       | 说明        |
| ------------ | -------- | --------- |
| createdAt    | datetime | 创建时间      |
| createdBy    | string   | 创建人账号或姓名  |
| updatedAt    | datetime | 更新时间      |
| updatedBy    | string   | 更新人账号或姓名  |
| remark       | string   | 操作备注      |
| operatorId   | number   | 操作人 ID，可选 |
| operatorName | string   | 操作人姓名     |


## 3. 角色与权限

### 3.1 RTM 角色


| 角色编码               | 中文角色  | 说明               |
| ------------------ | ----- | ---------------- |
| production_manager | 生产主管  | 工单、批次计划与调度       |
| team_leader        | 班组长   | 生产执行协调、上料、进站、出站  |
| operator           | 操作工   | 上料、进站、出站、追溯查看    |
| quality_engineer   | 质量工程师 | 出站质量判定、批次锁定、维修管理 |
| admin              | 工厂管理层 | 全模块查看与管理         |


### 3.2 权限模块


| 权限编码       | 模块        |
| ---------- | --------- |
| dashboard  | 首页        |
| kanban     | 看板中心      |
| work_order | 工单管理      |
| batch      | 批次管理      |
| loading    | 上料管理      |
| check_in   | 进站操作      |
| check_out  | 出站操作      |
| tracking   | 批次跟踪      |
| repair     | 维修管理      |
| device     | 设备监控      |
| system     | 个人中心、消息通知 |


### 3.3 后端权限校验要求

- 前端按钮隐藏只做体验优化，后端必须基于 token 中的角色和权限重新校验。
- 生产主管可新建/释放/暂停/恢复/关闭工单，可创建/投产/暂停/恢复批次，可强制出站。
- 班组长可执行上料、进站、出站、批次暂停/恢复，不可创建工单，不可强制出站。
- 操作工可执行上料、进站、出站，不可锁定/解锁批次。
- 质量工程师可执行出站质量判定、批次锁定/解锁、维修提交。
- 管理层 admin 默认拥有全部权限。

## 4. 核心枚举

### 4.1 工单状态 workOrderStatus


| 值         | 中文  | 说明                    |
| --------- | --- | --------------------- |
| pending   | 待释放 | 工单已创建，未释放             |
| released  | 已释放 | 工单已通过 BOM、工艺路线、参数模板校验 |
| running   | 生产中 | 已创建批次或已有批次投产          |
| paused    | 暂停  | 工单暂停                  |
| completed | 已完成 | 工单计划数量已完成             |
| closed    | 已关闭 | 工单关闭归档                |


> 原型中存在 `draft/待创建`，但当前页面状态卡已去掉，后端一期不建议作为正式流转状态。

### 4.2 批次状态 batchStatus


| 值         | 中文  | 说明          |
| --------- | --- | ----------- |
| pending   | 待生产 | 批次已创建，未投产   |
| running   | 生产中 | 批次已投产或工序流转中 |
| paused    | 暂停  | 批次暂停        |
| repair    | 维修中 | 出站产生维修任务    |
| locked    | 已锁定 | 质量异常或人工锁定   |
| completed | 已完成 | 批次全部工序完成或关闭 |


### 4.3 工序状态 processStatus


| 值           | 中文  | 说明       |
| ----------- | --- | -------- |
| wait_in     | 待进站 | 当前工序等待进站 |
| checked_in  | 已进站 | 当前工序生产中  |
| checked_out | 已出站 | 当前工序已完成  |
| paused      | 暂停  | 工序暂停     |
| locked      | 锁定  | 工序被质量锁定  |
| skipped     | 跳过  | 特殊跳过     |


### 4.4 出站处置 disposal


| 值      | 中文   | 说明        |
| ------ | ---- | --------- |
| repair | 维修   | 生成维修任务    |
| scrap  | 报废   | 记录报废数量    |
| force  | 强制出站 | 由生产主管强制放行 |


### 4.5 检测工序质量动作 qualityAction


| 值      | 中文   | 说明        |
| ------ | ---- | --------- |
| normal | 正常出站 | 通过率达到阈值   |
| force  | 强制出站 | 低于阈值但强制放行 |
| lock   | 批次锁定 | 低于阈值并锁定批次 |


### 4.6 维修结果 repairResult


| 值           | 中文     | 说明          |
| ----------- | ------ | ----------- |
| repair_pass | 维修合格回流 | 批次回到当前工序待进站 |
| close       | 转报废关闭  | 批次关闭或完成     |


## 5. 核心数据对象字段

### 5.1 WorkOrderDTO


| 字段               | 类型            | 必填  | 说明                    |
| ---------------- | ------------- | --- | --------------------- |
| id               | string        | 是   | 工单号，如 `WO20260512001` |
| workOrderId      | number        | 是   | 数据库主键                 |
| productId        | number        | 是   | 产品 ID                 |
| productModel     | string        | 是   | 产品型号                  |
| productName      | string        | 是   | 产品名称                  |
| routeId          | number/string | 是   | 工艺路线 ID 或编码           |
| routeName        | string        | 是   | 工艺路线名称                |
| planned          | number        | 是   | 计划数量                  |
| completed        | number        | 是   | 已完工数量                 |
| dueDate          | date          | 是   | 交货期                   |
| line             | string        | 是   | 分配产线                  |
| releasedBatches  | number        | 是   | 已释放/已创建批次数            |
| completedBatches | number        | 是   | 已完成批次数                |
| status           | string        | 是   | 工单状态                  |
| creator          | string        | 是   | 创建人                   |
| createdAt        | datetime      | 是   | 创建时间                  |
| releasedAt       | datetime      | 否   | 释放时间                  |
| closedAt         | datetime      | 否   | 关闭时间                  |


### 5.2 BatchDTO


| 字段                 | 类型       | 必填  | 说明                      |
| ------------------ | -------- | --- | ----------------------- |
| id                 | string   | 是   | 批次号，如 `B20260512001-01` |
| lotId              | number   | 是   | 批次数据库主键                 |
| workOrderId        | string   | 是   | 所属工单号                   |
| productModel       | string   | 是   | 产品型号                    |
| productName        | string   | 是   | 产品名称                    |
| line               | string   | 是   | 分配产线                    |
| planned            | number   | 是   | 批次计划数量                  |
| completed          | number   | 是   | 良品或完工数量                 |
| defective          | number   | 是   | 不良数量                    |
| scrap              | number   | 是   | 报废数量                    |
| currentStep        | string   | 是   | 当前工序                    |
| currentRouteStepId | number   | 否   | 当前工艺步骤 ID               |
| eta                | datetime | 否   | 预计完成时间                  |
| onlineAt           | datetime | 否   | 上线时间                    |
| status             | string   | 是   | 批次状态                    |
| lockReason         | string   | 否   | 锁定原因                    |
| owner              | string   | 否   | 负责人                     |
| autoLocked         | boolean  | 是   | 是否系统自动锁定                |


### 5.3 RouteStepDTO


| 字段              | 类型            | 必填  | 说明              |
| --------------- | ------------- | --- | --------------- |
| routeStepId     | number        | 是   | 工艺步骤 ID         |
| sequence        | number        | 是   | 工序顺序            |
| step            | string        | 是   | 工序名称，如印刷、SPI 检测 |
| operationCode   | string        | 否   | 工序编码            |
| deviceType      | string        | 是   | 对应设备类型          |
| equipmentTypeId | number        | 是   | 设备类型 ID         |
| standardTime    | number/string | 否   | 标准工时            |
| isInspection    | boolean       | 是   | 是否 SPI/AOI 检测工序 |


### 5.4 BomItemDTO


| 字段                  | 类型     | 必填  | 说明       |
| ------------------- | ------ | --- | -------- |
| bomItemId           | number | 是   | BOM 行 ID |
| materialId          | number | 是   | 物料 ID    |
| material            | string | 是   | 元件料号     |
| position            | string | 是   | 位号       |
| qty                 | number | 是   | 单板用量     |
| required            | number | 否   | 当前批次应上数量 |
| spec                | string | 否   | 物料规格     |
| packageType         | string | 否   | 封装       |
| substitute          | string | 否   | 替代料规则    |
| substituteMaterials | array  | 否   | 替代料列表    |


### 5.5 LoadingTaskDTO


| 字段           | 类型       | 必填  | 说明                    |
| ------------ | -------- | --- | --------------------- |
| batchId      | string   | 是   | 批次号                   |
| routeStepId  | number   | 否   | 工序步骤 ID，一期首道校验可为空或首工序 |
| station      | string   | 是   | 站位号，如 `F-001`         |
| materialId   | number   | 是   | BOM 主料 ID             |
| material     | string   | 是   | BOM 料号                |
| spec         | string   | 否   | 规格                    |
| packageType  | string   | 否   | 封装                    |
| required     | number   | 是   | 应上数量                  |
| loaded       | number   | 是   | 已上数量                  |
| status       | string   | 是   | `待上料` / `待补料` / `已齐套` |
| substitute   | string   | 否   | 可替代物料                 |
| lastLoadedAt | datetime | 否   | 最近上料时间                |
| operator     | string   | 否   | 最近上料人                 |


### 5.6 ProcessRecordDTO


| 字段              | 类型       | 必填  | 说明          |
| --------------- | -------- | --- | ----------- |
| processRecordId | number   | 是   | 批次工序状态记录 ID |
| batchId         | string   | 是   | 批次号         |
| routeStepId     | number   | 是   | 工艺步骤 ID     |
| step            | string   | 是   | 工序名称        |
| status          | string   | 是   | 工序状态        |
| inAt            | datetime | 否   | 进站时间        |
| outAt           | datetime | 否   | 出站时间        |
| qty             | number   | 是   | 进站数量        |
| goodQty         | number   | 是   | 良品数量        |
| badQty          | number   | 是   | 不良数量        |
| scrapQty        | number   | 是   | 报废数量        |
| deviceId        | string   | 否   | 设备编号        |
| operator        | string   | 否   | 操作人         |
| passRate        | number   | 否   | 检测通过率       |
| threshold       | number   | 否   | 检测阈值        |
| disposal        | string   | 否   | 出站处置        |
| remark          | string   | 否   | 备注          |


### 5.7 RepairTaskDTO


| 字段           | 类型       | 必填  | 说明        |
| ------------ | -------- | --- | --------- |
| repairId     | number   | 是   | 维修任务 ID   |
| batchId      | string   | 是   | 批次号       |
| routeStepId  | number   | 是   | 发生维修的工序步骤 |
| productModel | string   | 是   | 产品型号      |
| line         | string   | 是   | 产线        |
| process      | string   | 是   | 工序        |
| badQty       | number   | 是   | 送修数量      |
| repairedQty  | number   | 否   | 已修复数量     |
| scrapQty     | number   | 否   | 报废数量      |
| defect       | string   | 否   | 不良/故障描述   |
| reason       | string   | 否   | 原因分析      |
| prevention   | string   | 否   | 预防措施      |
| status       | string   | 是   | 待维修 / 已完成 |
| reportedAt   | datetime | 是   | 创建时间      |
| completedAt  | datetime | 否   | 完成时间      |
| handler      | string   | 否   | 处理人       |


## 6. 接口清单

## 6.1 登录与系统接口

### POST `/auth/login`

登录。RTM 不提供注册，用户来源于 MDM 用户管理。

请求：


| 字段        | 类型     | 必填  | 说明           |
| --------- | ------ | --- | ------------ |
| username  | string | 是   | 账号           |
| password  | string | 是   | 密码           |
| subsystem | string | 是   | 固定 `MES-RTM` |


响应 `data`：


| 字段          | 类型     | 说明      |
| ----------- | ------ | ------- |
| token       | string | JWT     |
| userInfo    | object | 当前用户    |
| permissions | array  | 权限编码    |
| homePath    | string | 登录后默认首页 |


### GET `/auth/user-info`

获取当前用户信息。

响应字段：


| 字段          | 类型     | 说明      |
| ----------- | ------ | ------- |
| userId      | number | 用户 ID   |
| username    | string | 账号      |
| name        | string | 姓名      |
| department  | string | 部门      |
| post        | string | 岗位      |
| roles       | array  | 角色编码    |
| permissions | array  | 权限编码    |
| lineCodes   | array  | 可访问产线范围 |


### POST `/auth/change-password`

修改密码。

请求字段：`oldPassword`、`newPassword`、`confirmPassword`。

### GET `/messages`

消息列表。

查询参数：`category`、`unread`、`page`、`pageSize`。

响应字段：`id`、`category`、`title`、`content`、`time`、`unread`、`link`。

### POST `/messages/read-all`

全部标记已读。

### DELETE `/messages/{id}`

删除消息。

### GET `/messages/unread-count`

未读消息数量。

## 6.2 MDM 只读主数据接口

> 这些数据由 MDM 维护，RTM 只读。后端可以直接调用 MDM 服务，也可以在同库中只读查询。

### GET `/mdm/products`

产品列表。

查询参数：`keyword`、`productTypeId`、`status`。

响应字段：`productId`、`productCode`、`productName`、`model`、`version`、`spiThreshold`、`aoiThreshold`、`defaultRouteId`。

### GET `/mdm/products/{productId}/bom`

产品 BOM。

响应字段：`bomId`、`version`、`items: BomItemDTO[]`。

### GET `/mdm/products/{productId}/routes`

产品可用工艺路线。

响应字段：`routeId`、`routeCode`、`routeName`、`lineCode`、`steps: RouteStepDTO[]`。

### GET `/mdm/routes/{routeId}`

工艺路线详情。

### GET `/mdm/lines`

产线列表。

响应字段：`lineId`、`lineCode`、`lineName`、`workshop`、`status`。

### GET `/mdm/devices`

设备列表。

查询参数：`lineCode`、`equipmentTypeId`、`status`。

响应字段：`equipmentId`、`equipmentCode`、`equipmentName`、`equipmentTypeId`、`equipmentTypeName`、`lineCode`、`status`。

### GET `/mdm/devices/available`

当前工序可用设备。

查询参数：


| 字段          | 类型     | 必填  | 说明     |
| ----------- | ------ | --- | ------ |
| lineCode    | string | 是   | 产线     |
| routeStepId | number | 是   | 当前工序步骤 |
| batchId     | string | 否   | 批次号    |


返回只包含同产线、设备类型匹配、非故障/离线设备。

## 6.3 首页与看板接口

### GET `/dashboard`

首页总览。

查询参数：`workshop`、`lineCode`、`dateStart`、`dateEnd`。

响应 `data`：


| 字段                       | 类型     | 说明             |
| ------------------------ | ------ | -------------- |
| metrics.totalOrders      | number | 当日工单总数         |
| metrics.inProcessBatches | number | 在制批次数          |
| metrics.firstPassYield   | number | 整体直通率          |
| metrics.planCompletion   | number | 计划完成率          |
| lines                    | array  | 产线状态卡片         |
| alerts                   | array  | 异常告警           |
| productionProgress       | array  | 工单完成率排行        |
| qualityTrend             | array  | SPI/AOI/批次良率趋势 |


### GET `/dashboard/line-status`

产线状态总览。

响应字段：`lineCode`、`lineName`、`workOrderId`、`batchId`、`productModel`、`planned`、`completed`、`status`、`devices`、`oee`、`dueTime`、`alerts`。

### GET `/dashboard/alerts`

异常告警列表。

查询参数：`level`、`type`、`handled`、`page`、`pageSize`。

响应字段：`id`、`level`、`type`、`title`、`target`、`time`、`handled`。

### GET `/dashboard/production-progress`

生产进度看板。

响应字段：`workOrderId`、`planned`、`completed`、`completionRate`、`dueDate`、`status`。

### GET `/dashboard/quality-trend`

质量趋势。

查询参数：`lineCode`、`dateStart`、`dateEnd`。

响应字段：`time`、`spi`、`aoi`、`batchYield`。

## 6.4 工单管理接口

### GET `/work-orders`

工单分页查询。

查询参数：


| 字段           | 类型     | 说明     |
| ------------ | ------ | ------ |
| keyword      | string | 工单号关键字 |
| productModel | string | 产品型号   |
| status       | string | 工单状态   |
| lineCode     | string | 产线     |
| dueStart     | date   | 交货期开始  |
| dueEnd       | date   | 交货期结束  |
| page         | number | 页码     |
| pageSize     | number | 每页数量   |


响应：分页 `WorkOrderDTO[]`。

### GET `/work-orders/{id}`

工单详情。

响应 `data`：


| 字段             | 类型           | 说明       |
| -------------- | ------------ | -------- |
| workOrder      | WorkOrderDTO | 工单基础信息   |
| bom            | BomItemDTO[] | 产品 BOM   |
| route          | object       | 工艺路线与工序  |
| batches        | BatchDTO[]   | 工单下批次    |
| processSummary | array        | 工序完成数量图表 |


### POST `/work-orders`

新建工单。

请求：


| 字段              | 类型     | 必填  | 说明        |
| --------------- | ------ | --- | --------- |
| productId       | number | 是   | 产品 ID     |
| routeId         | number | 是   | 工艺路线 ID   |
| plannedQuantity | number | 是   | 计划数量，大于 0 |
| dueDate         | date   | 是   | 交货期       |
| lineCode        | string | 是   | 分配产线      |
| remark          | string | 否   | 备注        |


后端规则：

- 校验产品存在且启用。
- 校验工艺路线存在且启用。
- 校验产品 BOM 存在且启用。
- 校验计划数量大于 0。
- 创建后状态为 `pending`。

### POST `/work-orders/{id}/release`

释放工单。

请求字段：`remark`。

后端规则：

- 仅 `pending` 状态允许释放。
- 校验产品、BOM、工艺路线、工序、设备类型、参数模板完整。
- 释放成功后状态为 `released`，写入 `releasedAt`。

### POST `/work-orders/{id}/pause`

暂停工单。

请求字段：`reason`。

允许状态：`running`。

### POST `/work-orders/{id}/resume`

恢复工单。

请求字段：`reason` 可选。

允许状态：`paused`，恢复后为 `running`。

### POST `/work-orders/{id}/close`

关闭工单。

请求字段：`reason` 可选。

允许状态：`completed`，关闭后为 `closed`。

### GET `/work-orders/export`

导出当前筛选条件下的工单 Excel。

查询参数同 `/work-orders`。

### GET `/work-orders/{id}/print-task`

打印生产任务单，返回 PDF/HTML/文件地址。

## 6.5 批次管理接口

### GET `/batches`

批次分页查询。

查询参数：


| 字段           | 类型     | 说明   |
| ------------ | ------ | ---- |
| keyword      | string | 批次号  |
| workOrderId  | string | 工单号  |
| productModel | string | 产品型号 |
| status       | string | 批次状态 |
| lineCode     | string | 产线   |
| page         | number | 页码   |
| pageSize     | number | 每页数量 |


响应：分页 `BatchDTO[]`。

### GET `/batches/creatable-work-orders`

新建批次弹窗中可选择的工单。

返回规则：

- 工单状态为 `released` 或 `running`。
- 工单剩余数量大于 0。
- 当前原型规则为一个工单创建一组批次后不再重复创建；后端可按 `plannedQuantity - 已创建批次数量合计` 判断是否可创建。

响应字段：`workOrderId`、`productModel`、`productName`、`planned`、`completed`、`remainingQty`、`routeId`、`routeName`、`lineCode`。

### POST `/batches`

创建批次。

请求：

```json
{
  "workOrderId": "WO20260512001",
  "owner": "张工",
  "batches": [
    {
      "batchCode": "B20260512001-01",
      "plannedQuantity": 600,
      "lineCode": "SMT-A1"
    }
  ]
}
```

后端规则：

- 只有生产主管可操作。
- 批次计划数量合计不能超过工单剩余数量。
- 每个批次必须有产线。
- 批次创建后状态为 `pending`，当前工序为 `-`。
- 工单状态可更新为 `running`，并更新已创建批次数。

### GET `/batches/{id}`

批次详情。

响应：


| 字段           | 类型                 | 说明     |
| ------------ | ------------------ | ------ |
| batch        | BatchDTO           | 批次基础信息 |
| workOrder    | WorkOrderDTO       | 所属工单   |
| route        | object             | 工艺路线   |
| processes    | ProcessRecordDTO[] | 工序流转记录 |
| loadingTasks | LoadingTaskDTO[]   | 上料任务   |
| trace        | array              | 追溯记录   |


### POST `/batches/{id}/start`

批次投产。

后端规则：

- 只有生产主管可操作。
- 仅 `pending` 批次可投产。
- 投产后批次状态为 `running`。
- 根据工单路线创建首道工序 `wait_in` 记录。
- 创建批次追溯记录。

响应字段：`batch`、`currentProcess`。

### POST `/batches/{id}/lock`

人工锁定批次。

请求字段：`reason`。

权限：质量工程师、生产主管。

### POST `/batches/{id}/unlock`

解锁批次。

请求字段：`reason`。

规则：

- 人工锁定可由质量工程师或生产主管解锁。
- 系统自动锁定建议仅质量工程师完成异常处置后解锁。

### POST `/batches/{id}/pause`

暂停批次。

请求字段：`reason`。

权限：生产主管、班组长。

### POST `/batches/{id}/resume`

恢复批次。

请求字段：`reason` 可选。

权限：生产主管、班组长。

### POST `/batches/bulk-pause`

批量暂停。

请求字段：`batchIds`、`reason`。

### POST `/batches/bulk-resume`

批量恢复。

请求字段：`batchIds`、`reason`。

### GET `/batches/{id}/trace`

批次追溯记录。

响应字段：


| 字段       | 类型       | 说明                                                    |
| -------- | -------- | ----------------------------------------------------- |
| id       | string   | 记录 ID                                                 |
| time     | datetime | 发生时间                                                  |
| type     | string   | status/checkin/checkout/loading/repair/quality/device |
| step     | string   | 工序                                                    |
| qty      | number   | 数量                                                    |
| deviceId | string   | 设备                                                    |
| operator | string   | 操作人                                                   |
| message  | string   | 描述                                                    |


## 6.6 上料管理接口

### GET `/execution/loading-batches`

待上料批次列表。

查询参数：`lineCode`、`batchId`。

返回规则：

- 批次已投产。
- 当前工序为 `wait_in`。
- 一期按“首道进站前做整批 BOM 齐套校验”处理，后续工序不重复整批上料，除非后续扩展工序级物料需求。

响应字段：`batchId`、`workOrderId`、`productModel`、`lineCode`、`currentStep`、`loadingPercentage`、`validationStatus`。

### GET `/execution/loading-tasks`

批次上料清单。

查询参数：


| 字段          | 类型     | 必填  | 说明        |
| ----------- | ------ | --- | --------- |
| batchId     | string | 是   | 批次号       |
| routeStepId | number | 否   | 一期可为空或首工序 |


响应：`LoadingTaskDTO[]`。

### POST `/execution/loading-records`

保存上料扫码记录。

请求：


| 字段           | 类型       | 必填  | 说明             |
| ------------ | -------- | --- | -------------- |
| batchId      | string   | 是   | 批次号            |
| routeStepId  | number   | 否   | 一期可为空或首工序      |
| station      | string   | 是   | 站位号            |
| materialCode | string   | 是   | 扫描物料条码或料号      |
| loadedQty    | number   | 是   | 本次上料数量         |
| operator     | string   | 是   | 操作人            |
| loadedAt     | datetime | 否   | 上料时间，默认服务端当前时间 |


后端校验：

- 批次存在且未锁定。
- 站位存在。
- 物料条码必须匹配 BOM 主料或允许替代料。
- 上料数量大于 0。
- 已上数量不能超过应上数量，超出部分可截断或报错，建议报错。
- 齐套后清除该批次补料请求。

响应字段：`task`、`summary`、`validation`。

### POST `/execution/verify-loading`

BOM 齐套校验。

请求字段：`batchId`、`routeStepId` 可选。

响应：


| 字段         | 类型               | 说明    |
| ---------- | ---------------- | ----- |
| pass       | boolean          | 是否齐套  |
| total      | number           | 上料项总数 |
| finished   | number           | 已齐套项数 |
| percentage | number           | 完成率   |
| missing    | LoadingTaskDTO[] | 未齐套项  |
| message    | string           | 提示信息  |


### POST `/execution/loading-request`

进站校验发现未齐套时生成补料请求。

请求字段：`batchId`、`reason`。

响应字段：`requestId`、`batchId`、`reason`、`requestedAt`、`status`。

## 6.7 进站操作接口

### GET `/execution/check-in/batches`

待进站批次列表。

返回规则：

- 当前工序状态为 `wait_in`。
- 批次状态为 `pending` 或 `running`。
- 批次不能为 `locked`、`paused`、`repair`、`completed`。

响应字段：`batchId`、`workOrderId`、`productModel`、`lineCode`、`currentStep`、`pendingQty`、`processStatus`。

### GET `/execution/check-in/context`

进站上下文。

查询参数：`batchId`。

响应字段：


| 字段                | 类型               | 说明         |
| ----------------- | ---------------- | ---------- |
| batch             | BatchDTO         | 当前批次       |
| currentProcess    | ProcessRecordDTO | 当前工序       |
| previousStep      | string           | 上一工序       |
| processCompliance | object           | 是否满足进站流转条件 |
| availableDevices  | array            | 可用设备       |
| loadingSummary    | object           | 上料完成率      |
| loadingValidation | object           | 齐套校验结果     |


### POST `/execution/check-in`

提交进站。

请求：


| 字段          | 类型            | 必填  | 说明        |
| ----------- | ------------- | --- | --------- |
| batchId     | string        | 是   | 批次号       |
| routeStepId | number        | 是   | 当前工序步骤 ID |
| deviceId    | string/number | 是   | 设备编号或 ID  |
| qty         | number        | 是   | 进站数量      |
| operator    | string        | 是   | 操作人       |
| remark      | string        | 否   | 备注        |
| inAt        | datetime      | 否   | 进站时间      |


后端校验：

- 批次存在。
- 批次未锁定、未暂停、未维修中。
- 当前工序状态为 `wait_in`。
- 如果不是首道工序，上一工序必须已出站。
- 设备必须属于当前产线，且设备类型匹配当前工序要求，状态不能为故障/离线。
- 首道进站前必须通过 BOM 齐套校验。
- 进站数量必须大于 0，且不能超过待进站数量。

成功后：

- 当前工序状态更新为 `checked_in`。
- 写入进站记录。
- 批次状态更新为 `running`。
- 写入追溯记录。

## 6.8 出站操作接口

### GET `/execution/check-out/batches`

可出站批次列表。

返回规则：

- 当前工序状态为 `checked_in`。

响应字段：`batchId`、`workOrderId`、`productModel`、`currentStep`、`currentInQty`、`completed`、`defective`、`status`。

### GET `/execution/check-out/context`

出站上下文。

查询参数：`batchId`。

响应字段：


| 字段                  | 类型               | 说明          |
| ------------------- | ---------------- | ----------- |
| batch               | BatchDTO         | 批次          |
| currentProcess      | ProcessRecordDTO | 当前工序        |
| currentInQty        | number           | 当前进站数量      |
| isInspection        | boolean          | 是否检测工序      |
| inspectionType      | string           | SPI/AOI     |
| inspectionThreshold | number           | 阈值          |
| canForce            | boolean          | 当前用户是否可强制出站 |


### POST `/execution/check-out`

提交出站。

普通工序请求：


| 字段          | 类型       | 必填   | 说明                      |
| ----------- | -------- | ---- | ----------------------- |
| batchId     | string   | 是    | 批次号                     |
| routeStepId | number   | 是    | 当前工序步骤 ID               |
| goodQty     | number   | 是    | 良品数量                    |
| badQty      | number   | 是    | 不良数量                    |
| scrapQty    | number   | 是    | 报废数量                    |
| disposal    | string   | 否    | 不良处置 repair/scrap/force |
| forceReason | string   | 条件必填 | 强制出站原因                  |
| operator    | string   | 是    | 操作人                     |
| remark      | string   | 否    | 备注                      |
| outAt       | datetime | 否    | 出站时间                    |


检测工序请求：


| 字段            | 类型       | 必填   | 说明                |
| ------------- | -------- | ---- | ----------------- |
| batchId       | string   | 是    | 批次号               |
| routeStepId   | number   | 是    | 当前工序步骤 ID         |
| passRate      | number   | 是    | 检测通过率             |
| qualityAction | string   | 是    | normal/force/lock |
| forceReason   | string   | 条件必填 | 强制或锁定原因           |
| operator      | string   | 是    | 操作人               |
| remark        | string   | 否    | 备注                |
| outAt         | datetime | 否    | 出站时间              |


后端校验：

- 当前工序必须为 `checked_in`。
- 批次不能为 `locked`。
- 普通工序：`goodQty + badQty + scrapQty` 必须等于当前进站数量。
- 普通工序：`disposal=force` 必须生产主管权限，且必须填写原因。
- 普通工序：`badQty > 0 && disposal=repair` 时生成维修任务，批次状态变为 `repair`。
- 检测工序：`passRate >= threshold` 时只能正常出站。
- 检测工序：`passRate < threshold` 时必须选择 `force` 或 `lock`。
- 检测工序：`force` 必须生产主管权限，且必须填写原因。
- 检测工序：`lock` 后批次状态变为 `locked`，写入锁定原因。

成功后：

- 当前工序更新为 `checked_out`，写入出站记录。
- 如果存在下一工序，创建下一工序 `wait_in` 记录，并设置待进站数量。
- 如果无下一工序，批次状态更新为 `completed`。
- 更新批次良品、不良、报废数量。
- 写入追溯记录。

响应字段：


| 字段         | 类型            | 说明                              |
| ---------- | ------------- | ------------------------------- |
| batch      | BatchDTO      | 更新后的批次                          |
| nextStep   | string        | 下一工序，完成时为空                      |
| status     | string        | wait_in/repair/locked/completed |
| repairTask | RepairTaskDTO | 生成维修任务时返回                       |


## 6.9 维修管理接口

### GET `/repairs`

维修任务列表。

查询参数：`batchId`、`productModel`、`lineCode`、`status`、`page`、`pageSize`。

响应：分页 `RepairTaskDTO[]`。

### POST `/repairs/{id}/submit`

提交维修结果。

请求：


| 字段          | 类型       | 必填  | 说明                |
| ----------- | -------- | --- | ----------------- |
| result      | string   | 是   | repair_pass/close |
| repairQty   | number   | 是   | 维修合格数量            |
| scrapQty    | number   | 是   | 报废数量              |
| reason      | string   | 否   | 原因分析              |
| prevention  | string   | 否   | 预防措施              |
| handler     | string   | 是   | 处理人               |
| completedAt | datetime | 否   | 完成时间              |


后端规则：

- 只有质量工程师可提交。
- `repairQty + scrapQty` 不能超过送修数量。
- `repair_pass`：维修任务完成，批次状态回到 `running`，当前工序回到 `wait_in`，待进站数量为 `repairQty`。
- `close`：维修任务完成，批次增加报废数量，批次状态变为 `completed` 或关闭状态。
- 写入追溯记录。

### POST `/repairs/{id}/accept`

接单，可选接口。请求字段：`handler`。

### POST `/repairs/{id}/scrap`

确认报废，可选接口。请求字段：`scrapQty`、`reason`、`handler`。

## 6.10 批次跟踪接口

### GET `/tracking/batches`

追溯页批次搜索。

查询参数：`keyword`、`workOrderId`、`productModel`、`status`、`page`、`pageSize`。

### GET `/tracking/batches/{id}`

批次追溯详情。

响应：


| 字段             | 类型                 | 说明     |
| -------------- | ------------------ | ------ |
| batch          | BatchDTO           | 批次基础信息 |
| workOrder      | WorkOrderDTO       | 工单     |
| processes      | ProcessRecordDTO[] | 工序记录   |
| loadingRecords | array              | 上料记录   |
| repairRecords  | RepairTaskDTO[]    | 维修记录   |
| trace          | array              | 事件时间线  |


### GET `/tracking/batches/{id}/export`

导出追溯报告。

返回文件地址或文件流。

## 6.11 设备监控接口

### GET `/devices`

设备列表。

查询参数：


| 字段       | 类型     | 说明      |
| -------- | ------ | ------- |
| keyword  | string | 设备编号/名称 |
| lineCode | string | 产线      |
| type     | string | 设备类型    |
| status   | string | 设备状态    |
| page     | number | 页码      |
| pageSize | number | 每页数量    |


响应字段：


| 字段          | 类型            | 说明                                        |
| ----------- | ------------- | ----------------------------------------- |
| id          | string        | 设备编号                                      |
| equipmentId | number        | 设备 ID                                     |
| name        | string        | 设备名称                                      |
| type        | string        | 设备类型                                      |
| line        | string        | 产线                                        |
| status      | string        | running/standby/fault/maintenance/offline |
| batch       | string        | 当前批次                                      |
| duration    | string        | 运行时长                                      |
| oee         | number        | OEE                                       |
| output      | number        | 当日产量                                      |
| throwRate   | string/number | 抛料率                                       |
| fault       | string        | 故障描述                                      |


### GET `/devices/{id}`

设备详情。

### POST `/devices/{id}/fault`

故障提报。

请求字段：`faultType`、`faultDescription`、`operator`、`occurredAt`。

成功后设备状态变为 `fault`，并生成告警。

### POST `/devices/{id}/maintenance`

保养确认。

请求字段：`maintenanceItem`、`operator`、`remark`、`completedAt`。

### GET `/devices/{id}/oee`

设备 OEE 趋势。

查询参数：`dateStart`、`dateEnd`、`granularity`。

## 6.12 导出、打印与文件接口

### GET `/exports/work-orders`

工单导出。

查询参数同 `/work-orders`。

### GET `/exports/batches`

批次导出。

查询参数同 `/batches`。

### GET `/exports/trace/{batchId}`

批次追溯报告导出。

### GET `/prints/work-orders/{id}/task-sheet`

生产任务单打印。

返回：


| 字段       | 类型     | 说明     |
| -------- | ------ | ------ |
| fileUrl  | string | 文件访问地址 |
| fileName | string | 文件名    |


## 7. 关键业务流转

### 7.1 工单到批次

1. 生产主管创建工单，状态为 `pending`。
2. 生产主管释放工单，后端校验 BOM、工艺路线、参数模板完整，状态变为 `released`。
3. 生产主管按工单剩余数量拆分批次，批次状态为 `pending`。
4. 批次创建后工单进入 `running` 或保持 `released`，建议以“是否已有在制批次”决定；当前原型创建批次后将工单置为 `running`。

### 7.2 批次投产到首道进站

1. 生产主管对 `pending` 批次执行投产。
2. 后端根据工艺路线创建首道工序记录，状态 `wait_in`。
3. 批次状态变为 `running`。
4. 上料管理根据批次 BOM 生成上料任务。
5. 首道进站前必须完成 BOM 齐套校验。

### 7.3 上料校验

1. 操作工/班组长扫描站位与物料条码。
2. 后端校验物料是否为 BOM 主料或允许替代料。
3. 记录本次上料数量、物料条码、操作人、时间。
4. 所有站位齐套后，进站校验通过。

一期建议：只在首道进站前做整批 BOM 齐套校验。后续如果每道工序有独立物料需求，再增加 `routeStepId + requiredMaterials` 的工序级 BOM 校验。

### 7.4 进站

1. 当前工序必须是 `wait_in`。
2. 上一工序必须已完成；首道工序无上一工序。
3. 设备必须匹配当前工序设备类型，且属于当前产线。
4. 首道进站必须通过 BOM 齐套校验。
5. 提交后当前工序变为 `checked_in`。

### 7.5 出站

普通工序：

1. 当前工序必须是 `checked_in`。
2. 校验 `良品 + 不良 + 报废 = 进站数量`。
3. 有不良且选择维修时生成维修任务，批次状态变为 `repair`。
4. 无维修时流转至下一工序 `wait_in`，或批次完成。

SPI/AOI 检测工序：

1. 根据产品的 `spiThreshold` / `aoiThreshold` 判断通过率。
2. 达标则正常出站。
3. 不达标时必须选择强制出站或批次锁定。
4. 强制出站必须生产主管权限。
5. 锁定后批次状态为 `locked`，等待质量工程师处理。

### 7.6 维修回流

1. 出站不良选择维修后生成维修任务。
2. 质量工程师提交维修结果。
3. 维修合格回流：批次回到当前工序 `wait_in`，待进站数量为维修合格数量。
4. 转报废关闭：批次状态更新为 `completed`，记录报废数量。

## 8. 数据库表映射建议

可优先复用 `smt_mes.sql` 中已有表：


| 业务对象   | 建议表                                                                 |
| ------ | ------------------------------------------------------------------- |
| 产品     | smt_products                                                        |
| BOM    | smt_bom、smt_bom_items                                               |
| 物料     | smt_materials、smt_material_substitutes                              |
| 工艺路线   | smt_routes、smt_route_steps、smt_operations                           |
| 设备     | smt_equipment、smt_equipment_types                                   |
| 产线     | smt_lines                                                           |
| 用户权限   | smt_users、smt_roles、smt_functions、smt_user_roles、smt_role_functions |
| 工单     | smt_work_orders                                                     |
| 批次     | smt_lots                                                            |
| 批次工序状态 | smt_lot_operation_status                                            |
| 进站记录   | smt_station_in_records                                              |
| 出站记录   | smt_station_out_records                                             |
| 上料记录   | smt_loading_records                                                 |
| 维修记录   | smt_repair_records                                                  |


建议新增或补充的表：


| 表                              | 说明                         |
| ------------------------------ | -------------------------- |
| rtm_batch_trace_events         | 批次追溯事件时间线，便于前端直接展示         |
| rtm_messages                   | 站内消息通知                     |
| rtm_alerts                     | 异常告警                       |
| rtm_loading_requirements       | 批次级上料需求快照，避免 BOM 变更影响已投产批次 |
| rtm_loading_requests           | 补料请求                       |
| rtm_device_fault_records       | 设备故障记录                     |
| rtm_device_maintenance_records | 设备保养记录                     |


## 9. 事务与一致性要求

以下接口必须使用数据库事务：

- 新建工单。
- 释放工单。
- 创建批次。
- 批次投产。
- 批次锁定/解锁/暂停/恢复。
- 上料保存。
- 进站。
- 出站。
- 维修提交。

关键一致性：

- 批次状态、当前工序状态、进站记录、出站记录、追溯事件必须同步写入。
- 出站生成维修任务时，批次状态必须同步变为 `repair`。
- 检测低于阈值锁定时，批次状态、工序状态、锁定原因、告警、消息必须同步写入。
- 工单完成数量建议由批次完工汇总计算，避免前端手工传入。

## 10. 实时刷新与事件推送

前端当前默认 30s 自动刷新，但关键事件建议支持 WebSocket 或 SSE。

建议接口：

```text
GET /rtm/events/stream
```

事件类型：


| type                      | 说明     |
| ------------------------- | ------ |
| work_order.status_changed | 工单状态变化 |
| batch.status_changed      | 批次状态变化 |
| process.checked_in        | 进站     |
| process.checked_out       | 出站     |
| loading.updated           | 上料更新   |
| repair.created            | 维修任务生成 |
| repair.completed          | 维修完成   |
| alert.created             | 告警生成   |
| device.status_changed     | 设备状态变化 |
| message.unread_changed    | 未读消息变化 |


## 11. 后端开发优先级

### P0 必须完成

- 登录、用户信息、权限校验。
- MDM 只读产品、BOM、工艺路线、产线、设备查询。
- 工单列表/详情/新建/释放。
- 批次列表/详情/创建/投产。
- 上料任务/上料保存/齐套校验。
- 进站/出站完整流转。
- 维修任务列表/提交维修结果。
- 批次追溯。

### P1 应完成

- 首页和看板真实数据聚合。
- 设备故障提报、保养确认。
- 消息通知、告警列表。
- 导出和打印接口。
- 批量暂停/恢复。

### P2 可后续增强

- WebSocket/SSE 实时推送。
- 复杂质量拦截管理。
- 工序级 BOM 上料校验。
- 外部系统集成。
- 更细粒度的数据权限配置。

## 12. 联调验收要点

- 生产主管创建工单后，工单应为 `pending`。
- 工单释放前缺 BOM、缺路线、缺参数模板时必须拦截。
- 创建批次时批次数量合计不能超过工单剩余数量。
- 批次投产后必须生成首道工序 `wait_in`。
- 首道进站前 BOM 未齐套必须拦截，并生成补料请求。
- 上料物料必须匹配 BOM 主料或替代料。
- 进站后工序变为 `checked_in`，出站页能看到该批次。
- 普通工序出站数量必须满足进站数量等式。
- SPI/AOI 低于阈值时不能直接正常出站。
- 低于阈值锁定时批次必须变为 `locked`。
- 出站不良选择维修时必须生成维修任务。
- 维修合格后批次回到当前工序 `wait_in`。
- 批次完成后状态必须为 `completed`，并能在追溯中看到完整事件链。

