import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref({
    id: '',
    username: '',
    name: '',
    department: '',
    role: '',
    roles: [],
  })

  function setToken(val) {
    token.value = val
    localStorage.setItem('token', val)
  }

  function setUserInfo(info) {
    userInfo.value = info
  }

  function logout() {
    token.value = ''
    userInfo.value = { id: '', username: '', name: '', department: '', role: '', roles: [] }
    localStorage.removeItem('token')
  }

  function hasRole(role) {
    return userInfo.value.roles.includes(role) || userInfo.value.role === 'admin'
  }

  return { token, userInfo, setToken, setUserInfo, logout, hasRole }
})
