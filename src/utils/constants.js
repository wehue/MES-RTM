export const WORK_ORDER_STATUS = {
  TO_CREATE: { value: 0, label: '待创建', color: '#909399' },
  TO_RELEASE: { value: 1, label: '待释放', color: '#e6a23c' },
  IN_PRODUCTION: { value: 2, label: '生产中', color: '#409eff' },
  PAUSED: { value: 3, label: '暂停', color: '#e6a23c' },
  COMPLETED: { value: 4, label: '已完成', color: '#67c23a' },
  CLOSED: { value: 5, label: '已关闭', color: '#909399' },
}

export const BATCH_STATUS = {
  TO_STATION: { value: 0, label: '待进站', color: '#909399' },
  IN_PRODUCTION: { value: 1, label: '生产中', color: '#409eff' },
  PAUSED: { value: 2, label: '暂停', color: '#e6a23c' },
  IN_REPAIR: { value: 3, label: '维修中', color: '#f56c6c' },
  COMPLETED: { value: 4, label: '已完成', color: '#67c23a' },
  LOCKED: { value: 5, label: '已锁定', color: '#f56c6c' },
}

export const DEVICE_STATUS = {
  RUNNING: { value: 0, label: '运行', color: '#67c23a' },
  STANDBY: { value: 1, label: '待机', color: '#e6a23c' },
  FAULT: { value: 2, label: '故障', color: '#f56c6c' },
  OFFLINE: { value: 3, label: '离线', color: '#909399' },
}

export const DEVICE_TYPES = [
  { value: 'printer', label: '印刷机' },
  { value: 'spi', label: 'SPI检测仪' },
  { value: 'high_speed_mounter', label: '高速贴片机' },
  { value: 'flex_mounter', label: '泛用贴片机' },
  { value: 'reflow', label: '回流炉' },
  { value: 'aoi', label: 'AOI检测仪' },
]

export const DEFECT_TYPES = [
  { value: 'missing', label: '缺件' },
  { value: 'offset', label: '偏移' },
  { value: 'tombstone', label: '立碑' },
  { value: 'bridge', label: '桥接' },
  { value: 'polarity', label: '极性反' },
  { value: 'solder_short', label: '短路' },
  { value: 'solder_insufficient', label: '少锡' },
  { value: 'solder_excess', label: '多锡' },
]

export const INTERCEPT_REASONS = [
  { value: 'yield_below_threshold', label: '直通率低于阈值' },
  { value: 'param_exceed', label: '参数超差' },
  { value: 'defect_detected', label: '检测不良' },
]

export const DISPOSAL_METHODS = [
  { value: 'repair', label: '维修返工' },
  { value: 'unlock', label: '批次解锁' },
  { value: 'force_release', label: '强制放行' },
  { value: 'scrap', label: '批次报废' },
]

export const ROLES = [
  { value: 'operator', label: '操作工' },
  { value: 'team_leader', label: '班组长' },
  { value: 'production_manager', label: '生产主管' },
  { value: 'quality_engineer', label: '质量工程师' },
  { value: 'repairman', label: '维修员' },
  { value: 'admin', label: '管理员' },
]

export function getStatusMap(statusObj) {
  return Object.values(statusObj).reduce((map, item) => {
    map[item.value] = item
    return map
  }, {})
}

export const workOrderStatusMap = getStatusMap(WORK_ORDER_STATUS)
export const batchStatusMap = getStatusMap(BATCH_STATUS)
export const deviceStatusMap = getStatusMap(DEVICE_STATUS)
