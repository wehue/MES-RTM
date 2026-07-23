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

// 获取待进站批次列表（进站操作用）
// 接口：GET /api/lots/station-in/list
// 用途：进站操作页面左侧列表，展示所有状态为生产中且当前工序待进站的批次
export function getStationInList() {
  return request.get('/lots/station-in/list')
}

// 按批次号查询进站详情
// 接口：GET /api/lots/station-in/detail
// 用途：进站操作页面右侧详情，展示当前工序、上一工序、待进站数量等信息
export function getStationInDetail(lotCode) {
  return request.get('/lots/station-in/detail', { params: { lotCode } })
}

// 获取可出站批次列表（出站操作用）
// 接口：GET /api/lots/station-out/list
// 用途：出站操作页面左侧列表，展示所有当前工序已进站可出站的批次
export function getStationOutList() {
  return request.get('/lots/station-out/list')
}

// 按批次号查询出站详情
// 接口：GET /api/lots/station-out/detail
// 用途：出站操作页面右侧详情，展示当前工序、进站数量、批次状态等信息
export function getStationOutDetail(lotCode) {
  return request.get('/lots/station-out/detail', { params: { lotCode } })
}

// 执行出站
// 接口：POST /api/station-out
// 用途：出站操作页面提交“执行出站”；后端自动确定当前已进站工序，更新工序状态为已出站并写入出站历史记录
// 参数：{ lotId, routeStepId, operatorId, finishedQuantity, defectQuantity, disposalType, disposalRemark, spiPassRate, aoiPassRate, remark }
export function createStationOut(data) {
  return request.post('/station-out', data)
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

// 执行进站
// 接口：POST /api/station-in
// 用途：进站操作页面提交“执行进站”；后端会自动识别当前工序、写入进站记录，
//      首道工序进站时会把批次状态改为“生产中”
// 参数：{ lotId, operatorId, stationInQuantity, remark }
// 说明：工站与设备为一对一关系，进站设备由后端根据当前工站自动识别，
//      前端无需再传递 equipmentId
export function createStationIn(data) {
  return request.post('/station-in', data)
}

// 执行上料/补料
// 接口：PUT /api/loading/supplement
// 用途：上料管理页面提交“保存上料”，后端将本次补充数量写入 smt_loading_records，
//      并更新该批次对应物料的已上数量与 BOM 校验状态
// 参数：{ lotId, materialCode, supplementQuantity, operatorId, routeStepId }
export function supplementMaterial(data) {
  return request.put('/loading/supplement', data)
}
