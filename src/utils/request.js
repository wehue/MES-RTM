import axios from 'axios'
import { ElMessage } from 'element-plus'
import NProgress from 'nprogress'
import 'nprogress/nprogress.css'

NProgress.configure({ showSpinner: false })

// 防止多个 401 并发时重复弹窗和跳转
let isRedirecting = false

const request = axios.create({
  baseURL: '/api',
  timeout: 30000,
})

request.interceptors.request.use(
  (config) => {
    NProgress.start()
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
      config.headers.token = token
    }
    return config
  },
  (error) => {
    NProgress.done()
    return Promise.reject(error)
  }
)

request.interceptors.response.use(
  (response) => {
    NProgress.done()
    const { code, data, message } = response.data
    if (code === 200 || code === 0 || (code >= 200 && code < 300)) {
      return data
    }
    // 业务层返回 401 状态码（token 过期/无效）
    if (code === 401) {
      handleTokenExpired(message)
      return Promise.reject({ message: message || '登录已过期', response: response.data })
    }
    ElMessage.error(message || '请求失败')
    return Promise.reject({
      message: message || '请求失败',
      response: response.data
    })
  },
  (error) => {
    NProgress.done()
    if (error.response) {
      const { status } = error.response
      if (status === 401) {
        handleTokenExpired(error.response.data?.message)
      } else if (status === 403) {
        ElMessage.error('没有操作权限')
      } else if (status === 500) {
        ElMessage.error('服务器内部错误')
      } else {
        ElMessage.error(error.response.data?.message || '请求失败')
      }
    } else {
      ElMessage.error('网络连接异常')
    }
    return Promise.reject(error)
  }
)

// token 过期统一处理：弹窗提示 → 清除登录态 → 跳转登录页
function handleTokenExpired(message) {
  if (isRedirecting) return
  isRedirecting = true
  ElMessage.error(message || '登录已过期，请重新登录')
  localStorage.removeItem('token')
  localStorage.removeItem('userInfo')
  localStorage.removeItem('userFunctions')
  localStorage.removeItem('permissionCodes')
  // 延迟跳转，让用户看到提示
  setTimeout(() => {
    window.location.href = '/login'
  }, 800)
}

export default request
