# MES-RTM 待完善清单

本文档基于当前项目代码与现有业务逻辑整理，目的不是重新定义需求，而是把“已经明确但还没做完”的内容拆成可执行清单，方便后续逐项推进。

## 一、高优先级

这一部分直接影响项目主流程是否真正闭环，建议优先处理。

### 1. 批次进站后要真实流转

当前进站页面已经有批次选择、设备选择、物料校验和提交入口，但还需要补成真正的业务动作：

- 提交进站后，批次状态从`待进站`改为`生产中`
- 记录本次进站信息：
  - 批次
  - 当前工序
  - 设备
  - 进站数量
  - 操作人
  - 进站时间
- 将本次进站记录写入批次跟踪
- 批次详情页同步展示本次进站数据

涉及页面 / 文件：

- [src/views/execution/CheckInView.vue](./src/views/execution/CheckInView.vue)
- [src/views/production/BatchDetailView.vue](./src/views/production/BatchDetailView.vue)
- [src/views/execution/TrackingView.vue](./src/views/execution/TrackingView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

### 2. 批次出站后要自动推进到下一工序

这是当前最关键的缺口。

需要补的逻辑：

- 提交出站后，当前工序形成完整出站记录
- 系统根据该批次所属工艺路线找到下一道工序
- 如果存在下一工序：
  - 批次当前工序切换到下一工序
  - 批次状态改为`待进站`
- 如果当前已经是最后一道工序：
  - 批次状态改为`已完成`
- 所有结果同步写入批次详情和批次跟踪

涉及页面 / 文件：

- [src/views/execution/CheckOutView.vue](./src/views/execution/CheckOutView.vue)
- [src/views/production/BatchDetailView.vue](./src/views/production/BatchDetailView.vue)
- [src/views/execution/TrackingView.vue](./src/views/execution/TrackingView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

### 3. 统一进站 / 出站数量规则

这一块不统一，后面所有统计都会乱。

建议固定规则：

- `进站数量 = 完工良品数量 + 不良数量 + 报废数量`

需要补的内容：

- 出站页前端校验数量关系
- 不允许录入相互矛盾的数据
- 批次跟踪中记录每次数量变化
- 批次详情中的产出汇总口径与出站口径一致

涉及页面 / 文件：

- [src/views/execution/CheckOutView.vue](./src/views/execution/CheckOutView.vue)
- [src/views/production/BatchDetailView.vue](./src/views/production/BatchDetailView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

### 4. 维修管理要形成闭环

当前维修页面已经存在，但业务闭环还不完整。

需要补：

- 出站时选择`维修`后，自动生成维修任务
- 维修任务要带出：
  - 批次号
  - 工单号
  - 工序
  - 不良数量
  - 不良原因
  - 提交时间
- 在维修管理中处理维修结果：
  - 修复回流
  - 转报废
  - 关闭处理
- 明确维修完成后如何影响批次数量和状态

涉及页面 / 文件：

- [src/views/execution/CheckOutView.vue](./src/views/execution/CheckOutView.vue)
- [src/views/execution/RepairView.vue](./src/views/execution/RepairView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

### 5. 批次跟踪要补成完整追溯页

当前批次跟踪更接近简化展示，后续建议补成真正追溯页。

至少应包含：

- 批次基本信息
- 工序流转时间线
- 每道工序的进站记录
- 每道工序的出站记录
- 上料记录
- 不良 / 报废 / 维修记录
- 状态变化日志

涉及页面 / 文件：

- [src/views/execution/TrackingView.vue](./src/views/execution/TrackingView.vue)
- [src/views/production/BatchDetailView.vue](./src/views/production/BatchDetailView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

## 二、中优先级

这一部分主要影响业务严谨性和页面协同一致性。

### 6. 上料管理与工序 BOM 绑定再做细

当前上料管理方向已经对了，但还可以继续做严谨：

- 每个批次应基于“当前工序”加载对应 BOM
- 不同工序不应共用同一套默认上料清单
- 补料记录应按批次 + 工序维度保留
- 进站物料校验结果应明确指出：
  - 缺什么料
  - 缺多少
  - 哪个站位未完成

涉及页面 / 文件：

- [src/views/execution/LoadingView.vue](./src/views/execution/LoadingView.vue)
- [src/views/execution/CheckInView.vue](./src/views/execution/CheckInView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

### 7. 工单与批次关系再收紧

当前逻辑基本成立，但还可以更清晰：

- 只有已释放工单才允许进入批次创建池
- 一个工单拆分后的批次数量总和不能超过工单计划数量
- 工单完成条件应明确为：
  - 所有批次全部完成后，工单才可完成
- 工单详情页应更明确展示：
  - 已拆分数量
  - 剩余可拆分数量
  - 已完成批次数

涉及页面 / 文件：

- [src/views/production/WorkOrderView.vue](./src/views/production/WorkOrderView.vue)
- [src/views/production/WorkOrderDetailView.vue](./src/views/production/WorkOrderDetailView.vue)
- [src/views/production/BatchView.vue](./src/views/production/BatchView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

### 8. 状态展示要统一

现在状态已经不少了，后续要保证所有页面口径一致。

建议统一：

- 工单状态文案
- 批次状态文案
- 状态颜色
- 顶部统计卡片口径
- 操作按钮启用 / 禁用条件

涉及页面 / 文件：

- [src/utils/constants.js](./src/utils/constants.js)
- [src/views/production/BatchView.vue](./src/views/production/BatchView.vue)
- [src/views/execution/CheckInView.vue](./src/views/execution/CheckInView.vue)
- [src/views/execution/CheckOutView.vue](./src/views/execution/CheckOutView.vue)
- [src/views/production/BatchDetailView.vue](./src/views/production/BatchDetailView.vue)

### 9. 批次详情页信息还可以补全

当前批次详情已经有基础内容，但建议进一步补强：

- 当前批次所处工序
- 当前工序对应设备
- 当前工序最近一次进站 / 出站信息
- 工序级数量汇总
- 最近一次上料结果
- 最近一次异常处理结果

涉及页面 / 文件：

- [src/views/production/BatchDetailView.vue](./src/views/production/BatchDetailView.vue)
- [src/utils/mockData.js](./src/utils/mockData.js)

## 三、低优先级

这一部分主要影响“更像真实系统”和“后续可扩展性”。

### 10. 把关键业务动作收口成统一数据方法

当前很多页面直接改 mock 数据。后续建议把核心动作收口成统一方法，例如：

- 创建批次
- 投产批次
- 保存上料
- 提交进站
- 提交出站
- 生成维修任务
- 完成维修任务

这样可以减少页面各改各的数据，后面接真实接口也更容易。

建议集中在：

- [src/utils/mockData.js](./src/utils/mockData.js)
- 或新增业务工具文件，例如`src/utils/workflow.js`

### 11. mock 数据结构进一步规范

当前 mock 数据能支撑演示，但后续如果要持续改功能，建议把结构拆得更清晰：

- 批次主数据
- 批次工序实例数据
- 进站记录
- 出站记录
- 上料记录
- 维修记录
- 状态变更日志

这样后续做批次跟踪、批次详情、统计看板会更稳。

### 12. 再决定是否接真实后端接口

当前项目仍以 mock 为主，后续如果要接后端，建议先做两步：

1. 先把前端业务动作和数据结构理顺
2. 再用接口逐步替换 mock

否则很容易出现“前端口径没统一就直接对后端”的问题。

## 四、建议的推进顺序

如果按实施顺序推进，我建议这样排：

1. 出站后自动推进下一工序
2. 进站 / 出站数量规则统一
3. 维修任务生成与维修闭环
4. 批次跟踪补成完整追溯页
5. 上料管理与工序 BOM 做细
6. 工单与批次关系补强
7. 状态展示统一
8. 数据方法收口

## 五、当前最值得先动手的第一批

如果马上开始做，最合适的第一批改动是：

1. `CheckOutView.vue`
  - 出站提交后推进下一工序
  - 校验数量关系
2. `mockData.js`
  - 增加统一的批次流转方法
  - 增加工序推进和维修任务生成逻辑
3. `TrackingView.vue`
  - 接入真实的进站 / 出站 / 维修 / 上料记录

这一批做完，整个项目就会从“有流程页面”变成“流程真正跑起来”。