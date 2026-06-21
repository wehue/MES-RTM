import request from '@/utils/request'

// 获取工艺路线列表
// 接口：GET /api/routes
// 用途：新建工单时的工艺路线下拉选择
export function getRouteList() {
  return request.get('/routes')
}
