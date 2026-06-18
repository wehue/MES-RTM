import { reactive } from 'vue'

const NOW = '2026-05-20 14:30'

export const WORK_ORDER_STATUS_CODE = {
  draft: 1,
  pending: 2,
  released: 2,
  running: 3,
  paused: 4,
  completed: 5,
  closed: 6,
}

export const BATCH_STATUS_CODE = {
  pending: 1,
  running: 2,
  paused: 3,
  repair: 4,
  locked: 5,
  completed: 6,
}

export const PROCESS_STATUS_CODE = {
  wait_in: 1,
  checked_in: 2,
  checked_out: 3,
  paused: 4,
  locked: 5,
  skipped: 6,
}

export const DISPOSAL_TYPE_CODE = {
  repair: 1,
  scrap: 2,
  force: 3,
}

export const VERIFY_STATUS_CODE = {
  pending: 0,
  passed: 1,
  failed: 2,
}

export const lineOptions = ['SMT-A1']

export const products = [
  {
    Id: 1,
    ProductCode: 'PCBA-RTM-100',
    ProductName: '工业控制主板',
    Model: 'PCBA-RTM-100',
    Version: 'V1.0',
    ProductTypeId: 1,
    SpiThreshold: 97,
    AoiThreshold: 96,
    DefaultRouteId: 1,
    model: 'PCBA-RTM-100',
    name: '工业控制主板',
  },
]

export const processRoutes = [
  {
    Id: 1,
    RouteCode: 'ROUTE-SMT-STD',
    RouteName: '标准 SMT 工艺路线',
    ProductTypeId: 1,
    Status: 2,
    id: 'ROUTE-SMT-STD',
    productModel: 'PCBA-RTM-100',
    name: '标准 SMT 工艺路线',
    line: 'SMT-A1',
    steps: [
      { Id: 101, RouteId: 1, OperationId: 1, OperationName: '印刷', Sequence: 10, EquipmentTypeName: '印刷机', StandardTime: 480, step: '印刷', device: '印刷机', standardTime: '8 分钟' },
      { Id: 102, RouteId: 1, OperationId: 2, OperationName: 'SPI 检测', Sequence: 20, EquipmentTypeName: 'SPI 检测仪', StandardTime: 300, step: 'SPI 检测', device: 'SPI 检测仪', standardTime: '5 分钟' },
      { Id: 103, RouteId: 1, OperationId: 3, OperationName: '贴片', Sequence: 30, EquipmentTypeName: '贴片机', StandardTime: 1440, step: '贴片', device: '贴片机', standardTime: '24 分钟' },
      { Id: 104, RouteId: 1, OperationId: 4, OperationName: '回流焊接', Sequence: 40, EquipmentTypeName: '回流炉', StandardTime: 1080, step: '回流焊接', device: '回流炉', standardTime: '18 分钟' },
      { Id: 105, RouteId: 1, OperationId: 5, OperationName: 'AOI 检测', Sequence: 50, EquipmentTypeName: 'AOI 检测仪', StandardTime: 420, step: 'AOI 检测', device: 'AOI 检测仪', standardTime: '7 分钟' },
    ],
  },
]

export function routeOptionsByProduct(productModel) {
  if (!productModel) return []
  return processRoutes.filter((route) => route.productModel === productModel)
}

export function routeById(routeId) {
  return processRoutes.find((route) => route.id === routeId) || processRoutes[0]
}

export const workOrders = reactive([
  {
    Id: 1,
    WorkOrderCode: 'WO20260512001',
    ProductId: 1,
    RouteId: 1,
    PlannedQuantity: 1800,
    DueDate: '2026-05-20 23:59',
    Status: WORK_ORDER_STATUS_CODE.running,
    id: 'WO20260512001',
    productModel: 'PCBA-RTM-100',
    productName: '工业控制主板',
    planned: 1800,
    completed: 1120,
    dueDate: '2026-05-20',
    line: 'SMT-A1',
    routeId: 'ROUTE-SMT-STD',
    routeName: '标准 SMT 工艺路线',
    releasedBatches: 3,
    completedBatches: 1,
    status: 'running',
    creator: '王主管',
    createdAt: '2026-05-20 08:00',
    releasedAt: '2026-05-20 08:20',
    closedAt: '-',
  },
])

