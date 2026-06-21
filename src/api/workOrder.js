import request from '@/utils/request'

// 多条件分页查询工单列表
// 接口：GET /api/work-orders
// 用途：工单管理页面列表展示，支持按工单号、产品、状态等条件筛选
export function getWorkOrderList(params) {
  return request.get('/work-orders', { params })
}

// 获取已下达工单列表（用于创建批次时选择工单）
// 接口：GET /api/work-orders/released
// 用途：新建批次弹窗的工单下拉选择，只返回状态为已下达的工单
export function getReleasedWorkOrders() {
  return request.get('/work-orders/released')
}

// 获取已下达工单详情
// 接口：GET /api/work-orders/released/detail
// 用途：新建批次时根据选中的工单获取产品、工艺路线等信息
export function getReleasedWorkOrderDetail(id) {
  return request.get('/work-orders/released/detail', { params: { id } })
}

// 获取各状态工单数量统计
// 接口：GET /api/work-orders/status-stats
// 用途：工单管理页面顶部状态卡片（计划中/已下达/生产中/已完成等数量）
export function getWorkOrderStatusStats() {
  return request.get('/work-orders/status-stats')
}

// 查询工单详情
// 接口：GET /api/work-orders/detail
// 用途：工单详情页展示，包含工单基本信息、关联批次、工艺路线等
export function getWorkOrderDetail(id) {
  return request.get('/work-orders/detail', { params: { id } })
}

// 新建工单
// 接口：POST /api/work-orders
// 用途：工单管理页面新增工单，参数包含 workOrderCode、productId、routeId、plannedQuantity 等
export function createWorkOrder(data) {
  return request.post('/work-orders', data)
}

// 修改工单状态
// 接口：PUT /api/work-orders/status
// 用途：下达、暂停、恢复、关闭等状态切换操作
// status: 1-计划中 2-已下达 3-生产中 4-已暂停 5-已完成 6-已关闭
export function updateWorkOrderStatus(id, status) {
  return request.put('/work-orders/status', null, { params: { id, status } })
}

// 下达工单
// 接口：PUT /api/work-orders/status (status=2)
// 用途：工单管理页面"下达"按钮，将工单状态从计划中改为已下达
export function releaseWorkOrder(id) {
  return updateWorkOrderStatus(id, 2)
}

// 暂停工单
// 接口：PUT /api/work-orders/status (status=4)
// 用途：工单管理页面"暂停"按钮，暂停生产中的工单
export function pauseWorkOrder(id) {
  return updateWorkOrderStatus(id, 4)
}

// 恢复工单
// 接口：PUT /api/work-orders/status (status=3)
// 用途：工单管理页面"恢复"按钮，恢复已暂停的工单
export function resumeWorkOrder(id) {
  return updateWorkOrderStatus(id, 3)
}

// 关闭工单
// 接口：PUT /api/work-orders/status (status=6)
// 用途：工单管理页面"关闭"按钮，手动关闭工单
export function closeWorkOrder(id) {
  return updateWorkOrderStatus(id, 6)
}
