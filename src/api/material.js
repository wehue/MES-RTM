import request from '@/utils/request'

// 物料编码可选列表（下拉）
// 接口：GET /api/materials/options
// 用途：新建物料批次 / 上料时「物料编码」下拉选择
// 后端筛选：所有未删除的物料编码
// Query 参数：
//   keyword  string  可选，关键字，模糊匹配物料编码或物料名称
// 返回字段：
//   materialCode / materialName / packageCode（封装编码）/ brand
export function getMaterialOptions(params) {
  return request.get('/materials/options', { params })
}