export const batches = reactive([
  {
    Id: 1,
    LotCode: 'B20260512005-01',
    WorkOrderId: 1,
    LineId: 1,
    PlannedQuantity: 600,
    CompletedQuantity: 0,
    Status: BATCH_STATUS_CODE.pending,
    EstimatedCompletionTime: '2026-05-20 18:00',
    StartTime: null,
    EndTime: null,
    id: 'B20260512005-01',
    workOrderId: 'WO20260512001',
    productModel: 'PCBA-RTM-100',
    productName: '工业控制主板',
    line: 'SMT-A1',
    planned: 600,
    completed: 0,
    defective: 0,
    scrap: 0,
    currentStep: '-',
    eta: '2026-05-20 18:00',
    onlineAt: '-',
    status: 'pending',
    lockReason: '-',
    owner: '张工',
    autoLocked: false,
  },
  {
    Id: 2,
    LotCode: 'B20260512001-01',
    WorkOrderId: 1,
    LineId: 1,
    PlannedQuantity: 600,
    CompletedQuantity: 520,
    Status: BATCH_STATUS_CODE.running,
    EstimatedCompletionTime: '2026-05-20 16:20',
    StartTime: '2026-05-20 08:42',
    EndTime: null,
    id: 'B20260512001-01',
    workOrderId: 'WO20260512001',
    productModel: 'PCBA-RTM-100',
    productName: '工业控制主板',
    line: 'SMT-A1',
    planned: 600,
    completed: 520,
    defective: 7,
    scrap: 1,
    currentStep: 'AOI 检测',
    eta: '2026-05-20 16:20',
    onlineAt: '2026-05-20 08:42',
    status: 'running',
    lockReason: '-',
    owner: '张工',
    autoLocked: false,
  },
  {
    Id: 3,
    LotCode: 'B20260512001-02',
    WorkOrderId: 1,
    LineId: 1,
    PlannedQuantity: 600,
    CompletedQuantity: 600,
    Status: BATCH_STATUS_CODE.completed,
    EstimatedCompletionTime: '2026-05-20 12:10',
    StartTime: '2026-05-20 06:20',
    EndTime: '2026-05-20 12:10',
    id: 'B20260512001-02',
    workOrderId: 'WO20260512001',
    productModel: 'PCBA-RTM-100',
    productName: '工业控制主板',
    line: 'SMT-A1',
    planned: 600,
    completed: 600,
    defective: 0,
    scrap: 0,
    currentStep: '已下线',
    eta: '2026-05-20 12:10',
    onlineAt: '2026-05-20 06:20',
    status: 'completed',
    lockReason: '-',
    owner: '张工',
    autoLocked: false,
  },
])

export const lines = reactive([
  {
    Id: 1,
    LineCode: 'SMT-A1',
    LineName: 'SMT-A1 标准线',
    Workshop: '一车间',
    id: 'SMT-A1',
    name: 'SMT-A1 标准线',
    workshop: '一车间',
    workOrder: 'WO20260512001',
    batch: 'B20260512001-01',
    productModel: 'PCBA-RTM-100',
    productName: '工业控制主板',
    planned: 1800,
    completed: 1120,
    status: 'running',
    devices: ['running', 'running', 'standby', 'running', 'running'],
    oee: 86.4,
    dueTime: '18:00',
    alerts: 0,
  },
])

export const devices = reactive([
  { Id: 1, EquipmentCode: 'PRT-A1-01', EquipmentName: 'A1 印刷机', EquipmentTypeId: 1, LineId: 1, Status: 1, id: 'PRT-A1-01', name: 'A1 印刷机', type: '印刷机', line: 'SMT-A1', status: 'running', batch: 'B20260512001-01', duration: '5h 12m', oee: 88, output: 1120, throwRate: '-', fault: '-' },
  { Id: 2, EquipmentCode: 'SPI-A1-01', EquipmentName: 'A1 SPI', EquipmentTypeId: 2, LineId: 1, Status: 1, id: 'SPI-A1-01', name: 'A1 SPI', type: 'SPI 检测仪', line: 'SMT-A1', status: 'running', batch: 'B20260512001-01', duration: '4h 50m', oee: 86, output: 1116, throwRate: '-', fault: '-' },
  { Id: 3, EquipmentCode: 'MNT-A1-01', EquipmentName: 'A1 贴片机', EquipmentTypeId: 3, LineId: 1, Status: 2, id: 'MNT-A1-01', name: 'A1 贴片机', type: '贴片机', line: 'SMT-A1', status: 'standby', batch: '-', duration: '-', oee: 82, output: 1100, throwRate: '0.18%', fault: '-' },
  { Id: 4, EquipmentCode: 'RFL-A1-01', EquipmentName: 'A1 回流炉', EquipmentTypeId: 4, LineId: 1, Status: 1, id: 'RFL-A1-01', name: 'A1 回流炉', type: '回流炉', line: 'SMT-A1', status: 'running', batch: 'B20260512001-01', duration: '3h 40m', oee: 84, output: 1088, throwRate: '-', fault: '-' },
  { Id: 5, EquipmentCode: 'AOI-A1-01', EquipmentName: 'A1 AOI', EquipmentTypeId: 5, LineId: 1, Status: 1, id: 'AOI-A1-01', name: 'A1 AOI', type: 'AOI 检测仪', line: 'SMT-A1', status: 'running', batch: 'B20260512001-01', duration: '2h 10m', oee: 87, output: 528, throwRate: '-', fault: '-' },
])

