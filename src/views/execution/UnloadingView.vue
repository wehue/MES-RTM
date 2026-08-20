<script setup>
import { computed, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Clock,
  Delete,
  Document,
  Download,
  Goods,
  Monitor,
  Plus,
  Search,
  Tickets,
  Top,
  View,
  WarningFilled,
  CircleCheckFilled,
} from '@element-plus/icons-vue'
import SectionCard from '@/components/SectionCard.vue'
import { getOperators } from '@/api/user'
import {
  getLoadingStations as getLoadingStationsApi,
} from '@/api/materialLot'
import {
  batchCreateUnloadingRecords,
  getPendingUnloadingLots,
  getStationUnloadingRecords as getStationUnloadingRecordsApi,
  getUnloadingLoadingRecords as getUnloadingLoadingRecordsApi,
} from '@/api/unloading'
import { UNLOAD_REASON } from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { formatDateTime } from '@/utils/format'

const router = useRouter()
const userStore = useUserStore()

// ==================== Tab 切换 ====================
const activeTab = ref('unloading')

// ==================== 操作人列表 ====================
const operatorList = ref([])

async function loadOperatorList() {
  try {
    const data = await getOperators()
    operatorList.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.warn('[Unloading] 操作人列表接口失败：', error)
    operatorList.value = []
    ElMessage.warning('操作人列表接口暂不可用，请稍后重试')
  }
}

function getOperatorLabel(user) {
  if (!user) return '-'
  const name = user.fullName || user.FullName || user.username || user.Username || ''
  const position = user.position || user.Position || ''
  const dept = user.department || user.Department || ''
  return [name, position, dept].filter(Boolean).join(' / ')
}

// ==================== 已投产批次 + 批次工站（与上料管理一致） ====================
// ① 选中的已投产批次（Tab1 下料操作）
const selectedBatchId = ref(null)
// ② 选中的工站（Tab1 下料操作）
const selectedStationId = ref(null)

// 归一化待下料批次字段（对齐 GET /api/unloading/pending-lots 返回 6 字段：id/lotCode/productName/workOrderCode/lineName/currentOperationName）
// 后端批次状态筛选：生产中(2)或已完成(6) + 存在未下料完毕的上料记录
function normalizePendingLot(item) {
  if (!item) return null
  const id = item.id ?? item.Id ?? item.lotId ?? item.LotId
  if (id == null) return null
  return {
    ...item,
    id,
    lotCode: item.lotCode ?? item.LotCode ?? '',
    productName: item.productName ?? item.ProductName ?? '',
    workOrderCode: item.workOrderCode ?? item.WorkOrderCode ?? '',
    lineName: item.lineName ?? item.LineName ?? '',
    // 前端展示 currentOperation：已进站工序名（后端 currentOperationName）
    currentOperation: item.currentOperation
      ?? item.currentOperationName
      ?? item.CurrentOperation
      ?? item.CurrentOperationName
      ?? '',
  }
}

// 批次列表（Tab1 与 Tab2 共享）
const batchList = ref([])
const batchListLoading = ref(false)

// Tab1 下料操作：当前批次的工站列表
const batchStations = ref([])
const batchStationsLoading = ref(false)

// 归一化下料工站选项（对齐 GET /api/unloading/stations 返回 5 字段：id/stationCode/stationName/operationName/equipmentTypeName）
function normalizeUnloadingStation(item, index) {
  if (!item) return null
  const id = item.id ?? item.Id ?? item.stationId ?? item.StationId
  if (id == null) return null
  const stationCode = item.stationCode ?? item.StationCode ?? '-'
  const stationName = item.stationName ?? item.StationName ?? '-'
  const operationName = item.operationName ?? item.OperationName ?? '-'
  const equipmentTypeName = item.equipmentTypeName ?? item.EquipmentTypeName ?? '-'
  return {
    ...item,
    id,
    // 注：后端直接传的"下料工站下拉"主键 id，前端 routeStepId / stationId 历史字段统一等于 id
    routeStepId: id,
    stationId: id,
    equipmentId: item.equipmentId ?? item.EquipmentId ?? id,
    equipmentTypeId: item.equipmentTypeId ?? item.EquipmentTypeId,
    sequence: item.sequence ?? item.Sequence ?? (index + 1) * 10,
    stationCode,
    stationName,
    operationName,
    equipmentCode: item.equipmentCode ?? item.EquipmentCode ?? stationCode,
    equipmentName: item.equipmentName ?? item.EquipmentName ?? stationName,
    equipmentTypeName,
  }
}

// 从响应体中取出数组 payload（兼容多种包装结构）
function extractListPayload(data) {
  if (Array.isArray(data)) return data
  if (data && typeof data === 'object') {
    const arr = data.list
      || data.content
      || data.records
      || data.rows
      || data.items
      || data.data
      || (Array.isArray(data.Data) ? data.Data : null)
    if (Array.isArray(arr)) return arr
  }
  return []
}

// ① 加载已投产（待上料）批次列表（真实 API：GET /api/loading/pending-lots）
async function loadBatchList() {
  batchListLoading.value = true
  try {
    console.log('[Unloading] GET /api/unloading/pending-lots（下料模块专用待下料批次，无入参）')
    const data = await getPendingUnloadingLots()
    console.log('[Unloading] 待下料批次列表原始返回：', data)
    const list = extractListPayload(data).map(normalizePendingLot).filter(Boolean)
    batchList.value = list
    console.log('[Unloading] 待下料批次列表解析后条数：', list.length)
  } catch (error) {
    console.warn('[Unloading] 待下料批次列表接口失败：', error)
    batchList.value = []
    ElMessage.warning('待下料批次列表接口暂不可用，请稍后重试')
  } finally {
    batchListLoading.value = false
  }
}

// 按批次 id 加载该批次下"存在未下料完毕上料记录"的工站（真实 API：GET /api/unloading/stations?lotId=xxx）
async function loadBatchStations(batchId) {
  if (!batchId) {
    batchStations.value = []
    return
  }
  batchStationsLoading.value = true
  try {
    const params = { lotId: Number(batchId) }
    console.log('[Unloading] GET /api/loading/stations（下料复用上料工站接口）参数：', params)
    const data = await getLoadingStationsApi(params)
    console.log('[Unloading] 下料可用工站列表原始返回：', data)
    const list = extractListPayload(data)
      .map((item, i) => normalizeUnloadingStation(item, i))
      .filter(Boolean)
    list.sort((a, b) => (a.sequence || 0) - (b.sequence || 0))
    batchStations.value = list
  } catch (error) {
    console.warn('[Unloading] 下料可用工站列表接口失败：', error)
    batchStations.value = []
    ElMessage.warning('工站列表接口暂不可用，请稍后重试')
  } finally {
    batchStationsLoading.value = false
  }
}

// Tab1 当前选中的批次
const currentBatch = computed(() => {
  if (!selectedBatchId.value) return null
  return batchList.value.find((b) => b.id === selectedBatchId.value) || null
})

// Tab1 当前选中的工站
const currentStation = computed(() => {
  if (!selectedStationId.value) return null
  return batchStations.value.find((s) => s.routeStepId === selectedStationId.value) || null
})

// ==================== Tab 1: 下料操作 ====================
const unloadableList = ref([])
const unloadableLoading = ref(false)

// 下料录入行（与上料管理 loadingRows 对齐：支持多行录入）
const unloadingRows = ref([])

const submitting = ref(false)

// 下料原因下拉选项（对齐数据库 1-4 枚举）
const unloadReasonOptions = Object.values(UNLOAD_REASON).map((item) => ({
  value: item.code,
  label: item.label,
}))

// 从 unloadableList（即工站可下料的上料记录）生成条码候选
const barcodeOptionsForUnload = computed(() => {
  const usedCodes = new Set(
    unloadingRows.value
      .map((r) => String(r.barcode || '').trim())
      .filter(Boolean),
  )
  return unloadableList.value
    .filter((r) => !usedCodes.has(String(r.Barcode || '').trim()))
    .map((r) => {
      const initialQty = Number(r.InitialQuantity ?? r.ActualQuantity ?? r.UnloadableQuantity ?? 0)
      const unloadableQty = Number(r.UnloadableQuantity || 0)
      return {
        value: r.Barcode,
        label: r.Barcode,
        loadingRecordId: r.Id,
        materialCode: r.MaterialCode,
        batchNo: r.BatchNo,
        packageType: r.PackageType,
        supplier: r.Supplier,
        initialQty,
        unloadableQty,
      }
    })
})

