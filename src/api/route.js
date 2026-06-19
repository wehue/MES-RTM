import request from '@/utils/request'

export function getRouteList() {
  return request.get('/routes')
}

