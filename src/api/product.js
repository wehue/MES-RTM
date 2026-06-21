import request from '@/utils/request'

// 获取产品列表
// 接口：GET /api/products
// 用途：新建工单时的产品下拉选择、工单列表的产品筛选等
export function getProductList() {
  return request.get('/products')
}
