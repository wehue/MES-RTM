import request from '@/utils/request'

export function checkIn(data) {
  return request.post('/execution/check-in', data)
}

export function checkOut(data) {
  return request.post('/execution/check-out', data)
}

export function getLoadingTasks(batchId, processId) {
  return request.get('/execution/loading-tasks', { params: { batchId, processId } })
}

export function verifyLoading(data) {
  return request.post('/execution/verify-loading', data)
}

export function batchVerifyLoading(data) {
  return request.post('/execution/batch-verify-loading', data)
}
