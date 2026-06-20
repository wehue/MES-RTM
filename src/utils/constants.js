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

export const ROLE_PERMISSIONS = {
  production_manager: [
    PERMISSION_CODES.DASHBOARD,
    PERMISSION_CODES.KANBAN,
    PERMISSION_CODES.WORK_ORDER,
    PERMISSION_CODES.BATCH,
    PERMISSION_CODES.TRACKING,
    PERMISSION_CODES.DEVICE,
    PERMISSION_CODES.SYSTEM,
  ],
  team_leader: [
    PERMISSION_CODES.DASHBOARD,
    PERMISSION_CODES.KANBAN,
    PERMISSION_CODES.LOADING,
    PERMISSION_CODES.CHECK_IN,
    PERMISSION_CODES.CHECK_OUT,
    PERMISSION_CODES.TRACKING,
    PERMISSION_CODES.DEVICE,
    PERMISSION_CODES.SYSTEM,
  ],
  operator: [
    PERMISSION_CODES.DASHBOARD,
    PERMISSION_CODES.KANBAN,
    PERMISSION_CODES.LOADING,
    PERMISSION_CODES.CHECK_IN,
    PERMISSION_CODES.CHECK_OUT,
    PERMISSION_CODES.TRACKING,
    PERMISSION_CODES.SYSTEM,
  ],
  quality_engineer: [
    PERMISSION_CODES.DASHBOARD,
    PERMISSION_CODES.KANBAN,
    PERMISSION_CODES.BATCH,
    PERMISSION_CODES.CHECK_OUT,
    PERMISSION_CODES.REPAIR,
    PERMISSION_CODES.TRACKING,
    PERMISSION_CODES.DEVICE,
    PERMISSION_CODES.SYSTEM,
  ],
  admin: Object.values(PERMISSION_CODES),
}

export const ROLE_HOME_PATH = {
  production_manager: '/production/work-order',
  team_leader: '/execution/loading',
  operator: '/execution/loading',
  quality_engineer: '/execution/repair',
  admin: '/dashboard',
}

export function isRtmRole(role) {
  return role === 'admin' || Boolean(ROLE_PERMISSIONS[role])
}

export function roleHasPermission(role, permission) {
  if (!permission || role === 'admin') return true
  return ROLE_PERMISSIONS[role]?.includes(permission) || false
}

export function firstAccessiblePath(role) {
  return ROLE_HOME_PATH[role] || '/dashboard'
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