function createEmptyUnloadingRow() {
  return {
    inputMode: 'select',         // 'select' 下拉选择 / 'manual' 手动输入
    barcode: '',                  // 物料批次条码（用于交叉校验防扫错盘）
    loadingRecordId: null,        // 匹配到的上料记录 ID
    matchedMaterialInfo: null,    // { materialCode, batchNo, packageType, supplier, unloadableQty, initialQty }
    unloadQuantity: 0,            // 下料数量（回库完好料，>=0）
    actualUsedQuantity: 0,        // 实际使用数量（生产消耗，>=0）
    wastageQuantity: 0,           // 损耗数量（抛料/不良等，>=0）
    reason: '',                   // 下料原因（1-4）：1批次完工换线/2物料耗尽/3品质异常/4其他
    remark: '',                   // 备注（<=200字）
    operatorId: '',               // 操作人（前端记录展示用，提交时后端从JWT获取）
    errors: [],                   // 校验错误
  }
}

function addUnloadingRow() {
  unloadingRows.value.push(createEmptyUnloadingRow())
}

function removeUnloadingRow(idx) {
  unloadingRows.value.splice(idx, 1)
}

// 从上料记录列表一键添加下料行（自动填充条码、默认数量等）
function addRowFromLoadingRecord(record) {
  // 防护：已下料完毕 -> 直接阻止添加
  const info = getUnloadableStatus(record)
  if (info.status === 'done') {
    ElMessage.info('该物料批次已下料完毕，无需继续下料')
    return
  }
  const row = createEmptyUnloadingRow()
  const initialQty = Number(record.InitialQuantity ?? 0)
  // 剩余可下料：直接用 mapLoadingRecordToUnloadable 已算好的 UnloadableQuantity
  //   （优先 backend 的 latestRemainQuantity，兜底 = loadingQty - totalUnloadQuantity）
  const unloadableQty = Math.max(0, Number(record.UnloadableQuantity ?? 0))
  // 已实耗 + 已损耗合计（来自后端的精准数据）
  const usedSoFar = Number(record.TotalActualUsed ?? 0) + Number(record.TotalWastage ?? 0)
  // 默认本次实耗：0（让用户填写本次真正消耗的量），若用户需要可自行修改
  const defaultUsedQty = 0
  row.barcode = record.Barcode || ''
  // 优先用 LoadingRecordId（接口明确要求的上料记录ID字段），兜底 Id
  row.loadingRecordId = record.LoadingRecordId ?? record.Id
  row.matchedMaterialInfo = {
    materialCode: record.MaterialCode,
    batchNo: record.BatchNo,
    packageType: record.PackageType,
    supplier: record.Supplier,
    initialQty,
    unloadableQty,
  }
  // 默认下料数量 = 剩余可下料量（latestRemainQuantity，让用户一次性清完剩余回库）
  row.unloadQuantity = unloadableQty
  row.actualUsedQuantity = defaultUsedQty
  row.wastageQuantity = 0
  // 操作人默认取当前用户
  const currentOp = unloadingRows.value.length
    ? unloadingRows.value[0].operatorId
    : (operatorList.value.length ? (operatorList.value[0].id || operatorList.value[0].Id) : '')
  if (!row.operatorId && currentOp) row.operatorId = currentOp
  unloadingRows.value.push(row)
}

// 行条码变化 → 查找匹配的可下料记录并自动填充参考信息
function onRowBarcodeChange(row) {
  row.loadingRecordId = null
  row.matchedMaterialInfo = null
  row.errors = []
  const barcode = String(row.barcode || '').trim()
  if (!barcode) return
  const found = unloadableList.value.find((r) => String(r.Barcode || '').trim() === barcode)
  if (!found) {
    row.errors.push(`该条码在当前工站没有可下料的上料记录`)
    return
  }
  const initialQty = Number(found.InitialQuantity ?? found.UnloadableQuantity ?? 0)
  const unloadableQty = Number(found.UnloadableQuantity || 0)
  const defaultUsedQty = Math.max(0, initialQty - unloadableQty)
  // 优先用 LoadingRecordId（接口明确要求的上料记录ID字段），兜底 Id
  row.loadingRecordId = found.LoadingRecordId ?? found.Id
  row.matchedMaterialInfo = {
    materialCode: found.MaterialCode,
    batchNo: found.BatchNo,
    packageType: found.PackageType,
    supplier: found.Supplier,
    initialQty,
    unloadableQty,
  }
  // 默认下料数量 = 全部可下料数量（剩余回库）
  if (!row.unloadQuantity || row.unloadQuantity <= 0) {
    row.unloadQuantity = unloadableQty
  }
  // 默认实耗 = 初始上料 - 可下料（即已消耗在生产上的部分）
  if (!row.actualUsedQuantity || row.actualUsedQuantity <= 0) {
    row.actualUsedQuantity = defaultUsedQty
  }
  // 默认损耗 = 0
  if (row.wastageQuantity == null || row.wastageQuantity < 0) {
    row.wastageQuantity = 0
  }
}

// 映射 GET /api/unloading/loading-records（下料专用接口）返回的 12 字段 → 前端表格结构
// 接口字段（基础 8 字段 + 历史下料合计 4 字段）：
//   —— 基础 ——
//   id / materialLotBarcode / materialCode / packageCode /
//   supplier / operatorName / loadingTime / loadingQuantity
//   —— 历史下料合计（新增）——
//   totalUnloadQuantity  历史下料回库数量合计
//   totalActualUsedQuantity  历史实际使用数量合计
//   totalWastageQuantity  历史损耗数量合计
//   latestRemainQuantity  最新一条下料记录的剩余数量
function mapLoadingRecordToUnloadable(rec) {
  const loadedQty = Number(rec.loadingQuantity ?? 0)
  const totalUnload = Number(rec.totalUnloadQuantity ?? 0)
  const totalActualUsed = Number(rec.totalActualUsedQuantity ?? 0)
  const totalWastage = Number(rec.totalWastageQuantity ?? 0)
  const rawLatestRemain = Number(rec.latestRemainQuantity)
  const hasAnyHistory = totalUnload + totalActualUsed + totalWastage > 0
  // latestRemain 的可信度：只有存在下料历史时 latestRemain 才有意义；
  // 从未下过料但后端又返回 latestRemainQuantity=0 时，该 0 是无意义默认值，应忽略。
  const latestRemainUsable = hasAnyHistory && Number.isFinite(rawLatestRemain) && rawLatestRemain >= 0
  const latestRemain = latestRemainUsable ? rawLatestRemain : null
  // 剩余可下料：优先可信的 latestRemain；否则 = 上料量 - 历史下料回库合计
  const unloadableQty = latestRemainUsable
    ? rawLatestRemain
    : Math.max(0, loadedQty - totalUnload)
  // 操作人：接口返回 FullName + Username 两个字段；
  //   operatorName 语义：优先姓名（FullName），Username 兜底；但用户希望同时看到账号（如 admin）
  //   兼容可能的字段命名：operatorUsername / username / operator / Operator 等。
  const fullName = String(rec.operatorName ?? rec.OperatorName ?? rec.fullName ?? rec.FullName ?? '').trim()
  const userName = String(
    rec.operatorUsername ?? rec.OperatorUsername ??
    rec.username ?? rec.Username ??
    rec.operator ?? rec.Operator ??
    rec.operatorCode ?? rec.OperatorCode ?? '',
  ).trim()
  // 最终展示用 OperatorName：优先取 FullName，没有则用 Username
  const operatorName = fullName || userName || '-'
  // OperatorUsername：账号名（如果和 FullName 不一致则保存，用于拼"姓名（账号）"展示）
  const operatorUsername =
    userName && fullName && userName.toLowerCase() !== fullName.toLowerCase()
      ? userName
      : ''
  return {
    Id: rec.id,
    LoadingRecordId: rec.id,       // 直接作为批量录入接口 records[i].loadingRecordId 的值
    Barcode: rec.materialLotBarcode,
    MaterialCode: rec.materialCode,
    PackageType: rec.packageCode,
    Supplier: rec.supplier,
    OperatorName: operatorName,
    OperatorUsername: operatorUsername,
    LoadingTime: rec.loadingTime,
    InitialQuantity: loadedQty,
    UnloadableQuantity: unloadableQty,
    // 后端返回的历史合计（精准数据，优先使用）
    TotalUnload: totalUnload,
    TotalActualUsed: totalActualUsed,
    TotalWastage: totalWastage,
    LatestRemain: latestRemain,
  }
}

