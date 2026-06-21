import request from '@/utils/request'

// 获取设备类型列表
// 接口：GET /api/equipment-types
// 用途：进站操作中选择设备时，显示设备类型名称
export function getEquipmentTypes() {
  return request.get('/equipment-types')
}
