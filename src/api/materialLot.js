import request from '@/utils/request'

// 分页查询物料批次列表 + 多条件查询
// 接口：GET /api/material-lots
// 外层统一包装：{ code, message, data }
//   data = { pageNum, pageSize, total, totalPages, list: SMT MaterialLotVO[] }
// Query 参数（全部小驼峰，全部可选）：
//   materialCode string      物料编码，精确匹配
//   status         string  状态：在库/已使用/已冻结/已报废
//   keyword        string  关键字，批次号或条码模糊匹配
//   supplier       string  供应商，模糊匹配
//   expiryStart    string<date>  有效期起始日期（含），yyyy-MM-dd
//   expiryEnd      string<date>  有效期结束日期（含），yyyy-MM-dd
//   inboundStart   string<datetime> 入库起始时间（含）
//   inboundEnd     string<datetime> 入库结束时间（含）
//   pageNum        integer 页码，从 1 开始，默认 1
//   pageSize       integer 每页大小，默认 20
// 返回 list 中每条 VO 字段：
//   id / materialCode / batchNo / supplier / supplierBatchNo
//   inboundQuantity(入库数) / currentQuantity(剩余数) / usedQuantity(已用数)
//   productionDate / expiryDate / mslLevel / inboundDate / status / barcode
export function getMaterialLots(params) {
  return request.get('/material-lots', { params })
}

// 创建物料批次
// 接口：POST /api/material-lots
// 用途：物料入库时手动创建物料批次记录
// 请求参数（全部小驼峰）：
//   materialCode       string      物料编码（关联 smt_materials）
//   inboundQuantity    integer     入库数量，必须 > 0
//   inboundDate        string<datetime>  入库时间（如 2026-08-24T14:15:22.123Z）
//   supplier           string      供应商
//   supplierBatchNo    string      供应商批次号
//   productionDate     string<date>      生产日期
//   expiryDate         string<date>      有效期
//   mslLevel           integer     MSD 湿敏等级（1-6）
// 后端自动生成：批次号（yyyyMMdd+4 位流水号）、条码（物料编码#批次号）
// 返回：包含后端生成的 id/batchNo/barcode
export function createMaterialLot(data) {
  return request.post('/material-lots', data)
}

// 更新物料批次状态
// 接口：PUT /api/material-lots/status
// 用途：冻结/报废/解冻物料批次
// Query 参数：
//   id     integer<int64>  物料批次ID（必需）
//   status string          目标状态：在库/已冻结/已报废/已使用（必需）
export function updateMaterialLotStatus(id, status) {
  return request.put('/material-lots/status', null, { params: { id, status } })
}



// 上料操作 - 物料批次条码下拉选项
// 接口：GET /api/loading/material-lot-barcode-options
// 用途：上料录入时的物料批次条码下拉选择（图3红框）
// 后端过滤：Status='在库' 且 CurrentQuantity > 0
// Query 参数：
//   keyword string  可选，关键字模糊匹配：条码 / 物料编码 / 批次号
// 返回 data = SmtMaterialLotBarcodeOptionVO[]：
//   materialLotId   int64   物料批次ID
//   barcode         string  条码
//   materialCode    string  物料编码
//   currentQuantity int32   剩余库存
//   status          string  状态（应为"在库"）
export function getMaterialLotBarcodeOptions(params) {
  return request.get('/loading/material-lot-barcode-options', { params })
}

// 上料操作 - 查询上料工站列表
// 接口：GET /api/loading/stations
// 用途：上料操作 Tab 中「① 选择工站」步骤的工站卡片展示
// 后端自动 JOIN 工序名 + 设备类型名
// 请求参数：无
// 返回 data = 工站下拉选项VO[]：
//   id                  int64   工站ID
//   stationCode         string  工站编码
//   stationName         string  工站名称
//   operationName       string  工序名称
//   equipmentTypeName   string  设备类型名称
export function getLoadingStations() {
  return request.get('/loading/stations')
}


// 上料操作 - 查询工站已上料记录
// 接口：GET /api/loading/stations/records
// 用途：上料操作 Tab 中「查看工站已上料记录」按钮弹窗
// Query 参数：
//   stationId int64 必填，工站ID
// 返回 data = { overview, records }
//   overview = 工站上料概览VO：
//     stationName           string  工站名称
//     recordCount           int32   关联上料记录条数
//     totalLoadedQuantity   int32   上料总量（SUM InboundQuantity）
//   records = 工站上料记录条目VO[]：
//     id                  int64   上料记录ID
//     barcode             string  物料批次条码
//     materialCode        string  物料编码
//     lotCode             string  批次号（无则返回 "-"）
//     packageCode         string  封装编码（无则返回 "-"）
//     supplier            string  供应商
//     loadedQuantity      int32   上料数量
//     verifyStatusCode    int32   校验状态码：0-未校验 1-校验通过 2-校验失败
//     verifyStatusText    string  校验状态文本（中文）
//     operatorName        string  操作人姓名
//     loadingTime         string  上料时间（date-time）
export function getStationLoadingRecords(params) {
  return request.get('/loading/stations/records', { params })
}



// 上料操作 - 批量录入上料记录（单条录入时 records 长度 = 1）
// 接口：POST /api/loading/records
// 用途：点击「提交上料」时写入工站上料记录（单条录入即批量录入的退化形式）
// 接口说明：每条单独校验；成功的 INSERT，失败的加入 failDetails，不整体回滚；
//         LotId = NULL 表示未绑批次，VerifyStatus = 0 表示未校验，不落库，保留 remark。
// Body：
//   stationId  int64                必填  工站ID (smt_stations.Id)
//   records    单条上料记录创建DTO[]  必填  上料记录列表（长度1即单条录入）
//     records[].barcode         string  必填  物料批次条码 (smt_material_lots.Barcode)
//     records[].loadedQuantity  int32   必填  上料数量（必须 > 0）
//     records[].operatorId      int64   必填  操作人ID (smt_users.Id)
// 返回 data = {
//   successCount:  int32                 成功条数
//   failCount:     int32                 失败条数
//   failDetails:   {barcode, message}[]  失败详情（可选）
//   createdIds?:  int64[]                成功创建的记录ID列表（可选）
// }
export function createLoadingRecords(body) {
  return request.post('/loading/records', body)
}



// 上料操作 - 单条上料校验（不落库）
// 接口：POST /api/loading/verify
// 用途：上料录入行点击「校验」按钮时的前端点校验调用（6 层校验，后端不写任何数据库）
// 校验层次：1.条码存在/在库 2.库存够 3.未过期 4.MSL警告(非拦截) 5.传了stationId才做BOM匹配 6.封装匹配
// Body：
//   barcode         string  必填  物料批次条码 (smt_material_lots.Barcode)
//   loadedQuantity  int32   必填  上料数量（必须 > 0）
//   stationId       int64   可选  工站ID（传了才做 BOM 匹配 + 封装匹配）
// 返回 data = 单条上料校验结果VO：
//   passed              boolean 是否通过（true=校验通过/false=校验失败）
//   verifyStatusCode    int32   校验状态码：0-未校验 1-校验通过 2-校验失败
//   message             string  具体原因（通过/失败原因）
//   warning             boolean 是否有 MSL 湿敏等级警告（true=警告，非拦截，passed 仍可能为 true）
export function verifyLoadingRecord(body) {
  return request.post('/loading/verify', body)
}
