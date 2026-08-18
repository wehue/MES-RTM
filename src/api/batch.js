import request from '@/utils/request'

// 多条件分页查询批次列表
// 接口：GET /api/lots
// 用途：批次管理页面列表展示，支持按工单号、产品、产线、状态等条件筛选
export function getBatchList(params) {
  return request.get('/lots', { params })
}

// 获取各状态批次数量统计
// 接口：GET /api/lots/status-stats
// 用途：批次管理页面顶部状态卡片（待生产/生产中/已完成等数量）
export function getBatchStatusStats() {
  return request.get('/lots/status-stats')
}

// 修改批次状态
// 接口：PUT /api/lots/status
// 用途：投产、暂停、恢复、锁定、解锁等状态切换操作
// status: 1-待生产 2-生产中 3-已暂停 4-已完成 5-已锁定
export function updateBatchStatus(id, status) {
  return request.put('/lots/status', null, { params: { id, status } })
}

// 查询批次详情
// 接口：GET /api/lots/detail?id={lotId}
// 用途：批次详情页展示，包含批次基础信息、工艺路线、当前工序上料清单（operationMaterials）等
export function getBatchDetail(id) {
  return request.get('/lots/detail', { params: { id } })
}

// 获取待进站批次列表（进站操作用，分页）
// 接口：GET /api/station-in/list
// 用途：进站操作页面"待进站批次列表"表格，后端筛选：
//        ① 无任何已进站(Status=2)的工序
//        ② 至少有一道待进站(Status=1)的工序
//        ③ 批次状态 IN (1-待生产, 2-生产中)
//        ④ 排序：创建时间 DESC
// Query 参数：
//   pageNum  int  可选，页码（从 1 开始，默认 1）
//   pageSize int  可选，每页大小（默认 20）
// 返回 data：{ pageNum, pageSize, total, totalPages, list: [{lotId, lotCode, productCode, productName,
//           lineName, plannedQuantity, completedQuantity, pendingStationInQuantity,
//           currentPendingOperationName, lotStatusName, createdAt}] }
export function getStationInList(params) {
  return request.get('/station-in/list', { params })
}

// 按批次号查询进站批次基础资料（含 BOM 校验）
// 接口：GET /api/station-in/detail
// 用途：进站操作页面「批次选择与基础信息」展示，以及 BOM 封装匹配校验
// Query 参数：
//   lotCode  string  必填，批次号（接口1列表返回的 lotCode）
// 返回 data（进站批次基本资料VO）：
//   基础信息：lotId, lotCode, productId, productCode, productName, lineId, lineName,
//             plannedQuantity, completedQuantity, pendingStationInQuantity,
//             currentPendingRouteStepId, currentPendingOperationName,
//             currentPendingStationId, currentPendingStationName,
//             lotStatusName, createdAt
//   BOM 校验：bomVerifyPassed (bool), bomVerifyMessage (中文说明),
//             bomPackages[] (packageCode/packageName),
//             supportedPackages[] (packageCode/packageName),
//             mismatchedPackages[] (packageCode/packageName, 失败时的差集)
export function getStationInDetail(lotCode) {
  return request.get('/station-in/detail', { params: { lotCode } })
}

// 获取可出站批次列表（出站操作用，分页）
// 接口：GET /api/station-out/list
// 用途：出站操作页面「可出站批次列表」表格，后端筛选：
//        ① 至少有一道已进站(Status=2)且待出站的工序
//        ② 批次状态 = 生产中(Status=2)
//        ③ 待出站数量 > 0
//        ④ 排序：创建时间 DESC
// 入参仅支持 pageNum / pageSize，不支持 keyword、lineId
// Query 参数：
//   pageNum  int  可选，页码（从 1 开始，默认 1）
//   pageSize int  可选，每页大小（默认 20）
// 返回 data：{ pageNum, pageSize, total, totalPages, list: [{lotId, lotCode, productCode, productName,
//           lineName, plannedQuantity, completedQuantity, pendingStationOutQuantity,
//           currentPendingOperationName, lotStatusName, createdAt}] }
// pendingStationOutQuantity = 当前工序累计进站数量 − 该工序历史累计成品出站数量
// currentPendingOperationName = Status=2 且 Sequence 最小的待出站工序
export function getStationOutList(params) {
  return request.get('/station-out/list', { params })
}

