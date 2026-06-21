import request from '@/utils/request'

// 获取产线列表
// 接口：GET /api/lines
// 用途：新建批次时的产线下拉选择、批次列表的产线筛选等
export function getLineList() {
  return request.get('/lines')
}
