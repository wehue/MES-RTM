export const ROLES = [
  { value: 'production_manager', label: '生产主管' },
  { value: 'team_leader', label: '班组长' },
  { value: 'operator', label: '操作工' },
  { value: 'quality_engineer', label: '质量工程师' },
  { value: 'admin', label: '工厂管理层' },
]

export const PERMISSION_CODES = {
  DASHBOARD: 'dashboard',
  KANBAN: 'kanban',
  WORK_ORDER: 'work_order',
  BATCH: 'batch',
  LOADING: 'loading',
  CHECK_IN: 'check_in',
  CHECK_OUT: 'check_out',
  TRACKING: 'tracking',
  REPAIR: 'repair',
  DEVICE: 'device',
  SYSTEM: 'system',
}

export const BACKEND_FUNCTION_PERMISSION_MAP = {
  dashboard: [PERMISSION_CODES.DASHBOARD],
  kanban: [PERMISSION_CODES.KANBAN],
  work_order: [PERMISSION_CODES.WORK_ORDER],
  batch: [PERMISSION_CODES.BATCH],
  loading: [PERMISSION_CODES.LOADING],
  check_in: [PERMISSION_CODES.CHECK_IN],
  check_out: [PERMISSION_CODES.CHECK_OUT],
  tracking: [PERMISSION_CODES.TRACKING],
  repair: [PERMISSION_CODES.REPAIR],
  device: [PERMISSION_CODES.DEVICE],
  equipment: [PERMISSION_CODES.DEVICE],
  system: [PERMISSION_CODES.SYSTEM],
  user: [PERMISSION_CODES.SYSTEM],
  role: [PERMISSION_CODES.SYSTEM],
  WO_MANAGE: [PERMISSION_CODES.WORK_ORDER],
  BATCH_MANAGE: [PERMISSION_CODES.BATCH],
  LINE_LOAD_MONITOR: [PERMISSION_CODES.DASHBOARD],
  SCHEDULE_BOARD: [PERMISSION_CODES.DASHBOARD, PERMISSION_CODES.KANBAN],
  INBOUND_MANAGE: [PERMISSION_CODES.CHECK_IN],
  LOADING_TASK_VIEW: [PERMISSION_CODES.LOADING],
  INBOUND_LOADING_CHECK: [PERMISSION_CODES.CHECK_IN, PERMISSION_CODES.LOADING],
  OUTBOUND_MANAGE: [PERMISSION_CODES.CHECK_OUT],
  REPAIR_MANAGE: [PERMISSION_CODES.REPAIR],
  QUALITY_JUDGE_INTERCEPT: [PERMISSION_CODES.BATCH, PERMISSION_CODES.CHECK_OUT, PERMISSION_CODES.REPAIR],
  PARAM_QUALITY_RELATE_QUERY: [PERMISSION_CODES.TRACKING],
  LINE_STATUS_BOARD: [PERMISSION_CODES.KANBAN],
  QUALITY_BOARD: [PERMISSION_CODES.KANBAN],
  PARAM_TEMPLATE_SELECT: [PERMISSION_CODES.DEVICE],
  PARAM_ISSUE: [PERMISSION_CODES.DEVICE],
  PARAM_CONSISTENCY_CHECK: [PERMISSION_CODES.DEVICE],
}

export const PERMISSION_HOME_PATH = [
  { permission: PERMISSION_CODES.DASHBOARD, path: '/dashboard' },
  { permission: PERMISSION_CODES.WORK_ORDER, path: '/production/work-order' },
  { permission: PERMISSION_CODES.BATCH, path: '/production/batch' },
  { permission: PERMISSION_CODES.LOADING, path: '/execution/loading' },
  { permission: PERMISSION_CODES.CHECK_IN, path: '/execution/check-in' },
  { permission: PERMISSION_CODES.CHECK_OUT, path: '/execution/check-out' },
  { permission: PERMISSION_CODES.REPAIR, path: '/execution/repair' },
  { permission: PERMISSION_CODES.TRACKING, path: '/execution/tracking' },
  { permission: PERMISSION_CODES.DEVICE, path: '/device' },
  { permission: PERMISSION_CODES.KANBAN, path: '/kanban/line-status' },
]