export const routeSteps = processRoutes[0].steps

export const inspectionThresholds = {
  SPI: 97,
  AOI: 96,
}

export function inspectionTypeByStep(step = '') {
  if (step.includes('SPI')) return 'SPI'
  if (step.includes('AOI')) return 'AOI'
  return ''
}

export function isInspectionProcess(step = '') {
  return Boolean(inspectionTypeByStep(step))
}

export function getInspectionThreshold(step = '') {
  const type = inspectionTypeByStep(step)
  if (!type) return 0
  const product = products[0]
  if (type === 'SPI') return product?.SpiThreshold ?? inspectionThresholds.SPI
  if (type === 'AOI') return product?.AoiThreshold ?? inspectionThresholds.AOI
  return inspectionThresholds[type] || 0
}

export const bomItems = [
  { material: 'R0603-10K', position: 'R1,R2,R3', qty: 3, spec: '0603 10K 1%', packageType: '0603', substitute: '-' },
  { material: 'C0402-10uF', position: 'C1,C4', qty: 2, spec: '0402 10uF 16V', packageType: '0402', substitute: 'C0402-10uF-B' },
  { material: 'U-QFN32-MCU', position: 'U1', qty: 1, spec: 'QFN32 MCU', packageType: 'QFN32', substitute: '-' },
  { material: 'LED0603-G', position: 'D1,D2', qty: 2, spec: '0603 Green', packageType: '0603', substitute: '-' },
]

const loadingTaskTemplate = [
  { station: 'F-001', material: 'R0603-10K', spec: '0603 10K 1%', packageType: '0603', required: 3000, loaded: 0, status: '待上料', substitute: '-' },
  { station: 'F-002', material: 'C0402-10uF', spec: '0402 10uF 16V', packageType: '0402', required: 2000, loaded: 0, status: '待上料', substitute: 'C0402-10uF-B' },
  { station: 'F-003', material: 'U-QFN32-MCU', spec: 'QFN32 MCU', packageType: 'QFN32', required: 600, loaded: 0, status: '待上料', substitute: '-' },
  { station: 'F-004', material: 'LED0603-G', spec: '0603 Green', packageType: '0603', required: 1200, loaded: 0, status: '待上料', substitute: '-' },
]

function cloneLoadingTasks(overrides = {}) {
  return loadingTaskTemplate.map((item) => ({ ...item, loadingRecords: [], ...overrides[item.station] }))
}

export const batchLoadingState = reactive({
  'B20260512005-01': cloneLoadingTasks({
    'F-001': { loaded: 3000, status: '已齐套' },
    'F-002': { loaded: 1200, status: '待补料' },
    'F-003': { loaded: 600, status: '已齐套' },
    'F-004': { loaded: 0, status: '待上料' },
  }),
  'B20260512001-01': cloneLoadingTasks({
    'F-001': { loaded: 3000, status: '已齐套' },
    'F-002': { loaded: 2000, status: '已齐套' },
    'F-003': { loaded: 600, status: '已齐套' },
    'F-004': { loaded: 1200, status: '已齐套' },
  }),
})

export const batchProcessState = reactive({
  'B20260512001-01': [
    { step: 'AOI 检测', status: 'checked_in', inAt: '2026-05-20 13:10', outAt: '-', qty: 528, goodQty: 520, badQty: 7, scrapQty: 1, deviceId: 'AOI-A1-01', operator: '张工' },
  ],
  'B20260512001-02': [
    { step: 'AOI 检测', status: 'checked_out', inAt: '2026-05-20 11:30', outAt: '2026-05-20 12:10', qty: 600, goodQty: 600, badQty: 0, scrapQty: 0, deviceId: 'AOI-A1-01', operator: '张工' },
  ],
})

export const batchExecutionState = reactive({
  'B20260512005-01': {
    pendingQty: 0,
    currentInQty: 0,
    currentInAt: '-',
    currentDeviceId: '',
    currentOperator: '',
  },
  'B20260512001-01': {
    pendingQty: 0,
    currentInQty: 528,
    currentInAt: '2026-05-20 13:10',
    currentDeviceId: 'AOI-A1-01',
    currentOperator: '张工',
  },
  'B20260512001-02': {
    pendingQty: 0,
    currentInQty: 0,
    currentInAt: '-',
    currentDeviceId: '',
    currentOperator: '',
  },
})