async function loadUnloadableList() {
  if (!currentBatch.value || !currentStation.value) {
    unloadableList.value = []
    return
  }
  unloadableLoading.value = true
  try {
    const params = {
      lotId: currentBatch.value.id,
      stationId: currentStation.value.stationId,
    }
    console.log('[Unloading] GET /api/unloading/loading-records（批次+工站精准筛选）参数：', params)
    const data = await getUnloadingLoadingRecordsApi(params)
    console.log('[Unloading] 可下料上料记录原始返回：', data)
    const rawList = Array.isArray(data) ? data : (data?.records || data?.list || [])
    unloadableList.value = rawList.map(mapLoadingRecordToUnloadable).filter((r) => r.Id)
    console.log('[Unloading] 映射后可下料记录条数：', unloadableList.value.length)
    // 刷新已录入行的匹配信息
    unloadingRows.value.forEach((row) => onRowBarcodeChange(row))
  } catch (error) {
    console.warn('[Unloading] 可下料上料记录接口失败：', error)
    unloadableList.value = []
    ElMessage.warning('可下料上料记录接口暂不可用，请稍后重试')
  } finally {
    unloadableLoading.value = false
  }
}

function validateUnloadingRows() {
  let ok = true
  unloadingRows.value.forEach((row) => {
    row.errors = []
    if (!String(row.barcode || '').trim()) {
      row.errors.push('请扫描/选择物料批次条码')
      ok = false
    }
    if (!row.loadingRecordId) {
      if (!row.errors.includes('该条码在当前工站没有可下料的上料记录')) {
        row.errors.push('该条码在当前工站没有可下料的上料记录')
      }
      ok = false
    }
    // 下料数量（回库完好料）>= 0
    const unloadQty = Number(row.unloadQuantity ?? 0)
    if (unloadQty < 0) {
      row.errors.push('下料数量不能小于 0')
      ok = false
    }
    // 实际使用数量 >= 0
    const usedQty = Number(row.actualUsedQuantity ?? 0)
    if (usedQty < 0) {
      row.errors.push('实际使用数量不能小于 0')
      ok = false
    }
    // 损耗数量 >= 0
    const wasteQty = Number(row.wastageQuantity ?? 0)
    if (wasteQty < 0) {
      row.errors.push('损耗数量不能小于 0')
      ok = false
    }
    // 三项相加必须 > 0（至少有一项有值，否则无意义）
    if (unloadQty + usedQty + wasteQty <= 0) {
      row.errors.push('下料数量、实耗、损耗三者至少有一项大于 0')
      ok = false
    }
    // 下料数量不能超过可下料数量（剩余回库部分）
    const maxQty = row.matchedMaterialInfo?.unloadableQty ?? 0
    if (unloadQty > maxQty) {
      row.errors.push(`下料数量不能超过可下料数量（${maxQty}）`)
      ok = false
    }
    // 可选校验：三项合计不能超过初始上料数量（防止统计超出）
    const initQty = row.matchedMaterialInfo?.initialQty ?? 0
    if (initQty > 0 && unloadQty + usedQty + wasteQty > initQty) {
      row.errors.push(`下料+实耗+损耗合计（${unloadQty + usedQty + wasteQty}）不能超过初始上料数量（${initQty}）`)
      ok = false
    }
    // 下料原因必填（1-4）
    const reason = Number(row.reason)
    if (![1, 2, 3, 4].includes(reason)) {
      row.errors.push('请选择下料原因')
      ok = false
    }
    // 其他原因必填备注
    if (reason === 4 && !String(row.remark || '').trim()) {
      row.errors.push('选择"其他"原因时必须填写备注')
      ok = false
    }
    // 操作人前端保留校验（提交时后端从JWT获取，前端仅做UI态校验）
    if (!row.operatorId) {
      row.errors.push('请选择操作人')
      ok = false
    }
  })
  return ok
}

async function submitUnloading() {
  if (!currentStation.value) {
    ElMessage.warning('请先选择工站')
    return
  }
  if (!unloadingRows.value.length) {
    ElMessage.warning('请先新增至少一条下料记录')
    return
  }
  if (!validateUnloadingRows()) {
    ElMessage.error('存在录入错误，请检查每行的红色提示')
    return
  }

  submitting.value = true

  try {
    // 组装批量提交 payload（对齐 POST /api/unloading/records 新接口）
    const records = unloadingRows.value.map((row) => {
      const operatorId = Number(row.operatorId) || 0
      const record = {
        loadingRecordId: Number(row.loadingRecordId),
        unloadQuantity: Number(row.unloadQuantity ?? 0),
        actualUsedQuantity: Number(row.actualUsedQuantity ?? 0),
        wastageQuantity: Number(row.wastageQuantity ?? 0),
        reason: Number(row.reason),
        operatorId,
      }
      // 可选字段：remark（≤200字）
      const remark = String(row.remark || '').trim()
      if (remark) record.remark = remark
      // 可选字段：barcode（交叉校验防扫错盘）
      const barcode = String(row.barcode || '').trim()
      if (barcode) record.barcode = barcode
      return record
    })

    console.log('[Unloading] POST /api/unloading/records 批量提交 payload：', { records })
    const resp = await batchCreateUnloadingRecords({ records })
    console.log('[Unloading] 批量下料返回：', resp)

    // 解析返回：兼容 { successCount, failCount, failDetails } 或其他包装结构
    const payload = (resp && typeof resp === 'object') ? resp : {}
    const total = records.length
    const rawFailDetails = Array.isArray(payload.failDetails) ? payload.failDetails : []
    // failDetails 元素可能是字符串（如截图）或 { message/msg } 对象；统一抽成「文本 + 原始行索引」
    //   后端字符串格式通常形如 "第1条：xxx"，解析前缀数字对齐 unloadingRows 的下标（0-based）
    const failDetails = rawFailDetails.map((item) => {
      const text =
        typeof item === 'string' ? item
          : (item && typeof item === 'object')
            ? (item.message || item.msg || item.error || String(item))
            : String(item ?? '')
      let rowIndex = -1
      const m = /第\s*(\d+)\s*条/.exec(text)
      if (m) {
        const n = parseInt(m[1], 10)
        if (Number.isFinite(n) && n >= 1) rowIndex = n - 1
      }
      return { rowIndex, text, raw: item }
    })
    const successCount = Number(payload.successCount ?? (total - failDetails.length))
    const failCount = Number(payload.failCount ?? failDetails.length)

    // 把失败明细写入对应行的 errors（方便用户直接定位哪一行有问题）
    if (failDetails.length) {
      unloadingRows.value.forEach((row) => { row.errors = row.errors || [] })
      failDetails.forEach((fd) => {
        const idx = fd.rowIndex
        if (idx >= 0 && idx < unloadingRows.value.length) {
          unloadingRows.value[idx].errors.push(fd.text)
        }
      })
      console.warn('[Unloading] 下料失败明细：', failDetails)
    }

    if (successCount > 0 && failCount === 0) {
      ElMessage.success(`成功下料 ${successCount} 条记录，可重新上料`)
      // 全部成功才清空录入行
      unloadingRows.value = []
      await Promise.all([loadUnloadableList(), loadUnloadedList()])
    } else if (successCount > 0 && failCount > 0) {
      ElMessage.warning(`部分成功：下料成功 ${successCount} 条，失败 ${failCount} 条`)
      const detailText = failDetails.map((fd, i) => `${i + 1}. ${fd.text}`).join('\n')
      ElMessageBox.alert(
        detailText,
        `下料失败明细（共 ${failCount} 条）`,
        { confirmButtonText: '我知道了', type: 'warning', dangerouslyUseHTMLString: false },
      ).catch(() => { /* 用户关闭弹窗不抛错 */ })
      // 部分成功：刷新列表（因为已成功的需要同步状态），但保留录入行
      await Promise.all([loadUnloadableList(), loadUnloadedList()])
    } else {
      const firstFail = failDetails[0]?.text?.trim()
      ElMessage.error(firstFail ? `下料全部失败：${firstFail}` : '下料失败，请重试')
      if (failDetails.length > 1) {
        const detailText = failDetails.map((fd, i) => `${i + 1}. ${fd.text}`).join('\n')
        ElMessageBox.alert(
          detailText,
          `下料失败明细（共 ${failCount} 条）`,
          { confirmButtonText: '我知道了', type: 'error', dangerouslyUseHTMLString: false },
        ).catch(() => {})
      }
      // 全部失败：保留录入行和 errors 不清理，方便用户修改后重提
      await Promise.all([loadUnloadableList(), loadUnloadedList()])
    }
  } catch (error) {
    console.warn('[Unloading] 批量下料接口异常：', error)
    const msg = error?.message || error?.msg || '下料失败，请稍后重试'
    ElMessage.error(msg)
  } finally {
    submitting.value = false
  }
}

// ==================== 工站已下料记录查看（弹窗模式，仿上料管理） ====================
const unloadedDialogVisible = ref(false)
const unloadedLotFilter = ref('')

// 概览数据（来自 GET /api/unloading/stations/records → overview）
const unloadedOverview = ref(null)

