import { defineStore } from 'pinia'
import { ref } from 'vue'
import { roleHasPermission } from '@/utils/constants'

const savedUser = localStorage.getItem('userInfo')

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref(savedUser ? JSON.parse(savedUser) : {
    id: 'U001',
    username: 'admin',
    name: '工厂管理层',
    department: '生产部',
    post: '管理层',
    role: 'admin',
    roles: ['admin'],
    lines: ['SMT-A1', 'SMT-A2', 'SMT-B1', 'SMT-B2'],
  })

  function setToken(val) {
    token.value = val
    localStorage.setItem('token', val)
  }

  function setUserInfo(info) {
    userInfo.value = info
    localStorage.setItem('userInfo', JSON.stringify(info))
  }

  function logout() {
    token.value = ''
    localStorage.removeItem('token')
  }

  function hasRole(role) {
    return userInfo.value.role === 'admin' || userInfo.value.roles?.includes(role)
  }

  function hasAnyRole(roles) {
    return userInfo.value.role === 'admin' || roles.some((role) => userInfo.value.roles?.includes(role))
  }

  function hasPermission(permission) {
    return roleHasPermission(userInfo.value.role, permission)
  }

  return { token, userInfo, setToken, setUserInfo, logout, hasRole, hasAnyRole, hasPermission }
})