export const batchTraceState = reactive({
  'B20260512005-01': [
    { id: 'B20260512005-01-1', time: '2026-05-20 14:20', type: 'status', step: '-', message: '批次已创建，等待投产生成首道工序' },
  ],
  'B20260512001-01': [
    { id: 'B20260512001-01-1', time: '2026-05-20 13:10', type: 'checkin', step: 'AOI 检测', qty: 528, deviceId: 'AOI-A1-01', operator: '张工', message: 'AOI 检测已进站' },
  ],
  'B20260512001-02': [
    { id: 'B20260512001-02-1', time: '2026-05-20 12:10', type: 'status', step: '已下线', qty: 600, message: '批次全部工序完成' },
  ],
})

export const batchLoadingRequestState = reactive({})

export function getBatchLoadingTasks(batchId) {
  if (!batchId || !findBatch(batchId)) return []
  if (!batchLoadingState[batchId]) {
    batchLoadingState[batchId] = cloneLoadingTasks()
  }
  return batchLoadingState[batchId]
}

export function fillBatchMaterial(batchId, payload) {
  const tasks = getBatchLoadingTasks(batchId)
  const target = tasks.find((item) => item.station === payload.station)
  if (!target) {
    return { ok: false, message: '站位不存在。' }
  }
  const scannedCode = String(payload.materialCode || '').trim()
  if (!scannedCode) {
    return { ok: false, message: '物料条码不能为空。' }
  }
  const allowedMaterials = [target.material]
  if (target.substitute && target.substitute !== '-') {
    allowedMaterials.push(...String(target.substitute).split(/[、,，/]/).map((item) => item.trim()).filter(Boolean))
  }
  const matchedMaterial = allowedMaterials.find((material) => scannedCode === material || scannedCode.startsWith(`${material}#`))
  if (!matchedMaterial) {
    return {
      ok: false,
      message: `物料不匹配：站位 ${target.station} 需要 ${target.material}${target.substitute && target.substitute !== '-' ? `，允许替代料 ${target.substitute}` : ''}。`,
    }
  }
  const addedQty = Math.max(Number(payload.loaded) || 0, 0)
  if (addedQty <= 0) {
    return { ok: false, message: '上料数量必须大于 0。' }
  }
  target.loaded = Math.min(target.loaded + addedQty, target.required)
  target.status = target.loaded >= target.required ? '已齐套' : '待补料'
  target.scannedMaterial = payload.materialCode
  target.matchedMaterial = matchedMaterial
  target.lastLoadedAt = payload.loadedAt
  target.operator = payload.operator
  target.lastAddedQty = addedQty
  target.loadingRecords = [
    {
      materialCode: payload.materialCode,
      addedQty,
      loadedAt: payload.loadedAt,
      operator: payload.operator,
    },
    ...(target.loadingRecords || []),
  ]
  if (validateBatchLoading(batchId).pass) {
    clearBatchLoadingRequest(batchId)
  }
  return { ok: true, task: target }
}

export function getBatchLoadingSummary(batchId) {
  const tasks = getBatchLoadingTasks(batchId)
  const finished = tasks.filter((item) => item.loaded >= item.required).length
  return {
    total: tasks.length,
    finished,
    percentage: tasks.length ? Math.round((finished / tasks.length) * 100) : 0,
  }
}

export function validateBatchLoading(batchId) {
  const tasks = getBatchLoadingTasks(batchId)
  const missing = tasks.filter((item) => item.loaded < item.required)
  return {
    pass: missing.length === 0,
    missing,
    message: missing.length === 0 ? 'BOM 上料校验通过。' : `仍有 ${missing.length} 个站位未齐套。`,
  }
}

export function requestBatchLoading(batchId, reason = '进站 BOM 校验未通过') {
  const batch = findBatch(batchId)
  if (!batch) return { ok: false, message: '批次不存在。' }
  batchLoadingRequestState[batchId] = {
    batchId,
    reason,
    requestedAt: nowText(),
  }
  return { ok: true, request: batchLoadingRequestState[batchId] }
}

export function clearBatchLoadingRequest(batchId) {
  delete batchLoadingRequestState[batchId]
}

export function hasBatchLoadingRequest(batchId) {
  return Boolean(batchLoadingRequestState[batchId])
}

export const processTimeline = [
  { step: '印刷', inAt: '08:42', outAt: '09:02', qty: 600, bad: 0, operator: '张工', device: 'PRT-A1-01', result: '通过' },
  { step: 'SPI 检测', inAt: '09:05', outAt: '09:28', qty: 596, bad: 4, operator: '张工', device: 'SPI-A1-01', result: '通过' },
  { step: '贴片', inAt: '09:33', outAt: '11:40', qty: 590, bad: 6, operator: '周工', device: 'MNT-A1-01', result: '通过' },
  { step: '回流焊接', inAt: '11:50', outAt: '12:20', qty: 586, bad: 4, operator: '周工', device: 'RFL-A1-01', result: '通过' },
  { step: 'AOI 检测', inAt: '13:10', outAt: '-', qty: 528, bad: 7, operator: '张工', device: 'AOI-A1-01', result: '已进站' },
]

