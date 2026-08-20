import request from '@/utils/request'

// 查询待下料批次列表
// 接口：GET /api/unloading/pending-lots（下料操作模块专用）
// 用途：下料管理页面的"① 选择已投产批次"，无需入参
// 后端筛选规则：批次状态=生产中(2)或已完成(6) + 存在未下料完毕的上料记录
// 排序规则：生产中批次优先取"已进站工序"；已完成批次取"最后一道出站工序"
// 返回字段（PascalCase/camelCase 兼容）：
//   { id, lotCode, productName, workOrderCode, lineName, currentOperationName }
export function getPendingUnloadingLots() {
  return request.get('/unloading/pending-lots')
}

// 查询可下料的上料记录列表（按批次+工站双必填精准筛选）
// 接口：GET /api/unloading/loading-records
// 入参：lotId（批次ID，必传 smt_lots.Id）
//      stationId（工站ID，必传 smt_stations.Id）
// 用途：下料管理选择批次 + 工站后，加载"该批次+该工站下所有未下料完毕的上料记录"
//       作为「工站已上料记录」表格数据源；点击"下料"按钮时直接用其 id 作为
//       批量录入接口 records[i].loadingRecordId 的值（后端可从 loadingRecord 推导 lotId/stationId/materialLotId）
// 返回 data 数组每条共 12 字段：
//   —— 基础 8 字段 ——
//   id                  int64   上料记录ID（smt_loading_records.Id）
//   materialLotBarcode  string  物料批次条码
//   materialCode        string  物料编码
//   packageCode         string  封装编码（未配返回 '-'）
//   supplier            string  供应商
//   operatorName        string  操作人姓名（FullName优先，Username兜底）
//   loadingTime         string  上料时间（yyyy-MM-dd HH:mm:ss）
//   loadingQuantity     int32   上料数量（smt_loading_records.LoadingQuantity）
//   —— 历史下料合计 4 字段（新增，直接给前端用，无需再从已下料记录反向聚合）——
//   totalUnloadQuantity        int32  历史下料数量合计（对应所有下料记录 UnloadQuantity 求和，null=0）
//   totalActualUsedQuantity    int32  历史实际使用数量合计（对应所有下料记录 ActualUsedQuantity 求和，null=0）
//   totalWastageQuantity       int32  历史损耗数量合计（对应所有下料记录 WastageQuantity 求和，null=0）
//   latestRemainQuantity       int32  最新一条下料记录的剩余数量（按下料记录Id最大取 LatestRemainQuantity；一条都没下过返回 null；当前可下料数量参考值）
export function getUnloadingLoadingRecords(params) {
  return request.get('/unloading/loading-records', { params })
}

// 批量录入下料记录（单条录入：records 长度=1；多条录入：records 长度=N）
// 接口：POST /api/unloading/records
// 事务说明：每条单独校验，成功的 INSERT smt_unloading_records 并回库（unloadQuantity 加回物料批次 CurrentQuantity）
//          失败的加入 failDetails，不整体回滚
// 前端必填（records[i]）：loadingRecordId + unloadQuantity + actualUsedQuantity + wastageQuantity + reason
// 可选：remark（≤200字）、barcode（交叉校验防扫错）
// 后端自动推导：lotId、stationId、materialLotId、remainQuantity
// reason 枚举：1-批次完工换线 / 2-物料耗尽 / 3-品质异常 / 4-其他（与 UI UNLOAD_REASON 一致）
export function batchCreateUnloadingRecords(data) {
  return request.post('/unloading/records', data)
}

// 查询工站下料记录列表（旧版，保留兼容兜底）
// 接口：GET /api/unloading/list
// 参数：routeStepId、stationId、materialLotBarcode、startTime、endTime
// 注意：下料管理查看"工站已下料记录"请优先使用 getStationUnloadingRecords（返回 overview+records 双层）
export function getUnloadingList(params) {
  return request.get('/unloading/list', { params })
}

// 查询工站已下料记录（新版：概览 + 记录列表 双层结构）
// 接口：GET /api/unloading/stations/records
// 入参：stationId（必传，smt_stations.Id）
// 返回 data = { overview, records }
//   overview 概览 7 字段：{ stationId, stationName, recordCount,
//     totalUnloadQuantity 累计下料总量(回库), totalActualUsedQuantity 累计实耗,
//     totalWastageQuantity 累计损耗, lastUnloadingTime 最近下料时间 }
//   records 列表每记录 16 字段：
//     id / lotId / lotCode（生产批次号）/ loadingRecordId / materialLotId
//     / materialLotBarcode 物料批次条码 / materialCode 物料编码
//     / operatorName 操作人（FullName 优先 Username 兜底）/ unloadingTime 下料时间
//     / reasonCode（1完工换线 2物料耗尽 3品质异常 4其他）/ reasonText 原因中文
//     / unloadQuantity 下料数量(=剩余回库数量) / actualUsedQuantity 实际使用数
//     / remainQuantity 剩余数量 / wastageQuantity 损耗数量 / remark 下料备注
export function getStationUnloadingRecords(params) {
  return request.get('/unloading/stations/records', { params })
}

// 查询工站上下料历史（合并上料与下料记录）
// 接口：GET /api/unloading/station-history
// 用途：工站上下料记录查看，按时间倒序合并展示上料与下料记录
// 参数：routeStepId、startTime、endTime
export function getStationHistory(params) {
  return request.get('/unloading/station-history', { params })
}
