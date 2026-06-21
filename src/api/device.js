import request from '@/utils/request'

// 查询批次可用设备列表
// 接口：GET /api/equipment/available-for-lot?lotId={lotId}
// 参数：lotId - 批次ID（必填）
// 用途：进站操作中选择设备，根据批次查询可用的设备列表
export function getAvailableEquipmentForLot(lotId) {
  return request.get('/equipment/available-for-lot', { params: { lotId } })
}