export const loadingTasks = getBatchLoadingTasks('B20260512005-01')

export const repairTasks = reactive([])

export const alerts = reactive([
  { id: 1, level: 'warning', type: '流程提醒', title: 'B20260512005-01 投产后将在进站时校验 BOM 齐套', target: '/production/batch', time: '14:20' },
])

export const messages = reactive([
  { id: 1, category: '生产通知', title: '批次待投产', content: 'B20260512005-01 已创建，投产后生成首道工序待进站。', time: '2026-05-20 14:20', unread: true, link: '/production/batch' },
])

export const qualityTrend = [
  { hour: '08:00', spi: 98.2, aoi: 97.5, batchYield: 98.8 },
  { hour: '10:00', spi: 97.9, aoi: 96.8, batchYield: 98.1 },
  { hour: '12:00', spi: 97.1, aoi: 96.9, batchYield: 97.8 },
  { hour: '14:00', spi: 98.0, aoi: 97.6, batchYield: 98.5 },
]

export const defectDistribution = [
  { name: '偏移', value: 4 },
  { name: '少锡', value: 3 },
]

export function percent(done, total) {
  if (!total) return 0
  return Math.round((done / total) * 100)
}

export function getBatchRouteProgress(batchId) {
  const batch = findBatch(batchId)
  if (!batch) return 0
  const route = findBatchRoute(batch)
  const totalSteps = route?.steps?.length || 0
  if (!totalSteps) return 0
  if (batch.status === 'completed') return 100

  const currentIndex = route.steps.findIndex((item) => item.step === batch.currentStep)
  if (currentIndex < 0) return 0
  return Math.max(0, Math.min(100, Math.round((currentIndex / totalSteps) * 100)))
}

export function dashboardMetrics() {
  const totalOrders = workOrders.length
  const inProcessBatches = batches.filter((item) => ['running', 'paused', 'repair', 'locked'].includes(item.status)).length
  const planTotal = workOrders.reduce((sum, item) => sum + item.planned, 0)
  const completedTotal = workOrders.reduce((sum, item) => sum + item.completed, 0)
  const defective = batches.reduce((sum, item) => sum + item.defective, 0)
  return {
    totalOrders,
    inProcessBatches,
    firstPassYield: Number((100 - (defective / Math.max(completedTotal, 1)) * 100).toFixed(1)),
    planCompletion: percent(completedTotal, planTotal),
  }
}

function nowText() {
  return NOW
}

function setWorkOrderStatus(order, status) {
  if (!order) return
  order.status = status
  order.Status = WORK_ORDER_STATUS_CODE[status] || status
}

function setBatchStatus(batch, status) {
  if (!batch) return
  batch.status = status
  batch.Status = BATCH_STATUS_CODE[status] || status
}

function setBatchCompletedQuantity(batch, qty) {
  if (!batch) return
  batch.completed = qty
  batch.CompletedQuantity = qty
}

function setBatchTiming(batch, payload = {}) {
  if (!batch) return
  if (payload.estimatedCompletionTime !== undefined) {
    batch.eta = payload.estimatedCompletionTime || '-'
    batch.EstimatedCompletionTime = payload.estimatedCompletionTime || null
  }
  if (payload.startTime !== undefined) {
    batch.onlineAt = payload.startTime || '-'
    batch.StartTime = payload.startTime || null
  }
  if (payload.endTime !== undefined) {
    batch.EndTime = payload.endTime || null
  }
}

function findBatch(batchId) {
  return batches.find((item) => item.id === batchId || item.LotCode === batchId || item.Id === batchId) || null
}

function findBatchRoute(batch) {
  if (!batch) return null
  const workOrder = workOrders.find((item) => item.id === batch.workOrderId || item.Id === batch.WorkOrderId)
  if (!workOrder) return null
  return processRoutes.find((item) => item.id === workOrder.routeId || item.Id === workOrder.RouteId) || null
}

function ensureBatchExecutionState(batchId) {
  if (!batchExecutionState[batchId]) {
    batchExecutionState[batchId] = {
      pendingQty: 0,
      currentInQty: 0,
      currentInAt: '-',
      currentDeviceId: '',
      currentOperator: '',
    }
  }
  return batchExecutionState[batchId]
}

function ensureBatchTraceState(batchId) {
  if (!batchTraceState[batchId]) {
    batchTraceState[batchId] = []
  }
  return batchTraceState[batchId]
}

function ensureBatchProcessState(batchId) {
  if (!batchProcessState[batchId]) {
    batchProcessState[batchId] = []
  }
  return batchProcessState[batchId]
}