// 按批次号筛选的下拉选项（从 records 里去重提取 生产批次号 lotCode —— 原 BatchNo 列是物料自身批次号，现在按生产批次号过滤更合理）
const unloadedLotOptions = computed(() => {
  const set = new Set()
  unloadedList.value.forEach((r) => {
    const code = r.LotCode
    if (code && code !== '-') set.add(code)
  })
  return Array.from(set).map((code) => ({ value: code, label: code }))
})

// 过滤后展示的下料记录列表（弹窗内用）
const filteredUnloadedList = computed(() => {
  if (!unloadedLotFilter.value) return unloadedList.value
  return unloadedList.value.filter((r) => r.LotCode === unloadedLotFilter.value)
})

// 【工站已上料记录 vs 已下料记录 关联统计】
// 按 LoadingRecordId 聚合：累计已下料回库数量、累计实耗、累计损耗、最后下料时间
// —— 即使 /unloading/loading-records 接口仍返回"已下料过"的行，
//    前端也能从已下料记录（同 stationId 全量）反向计算状态，立刻给用户明确视觉反馈。
const unloadedStatByLoadingRecordId = computed(() => {
  const map = new Map()
  unloadedList.value.forEach((r) => {
    const key = Number(r.LoadingRecordId) || Number(r.LoadingRecordID) || r.loadingRecordId
    if (!key) return
    const prev = map.get(key) || {
      totalUnload: 0,
      totalActualUsed: 0,
      totalWastage: 0,
      count: 0,
      lastUnloadingTime: '',
    }
    map.set(key, {
      totalUnload: prev.totalUnload + Number(r.UnloadQuantity ?? 0),
      totalActualUsed: prev.totalActualUsed + Number(r.ActualUsedQuantity ?? 0),
      totalWastage: prev.totalWastage + Number(r.WastageQuantity ?? 0),
      count: prev.count + 1,
      lastUnloadingTime: [prev.lastUnloadingTime, r.UnloadingTime].filter(Boolean).sort().pop() || '',
    })
  })
  return map
})

// 根据上料行 + 已下料统计，判断下料状态：none 未下过 / partial 部分下料 / done 已下料完毕
// 优先级：
//   1. 优先使用 /unloading/loading-records 返回的合计字段（TotalUnload / TotalActualUsed / TotalWastage / LatestRemain）
//      —— 注意：LatestRemain 仅在"三项合计>0"时（即有下料历史时）才可信，否则会被 map 函数置为 null
//   2. 字段缺失时兜底：从已下料记录反向聚合（unloadedStatByLoadingRecordId）
function getUnloadableStatus(record) {
  const loadingQty = Number(record.InitialQuantity ?? 0)
  if (loadingQty === 0) return { status: 'none', stat: null }
  // 后端直接给的历史合计（精准数据）
  const totalUnload = Number(record.TotalUnload ?? 0)
  const totalActualUsed = Number(record.TotalActualUsed ?? 0)
  const totalWastage = Number(record.TotalWastage ?? 0)
  const latestRemain = record.LatestRemain != null ? Number(record.LatestRemain) : null
  // hasBackendStat：仅以三项合计是否 >0 为准（latestRemain 单独不作为判定依据，
  //   防止"从未下过料但后端 latestRemainQuantity=0"这种无意义默认值导致误判）
  const hasBackendStat = totalUnload > 0 || totalActualUsed > 0 || totalWastage > 0
  if (hasBackendStat) {
    // 剩余量：优先可信的 latestRemain，兜底 = 上料量 - 历史下料回库合计
    const remain = latestRemain != null && Number.isFinite(latestRemain)
      ? Math.max(0, latestRemain)
      : Math.max(0, loadingQty - totalUnload)
    const stat = {
      totalUnload,
      totalActualUsed,
      totalWastage,
      // 从已下料聚合中取 lastUnloadingTime（仅展示用）
      lastUnloadingTime: unloadedStatByLoadingRecordId.value
        .get(Number(record.LoadingRecordId ?? record.Id))
        ?.lastUnloadingTime ?? '',
    }
    if (remain <= 0 || totalUnload >= loadingQty) {
      return { status: 'done', stat, remain: 0 }
    }
    return { status: 'partial', stat, remain }
  }
  // 兜底：从已下料记录反向聚合
  const stat = unloadedStatByLoadingRecordId.value.get(Number(record.LoadingRecordId ?? record.Id))
  if (!stat) return { status: 'none', stat: null }
  const remain = loadingQty - stat.totalUnload
  if (remain <= 0) return { status: 'done', stat, remain: 0 }
  return { status: 'partial', stat, remain }
}

// 表格行样式：已下料完毕行灰化，降低视觉权重
function unloadableRowStyle({ row }) {
  const { status } = getUnloadableStatus(row)
  if (status === 'done') return { opacity: 0.5, background: '#f5f7fa' }
  return {}
}

// 表格行 class（给内部文字/图标透传灰度用）
function unloadableRowClassName({ row }) {
  const { status } = getUnloadableStatus(row)
  if (status === 'done') return 'unloadable-row-done'
  if (status === 'partial') return 'unloadable-row-partial'
  return ''
}

// 打开弹窗：重置筛选 + 触发一次刷新
async function viewUnloadedRecords() {
  if (!currentStation.value) return
  unloadedLotFilter.value = ''
  unloadedOverview.value = null
  unloadedDialogVisible.value = true
  await loadUnloadedList()
}

// ==================== 工站已下料记录数据源（新版：GET /api/unloading/stations/records） ====================
const unloadedList = ref([])
const unloadedLoading = ref(false)

// 归一化下料记录（对齐新版 16 字段：id/lotId/lotCode/loadingRecordId/materialLotId/materialLotBarcode/materialCode/operatorName/unloadingTime/reasonCode/reasonText/unloadQuantity/actualUsedQuantity/remainQuantity/wastageQuantity/remark）
// 保留前端历史字段：Barcode / MaterialCode / LotCode（新）、BatchNo（物料批次号，拆 materialLotBarcode 兜底）/PackageType/Supplier/UnloadQuantity/ActualUsedQuantity/RemainQuantity/WastageQuantity/ReasonCode/ReasonText/Remark/OperatorName/UnloadingTime
function normalizeUnloadingRecord(item) {
  if (!item) return null
  const barcode = item.materialLotBarcode ?? item.MaterialLotBarcode ?? item.barcode ?? item.Barcode ?? ''
  // 从 materialLotBarcode 尝试拆出物料批次号（例 "R0603-10K#LOT202608010002" → 取 #LOT... 后半）
  let materialBatch = ''
  if (barcode) {
    const hashIdx = barcode.indexOf('#')
    if (hashIdx >= 0) materialBatch = barcode.substring(hashIdx + 1)
  }
  // 操作人：FullName + Username 拼接展示（与工站已上料记录一致）
  const fullName = String(item.OperatorName ?? item.operatorName ?? item.FullName ?? item.fullName ?? '').trim()
  const userName = String(
    item.OperatorUsername ?? item.operatorUsername ??
    item.Username ?? item.username ??
    item.Operator ?? item.operator ??
    item.OperatorCode ?? item.operatorCode ?? '',
  ).trim()
  const operatorName = fullName || userName || '-'
  const operatorUsername =
    userName && fullName && userName.toLowerCase() !== fullName.toLowerCase()
      ? userName
      : ''
  return {
    ...item,
    Id: item.Id ?? item.id,
    LotId: item.LotId ?? item.lotId,
    LotCode: item.LotCode ?? item.lotCode ?? '',               // 生产批次号（新字段，筛选用）
    LoadingRecordId: item.LoadingRecordId ?? item.loadingRecordId,
    MaterialLotId: item.MaterialLotId ?? item.materialLotId,
    MaterialCode: item.MaterialCode ?? item.materialCode ?? '',
    OperatorName: operatorName,
    OperatorUsername: operatorUsername,
    Barcode: barcode,
    BatchNo: materialBatch || (item.BatchNo ?? item.batchNo ?? item.materialBatchNo ?? ''),
    PackageType: item.PackageType ?? item.packageType ?? item.materialPackageType ?? '',
    Supplier: item.Supplier ?? item.supplier ?? '',
    UnloadQuantity: Number(item.UnloadQuantity ?? item.unloadQuantity ?? item.quantity ?? 0),
    ActualUsedQuantity: Number(item.ActualUsedQuantity ?? item.actualUsedQuantity ?? 0),
    RemainQuantity: Number(item.RemainQuantity ?? item.remainQuantity ?? 0),
    WastageQuantity: Number(item.WastageQuantity ?? item.wastageQuantity ?? 0),
    ReasonCode: Number(item.ReasonCode ?? item.reasonCode ?? item.reason ?? 0),
    ReasonText: item.ReasonText ?? item.reasonText ?? '',
    Remark: item.Remark ?? item.remark ?? '',
    UnloadingTime: item.UnloadingTime ?? item.unloadingTime ?? item.operationTime ?? item.OperationTime ?? '',
  }
}

