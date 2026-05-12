import request from '@/utils/request'

export function getThresholdList(params) {
  return request.get('/quality/thresholds', { params })
}

export function createThreshold(data) {
  return request.post('/quality/thresholds', data)
}

export function updateThreshold(id, data) {
  return request.put(`/quality/thresholds/${id}`, data)
}

export function toggleThreshold(id, enabled) {
  return request.post(`/quality/thresholds/${id}/toggle`, { enabled })
}

export function copyThreshold(id) {
  return request.post(`/quality/thresholds/${id}/copy`)
}

export function getInterceptList(params) {
  return request.get('/quality/intercepts', { params })
}

export function acceptIntercept(id) {
  return request.post(`/quality/intercepts/${id}/accept`)
}

export function disposeIntercept(id, data) {
  return request.post(`/quality/intercepts/${id}/dispose`, data)
}
