import request from '@/utils/request'

export function getRepairList(params) {
  return request.get('/repairs', { params })
}

export function acceptRepair(id) {
  return request.post(`/repairs/${id}/accept`)
}

export function submitRepair(id, data) {
  return request.post(`/repairs/${id}/submit`, data)
}

export function requestUnlock(id, data) {
  return request.post(`/repairs/${id}/request-unlock`, data)
}

export function approveUnlock(id, data) {
  return request.post(`/repairs/${id}/approve-unlock`, data)
}

export function confirmScrap(id, data) {
  return request.post(`/repairs/${id}/scrap`, data)
}
