import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
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
    const body = response.data
    // 非 JSON 响应（如文件下载）直接返回
    if (typeof body !== 'object' || body === null) return body
    // 后端未采用 { code, message, data } 标准包装时，直接返回 body 本身
    // （如分页接口直接返回 { pageNum, pageSize, total, list } 或数组）
    if (!('code' in body) && !('Code' in body)) return body
    const { code, data, message } = body
    if (code === 200 || code === 0 || (code >= 200 && code < 300)) {
      return data
    }
    // 业务层返回 401 状态码（token 过期/无效）
    if (code === 401) {
      handleTokenExpired(message)
      return Promise.reject({ message: message || '登录已过期', response: body })
    }
    ElMessage.error(message || '请求失败')
    return Promise.reject({
      message: message || '请求失败',
      response: body
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

// token 过期统一处理：模态弹窗阻塞操作 → 清除登录态 → 跳转登录页
function handleTokenExpired(message) {
  if (isRedirecting) return
  isRedirecting = true
  // 清除本地登录态
  localStorage.removeItem('token')
  localStorage.removeItem('userInfo')
  localStorage.removeItem('userFunctions')
  localStorage.removeItem('permissionCodes')
  // 使用模态弹窗强制阻塞用户操作，确认后跳转登录页
  ElMessageBox.alert(
    message || '登录状态已过期，请重新登录',
    '登录失效',
    {
      confirmButtonText: '重新登录',
      type: 'warning',
      showClose: false,
      closeOnClickModal: false,
      closeOnPressEscape: false,
    }
  ).finally(() => {
    isRedirecting = false
    // 使用 location.href 确保完全重置页面状态（Pinia store、路由等）
    window.location.href = '/login'
  })
}

export default request
