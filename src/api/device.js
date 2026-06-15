import request from '@/utils/request'

export function getDeviceList(params) {
  return request.get('/devices', { params })
}

export function getDeviceDetail(id) {
  return request.get(`/devices/${id}`)
}

export function reportFault(id, data) {
  return request.post(`/devices/${id}/fault`, data)
}

export function confirmMaintenance(id, data) {
  return request.post(`/devices/${id}/maintenance`, data)
}

export function getDeviceOEE(id, params) {
  return request.get(`/devices/${id}/oee`, { params })
}