// 归一化 overview（7 字段概览）
function normalizeUnloadingOverview(obj) {
  if (!obj) return null
  return {
    ...obj,
    StationId: obj.StationId ?? obj.stationId,
    StationName: obj.StationName ?? obj.stationName ?? '',
    RecordCount: Number(obj.RecordCount ?? obj.recordCount ?? 0),
    TotalUnloadQuantity: Number(obj.TotalUnloadQuantity ?? obj.totalUnloadQuantity ?? 0),
    TotalActualUsedQuantity: Number(obj.TotalActualUsedQuantity ?? obj.totalActualUsedQuantity ?? 0),
    TotalWastageQuantity: Number(obj.TotalWastageQuantity ?? obj.totalWastageQuantity ?? 0),
    LastUnloadingTime: obj.LastUnloadingTime ?? obj.lastUnloadingTime ?? '',
  }
}

async function loadUnloadedList() {
  if (!currentStation.value) {
    unloadedList.value = []
    unloadedOverview.value = null
    return
  }
  unloadedLoading.value = true
  try {
    const params = { stationId: currentStation.value.stationId }
    const data = await getStationUnloadingRecordsApi(params)
    // 新版返回：data = { overview, records }
    const payload = (data && typeof data === 'object') ? data : null
    const overview = payload?.overview ?? null
    const records = Array.isArray(payload?.records) ? payload.records : (Array.isArray(payload) ? payload : [])
    unloadedOverview.value = normalizeUnloadingOverview(overview)
    unloadedList.value = records.map(normalizeUnloadingRecord).filter(Boolean)
  } catch (error) {
    console.warn('[Unloading] 工站已下料记录接口失败：', error)
    unloadedList.value = []
    unloadedOverview.value = null
  } finally {
    unloadedLoading.value = false
  }
}

// 下料原因文本映射（对齐 UNLOAD_REASON 枚举：1-批次完工换线 2-物料耗尽 3-品质异常 4-其他）
function getUnloadReasonText(code) {
  const found = Object.values(UNLOAD_REASON).find((r) => r.code === Number(code))
  return found ? found.label : (code ? `原因${code}` : '-')
}

// ==================== 监听与初始化 ====================
// Tab1：切换批次时 → 加载该批次工站 + 重置下料录入行
watch(selectedBatchId, async (newBatchId) => {
  selectedStationId.value = null
  batchStations.value = []
  unloadingRows.value = []
  unloadableList.value = []
  unloadedList.value = []
  if (newBatchId) {
    await loadBatchStations(newBatchId)
  }
})

// Tab1：切换工站时 → 重置下料录入行并加载可下料记录 + 已下料记录
watch(selectedStationId, () => {
  unloadingRows.value = []
  loadUnloadableList()
  loadUnloadedList()
})

watch(operatorList, (list) => {
  if (!list.length) return
  const currentUsername = userStore.userInfo?.username || userStore.userInfo?.name
  const matched = list.find((u) =>
    (u.username || u.Username) === currentUsername ||
    (u.fullName || u.FullName) === currentUsername,
  )
  const defaultOpId = matched ? (matched.id || matched.Id) : (list[0].id || list[0].Id)
  unloadingRows.value.forEach((row) => {
    if (!row.operatorId) row.operatorId = defaultOpId
  })
})

