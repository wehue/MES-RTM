import request from '@/utils/request'

export function getBatchList(params) {
  return request.get('/batches', { params })
}

export function getBatchDetail(id) {
  return request.get(`/batches/${id}`)
}

export function createBatch(data) {
  return request.post('/batches', data)
}

export function deleteBatch(id) {
  return request.delete(`/batches/${id}`)
}

export function lockBatch(id, reason) {
  return request.post(`/batches/${id}/lock`, { reason })
}

export function unlockBatch(id, reason) {
  return request.post(`/batches/${id}/unlock`, { reason })
}

export function pauseBatch(id, reason) {
  return request.post(`/batches/${id}/pause`, { reason })
}

export function resumeBatch(id) {
  return request.post(`/batches/${id}/resume`)
}
