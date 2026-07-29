import request from '@/utils/request'

// 分页查询物料批次列表
// 接口：GET /api/material-lots
// 用途：物料批次管理页面列表展示，支持按 MaterialCode、Status 筛选
export function getMaterialLots(params) {
  return request.get('/material-lots', { params })
}

// 创建物料批次
// 接口：POST /api/material-lots
// 用途：物料入库时手动创建物料批次记录
// 返回：包含后端生成的 BatchNo 和 Barcode
export function createMaterialLot(data) {
  return request.post('/material-lots', data)
}

// 更新物料批次状态
// 接口：PUT /api/material-lots/:id/status
// 用途：冻结/报废/解冻物料批次
export function updateMaterialLotStatus(id, status) {
  return request.put(`/material-lots/${id}/status`, { status })
}

// 上料前校验
// 接口：POST /api/material-lots/validate
// 用途：校验封装类型、物料状态、有效期、库存
export function validateMaterialLot(data) {
  return request.post('/material-lots/validate', data)
}

// 上料成功后扣减库存
// 接口：POST /api/material-lots/consume
// 用途：扣减物料批次的 UsedQuantity
export function consumeMaterialLot(data) {
  return request.post('/material-lots/consume', data)
}
