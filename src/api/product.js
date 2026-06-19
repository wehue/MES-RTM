import request from '@/utils/request'

export function getProductList() {
  return request.get('/products')
}

