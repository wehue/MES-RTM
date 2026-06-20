import request from '@/utils/request'

export function getLineList() {
  return request.get('/lines')
}