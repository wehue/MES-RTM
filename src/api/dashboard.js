import request from '@/utils/request'

export function getDashboardData() {
  return request.get('/dashboard')
}

export function getLineStatusList() {
  return request.get('/dashboard/line-status')
}

export function getAlertList(params) {
  return request.get('/dashboard/alerts', { params })
}

export function getProductionProgress() {
  return request.get('/dashboard/production-progress')
}

export function getQualityTrend(params) {
  return request.get('/dashboard/quality-trend', { params })
}
