import request from '@/utils/request'

// 查询工站已上料记录（用于下料选择）
// 接口：GET /api/unloading/station-records
// 用途：下料管理页面选择工站后，加载该工站可下料的上料记录
// 参数：routeStepId、stationId
export function getStationUnloadableRecords(params) {
  return request.get('/unloading/station-records', { params })
}

// 提交下料
// 接口：POST /api/unloading
// 用途：下料管理页面提交"执行下料"，后端将本次下料数量写入 smt_unloading_records，
//      并回退该物料批次的已使用数量（UsedQuantity）
// 参数（字段对齐数据库 smt_unloading_records）：
//   { loadingRecordId, unloadQuantity, reasonCode, remark, operatorId }
//   reasonCode: 1-批次完工换线 / 2-物料耗尽 / 3-品质异常 / 4-其他
//   remark: 下料备注（"其他"原因时必填，说明上错料/进站校验失败等具体场景）
export function createUnloading(data) {
  return request.post('/unloading', data)
}

// 查询工站下料记录列表
// 接口：GET /api/unloading/list
// 用途：下料管理页面查询历史下料记录
// 参数：routeStepId、stationId、materialLotBarcode、startTime、endTime
export function getUnloadingList(params) {
  return request.get('/unloading/list', { params })
}

// 查询工站上下料历史（合并上料与下料记录）
// 接口：GET /api/unloading/station-history
// 用途：工站上下料记录查看，按时间倒序合并展示上料与下料记录
// 参数：routeStepId、startTime、endTime
export function getStationHistory(params) {
  return request.get('/unloading/station-history', { params })
}
