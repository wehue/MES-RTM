import request from '@/utils/request'

export function getWorkOrderList(params) {
  return request.get('/work-orders', { params })
}

export function getWorkOrderDetail(id) {
  return request.get(`/work-orders/${id}`)
}

export function createWorkOrder(data) {
  return request.post('/work-orders', data)
}

export function releaseWorkOrder(id, data) {
  return request.post(`/work-orders/${id}/release`, data)
}

export function pauseWorkOrder(id, reason) {
  return request.post(`/work-orders/${id}/pause`, { reason })
}

export function resumeWorkOrder(id) {
  return request.post(`/work-orders/${id}/resume`)
}

export function closeWorkOrder(id) {
  return request.post(`/work-orders/${id}/close`)
}