function pushBatchTrace(batchId, payload) {
  const trace = ensureBatchTraceState(batchId)
  trace.unshift({
    id: `${batchId}-${trace.length + 1}`,
    time: payload.time || nowText(),
    ...payload,
  })
}

function createProcessRecord(batch, step, status = 'wait_in', qty = 0) {
  const records = ensureBatchProcessState(batch.id)
  const route = findBatchRoute(batch)
  const routeStep = route?.steps?.find((item) => item.step === step || item.OperationName === step)
  const record = {
    LotId: batch.Id,
    RouteStepId: routeStep?.Id || null,
    Status: PROCESS_STATUS_CODE[status] || status,
    StationInTime: '-',
    StationInQuantity: qty,
    StationOutTime: '-',
    FinishedQuantity: 0,
    DefectQuantity: 0,
    step,
    status,
    inAt: '-',
    outAt: '-',
    qty,
    goodQty: 0,
    badQty: 0,
    scrapQty: 0,
    deviceId: '',
    operator: '',
  }
  records.push(record)
  batch.currentStep = step
  return record
}

export function getBatchProcessRecords(batchId) {
  return ensureBatchProcessState(batchId)
}

export function getCurrentProcess(batchId) {
  const records = ensureBatchProcessState(batchId)
  return records[records.length - 1] || null
}

export function getCurrentProcessStatus(batchId) {
  return getCurrentProcess(batchId)?.status || ''
}

export function releaseBatchToFirstProcess(batchId) {
  const batch = findBatch(batchId)
  if (!batch) return { ok: false, message: '批次不存在。' }
  if (batch.status !== 'pending') return { ok: false, message: '只有待生产批次可以投产。' }

  const route = findBatchRoute(batch)
  const firstStep = route?.steps?.[0]?.step
  if (!firstStep) return { ok: false, message: '未配置工艺路线。' }

  const state = ensureBatchExecutionState(batchId)
  createProcessRecord(batch, firstStep, 'wait_in', batch.planned)
  state.pendingQty = batch.planned
  setBatchStatus(batch, 'running')
  pushBatchTrace(batchId, {
    type: 'status',
    step: firstStep,
    qty: batch.planned,
    message: `投产成功，生成首道工序 ${firstStep} 待进站`,
    time: nowText(),
  })
  return { ok: true, batch, process: getCurrentProcess(batchId) }
}

export function getBatchPendingQty(batchId) {
  return ensureBatchExecutionState(batchId).pendingQty || 0
}

export function getBatchCurrentInQty(batchId) {
  return ensureBatchExecutionState(batchId).currentInQty || 0
}

export function getBatchTrace(batchId) {
  return ensureBatchTraceState(batchId)
}

export function submitBatchCheckIn(batchId, payload) {
  const batch = findBatch(batchId)
  if (!batch) return { ok: false, message: '批次不存在。' }

  const process = getCurrentProcess(batchId)
  if (!process || process.status !== 'wait_in') {
    return { ok: false, message: '当前工序不是待进站状态。' }
  }

  const state = ensureBatchExecutionState(batchId)
  const qty = Math.max(Number(payload.qty) || 0, 0)
  if (qty <= 0) return { ok: false, message: '进站数量必须大于 0。' }

  state.pendingQty = 0
  state.currentInQty = qty
  state.currentInAt = payload.inAt || nowText()
  state.currentDeviceId = payload.deviceId || ''
  state.currentOperator = payload.operator || ''

  process.status = 'checked_in'
  process.Status = PROCESS_STATUS_CODE.checked_in
  process.inAt = state.currentInAt
  process.StationInTime = state.currentInAt
  process.qty = qty
  process.StationInQuantity = qty
  process.deviceId = state.currentDeviceId
  process.operator = state.currentOperator

  if (batch.onlineAt === '-') {
    setBatchTiming(batch, { startTime: state.currentInAt })
  }
  setBatchStatus(batch, 'running')

  pushBatchTrace(batchId, {
    type: 'checkin',
    step: batch.currentStep,
    qty,
    deviceId: state.currentDeviceId,
    operator: state.currentOperator,
    message: `${batch.currentStep} 已进站`,
    time: state.currentInAt,
  })

  return { ok: true, batch }
}