export function normalizeFunctionList(payload) {
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload?.list)) return payload.list
  if (Array.isArray(payload?.records)) return payload.records
  return []
}

export function functionListToPermissionCodes(functions = []) {
  const codes = new Set()
  normalizeFunctionList(functions).forEach((item) => {
    const rawCode = item?.functionCode || item?.FunctionCode || item
    const functionCode = typeof rawCode === 'string' ? rawCode.trim() : rawCode
    const normalizedCode = typeof functionCode === 'string' ? functionCode.replace(/-/g, '_').toLowerCase() : functionCode
    const upperCode = typeof functionCode === 'string' ? functionCode.toUpperCase() : functionCode
    const permissions = BACKEND_FUNCTION_PERMISSION_MAP[functionCode]
      || BACKEND_FUNCTION_PERMISSION_MAP[normalizedCode]
      || BACKEND_FUNCTION_PERMISSION_MAP[upperCode]
      || []
    permissions.forEach((permission) => codes.add(permission))
  })
  codes.add(PERMISSION_CODES.SYSTEM)
  return [...codes]
}

export function hasBackendPermission(permissionCodes = [], permission) {
  if (!permission || permission === PERMISSION_CODES.SYSTEM) return true
  return permissionCodes.includes(permission)
}

export function firstAccessiblePathByPermissions(permissionCodes = []) {
  return PERMISSION_HOME_PATH.find((item) => hasBackendPermission(permissionCodes, item.permission))?.path || '/system/profile'
}

export function isRtmRole(role) {
  return ROLES.some((item) => item.value === role)
}

export const WORK_ORDER_STATUS = {
  1: { label: '草稿', type: 'info', color: '#909399' },
  2: { label: '已释放', type: 'warning', color: '#d97706' },
  3: { label: '生产中', type: 'primary', color: '#2563eb' },
  4: { label: '已暂停', type: 'warning', color: '#d97706' },
  5: { label: '已完成', type: 'success', color: '#16a34a' },
  6: { label: '已关闭', type: 'info', color: '#6b7280' },
}

export const BATCH_STATUS = {
  1: { label: '待生产', type: 'warning', color: '#b7791f' },
  2: { label: '生产中', type: 'primary', color: '#2563eb' },
  3: { label: '暂停', type: 'warning', color: '#d97706' },
  4: { label: '维修中', type: 'danger', color: '#dc2626' },
  5: { label: '已锁定', type: 'danger', color: '#dc2626' },
  6: { label: '已完成', type: 'success', color: '#16a34a' },
}

export const PROCESS_STATUS = {
  1: { label: '待进站', type: 'info', color: '#64748b' },
  2: { label: '已进站', type: 'primary', color: '#2563eb' },
  3: { label: '已出站', type: 'success', color: '#16a34a' },
  4: { label: '暂停', type: 'warning', color: '#d97706' },
  5: { label: '锁定', type: 'danger', color: '#dc2626' },
  6: { label: '跳过', type: 'info', color: '#6b7280' },
}

export const DEVICE_STATUS = {
  1: { label: '运行', type: 'success', color: '#16a34a' },
  2: { label: '待机', type: 'warning', color: '#d97706' },
  3: { label: '故障', type: 'danger', color: '#dc2626' },
  4: { label: '保养', type: 'warning', color: '#d97706' },
  5: { label: '离线', type: 'info', color: '#6b7280' },
  6: { label: '报废', type: 'danger', color: '#dc2626' },
  running: { label: '运行', type: 'success', color: '#16a34a' },
  standby: { label: '待机', type: 'warning', color: '#d97706' },
  fault: { label: '故障', type: 'danger', color: '#dc2626' },
  maintenance: { label: '保养', type: 'warning', color: '#d97706' },
  offline: { label: '离线', type: 'info', color: '#6b7280' },
  scrapped: { label: '报废', type: 'danger', color: '#dc2626' },
}

export const DEVICE_TYPES = [
  '印刷机',
  'SPI 检测仪',
  '贴片机',
  '回流炉',
  'AOI 检测仪',
]

export function statusMeta(map, value) {
  return map[value] || { label: value || '未知', type: 'info', color: '#909399' }
}
