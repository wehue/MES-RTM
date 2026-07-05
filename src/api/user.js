import request from '@/utils/request'

// 用户登录
// 接口：POST /api/user/login
// 参数：{ username, password }
// 返回：{ token, userId, username, fullName, department, position }
export function loginUser(data) {
  return request.post('/user/login', {
    username: data.username,
    password: data.password,
  })
}

// 用户注册
// 接口：POST /api/user/register
// 参数：{ username, password, fullName, department, position, contact }
// 返回：{ userId, username, fullName, department, position }
export function registerUser(data) {
  return request.post('/user/register', data)
}

// 查询当前登录用户的功能权限
// 接口：GET /api/user/current/functions
// Header：token
// 参数：{ pageNum, pageSize }
export function getCurrentUserFunctions(params = { pageNum: 1, pageSize: 200 }) {
  return request.get('/user/current/functions', { params })
}

// 查询指定用户的功能权限
// 接口：GET /api/user/functions
// 参数：{ userId, pageNum, pageSize }
export function getUserFunctions(params) {
  return request.get('/user/functions', { params })
}

// 获取操作员列表
// 接口：GET /api/user/operators
// 用途：进站/出站/上料/下料等操作页面中选择操作人，返回操作工和班组长角色的用户
export function getOperators() {
  return request.get('/user/operators')
}