export function submitBatchCheckOut(batchId, payload) {
  const batch = findBatch(batchId)
  if (!batch) return { ok: false, message: '批次不存在。' }

  const process = getCurrentProcess(batchId)
  if (!process || process.status !== 'checked_in') {
    return { ok: false, message: '当前工序不是已进站状态，不能出站。' }
  }

  const state = ensureBatchExecutionState(batchId)
  const isInspection = isInspectionProcess(batch.currentStep)

  if (isInspection) {
    const passRate = Math.max(0, Math.min(100, Number(payload.passRate) || 0))
    const threshold = getInspectionThreshold(batch.currentStep)
    const action = passRate >= threshold ? 'normal' : payload.qualityAction

    if (passRate < threshold && !['force', 'lock'].includes(action)) {
      return { ok: false, message: `检测通过率 ${passRate}% 低于阈值 ${threshold}%，请选择强制出站或批次锁定。` }
    }
    if (passRate < threshold && action === 'force' && !String(payload.remark || '').trim()) {
      return { ok: false, message: '请填写强制出站原因。' }
    }
    if (passRate < threshold && action === 'lock' && !String(payload.remark || '').trim()) {
      return { ok: false, message: '请填写批次锁定原因。' }
    }

    process.passRate = passRate
    process.threshold = threshold
    process.qualityAction = action
    process.operator = payload.operator || process.operator
    process.IsNormal = passRate >= threshold || action === 'force'
    process.DisposalType = action === 'force' ? DISPOSAL_TYPE_CODE.force : null
    process.DisposalRemark = payload.remark || ''
    if (inspectionTypeByStep(batch.currentStep) === 'SPI') process.SpiPassRate = passRate
    if (inspectionTypeByStep(batch.currentStep) === 'AOI') process.AoiPassRate = passRate

    if (passRate < threshold && action === 'lock') {
      process.status = 'locked'
      process.Status = PROCESS_STATUS_CODE.locked
      process.outAt = payload.outAt || nowText()
      process.StationOutTime = process.outAt
      setBatchStatus(batch, 'locked')
      batch.lockReason = payload.remark || `${batch.currentStep} 通过率 ${passRate}% 低于阈值 ${threshold}%`
      batch.autoLocked = true
      pushBatchTrace(batchId, {
        type: 'quality',
        step: batch.currentStep,
        passRate,
        threshold,
        operator: payload.operator || '',
        message: `${batch.currentStep} 通过率 ${passRate}% 低于阈值 ${threshold}%，批次已锁定，等待质量评审`,
        time: process.outAt,
      })
      return { ok: true, batch, nextStep: batch.currentStep, status: 'locked' }
    }

    const outQty = state.currentInQty
    process.status = 'checked_out'
    process.Status = PROCESS_STATUS_CODE.checked_out
    process.outAt = payload.outAt || nowText()
    process.StationOutTime = process.outAt
    process.goodQty = outQty
    process.badQty = 0
    process.scrapQty = 0
    process.FinishedQuantity = outQty
    process.DefectQuantity = 0

    pushBatchTrace(batchId, {
      type: 'checkout',
      step: batch.currentStep,
      qty: outQty,
      passRate,
      threshold,
      operator: payload.operator || '',
      message: passRate >= threshold
        ? `${batch.currentStep} 通过率 ${passRate}% 达到阈值，正常出站`
        : `${batch.currentStep} 通过率 ${passRate}% 低于阈值 ${threshold}%，已强制出站`,
      time: process.outAt,
    })

    state.currentInQty = 0
    state.currentDeviceId = ''
    state.currentOperator = ''

    const route = findBatchRoute(batch)
    const stepIndex = route ? route.steps.findIndex((item) => item.step === batch.currentStep) : -1
    const nextStep = route && stepIndex >= 0 && stepIndex < route.steps.length - 1 ? route.steps[stepIndex + 1].step : ''

    if (nextStep) {
      createProcessRecord(batch, nextStep, 'wait_in', outQty)
      state.pendingQty = outQty
      pushBatchTrace(batchId, {
        type: 'status',
        step: nextStep,
        qty: outQty,
        message: `流转至下一工序 ${nextStep}，等待进站`,
        time: process.outAt,
      })
      return { ok: true, batch, nextStep, status: 'wait_in' }
    }

    batch.currentStep = '已下线'
    setBatchStatus(batch, 'completed')
    setBatchCompletedQuantity(batch, outQty)
    setBatchTiming(batch, { endTime: process.outAt })
    state.pendingQty = 0
    pushBatchTrace(batchId, {
      type: 'status',
      step: '已下线',
      qty: outQty,
      message: '批次全部工序完成',
      time: process.outAt,
    })
    return { ok: true, batch, nextStep: '', status: 'completed' }
  }

  const goodQty = Math.max(Number(payload.goodQty) || 0, 0)
  const badQty = Math.max(Number(payload.badQty) || 0, 0)
  const scrapQty = Math.max(Number(payload.scrapQty) || 0, 0)
  const totalQty = goodQty + badQty + scrapQty
  if (totalQty !== state.currentInQty) {
    return { ok: false, message: `数量不匹配：进站数量 ${state.currentInQty}，出站合计 ${totalQty}。` }
  }

  setBatchCompletedQuantity(batch, goodQty)
  batch.defective = badQty
  batch.scrap = scrapQty

  process.status = 'checked_out'
  process.Status = PROCESS_STATUS_CODE.checked_out
  process.outAt = payload.outAt || nowText()
  process.StationOutTime = process.outAt
  process.goodQty = goodQty
  process.badQty = badQty
  process.scrapQty = scrapQty
  process.FinishedQuantity = goodQty
  process.DefectQuantity = badQty
  process.IsNormal = badQty === 0 && scrapQty === 0
  process.DisposalType = payload.disposal ? DISPOSAL_TYPE_CODE[payload.disposal] : null
  process.DisposalRemark = payload.remark || ''
  process.operator = payload.operator || process.operator

  pushBatchTrace(batchId, {
    type: 'checkout',
    step: batch.currentStep,
    qty: totalQty,
    goodQty,
    badQty,
    scrapQty,
    operator: payload.operator || '',
    message: `${batch.currentStep} 已出站`,
    time: process.outAt,
  })

  state.currentInQty = 0
  state.currentDeviceId = ''
  state.currentOperator = ''

  if (badQty > 0 && payload.disposal === 'repair') {
    setBatchStatus(batch, 'repair')
    repairTasks.unshift({
      LotId: batch.Id,
      RouteStepId: process.RouteStepId,
      Status: 0,
      RepairQuantity: badQty,
      RepairedQuantity: 0,
      ScrapQuantity: 0,
      RepairDescription: payload.remark || '待维修确认',
      batchId: batch.id,
      productModel: batch.productModel,
      line: batch.line,
      process: batch.currentStep,
      badQty,
      defect: payload.remark || '待维修确认',
      reportedAt: process.outAt,
      overdue: false,
      status: '待维修',
    })
    pushBatchTrace(batchId, {
      type: 'repair',
      step: batch.currentStep,
      badQty,
      message: `已生成维修任务，数量 ${badQty}`,
      time: process.outAt,
    })
    return { ok: true, batch, nextStep: batch.currentStep, status: 'repair' }
  }

  const route = findBatchRoute(batch)
  const stepIndex = route ? route.steps.findIndex((item) => item.step === batch.currentStep) : -1
  const nextStep = route && stepIndex >= 0 && stepIndex < route.steps.length - 1 ? route.steps[stepIndex + 1].step : ''

  if (nextStep) {
    createProcessRecord(batch, nextStep, 'wait_in', goodQty)
    state.pendingQty = goodQty
    pushBatchTrace(batchId, {
      type: 'status',
      step: nextStep,
      qty: goodQty,
      message: `流转至下一工序 ${nextStep}，等待进站`,
      time: process.outAt,
    })
    return { ok: true, batch, nextStep, status: 'wait_in' }
  }

  batch.currentStep = '已下线'
  setBatchStatus(batch, 'completed')
  setBatchTiming(batch, { endTime: process.outAt })
  state.pendingQty = 0
  pushBatchTrace(batchId, {
    type: 'status',
    step: '已下线',
    qty: goodQty,
    message: '批次全部工序完成',
    time: process.outAt,
  })
  return { ok: true, batch, nextStep: '', status: 'completed' }
}

