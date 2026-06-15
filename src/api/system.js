import request from '@/utils/request'

export function login(data) {
  return request.post('/auth/login', data)
}

export function getUserInfo() {
  return request.get('/auth/user-info')
}

export function changePassword(data) {
  return request.post('/auth/change-password', data)
}

export function getMessageList(params) {
  return request.get('/messages', { params })
}

export function markAllRead() {
  return request.post('/messages/read-all')
}

export function deleteMessage(id) {
  return request.delete(`/messages/${id}`)
}

export function getUnreadCount() {
  return request.get('/messages/unread-count')
}
