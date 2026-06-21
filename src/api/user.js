import request from '@/utils/request'

// 获取操作员列表
// 接口：GET /api/user/operators
// 用途：进站/出站/上料/下料等操作页面中选择操作人，返回操作工和班组长角色的用户
export function getOperators() {
  return request.get('/user/operators')
}