onMounted(async () => {
  await Promise.all([loadOperatorList(), loadBatchList()])
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">下料管理</h1>
      </div>
      <div class="table-actions">
        <el-button type="primary" plain @click="router.push('/execution/loading')">
          <el-icon style="margin-right: 4px"><Top /></el-icon>去上料
        </el-button>
        <el-button type="success" plain @click="router.push('/execution/check-in')">
          <el-icon style="margin-right: 4px"><Promotion /></el-icon>去进站
        </el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab" class="unloading-tabs">
      <!-- ==================== Tab 1: 下料操作 ==================== -->
      <el-tab-pane name="unloading">
        <template #label>
          <span class="tab-label">下料操作</span>
        </template>

        <!-- 步骤 1: 选择已投产批次 -->
        <SectionCard title="① 选择已投产批次">
          <div class="station-flex batch-grid" v-loading="batchListLoading">
            <el-empty
              v-if="!batchListLoading && !batchList.length"
              description="暂无已投产批次"
              :image-size="80"
            />
            <div
              v-for="batch in batchList"
              :key="batch.id"
              class="station-card batch-card"
              :class="{ active: selectedBatchId === batch.id }"
              @click="selectedBatchId = batch.id"
            >
              <div class="station-card-header">
                <el-icon class="station-seq station-seq-icon"><Tickets /></el-icon>
                <span class="station-code" :title="batch.lotCode">{{ batch.lotCode }}</span>
                <el-tag
                  v-if="batch.currentOperation"
                  size="small"
                  type="success"
                  effect="plain"
                  round
                >{{ batch.currentOperation }}</el-tag>
              </div>
              <div class="station-card-body">
                <div class="station-info-row" v-if="batch.productName">
                  <span class="label">产品</span>
                  <span class="value" :title="batch.productName">{{ batch.productName }}</span>
                </div>
                <div class="station-info-row" v-if="batch.workOrderCode">
                  <span class="label">工单</span>
                  <span class="value" :title="batch.workOrderCode">{{ batch.workOrderCode }}</span>
                </div>
                <div class="station-info-row" v-if="batch.lineName">
                  <span class="label">产线</span>
                  <span class="value" :title="batch.lineName">{{ batch.lineName }}</span>
                </div>
              </div>
            </div>
          </div>
        </SectionCard>

        <!-- 步骤 2: 选择工站 -->
        <SectionCard v-if="currentBatch" title="② 选择工站" class="mt-16">
          <div class="current-context-bar">
            <div class="context-item">
              <span class="context-label">批次号</span>
              <span class="context-value">{{ currentBatch.lotCode }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">产品</span>
              <span class="context-value">{{ currentBatch.productName }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">当前工序</span>
              <el-tag size="small" type="success" effect="plain">{{ currentBatch.currentOperation || '-' }}</el-tag>
            </div>
          </div>

          <div class="station-flex" v-loading="batchStationsLoading">
            <el-empty
              v-if="!batchStationsLoading && !batchStations.length"
              description="该批次暂无已上料工站，无可下料物料"
              :image-size="80"
            />
            <div
              v-for="station in batchStations"
              :key="station.routeStepId"
              class="station-card"
              :class="{ active: selectedStationId === station.routeStepId }"
              @click="selectedStationId = station.routeStepId"
            >
              <div class="station-card-header">
                <span class="station-seq">{{ station.sequence }}</span>
                <span class="station-code" :title="station.stationCode">{{ station.stationCode }}</span>
                <el-tag size="small" type="info" effect="plain" round>{{ station.operationName }}</el-tag>
              </div>
              <div class="station-card-body">
                <div class="station-info-row">
                  <span class="label">工站</span>
                  <span class="value">{{ station.stationName }}</span>
                </div>
                <div class="station-info-row">
                  <span class="label">设备类型</span>
                  <span class="value">{{ station.equipmentTypeName }}</span>
                </div>
              </div>
            </div>
          </div>
        </SectionCard>

        <!-- 步骤 3: 下料录入 -->
        <SectionCard v-if="currentStation" title="③ 下料录入" class="mt-16">
          <template #actions>
            <el-button size="small" plain @click="viewUnloadedRecords">
              <el-icon style="margin-right: 4px"><View /></el-icon>查看工站已下料记录
            </el-button>
          </template>

          <div class="current-context-bar">
            <div class="context-item">
              <span class="context-label">批次号</span>
              <span class="context-value">{{ currentBatch.lotCode }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">工站</span>
              <span class="context-value">{{ currentStation.stationName }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">工序</span>
              <span class="context-value">{{ currentStation.operationName }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">设备类型</span>
              <el-tag size="small" type="warning" effect="plain">{{ currentStation.equipmentTypeName }}</el-tag>
            </div>
          </div>

          <!-- 工站已上料记录（供下料选择参考） -->
          <div class="loading-records-section" v-if="currentStation">
            <div class="loading-records-header">
              <span class="loading-records-title">
                <el-icon style="margin-right: 4px"><Goods /></el-icon>
                工站已上料记录（{{ unloadableList.length }}） 
              </span>
              <span v-if="unloadableLoading" class="loading-records-loading">加载中...</span>
            </div>

            <el-empty
              v-if="!unloadableLoading && !unloadableList.length"
              description="该工站暂无已上料记录"
              :image-size="60"
            />

            <el-table
              v-else
              v-loading="unloadableLoading"
              :data="unloadableList"
              border
              stripe
              size="small"
              max-height="260"
              style="width: 100%"
              :row-style="unloadableRowStyle"
              :row-class-name="unloadableRowClassName"
            >
              <el-table-column label="物料批次条码" min-width="140" align="center">
                <template #default="{ row }">
                  <span class="barcode-text">{{ row.Barcode }}</span>
                </template>
              </el-table-column>
              <el-table-column prop="MaterialCode" label="物料编码" min-width="100" align="center" />
              <el-table-column label="封装" width="90" align="center">
                <template #default="{ row }">
                  <el-tag v-if="row.PackageType" size="small" effect="plain">{{ row.PackageType }}</el-tag>
                  <span v-else style="color: var(--rtm-text-muted)">-</span>
                </template>
              </el-table-column>
              <el-table-column label="供应商" min-width="90" align="center">
                <template #default="{ row }">
                  <span>{{ row.Supplier || '-' }}</span>
                </template>
              </el-table-column>
              <el-table-column label="操作人" width="140" align="center">
                <template #default="{ row }">
                  <span :title="row.OperatorUsername ? `${row.OperatorName} 账号：${row.OperatorUsername}` : row.OperatorName || '-'">
                    {{ row.OperatorName || '-' }}
                  </span>
                  <span
                    v-if="row.OperatorUsername"
                    style="font-size: 11px; color: var(--rtm-text-muted); margin-left: 2px;"
                  >({{ row.OperatorUsername }})</span>
                </template>
              </el-table-column>
              <el-table-column label="上料时间" width="180" align="center">
                <template #default="{ row }">
                  <span style="font-size: 12px">{{ formatDateTime(row.LoadingTime) || '-' }}</span>
                </template>
              </el-table-column>
              <el-table-column label="上料数量" width="150" align="center">
                <template #default="{ row }">
                  <div style="line-height: 1.2">
                    <div style="font-weight: 600">{{ row.InitialQuantity || 0 }}</div>
                    <template v-if="getUnloadableStatus(row).status !== 'none'">
                      <div style="font-size: 11px; color: var(--rtm-text-muted); margin-top: 2px">
                        已下 {{ getUnloadableStatus(row).stat?.totalUnload ?? 0 }} / 剩 {{ getUnloadableStatus(row).remain ?? row.InitialQuantity ?? 0 }}
                      </div>
                    </template>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="下料进度" width="130" align="center">
                <template #default="{ row }">
                  <template v-if="getUnloadableStatus(row).status === 'done'">
                    <el-tooltip :content="`累计下料回库 ${getUnloadableStatus(row).stat?.totalUnload ?? 0}${getUnloadableStatus(row).stat?.lastUnloadingTime ? '，上次下料时间 ' + formatDateTime(getUnloadableStatus(row).stat.lastUnloadingTime) : ''}`">
                      <el-tag type="success" effect="light" size="small">✓ 已下料完毕</el-tag>
                    </el-tooltip>
                  </template>
                  <template v-else-if="getUnloadableStatus(row).status === 'partial'">
                    <el-tooltip :content="`累计下料回库 ${getUnloadableStatus(row).stat?.totalUnload ?? 0} / 实耗 ${getUnloadableStatus(row).stat?.totalActualUsed ?? 0} / 损耗 ${getUnloadableStatus(row).stat?.totalWastage ?? 0}${getUnloadableStatus(row).stat?.lastUnloadingTime ? '，上次下料时间 ' + formatDateTime(getUnloadableStatus(row).stat.lastUnloadingTime) : ''}`">
                      <el-tag type="warning" effect="light" size="small">部分下料</el-tag>
                    </el-tooltip>
                  </template>
                  <template v-else>
                    <el-tag type="info" effect="plain" size="small">未下过料</el-tag>
                  </template>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="150" align="center" fixed="right">
                <template #default="{ row }">
                  <template v-if="getUnloadableStatus(row).status === 'done'">
                    <el-button
                      type="success"
                      size="small"
                      plain
                      disabled
                    >
                      <el-icon style="margin-right: 2px"><CircleCheckFilled /></el-icon>已下料
                    </el-button>
                  </template>
                  <template v-else-if="getUnloadableStatus(row).status === 'partial'">
                    <el-button
                      type="warning"
                      size="small"
                      plain
                      @click="addRowFromLoadingRecord(row)"
                    >
                      <el-icon style="margin-right: 2px"><Download /></el-icon>继续下料
                    </el-button>
                  </template>
                  <template v-else>
                    <el-button
                      type="primary"
                      size="small"
                      plain
                      @click="addRowFromLoadingRecord(row)"
                    >
                      <el-icon style="margin-right: 2px"><Download /></el-icon>下料
                    </el-button>
                  </template>
                </template>
              </el-table-column>
            </el-table>
          </div>

          <el-empty v-if="!unloadingRows.length" description="点击「下料」或下方「新增下料记录」开始录入" :image-size="80" />

          <div v-else class="unloading-rows">
            <div v-for="(row, index) in unloadingRows" :key="index" class="unloading-row">
              <div class="unloading-row-header">
                <span class="row-index">#{{ index + 1 }}</span>
                <el-button text type="danger" size="small" @click="removeUnloadingRow(index)">
                  <el-icon><Delete /></el-icon>移除
                </el-button>
              </div>

              <div class="unloading-row-form">
                <div class="form-item">
                  <label class="form-label">输入方式</label>
                  <el-radio-group v-model="row.inputMode" size="small">
                    <el-radio-button value="select">下拉选择</el-radio-button>
                    <el-radio-button value="manual">手动输入</el-radio-button>
                  </el-radio-group>
                </div>

                <div class="form-item form-item-barcode">
                  <label class="form-label">物料批次条码</label>
                  <el-select
                    v-show="row.inputMode === 'select'"
                    v-model="row.barcode"
                    filterable
                    clearable
                    :reserve-keyword="false"
                    :popper-options="{ strategy: 'fixed' }"
                    placeholder="选择已上料的物料批次条码"
                    style="width: 100%"
                    @change="onRowBarcodeChange(row)"
                  >
                    <el-option
                      v-for="opt in barcodeOptionsForUnload"
                      :key="opt.value"
                      :label="opt.label"
                      :value="opt.value"
                    >
                      <div class="material-option">
                        <span class="material-option__main">{{ opt.label }}</span>
                        <el-tag
                          v-if="opt.packageType"
                          size="small"
                          effect="plain"
                          type="info"
                          class="material-option__pkg"
                        >{{ opt.packageType }}</el-tag>
                        <el-tag
                          v-if="opt.unloadableQty"
                          size="small"
                          effect="plain"
                          type="warning"
                        >可下 {{ opt.unloadableQty }}</el-tag>
                      </div>
                    </el-option>
                  </el-select>
                  <el-input
                    v-show="row.inputMode !== 'select'"
                    v-model="row.barcode"
                    placeholder="手动输入物料批次条码，回车确认"
                    style="width: 100%"
                    @blur="onRowBarcodeChange(row)"
                    @change="onRowBarcodeChange(row)"
                    @keyup.enter="onRowBarcodeChange(row)"
                  >
                    <template #prefix><el-icon><Search /></el-icon></template>
                  </el-input>
                </div>

                <div class="form-item">
                  <label class="form-label">下料数量</label>
                  <el-input-number
                    v-model="row.unloadQuantity"
                    :min="0"
                    :max="row.matchedMaterialInfo?.unloadableQty || 9999999"
                    style="width: 130px"
                  />
                  <span
                    v-if="row.matchedMaterialInfo"
                    class="form-item-hint"
                    :title="`初始上料 ${row.matchedMaterialInfo.initialQty ?? 0}，可下料 ${row.matchedMaterialInfo.unloadableQty ?? 0}`"
                  >
                    可下 {{ row.matchedMaterialInfo.unloadableQty ?? 0 }}
                    <span v-if="row.matchedMaterialInfo.initialQty != null" style="margin-left: 4px;">
                      / 初始 {{ row.matchedMaterialInfo.initialQty }}
                    </span>
                  </span>
                </div>

                <div class="form-item">
                  <label class="form-label">实际使用</label>
                  <el-input-number
                    v-model="row.actualUsedQuantity"
                    :min="0"
                    :max="row.matchedMaterialInfo?.initialQty || 9999999"
                    style="width: 130px"
                  />
                  <span
                    class="form-item-hint"
                    title="本次消耗在生产上的实际数量"
                  >实耗</span>
                </div>

                <div class="form-item">
                  <label class="form-label">损耗数量</label>
                  <el-input-number
                    v-model="row.wastageQuantity"
                    :min="0"
                    :max="row.matchedMaterialInfo?.initialQty || 9999999"
                    style="width: 130px"
                  />
                  <span
                    class="form-item-hint"
                    title="抛料/不良等造成的损耗"
                  >损耗</span>
                </div>

                <div class="form-item">
                  <label class="form-label">下料原因</label>
                  <el-select
                    v-model="row.reason"
                    placeholder="选择原因"
                    style="width: 150px"
                  >
                    <el-option
                      v-for="opt in unloadReasonOptions"
                      :key="opt.value"
                      :label="opt.label"
                      :value="opt.value"
                    />
                  </el-select>
                </div>

                <div class="form-item">
                  <label class="form-label">操作人</label>
                  <el-select
                    v-model="row.operatorId"
                    filterable
                    clearable
                    :popper-options="{ strategy: 'fixed' }"
                    placeholder="选择操作人"
                    style="width: 160px"
                  >
                    <el-option
                      v-for="user in operatorList"
                      :key="String(user.__value != null ? user.__value : (user.id || user.Id))"
                      :label="String(user.__label != null ? user.__label : getOperatorLabel(user))"
                      :value="user.__value != null ? user.__value : (user.id || user.Id)"
                      :disabled="(user.__value == null && user.id == null && user.Id == null)"
                    />
                  </el-select>
                </div>
              </div>

              <!-- 匹配到的物料信息展示 -->
              <div v-if="row.matchedMaterialInfo" class="matched-info">
                <el-tag size="small" effect="plain">{{ row.matchedMaterialInfo.materialCode }}</el-tag>
                <el-tag size="small" effect="plain" type="info" title="物料批次号">批次 {{ row.matchedMaterialInfo.batchNo }}</el-tag>
                <el-tag
                  v-if="row.matchedMaterialInfo.packageType"
                  size="small"
                  effect="plain"
                >封装 {{ row.matchedMaterialInfo.packageType }}</el-tag>
                <el-tag size="small" effect="plain" type="success">初始 {{ row.matchedMaterialInfo.initialQty ?? 0 }}</el-tag>
                <span v-if="row.matchedMaterialInfo.supplier" class="matched-info__supplier">
                  供应商：{{ row.matchedMaterialInfo.supplier }}
                </span>
              </div>

              <!-- 备注 -->
              <div class="unloading-row-remark">
                <el-input
                  v-model="row.remark"
                  type="textarea"
                  :rows="1.5"
                  maxlength="200"
                  show-word-limit
                  resize="none"
                  :required="Number(row.reason) === 4"
                  :placeholder="Number(row.reason) === 4 ? '选择「其他」原因必须填写备注（必填）' : '下料备注（可选，≤200字）'"
                />
              </div>

              <!-- 校验错误展示 -->
              <div v-if="row.errors && row.errors.length" class="row-validation-errors">
                <div v-for="(err, i) in row.errors" :key="i" class="row-validation-error-line">
                  <el-icon><WarningFilled /></el-icon>
                  <span>{{ err }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="unload-actions">
            <el-button type="primary" plain @click="addUnloadingRow">
              <el-icon style="margin-right: 4px"><Plus /></el-icon>新增下料记录
            </el-button>
            <el-button
              type="warning"
              size="large"
              :loading="submitting"
              :disabled="!unloadingRows.length"
              @click="submitUnloading"
            >
              <el-icon style="margin-right: 6px"><Download /></el-icon>提交下料
            </el-button>
            <el-button type="primary" plain @click="router.push('/execution/loading')">
              <el-icon style="margin-right: 4px"><Top /></el-icon>返回上料管理重新上料
            </el-button>
          </div>
        </SectionCard>
      </el-tab-pane>
    </el-tabs>

    <!-- ==================== 工站已下料记录对话框 ==================== -->
    <el-dialog
      v-model="unloadedDialogVisible"
      title="工站已下料记录"
      width="1360px"
      top="8vh"
      class="station-records-dialog"
    >
      <!-- 摘要信息卡片 -->
      <div class="records-summary-cards">
        <div class="summary-card-item">
          <div class="summary-card-icon station"><el-icon><Monitor /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">工站</span>
            <span class="summary-card-value">
              {{ unloadedOverview?.StationName || currentStation?.stationName || '-' }}
            </span>
          </div>
        </div>
        <div class="summary-card-item">
          <div class="summary-card-icon count"><el-icon><Document /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">下料记录数</span>
            <span class="summary-card-value">
              {{ filteredUnloadedList.length }}
              <span v-if="unloadedOverview && unloadedOverview.RecordCount > filteredUnloadedList.length" style="color: var(--rtm-text-muted); font-weight: 500; margin-left: 4px;">
                / {{ unloadedOverview.RecordCount }}
              </span>
              条
            </span>
          </div>
        </div>
        <div class="summary-card-item">
          <div class="summary-card-icon unload-qty"><el-icon><Download /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">累计下料总量（回库）</span>
            <span class="summary-card-value" style="color: #e6a23c">
              {{ unloadedOverview?.TotalUnloadQuantity ?? '-' }}
            </span>
          </div>
        </div>
        <div class="summary-card-item">
          <div class="summary-card-icon used-qty"><el-icon><Goods /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">累计实际使用</span>
            <span class="summary-card-value" style="color: #409eff">
              {{ unloadedOverview?.TotalActualUsedQuantity ?? '-' }}
            </span>
          </div>
        </div>
        <div class="summary-card-item">
          <div class="summary-card-icon waste-qty"><el-icon><Clock /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">
              累计损耗
              <span style="color: #f56c6c">
                {{ unloadedOverview ? unloadedOverview.TotalWastageQuantity : '-' }}
              </span>
              · 最近下料
            </span>
            <span class="summary-card-value" :title="unloadedOverview?.LastUnloadingTime">
              {{ formatDateTime(unloadedOverview?.LastUnloadingTime) || '-' }}
            </span>
          </div>
        </div>
      </div>

      <!-- 批次筛选（按 生产批次号 lotCode） -->
      <div class="records-filter-bar">
        <span class="filter-label">按生产批次筛选</span>
        <el-select
          v-model="unloadedLotFilter"
          placeholder="全部生产批次"
          clearable
          style="width: 260px"
          :disabled="unloadedLoading || !unloadedList.length"
        >
          <el-option
            v-for="opt in unloadedLotOptions"
            :key="opt.value"
            :label="opt.label"
            :value="opt.value"
          />
        </el-select>
        <span v-if="unloadedLotFilter" class="filter-tip">
          当前仅展示生产批次「{{ unloadedLotFilter }}」的下料记录，清空可查看全部
        </span>
      </div>

      <!-- 记录列表 -->
      <el-table
        v-loading="unloadedLoading"
        :data="filteredUnloadedList"
        border
        stripe
        max-height="420"
        style="margin-top: 16px"
      >
        <el-table-column label="物料批次条码" min-width="150" align="center" fixed="left">
          <template #default="{ row }">
            <span class="barcode-text">{{ row.Barcode }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="MaterialCode" label="物料编码" min-width="70" align="center" />
        <el-table-column label="生产批次号" min-width="155" align="center" show-overflow-tooltip>
          <template #default="{ row }">
            <el-tag v-if="row.LotCode" size="small" effect="plain" type="primary">{{ row.LotCode }}</el-tag>
            <span v-else style="color: var(--rtm-text-muted)">-</span>
          </template>
        </el-table-column>
        <el-table-column label="下料数量" width="90" align="center">
          <template #default="{ row }">
            <span style="font-weight: 700; color: #e6a23c">{{ row.UnloadQuantity }}</span>
          </template>
        </el-table-column>
        <el-table-column label="实际使用" width="90" align="center">
          <template #default="{ row }">
            <span style="color: var(--rtm-primary); font-weight: 600">{{ row.ActualUsedQuantity ?? 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column label="损耗数量" width="90" align="center">
          <template #default="{ row }">
            <span style="color: #f56c6c; font-weight: 600">{{ row.WastageQuantity ?? 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column label="剩余数量" width="90" align="center">
          <template #default="{ row }">
            <span style="color: #909399">{{ row.RemainQuantity ?? 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column label="下料原因" min-width="120" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.ReasonText" size="small" effect="plain">{{ row.ReasonText }}</el-tag>
            <el-tag v-else-if="row.ReasonCode" size="small" effect="plain">{{ getUnloadReasonText(row.ReasonCode) }}</el-tag>
            <span v-else style="color: var(--rtm-text-muted)">-</span>
          </template>
        </el-table-column>
        <el-table-column label="备注" min-width="130" align="center" show-overflow-tooltip>
          <template #default="{ row }">
            <span v-if="row.Remark" :title="row.Remark">{{ row.Remark }}</span>
            <span v-else style="color: var(--rtm-text-muted)">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="OperatorName" label="操作人" min-width="100" align="center" />
        <el-table-column label="下料时间" min-width="140" align="center" fixed="right">
          <template #default="{ row }">{{ formatDateTime(row.UnloadingTime) || '-' }}</template>
        </el-table-column>
      </el-table>

      <el-empty
        v-if="!unloadedLoading && !filteredUnloadedList.length"
        :description="unloadedList.length ? '当前筛选条件下无下料记录，清空批次可查看全部' : '该工站暂无下料记录'"
        :image-size="80"
      />

      <template #footer>
        <el-button @click="unloadedDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.unloading-tabs :deep(.el-tabs__header) {
  margin-bottom: 16px;
}

.unloading-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 600;
  height: 44px;
  padding: 0 24px;
}

.unloading-tabs :deep(.el-tabs__item.is-active) {
  color: var(--rtm-primary);
  font-weight: 700;
}

.mt-16 {
  margin-top: 16px;
}

/* ===== 工站卡片（与上料管理保持一致） ===== */
.station-flex {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
}

/* 批次卡片专属容器：宽松布局 —— 间距更大、每行更少 */
.station-flex.batch-grid {
  gap: 20px 24px;  /* 行间距20 列间距24 */
  padding: 4px 2px;
}

.station-card {
  position: relative;
  flex: 1 0 calc(20% - 14px);
  min-width: 180px;
  max-width: 280px;
  border: 2px solid var(--rtm-line);
  border-radius: 10px;
  padding: 14px 16px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #fff;
  box-sizing: border-box;
}

/* 批次卡片专属：每行4个 + 更大的最小宽度与内边距 */
.batch-grid .station-card {
  flex: 1 0 calc(25% - 24px);
  min-width: 240px;
  max-width: 320px;
  padding: 18px 20px;
}

.station-card:hover {
  border-color: var(--rtm-primary);
  box-shadow: 0 4px 12px rgba(31, 95, 153, 0.12);
  transform: translateY(-1px);
}

.station-card.active {
  border-color: #e6a23c;
  background: linear-gradient(135deg, #fdf6ec 0%, #fefaf3 100%);
  box-shadow: 0 4px 14px rgba(230, 162, 60, 0.18);
}

.station-card.active::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  border-radius: 10px 10px 0 0;
  background: #e6a23c;
}

.station-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}

.station-seq {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 6px;
  background: #e6a23c;
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}

/* 批次卡片：序号方块用绿色调与工站卡片区分；内部放 Tickets 图标时字号调大 */
.batch-card .station-seq {
  background: #67c23a;
  width: 28px;
  font-size: 11px;
}
.batch-card .station-seq.station-seq-icon {
  font-size: 16px;
}

.batch-card.active {
  border-color: #67c23a;
  background: linear-gradient(135deg, #f0f9eb 0%, #f5fbf0 100%);
  box-shadow: 0 4px 14px rgba(103, 194, 58, 0.18);
}

.batch-card.active::before {
  background: #67c23a;
}

.station-code {
  font-weight: 700;
  font-size: 15px;
  color: var(--rtm-text);
  flex: 1;
}

.station-card-body {
  font-size: 13px;
  color: var(--rtm-text-soft);
  line-height: 1.9;
}

.station-info-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.station-info-row .label {
  min-width: 36px;
  color: var(--rtm-text-muted);
  flex-shrink: 0;
  text-align: right;
}

.station-info-row .value {
  color: var(--rtm-text);
  font-weight: 500;
}

/* ===== 当前上下文信息条 ===== */
.current-context-bar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 10px 16px;
  background: linear-gradient(90deg, #fdf6ec 0%, #f8fafc 100%);
  border: 1px solid #f5dab1;
  border-radius: 8px;
  margin-bottom: 16px;
}

.context-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.context-label {
  font-size: 11px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.context-value {
  font-size: 14px;
  color: var(--rtm-text);
  font-weight: 700;
}

/* ===== 区块标题 ===== */
.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  color: var(--rtm-text);
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--rtm-line);
}

/* ===== 工站已下料记录弹窗（仿上料管理） ===== */
/* 由于 el-dialog 默认 teleport 到 body，使用 :deep() 穿透到对话框内部节点（body/header/footer） */
.station-records-dialog :deep(.el-dialog__body) {
  padding: 20px 24px;
}

.records-filter-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 16px;
  padding: 10px 14px;
  background: var(--rtm-panel-soft, #f8fafc);
  border: 1px solid var(--rtm-line);
  border-radius: 8px;
}

.records-filter-bar .filter-label {
  font-size: 12px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.records-filter-bar .filter-tip {
  font-size: 12px;
  color: #e6a23c;
  font-weight: 500;
}

.records-summary-cards {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  margin-top: 2px;
}

.summary-card-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: var(--rtm-panel-soft, #f8fafc);
  border: 1px solid var(--rtm-line);
  border-radius: 8px;
}

.summary-card-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  font-size: 18px;
  flex-shrink: 0;
}

.summary-card-icon.station {
  background: #ecf5ff;
  color: #409eff;
}

.summary-card-icon.count {
  background: #f0f9eb;
  color: #67c23a;
}

.summary-card-icon.unload-qty {
  background: #fdf6ec;
  color: #e6a23c;
}

.summary-card-icon.used-qty {
  background: #ecf5ff;
  color: #409eff;
}

.summary-card-icon.waste-qty {
  background: #fef0f0;
  color: #f56c6c;
}

.summary-card-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow: hidden;
}

.summary-card-label {
  font-size: 11px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.summary-card-value {
  font-size: 14px;
  color: var(--rtm-text);
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.barcode-text {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 14px;
  color: var(--rtm-primary);
  font-weight: 600;
}

/* ===== 下料录入行（与上料录入行视觉一致） ===== */
.unloading-rows {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-bottom: 14px;
}

.unloading-row {
  background: var(--rtm-panel-soft, #fafbfc);
  border: 1px solid var(--rtm-line);
  border-radius: 10px;
  padding: 14px 16px 12px;
}

.unloading-row-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px dashed var(--rtm-line);
}

.row-index {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 30px;
  height: 22px;
  padding: 0 8px;
  border-radius: 11px;
  background: #e6a23c;
  color: #fff;
  font-size: 12px;
  font-weight: 700;
}

.unloading-row-form {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  align-items: flex-start;
}

.unloading-row-form .form-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.unloading-row-form .form-label {
  font-size: 12px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.unloading-row-form .form-item-barcode {
  flex: 1 1 300px;
  min-width: 260px;
}

.form-item-hint {
  display: inline-block;
  margin-top: 6px;
  margin-left: 6px;
  font-size: 12px;
  color: var(--rtm-text-muted);
}

/* 物料信息展示 */
.matched-info {
  margin-top: 10px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
}

.matched-info :deep(.el-tag) {
  font-size: 11px;
}

.matched-info__supplier {
  margin-left: 4px;
  font-size: 12px;
  color: var(--rtm-text-muted);
}

.unloading-row-remark {
  margin-top: 10px;
}

/* 校验错误 */
.row-validation-errors {
  margin-top: 10px;
  padding: 8px 10px;
  background: #fef0f0;
  border: 1px solid #fde2e2;
  border-radius: 6px;
}

.row-validation-error-line {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #f56c6c;
  font-size: 12px;
  font-weight: 500;
  line-height: 1.7;
}

/* 物料下拉选项 */
.material-option {
  display: flex;
  align-items: center;
  gap: 8px;
}

.material-option__main {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  font-weight: 600;
}

.material-option__pkg {
  margin-left: auto;
}

/* ===== 工站已上料记录区 ===== */
.loading-records-section {
  margin-bottom: 16px;
  padding: 12px 14px;
  background: var(--rtm-panel-soft, #f8fafc);
  border: 1px solid var(--rtm-line);
  border-radius: 10px;
}

.loading-records-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.loading-records-title {
  font-size: 13px;
  font-weight: 700;
  color: var(--rtm-text);
  display: flex;
  align-items: center;
  gap: 4px;
}

.loading-records-loading {
  font-size: 12px;
  color: var(--rtm-text-muted);
}

/* ===== 提交动作区 ===== */
.unload-actions {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 10px 0 4px;
  border-top: 1px dashed var(--rtm-line);
}

@media (max-width: 900px) {
  .station-card {
    flex: 1 0 100%;
    max-width: 100%;
  }

  .current-context-bar {
    flex-wrap: wrap;
  }

  .unloading-row-form {
    flex-direction: column;
  }

  .unloading-row-form .form-item {
    width: 100%;
  }

  .records-summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
