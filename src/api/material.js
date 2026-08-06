import request from '@/utils/request'

// 获取物料下拉可选列表
// 接口：GET /api/materials/options
// 用途：新建物料批次、上料时的物料编码下拉选择
// Query 参数：
//   keyword  string  关键字，模糊匹配物料编码或物料名称
//   pageSize number  每页条数（拉取下拉建议传较大值如 1000）
export function getMaterialOptions(params) {
  const query = { pageSize: 1000, ...(params || {}) }
  return request.get('/materials/options', { params: query })
}