// 按批次号查询出站批次基本资料
// 接口：GET /api/station-out/detail
// 用途：出站操作页面「批次与出站信息」展示，选择批次后查看该批次的数据
// Query 参数：
//   lotCode  string  必填，批次号（接口1列表返回的 lotCode）
// 返回 data（出站批次基本资料VO）：
//   基础信息：lotId, lotCode, productCode, productName, lineName,
//             plannedQuantity, completedQuantity, pendingStationOutQuantity,
//             currentPendingOperationName, currentPendingStationName,
//             previousOperationName, currentPendingOperationStatusName,
//             equipmentTypeName, lotStatusName, createdAt
// pendingStationOutQuantity = 当前工序累计进站数量 − 该工序历史累计完工出站数量
// 无BOM校验
export function getStationOutDetail(lotCode) {
  return request.get('/station-out/detail', { params: { lotCode } })
}

// 确认出站操作
// 接口：POST /api/station-out/confirm
// 用途：出站操作页面提交"确认出站"；一个事务只写2张表：
//        ① UPDATE 工序状态 Status=2→3，写出站时间/完工数量累加/不良数量累加
//        ② INSERT 出站历史流水
//      Token规则：CreatedBy/UpdatedBy 用 Token 解析的当前登录人；OperatorId 用前端传的 dto.operatorId
//      普通工序传 finishedQuantity+defectQuantity；SPI/AOI检测工序只对应 passRate
//      异常出站(isNormal=0)或有不良(defectQuantity>0)必须填 disposalRemark
// Body 参数：
//   lotId             int64  【必填】批次ID
//   operatorId        int64  【必填】出站操作员ID（谁具体干活）
//   finishedQuantity  int32  普通工序必填，检测工序不用传；必须>0且≤待出站数量
//   defectQuantity    int32  普通工序选填，默认0；>0时 disposalRemark 必填
//   spiPassRate       number SPI检测工序必填，范围0-100
//   aoiPassRate       number AOI检测工序必填，范围0-100
//   isNormal          int32  是否正常出站：1-正常【默认】，0-异常
//   disposalType      int32  不良处置方式：1-维修，2-报废，3-强制出站（isNormal=0时必填）
//   disposalRemark    string 处置原因/备注（defectQuantity>0 或 isNormal=0 时必填），最长200字符
// 返回 data（出站确认结果VO）：
//   lotId, lotCode, routeStepId, operationName, stationName, equipmentId,
//   stationOutTime, finishedQuantity, defectQuantity, round, isNormal,
//   spiPassRate, aoiPassRate
export function createStationOut(data) {
  return request.post('/station-out/confirm', data)
}

// 查询待上料批次列表（上料管理列表页用）
// 接口：GET /api/lots/pending-loading/list
// 用途：上料管理列表页，返回所有"待上料"批次，包含批次号、工单号、产品、产线、
//      当前工序、上料完成率、BOM 校验结果等信息
export function getPendingLoadingList() {
  return request.get('/lots/pending-loading/list')
}

// 新建批次
// 接口：POST /api/lots
// 用途：批次管理页面新增批次，参数包含 lotCode、workOrderId、lineId、plannedQuantity 等
export function createBatch(data) {
  return request.post('/lots', data)
}

// 确认进站操作
// 接口：POST /api/station-in/confirm
// 用途：进站操作页面提交"确认进站"；事务内只写 2 张表：
//        ① UPDATE 工序状态 Status=1→2，写入进站时间/进站数量
//        ② INSERT 进站历史流水
//      前置校验：批次/工序状态、进站数量 ≤ 待进站数量、BOM 必须通过、设备工站操作员均存在
//      CreatedBy/UpdatedBy 后端由 Token 解析的决策人填充；前端传的 operatorId = 具体干活的人（主管指定）
// Body 参数（必填，缺一不可）：
//   lotId                int64  批次ID（接口1/2返回的 lotId）
//   operatorId           int64  进站操作员ID（谁具体干活，不是 Token 决策人）
//   stationInQuantity    int32  进站数量（>0 且 ≤ 接口2返回的 pendingStationInQuantity）
// 返回 data（进站确认结果VO）：
//   lotId, lotCode, routeStepId, operationName, stationName, equipmentId,
//   stationInTime, stationInQuantity, round（第N次进这道工序）
export function createStationIn(data) {
  return request.post('/station-in/confirm', data)
}

// 执行上料/补料
// 接口：PUT /api/loading/supplement
// 用途：上料管理页面提交“保存上料”，后端将本次补充数量写入 smt_loading_records，
//      并更新该批次对应物料的已上数量与 BOM 校验状态
// 参数：{ lotId, materialCode, supplementQuantity, operatorId, routeStepId }
export function supplementMaterial(data) {
  return request.put('/loading/supplement', data)
}