export function submitRepairResult(batchId, payload) {
  const batch = findBatch(batchId)
  if (!batch) return { ok: false, message: '批次不存在。' }

  const task = repairTasks.find((item) => item.batchId === batchId && item.status !== '已完成')
  const state = ensureBatchExecutionState(batchId)
  const repairQty = Math.max(Number(payload.repairQty) || 0, 0)
  const scrapQty = Math.max(Number(payload.scrapQty) || 0, 0)

  if (task) {
    task.status = '已完成'
    task.Status = 2
    task.result = payload.result
    task.RepairResult = payload.result === 'repair_pass' ? 1 : 2
    task.RepairedQuantity = repairQty
    task.ScrapQuantity = scrapQty
    task.completedAt = payload.completedAt || nowText()
    task.RepairEndTime = task.completedAt
  }

  if (payload.result === 'repair_pass') {
    setBatchStatus(batch, 'running')
    state.pendingQty = repairQty
    const process = getCurrentProcess(batchId)
    if (process) process.status = 'wait_in'
    pushBatchTrace(batchId, {
      type: 'repair',
      step: batch.currentStep,
      qty: repairQty,
      message: `维修完成，返回 ${batch.currentStep} 待进站`,
      time: payload.completedAt || nowText(),
    })
    return { ok: true, batch, status: 'wait_in' }
  }

  batch.scrap += scrapQty
  setBatchStatus(batch, 'completed')
  state.pendingQty = 0
  pushBatchTrace(batchId, {
    type: 'repair',
    step: batch.currentStep,
    scrapQty,
    message: '维修结束，批次关闭',
    time: payload.completedAt || nowText(),
  })
  return { ok: true, batch, status: 'completed' }
}
