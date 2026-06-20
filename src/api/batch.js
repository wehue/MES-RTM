import request from '@/utils/request'

export function getBatchList(params) {
  return request.get('/lots', { params })
}

export function getBatchStatusStats() {
  return request.get('/lots/status-stats')
}

export function updateBatchStatus(id, status) {
  return request.put('/lots/status', null, { params: { id, status } })
}

export function getBatchDetail(id) {
  return request.get('/lots/detail', { params: { id } })
}

export function createBatch(data) {
  return request.post('/lots', data)
}

export function deleteBatch(id) {
  return request.delete(`/lots/${id}`)
}

export function lockBatch(id) {
  return request.put('/lots/status', null, { params: { id, status: 5 } })
}

export function unlockBatch(id) {
  return request.put('/lots/status', null, { params: { id, status: 2 } })
}

export function pauseBatch(id) {
  return request.put('/lots/status', null, { params: { id, status: 3 } })
}

export function resumeBatch(id) {
  return request.put('/lots/status', null, { params: { id, status: 2 } })
}
