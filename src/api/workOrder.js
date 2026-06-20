import request from '@/utils/request'

export function getWorkOrderList(params) {
  return request.get('/work-orders', { params })
}

export function getReleasedWorkOrders() {
  return request.get('/work-orders/released')
}

export function getReleasedWorkOrderDetail(id) {
  return request.get('/work-orders/released/detail', { params: { id } })
}

export function getWorkOrderStatusStats() {
  return request.get('/work-orders/status-stats')
}

export function getWorkOrderDetail(id) {
  return request.get('/work-orders/detail', { params: { id } })
}

export function createWorkOrder(data) {
  return request.post('/work-orders', data)
}

export function updateWorkOrderStatus(id, status) {
  return request.put('/work-orders/status', null, { params: { id, status } })
}

export function releaseWorkOrder(id) {
  return updateWorkOrderStatus(id, 2)
}

export function pauseWorkOrder(id) {
  return updateWorkOrderStatus(id, 4)
}

export function resumeWorkOrder(id) {
  return updateWorkOrderStatus(id, 3)
}

export function closeWorkOrder(id) {
  return updateWorkOrderStatus(id, 6)
}
