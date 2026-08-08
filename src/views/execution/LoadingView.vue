<script setup>
import { computed, reactive, ref, watch, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { getOperators } from '@/api/user'
import {
  getMaterialLots,
  createMaterialLot as createMaterialLotApi,
  updateMaterialLotStatus as updateMaterialLotStatusApi,
  getMaterialLotBarcodeOptions,
  getPendingLoadingLots,
  getLoadingStations,
  getStationLoadingRecords as getStationLoadingRecordsApi,
  createLoadingRecords,
  verifyLoadingRecord,
} from '@/api/materialLot'
import { getMaterialOptions } from '@/api/material'
import { formatDate, formatDateTime } from '@/utils/format'

const router = useRouter()

// ==================== Tab 切换 ====================
const activeTab = ref('materialLot')

// ==================== Tab 1: 物料批次管理 ====================
const lotListLoading = ref(false)
const lotList = ref([])
const lotFilters = reactive({
  MaterialCode: '',
  Status: '',
  BatchNo: '',
  Supplier: '',
  ExpiryDateRange: [],
  InboundDateRange: [],
})
const lotPagination = reactive({ pageNum: 1, pageSize: 10, total: 0 })

const createDialogVisible = ref(false)
const createForm = reactive({
  MaterialCode: '',
  Supplier: '',
  SupplierBatchNo: '',
  Quantity: 0,
  ProductionDate: '',
  ExpiryDate: '',
  MslLevel: '',
  InboundDate: '',
})
const createSubmitting = ref(false)
const createdLotInfo = ref(null) // 创建成功后展示后端返回的 BatchNo/Barcode

// 物料编码下拉选项：通过接口 /api/materials/options 获取
const materialOptions = ref([])
const materialOptionsLoading = ref(false)
// 所有物料完整信息（包含 desc、package、brand），供按 MaterialCode 查找详情
const allMaterials = ref([])

// 将单条物料归一化
// 兼容多种字段命名：小驼峰、PascalCase、下划线、ID 关联字段等
function normalizeMaterial(m) {
  if (!m) return null
  const code = m.MaterialCode ?? m.materialCode ?? m.Code ?? m.code ?? m.material_code ?? m.MatCode ?? m.matCode
  const desc = m.MaterialDesc ?? m.materialName ?? m.materialDesc ?? m.MaterialName ?? m.Desc ?? m.desc ?? m.Name ?? m.name ?? m.material_name ?? ''
  // 兼容 PackageType（字符串名称）和 PackageTypeId（数字关联 ID）
  const packageType = m.PackageType ?? m.packageType ?? m.PackageTypeName ?? m.packageTypeName ?? m.PackageTypeId ?? m.packageTypeId
  const brand = m.Brand ?? m.brand ?? m.BrandName ?? m.brandName ?? ''
  return {
    ...m,
    MaterialCode: code,
    MaterialDesc: desc,
    PackageType: typeof packageType === 'number' ? `类型${packageType}` : packageType,
    Brand: brand,
    __label: code ? (desc ? `${code} (${desc})` : code) : '',
  }
}

async function loadMaterialOptions(keyword) {
  materialOptionsLoading.value = true
  try {
    const params = keyword ? { keyword } : {}
    const data = await getMaterialOptions(params)
    console.log('[Loading] 物料接口原始返回：', data)

    // 兼容多种后端响应格式：
    //   1. 直接数组：[{...}, {...}]
    //   2. 标准分页：{ list/content/records/rows/items/data: [...], total }
    //   3. 对象包装但无外层 code：{ data: [...] }
    let raw = []
    if (Array.isArray(data)) {
      raw = data
    } else if (data && typeof data === 'object') {
      raw = data.list
        || data.content
        || data.records
        || data.rows
        || data.items
        || data.data
        || (Array.isArray(data.Data) ? data.Data : [])
    }
    console.log('[Loading] 物料接口解析后 raw list 条数：', raw?.length || 0)

    const list = (raw || []).map(normalizeMaterial).filter((m) => m && m.MaterialCode)
    console.log('[Loading] 物料接口归一化后有效条数：', list.length)
    if (list.length) {
      console.log('[Loading] 前 5 条物料：', list.slice(0, 5).map((m) => `${m.MaterialCode} - ${m.MaterialDesc}`))
    }

    // 合并到 allMaterials，避免覆盖已缓存
    const merged = [...allMaterials.value]
    list.forEach((item) => {
      const idx = merged.findIndex((x) => x.MaterialCode === item.MaterialCode)
      if (idx >= 0) merged[idx] = item
      else merged.push(item)
    })
    allMaterials.value = merged
    materialOptions.value = list
      .filter((m) => m && m.MaterialCode != null && String(m.MaterialCode) !== '')
      .map((m) => ({
        value: String(m.MaterialCode),
        label: String(m.__label || m.MaterialCode || ''),
        PackageType: m.PackageType,
        Brand: m.Brand,
      }))
      // 仅过滤掉 value/label 为 null/undefined/空字符串 的选项，避免过滤过严导致下拉全空
      .filter((o) =>
        o.value != null && o.value !== '' &&
        o.label != null && o.label !== '',
      )
    console.log('[Loading] 物料编码下拉最终条数：', materialOptions.value.length)
    // 如果使用了筛选条件后返回的列表为空，但缓存中有数据，回退到缓存筛选
    if (!materialOptions.value.length && allMaterials.value.length) {
      let cacheList = allMaterials.value
      if (keyword) {
        const kw = String(keyword).toLowerCase()
        cacheList = cacheList.filter((m) =>
          String(m.MaterialCode || '').toLowerCase().includes(kw)
          || String(m.MaterialDesc || '').toLowerCase().includes(kw),
        )
      }
      materialOptions.value = cacheList
        .filter((m) => m && m.MaterialCode != null && String(m.MaterialCode) !== '')
        .map((m) => ({
          value: String(m.MaterialCode),
          label: String(m.__label || m.MaterialCode || ''),
          PackageType: m.PackageType,
          Brand: m.Brand,
        }))
        .filter((o) =>
          o.value != null && o.value !== '' &&
          o.label != null && o.label !== '',
        )
      console.log('[Loading] 物料编码下拉（缓存回退）最终条数：', materialOptions.value.length)
    }
  } catch (error) {
    console.warn('[Loading] 物料编码接口失败：', error)
    materialOptions.value = []
    ElMessage.warning('物料编码列表接口暂不可用，请稍后重试')
  } finally {
    materialOptionsLoading.value = false
  }
}

// el-select remote-method
function materialRemoteSearch(query) {
  loadMaterialOptions(query || undefined)
}

// 选中物料时展示的参考信息：从 allMaterials（接口返回的最新数据）中查找
const selectedMaterialInfo = computed(() => {
  if (!createForm.MaterialCode) return null
  return allMaterials.value.find((item) => item.MaterialCode === createForm.MaterialCode) || null
})

const lotStatusOptions = [
  { value: '', label: '全部状态' },
  { value: '在库', label: '在库' },
  { value: '已使用', label: '已使用' },
  { value: '已冻结', label: '已冻结' },
  { value: '已报废', label: '已报废' },
]

function lotStatusTagType(status) {
  const map = { 在库: 'success', 已使用: 'info', 已冻结: 'warning', 已报废: 'danger' }
  return map[status] || 'info'
}

function remainingQuantity(row) {
  return (row.Quantity || 0) - (row.UsedQuantity || 0)
}

function isExpired(row) {
  // 优先使用后端返回的 expired 字段（后端按 当天日期 > 有效期 计算）
  if (typeof row.Expired === 'boolean') return row.Expired
  // 降级：后端未返回时前端自行计算（兼容旧数据/mock）
  if (!row.ExpiryDate) return false
  return new Date(row.ExpiryDate) < new Date()
}

// 重置筛选条件并重新加载列表
function resetFilters() {
  lotFilters.MaterialCode = ''
  lotFilters.Status = ''
  lotFilters.BatchNo = ''
  lotFilters.Supplier = ''
  lotFilters.ExpiryDateRange = []
  lotFilters.InboundDateRange = []
  loadLotList()
}

// 统一格式化日期字段：纯日期用 YYYY-MM-DD
// （底层走 utils/format.js 的 formatDate(value, 'YYYY-MM-DD')，空值返回空串，模板层再用 || '-'）
function _fmtDate(v) {
  return formatDate(v, 'YYYY-MM-DD')
}

// 将仅日期的字符串（yyyy-MM-dd）补齐为 LocalDateTime 格式
//   start=true  → 补 T00:00:00（当日起始，用于起始边界）
//   start=false → 补 T23:59:59（当日结束，用于结束边界，如 inboundEnd）
function toLocalDateTime(dateStr, start = true) {
  if (!dateStr) return null
  const s = String(dateStr).trim()
  if (!s) return null
  // 已是 datetime 格式（包含 T 或 空格+时分），直接返回标准化
  if (/[T\s]\d{1,2}:\d{1,2}/.test(s)) return s.replace(' ', 'T')
  // 纯日期 → 补齐
  const time = start ? 'T00:00:00' : 'T23:59:59'
  return s.slice(0, 10) + time
}

// 判断是否为有意义的展示值（排除 '-', 'null', 'undefined', 空串等无效占位值）
function isValidDisplay(value) {
  if (value == null) return false
  const s = String(value).trim()
  if (!s) return false
  const invalid = new Set(['-', '—', 'null', 'undefined', 'nan', 'none', 'n/a', 'unknown'])
  return !invalid.has(s.toLowerCase())
}

// 文本截断，超出 maxLen 显示省略号（通过 title 属性展示完整内容）
function ellipsis(text, maxLen = 10) {
  if (!isValidDisplay(text)) return ''
  const s = String(text)
  return s.length > maxLen ? s.slice(0, maxLen) + '…' : s
}

// 将后端可能返回的小驼峰/下划线字段统一为前端使用的 PascalCase 字段，保持列表展示一致
// 特别注意：后端使用 currentQuantity 表示剩余库存，usedQuantity 表示已使用，inboundQuantity 表示入库数量
function normalizeMaterialLot(item) {
  if (!item) return null
  const inboundQuantity = item.Quantity ?? item.quantity ?? item.inboundQuantity ?? 0
  const usedQuantity = item.UsedQuantity ?? item.usedQuantity ?? 0
  const currentQuantity = item.currentQuantity
    ?? item.RemainingQuantity
    ?? item.remainingQuantity
    ?? (typeof inboundQuantity === 'number' && typeof usedQuantity === 'number' ? inboundQuantity - usedQuantity : undefined)
  return {
    ...item,
    Id: item.Id ?? item.id,
    MaterialCode: item.MaterialCode ?? item.materialCode,
    BatchNo: item.BatchNo ?? item.batchNo,
    Supplier: item.Supplier ?? item.supplier,
    SupplierBatchNo: item.SupplierBatchNo ?? item.supplierBatchNo,
    Quantity: inboundQuantity,
    inboundQuantity,
    currentQuantity,
    UsedQuantity: usedQuantity,
    ProductionDate: item.ProductionDate ?? item.productionDate,
    ExpiryDate: item.ExpiryDate ?? item.expiryDate,
    MslLevel: item.MslLevel ?? item.mslLevel,
    InboundDate: item.InboundDate ?? item.inboundDate,
    Status: item.Status ?? item.status,
    Barcode: item.Barcode ?? item.barcode,
    Expired: item.Expired ?? item.expired ?? null,
  }
}

function buildApiFilters() {
  // 对齐 GET /api/material-lots 后端接口 Query 参数
  const f = {
    materialCode: lotFilters.MaterialCode || undefined,
    status: lotFilters.Status || undefined,
    keyword: lotFilters.BatchNo || undefined,   // 批次号/条码关键字模糊匹配
    supplier: lotFilters.Supplier || undefined,  // 供应商模糊匹配
    pageNum: lotPagination.pageNum,
    pageSize: lotPagination.pageSize,
  }
  if (lotFilters.ExpiryDateRange && lotFilters.ExpiryDateRange.length === 2) {
    f.expiryStart = lotFilters.ExpiryDateRange[0] || undefined
    f.expiryEnd = lotFilters.ExpiryDateRange[1] || undefined
  }
  if (lotFilters.InboundDateRange && lotFilters.InboundDateRange.length === 2) {
    // 后端 inboundStart / inboundEnd 为 <date-time>，必须带时分秒
    f.inboundStart = toLocalDateTime(lotFilters.InboundDateRange[0], true) || undefined
    f.inboundEnd = toLocalDateTime(lotFilters.InboundDateRange[1], false) || undefined
  }
  return f
}

// 判断用户是否设置了任何筛选条件，用于空数据时的提示
function hasAnyLotFilter() {
  const f = buildApiFilters()
  return !!(f.materialCode || f.status || f.keyword || f.supplier || f.expiryStart || f.expiryEnd || f.inboundStart || f.inboundEnd)
}

async function loadLotList() {
  lotListLoading.value = true
  try {
    const apiParams = buildApiFilters()
    console.log('[Loading] GET /api/material-lots 参数：', apiParams)
    // request 会解包外层 code/message/data，此处得到的就是内层分页对象
    const data = await getMaterialLots(apiParams)
    console.log('[Loading] API 返回原始数据：', data)

    // 兼容多种后端响应格式：
    //   1. 标准分页：{ pageNum, pageSize, total, totalPages, list: [] }
    //   2. Spring Data：{ content: [], totalElements, pageable: {...} }
    //   3. 直接数组：[{...}, {...}]
    //   4. 其他分页：{ records/rows/items, total/count }
    const pageData = Array.isArray(data)
      ? { list: data, total: data.length, pageNum: 1, pageSize: data.length }
      : data || {}
    const rawList = pageData.list
      || pageData.content
      || pageData.records
      || pageData.rows
      || pageData.items
      || []
    const total = pageData.total
      ?? pageData.totalElements
      ?? pageData.count
      ?? rawList.length

    if (typeof pageData.pageNum === 'number' && pageData.pageNum > 0) {
      lotPagination.pageNum = pageData.pageNum
    }
    if (typeof pageData.pageSize === 'number' && pageData.pageSize > 0) {
      lotPagination.pageSize = pageData.pageSize
    }
    lotList.value = rawList.map(normalizeMaterialLot).filter(Boolean)
    lotPagination.total = total
    console.log('[Loading] 解析结果：total=%d, 当前页条数=%d', total, lotList.value.length)
    // 数据为空时给出明确提示，避免用户以为是前端 bug
    if (!total || lotList.value.length === 0) {
      if (hasAnyLotFilter()) {
        ElMessage.info('暂无符合筛选条件的物料批次，可尝试清除筛选条件后查询')
      } else {
        ElMessage.info('暂无物料批次数据，请点击「新建批次」创建第一条记录')
      }
    }
  } catch (error) {
    console.warn('[Loading] API 获取物料批次列表失败：', error)
    lotList.value = []
    lotPagination.total = 0
    ElMessage.warning('物料批次列表接口暂不可用，请稍后重试')
  } finally {
    lotListLoading.value = false
  }
}

// 表格数据源：后端已分页，直接使用 lotList，不再前端二次 slice
// （之前的前端二次分页会在翻页后导致 lotList 只有当前页数据，slice 起始位置超出数组长度，显示为空）
const pagedLotList = computed(() => lotList.value)

function handleLotPageChange(pageNum) {
  lotPagination.pageNum = pageNum
}
function handleLotSizeChange(pageSize) {
  lotPagination.pageSize = pageSize
  lotPagination.pageNum = 1
}

function resetCreateForm() {
  createForm.MaterialCode = ''
  createForm.Supplier = ''
  createForm.SupplierBatchNo = ''
  createForm.Quantity = 0
  createForm.ProductionDate = ''
  createForm.ExpiryDate = ''
  createForm.MslLevel = ''
  createForm.InboundDate = ''
  createdLotInfo.value = null
}

async function submitCreateLot() {
  if (!createForm.MaterialCode) {
    ElMessage.error('请选择物料编码')
    return
  }
  if (!createForm.Quantity || createForm.Quantity <= 0) {
    ElMessage.error('入库数量必须大于 0')
    return
  }
  if (!createForm.InboundDate) {
    ElMessage.error('请选择入库日期')
    return
  }

  createSubmitting.value = true
  try {
    // 对齐后端接口 POST /api/material-lots 的小驼峰参数
    // 特别注意：inboundDate 后端是 LocalDateTime，前端仅返回 YYYY-MM-DD，需要补 T00:00:00 否则后端反序列化失败
    const payload = {
      materialCode: createForm.MaterialCode,
      inboundQuantity: Number(createForm.Quantity),
      inboundDate: toLocalDateTime(createForm.InboundDate, true),
      supplier: createForm.Supplier || null,
      supplierBatchNo: createForm.SupplierBatchNo || null,
      productionDate: toLocalDateTime(createForm.ProductionDate, true),
      expiryDate: toLocalDateTime(createForm.ExpiryDate, true),
      mslLevel: createForm.MslLevel != null && createForm.MslLevel !== '' ? Number(createForm.MslLevel) : undefined,
    }
    console.log('[Loading] POST /api/material-lots 请求参数：', payload)
    // createMaterialLot 走 _fullResponse，返回完整响应体 { code, message, data }
    const body = await createMaterialLotApi(payload)
    console.log('[Loading] POST /api/material-lots 返回数据：', body)
    // 后端对三个日期校验失败返回 code=202(PARAM_ERROR) + 具体消息，直接展示给用户，不再由前端校验
    const respCode = body?.code ?? body?.Code
    const respMsg = body?.message ?? body?.Message
    if (respCode !== 200 && respCode !== 0) {
      ElMessage.error(respMsg || '物料批次创建失败')
      return
    }
    const data = body?.data
    if (!data) {
      console.warn('[Loading] ⚠️ 后端返回 data 为空，可能未实际保存。请检查后端 POST 接口是否写入了数据库。')
    }
    // 后端返回包含后端生成的 batchNo / BatchNo、barcode / Barcode
    // 容错：即使后端返回 null（如标准包装 {code:200, data:null} 或 data 为空对象），创建仍算成功，
    // 只是提示信息中缺少批次号/条码，用用户输入的物料编码作为 fallback
    const normalized = data && typeof data === 'object'
      ? {
          Id: data.Id ?? data.id,
          BatchNo: data.BatchNo ?? data.batchNo,
          Barcode: data.Barcode ?? data.barcode,
          ...data,
        }
      : null
    createdLotInfo.value = normalized
    const batchNo = normalized?.BatchNo ?? normalized?.batchNo ?? ''
    const successTip = batchNo
      ? `（批次号：${batchNo}）`
      : (createForm.MaterialCode ? `（物料：${createForm.MaterialCode}）` : '')
    // 后端成功 message 形如 "新建成功，物料批次条码：xxx"，有则优先展示
    ElMessage.success(respMsg || `物料批次创建成功${successTip}`)
    // 创建成功后关闭对话框，回到第 1 页并刷新列表
    createDialogVisible.value = false
    resetCreateForm()
    lotPagination.pageNum = 1
    await loadLotList()
  } catch (error) {
    console.warn('[Loading] API 创建物料批次失败：', error)
    ElMessage.error('物料批次创建失败，请稍后重试')
  } finally {
    createSubmitting.value = false
  }
}

async function handleStatusChange(row, newStatus) {
  try {
    await ElMessageBox.confirm(
      `确认将物料批次 ${row.BatchNo} 的状态变更为「${newStatus}」？`,
      '状态变更确认',
      { type: 'warning' },
    )
  } catch {
    return
  }

  try {
    await updateMaterialLotStatusApi(row.Id, newStatus)
    ElMessage.success('状态变更成功')
    await loadLotList()
  } catch (error) {
    console.warn('[Loading] API 修改状态失败：', error)
    ElMessage.error('状态变更失败，请稍后重试')
  }
}

function copyBarcode(row) {
  navigator.clipboard?.writeText(row.Barcode).then(() => {
    ElMessage.success('条码已复制')
  }).catch(() => {
    ElMessage.warning('复制失败，请手动复制')
  })
}

// ==================== Tab 2: 上料操作 ====================
const operatorList = ref([])

// ① 选中的已投产批次
const selectedBatchId = ref(null)
// ② 选中的工站
const selectedStationId = ref(null)

// 上料录入行（支持多批次）
const loadingRows = ref([])
const submitting = ref(false)

// 归一化待上料批次字段：兼容后端返回的多种命名
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
    currentOperation: item.currentOperation
      ?? item.currentOperationName
      ?? item.CurrentOperation
      ?? item.CurrentOperationName
      ?? '',
  }
}

// ① 加载已投产（待上料）批次列表（真实 API：GET /api/loading/pending-lots）
async function loadBatchList() {
  batchListLoading.value = true
  try {
    console.log('[Loading] GET /api/loading/pending-lots')
    const data = await getPendingLoadingLots()
    console.log('[Loading] 待上料批次列表原始返回：', data)
    let raw = []
    if (Array.isArray(data)) raw = data
    else if (data && typeof data === 'object')
      raw = data.list
        || data.content
        || data.records
        || data.rows
        || data.items
        || data.data
        || (Array.isArray(data.Data) ? data.Data : [])
    const list = (raw || []).map(normalizePendingLot).filter(Boolean)
    batchList.value = list
    console.log('[Loading] 待上料批次列表解析后条数：', list.length)
  } catch (error) {
    console.warn('[Loading] 待上料批次列表接口失败：', error)
    batchList.value = []
    ElMessage.warning('待上料批次列表接口暂不可用，请稍后重试')
  } finally {
    batchListLoading.value = false
  }
}

// ② 按批次 id 加载该批次工艺路线下的工站列表（真实 API：GET /api/loading/stations?lotId=xxx）
async function loadBatchStations(batchId) {
  if (!batchId) {
    batchStations.value = []
    return
  }
  batchStationsLoading.value = true
  try {
    const params = { lotId: Number(batchId) }
    console.log('[Loading] GET /api/loading/stations 参数：', params)
    const data = await getLoadingStations(params)
    console.log('[Loading] 批次工站列表原始返回：', data)
    let raw = []
    if (Array.isArray(data)) raw = data
    else if (data && typeof data === 'object')
      raw = data.list
        || data.content
        || data.records
        || data.rows
        || data.items
        || data.data
        || (Array.isArray(data.Data) ? data.Data : [])
    const list = (raw || []).map((item, i) => normalizeLoadingStation(item, i)).filter(Boolean)
    list.sort((a, b) => (a.sequence || 0) - (b.sequence || 0))
    batchStations.value = list
    console.log('[Loading] 批次工站列表解析后条数：', list.length)
  } catch (error) {
    console.warn('[Loading] 批次工站列表接口失败：', error)
    batchStations.value = []
    ElMessage.warning('工站列表接口暂不可用，请稍后重试')
  } finally {
    batchStationsLoading.value = false
  }
}

async function loadOperatorList() {
  try {
    const data = await getOperators()
    console.log('[Loading] GET /api/user/operators 原始返回：', data)
    // 兼容多种响应结构：数组 / 分页包装 list/content/records/rows/items/data
    let list = []
    if (Array.isArray(data)) {
      list = data
    } else if (data && typeof data === 'object') {
      list = data.list
        || data.content
        || data.records
        || data.rows
        || data.items
        || data.data
        || (Array.isArray(data.Data) ? data.Data : [])
    }
    // 字段归一（小驼峰 / PascalCase 都兼容）
    operatorList.value = list
      .filter((u) => u && (u.id ?? u.Id ?? u.userId ?? u.UserId) != null)
      .map((u) => {
        const id = u.id ?? u.Id ?? u.userId ?? u.UserId
        const username = u.username ?? u.Username ?? ''
        const fullName = u.fullName ?? u.FullName ?? u.name ?? u.Name ?? ''
        const position = u.position ?? u.Position ?? u.post ?? u.Post ?? ''
        const department = u.department ?? u.Department ?? u.dept ?? u.Dept ?? ''
        // :value / :label 强制非空，避免 el-option value 为 undefined 触发内部 testOptions 空引用
        return {
          ...u,
          id,
          Id: id,
          username,
          Username: username,
          fullName,
          FullName: fullName,
          position,
          Position: position,
          department,
          Department: department,
          __value: id,
          __label: [fullName, position, department].filter(Boolean).join(' / ') || username || `用户${id}`,
        }
      })
      .filter((u) =>
        u.__value != null && u.__value !== '' &&
        u.__label != null && u.__label !== '',
      )
    console.log('[Loading] 操作人下拉最终条数：', operatorList.value.length)
  } catch (error) {
    console.warn('[Loading] API 获取操作人列表失败：', error)
    operatorList.value = []
    ElMessage.warning('操作人列表接口暂不可用，请稍后重试')
  }
}

// ① 已投产批次列表
const batchList = ref([])
const batchListLoading = ref(false)

// ② 当前批次下的工站列表
const batchStations = ref([])
const batchStationsLoading = ref(false)

// 归一化工站字段（兼容后端多种命名 + 设备类型 → equipmentTypeId 兜底）
function normalizeLoadingStation(item, index) {
  if (!item) return null
  const id = item.id ?? item.Id ?? item.stationId ?? item.StationId
  const stationCode = item.stationCode ?? item.StationCode ?? '-'
  const stationName = item.stationName ?? item.StationName ?? '-'
  const operationName = item.operationName ?? item.OperationName ?? '-'
  const equipmentTypeName = item.equipmentTypeName ?? item.EquipmentTypeName ?? '-'
  const equipTypeNameStr = String(equipmentTypeName || '')
  let equipmentTypeId = item.equipmentTypeId ?? item.EquipmentTypeId
  if (!equipmentTypeId) {
    if (equipTypeNameStr.includes('印刷')) equipmentTypeId = 1
    else if (equipTypeNameStr.includes('SPI')) equipmentTypeId = 2
    else if (equipTypeNameStr.includes('贴片')) equipmentTypeId = 3
    else if (equipTypeNameStr.includes('回流')) equipmentTypeId = 4
    else if (equipTypeNameStr.includes('AOI')) equipmentTypeId = 5
  }
  return {
    ...item,
    id,
    routeStepId: id, // 前端内部使用 routeStepId 作为选中主键，保持与 submit/查记录逻辑一致
    stationId: id,
    equipmentId: item.equipmentId ?? item.EquipmentId ?? id,
    equipmentTypeId,
    sequence: item.sequence ?? item.Sequence ?? index + 1,
    stationCode,
    stationName,
    operationName,
    equipmentCode: item.equipmentCode ?? item.EquipmentCode ?? stationCode,
    equipmentName: item.equipmentName ?? item.EquipmentName ?? stationName,
    equipmentTypeName,
  }
}

// 当前选中的批次
const currentBatch = computed(() => {
  if (!selectedBatchId.value) return null
  return batchList.value.find((b) => b.id === selectedBatchId.value) || null
})

// 当前选中的工站（从批次工站列表中查找）
const currentStation = computed(() => {
  if (!selectedStationId.value) return null
  return batchStations.value.find((s) => s.routeStepId === selectedStationId.value) || null
})

// 物料批次条码下拉选项（接口：GET /api/material-lots/barcode-options）
// 后端已过滤：status = '在库' AND currentQuantity > 0
// 策略：首次展开时拉一次「全部」→ 缓存 allBarcodeOptions；搜索框输入时走本地过滤 barcodeRemoteSearch
//       核心目的：避免 filterable + 每次输入触发远程请求 导致选项闪烁（"一下有一下没"）
const barcodeOptions = ref([])
const allBarcodeOptions = ref([]) // 缓存：接口加载的全部条码选项（本地过滤的源数据）
const barcodeOptionsLoading = ref(false)

function normalizeBarcodeOption(item) {
  if (!item) return null
  const materialLotId = item.materialLotId ?? item.MaterialLotId ?? item.id ?? item.Id
  const barcode = item.barcode ?? item.Barcode
  const materialCode = item.materialCode ?? item.MaterialCode
  const currentQuantity = item.currentQuantity
    ?? item.CurrentQuantity
    ?? item.RemainingQuantity
    ?? item.remainingQuantity
  const status = item.status ?? item.Status
  return {
    ...item,
    materialLotId,
    barcode,
    materialCode,
    currentQuantity,
    status,
    __value: barcode,
    __label: barcode ? (materialCode ? `${barcode} (${materialCode})` : barcode) : '',
  }
}

// 从接口加载全部在库条码选项，刷新 allBarcodeOptions + barcodeOptions
// 调用时机：下拉框每次展开（handleBarcodeVisibleChange），保证用户新建的物料批次能立刻出现
// keyword 在加载时不传，拉"全量在库"；搜索框输入时走本地过滤 barcodeRemoteSearch，不重复请求
async function loadBarcodeOptions() {
  barcodeOptionsLoading.value = true
  try {
    console.log('[Loading] GET /api/material-lots/barcode-options（展开下拉，加载全部在库条码）')
    const data = await getMaterialLotBarcodeOptions({})
    console.log('[Loading] 条码下拉接口原始返回：', data)

    // 兼容多种响应结构：直接数组 / 包装对象（list/content/records/rows/items/data）
    let raw = []
    if (Array.isArray(data)) {
      raw = data
    } else if (data && typeof data === 'object') {
      raw = data.list
        || data.content
        || data.records
        || data.rows
        || data.items
        || data.data
        || (Array.isArray(data.Data) ? data.Data : [])
    }
    console.log('[Loading] 条码下拉接口解析后条数：', raw?.length || 0)

    const list = (raw || []).map(normalizeBarcodeOption).filter((o) => o && o.barcode)
    // 只展示剩余库存 > 0 的（后端已过滤，但前端也兜底）
    const filtered = list.filter((o) => (o.currentQuantity ?? Number.MAX_SAFE_INTEGER) > 0)
    const options = filtered
      .map((o) => ({
        value: String(o.__value || ''),
        label: String(o.__label || o.__value || ''),
        materialCode: o.materialCode,
        currentQuantity: o.currentQuantity,
      }))
      .filter((o) =>
        o.value != null && o.value !== '' &&
        o.label != null && o.label !== '',
      )
    // 缓存全部 + 同步到当前显示
    allBarcodeOptions.value = options
    barcodeOptions.value = options
    console.log('[Loading] 物料批次条码下拉最终条数：', barcodeOptions.value.length)
  } catch (error) {
    console.warn('[Loading] 条码下拉接口失败：', error)
    allBarcodeOptions.value = []
    barcodeOptions.value = []
    ElMessage.warning('物料批次条码列表接口暂不可用，请稍后重试')
  } finally {
    barcodeOptionsLoading.value = false
  }
}

// el-select remote-method：本地过滤 allBarcodeOptions，不触发网络请求
// 这样输入/清空搜索时选项立即响应，不会出现"一下有一下没"的闪烁
function barcodeRemoteSearch(query) {
  const kw = (typeof query === 'string' ? query.trim() : '').toLowerCase()
  if (!kw) {
    // 搜索框为空：恢复全部
    barcodeOptions.value = allBarcodeOptions.value
    return
  }
  // 本地过滤：匹配条码 / 物料编码
  barcodeOptions.value = allBarcodeOptions.value.filter((o) => {
    const bc = String(o.value || '').toLowerCase()
    const mc = String(o.materialCode || '').toLowerCase()
    const label = String(o.label || '').toLowerCase()
    return bc.includes(kw) || mc.includes(kw) || label.includes(kw)
  })
}

// 条码下拉可见性变化：每次展开都重新请求接口，保证用户新建的物料批次能立刻出现在下拉里
function handleBarcodeVisibleChange(visible) {
  if (!visible) return
  loadBarcodeOptions().catch(() => {})
}

// 添加一行上料记录
function addLoadingRow() {
  loadingRows.value.push({
    barcode: '',
    inputMode: 'select', // 'select' | 'manual'
    loadingQuantity: 0,
    operatorId: '',
    validationResult: null, // 校验结果
  })
}

// 删除一行
function removeLoadingRow(index) {
  loadingRows.value.splice(index, 1)
}

// 校验单行物料批次（调用 POST /api/loading/verify）
async function validateRow(row) {
  if (!row.barcode) {
    row.validationResult = null
    return
  }
  if (!currentStation.value) {
    ElMessage.warning('请先选择工站')
    return
  }

  // 上料数量必须 > 0 才能做校验
  const loadedQuantity = Number(row.loadingQuantity) || 0
  if (loadedQuantity <= 0) {
    row.validationResult = {
      ok: false,
      passed: false,
      verifyStatusCode: 2,
      warning: false,
      message: '上料数量必须大于 0',
      code: 'INVALID_QTY',
    }
    return
  }

  const stationId = currentStation.value.stationId
    ?? currentStation.value.id
    ?? currentStation.value.routeStepId
  // 构造校验请求体（完全匹配 2.5 接口契约）
  const payload = {
    barcode: String(row.barcode),
    loadedQuantity,
    // stationId 传了后端才做 BOM 匹配 + 封装匹配；用户选了工站就传
    stationId: stationId != null ? Number(stationId) : undefined,
  }

  try {
    console.log('[Loading] POST /api/loading/verify 请求体：', payload)
    const data = await verifyLoadingRecord(payload)
    console.log('[Loading] 单条上料校验接口原始返回：', data)

    // 兼容多种响应格式：直接 {passed, verifyStatusCode, message, warning} 或包装对象
    const resp = (data && typeof data === 'object') ? data : {}
    const passed = Boolean(resp.passed ?? resp.Passed ?? (resp.verifyStatusCode === 1 || resp.VerifyStatusCode === 1))
    const verifyStatusCode = Number(resp.verifyStatusCode ?? resp.VerifyStatusCode ?? (passed ? 1 : 2))
    const message = String(resp.message ?? resp.Message ?? (passed ? '校验通过' : '校验失败'))
    const warning = Boolean(resp.warning ?? resp.Warning ?? false)

    // 尝试从接口返回的 lotInfo/materialInfo 字段（可选，后端可能一并返回）拼接详细展示
    const lotInfo = resp.lotInfo ?? resp.LotInfo ?? resp.lot ?? resp.Lot ?? null
    const materialInfo = resp.materialInfo ?? resp.MaterialInfo ?? resp.material ?? resp.Material ?? null

    row.validationResult = {
      ok: passed,
      passed,
      verifyStatusCode,
      message,
      warning,
      // 保留 lot / material 字段，validationDisplay 用于展示详细信息
      lot: lotInfo || null,
      material: materialInfo || null,
      code: passed ? null : resp.code ?? resp.Code ?? 'VERIFY_FAIL',
    }
  } catch (error) {
    console.warn('[Loading] 校验接口失败：', error)
    row.validationResult = {
      ok: false,
      passed: false,
      verifyStatusCode: 2,
      warning: false,
      message: '校验接口暂不可用，请稍后重试',
      code: 'VERIFY_FAIL',
      lot: null,
      material: null,
    }
    ElMessage.error('校验接口暂不可用，请稍后重试')
  }
}

// 校验结果展示信息（适配 POST /api/loading/verify 响应）
function validationDisplay(row) {
  if (!row.validationResult) return null
  const r = row.validationResult

  // 成功分支：接口 200 且 passed=true
  if (r.ok) {
    const lot = r.lot
    const material = r.material || null
    const details = []
    details.push(`✅ ${r.message || '校验通过'}`)
    if (r.warning) {
      details.push('⚠️ MSL 湿敏等级警告（不拦截，请留意烘烤时间）')
    }
    if (lot) {
      const remaining = (lot.Quantity || 0) - (lot.UsedQuantity || 0)
      details.push(
        `物料编码：${lot.MaterialCode || '-'}（${material?.MaterialDesc || '-'}）`,
        `批次号：${lot.BatchNo || '-'}`,
        `供应商：${lot.Supplier || '-'}`,
        `入库数量：${lot.Quantity || 0} | 已使用：${lot.UsedQuantity || 0} | 剩余：${remaining}`,
        `有效期：${lot.ExpiryDate || '无'}`,
        `MSL 等级：${lot.MslLevel || '-'}`,
      )
    }
    // 统一用 success 绿色效果，含 MSL 警告时额外带 warning 标记做细微区分（黄边/⚠️标识），
    // 不再用 type='warning' 导致整个卡片变橙色 + 前面显示 ❌ 图标，让用户误判为失败
    return {
      type: 'success',
      warning: Boolean(r.warning),
      title: r.warning ? '✅ 校验通过（含 MSL 警告）' : '✅ 校验通过',
      details,
    }
  }

  // 失败分支：接口 200 但 passed=false
  const errorCodeMap = {
    NOT_FOUND: '条码无效',
    PACKAGE_MISMATCH: '封装类型不匹配',
    STATUS_INVALID: '物料批次状态异常',
    EXPIRED: '物料批次已过期',
    INSUFFICIENT_QTY: '库存不足',
    INVALID_QTY: '上料数量非法',
    BOM_MISMATCH: '工单 BOM 未匹配该物料',
  }
  const errorLabel = errorCodeMap[r.code] || (r.verifyStatusCode === 2 ? '校验失败' : '校验失败')
  const details = []
  details.push(r.message || '校验失败')
  if (r.lot) {
    const remaining = (r.lot.Quantity || 0) - (r.lot.UsedQuantity || 0)
    details.push(
      `物料编码：${r.lot.MaterialCode || '-'}`,
      `批次号：${r.lot.BatchNo || '-'}`,
      `剩余库存：${remaining}`,
    )
  }
  return {
    type: 'error',
    title: `❌ 校验失败（${errorLabel}）`,
    details,
    code: r.code,
  }
}

// 批量提交上料（无需批次，直接关联工站）
async function submitBatchLoading() {
  if (!loadingRows.value.length) {
    ElMessage.warning('请先添加上料记录')
    return
  }
  if (!currentStation.value) {
    ElMessage.warning('请先选择工站')
    return
  }

  // 过滤出校验通过的行
  const validRows = loadingRows.value.filter((row) => row.validationResult?.ok)
  if (!validRows.length) {
    ElMessage.error('没有校验通过的上料记录，请先校验')
    return
  }

  // 检查操作人、数量和库存
  for (const row of validRows) {
    if (!row.operatorId) {
      ElMessage.error('请为所有校验通过的记录选择操作人')
      return
    }
    if (!row.loadingQuantity || Number(row.loadingQuantity) <= 0) {
      ElMessage.error('上料数量必须大于 0')
      return
    }
    // 提交前再次校验库存是否充足，防止校验后库存被其他操作扣减
    const lot = row.validationResult?.lot
    if (lot) {
      const remaining = (lot.Quantity || 0) - (lot.UsedQuantity || 0)
      if (remaining < Number(row.loadingQuantity)) {
        ElMessage.error(`物料批次 ${lot.BatchNo} 剩余库存 ${remaining}，不足需要的 ${row.loadingQuantity}，请调整上料数量`)
        return
      }
    }
  }

  submitting.value = true
  const station = currentStation.value
  // stationId 优先用 stationId / id / routeStepId
  const stationId = station.stationId ?? station.id ?? station.routeStepId
  // lotId 取自当前选中的已投产批次（smt_lots.Id）
  const lotId = currentBatch.value?.id ?? selectedBatchId.value
  // 构造批量请求 body（与接口契约一致：lotId + stationId + records）
  // records[].verifyStatus / verifyRemark 取自前端先调 /api/loading/verify 的返回值，
  // 后端建议"先调 verify 拿结果再回填这两个字段一起落库"，不传则默认 0=未校验
  const records = validRows.map((row) => {
    const v = row.validationResult ?? {}
    return {
      barcode: row.barcode,
      loadedQuantity: Number(row.loadingQuantity),
      operatorId: Number(row.operatorId),
      verifyStatus: Number(v.verifyStatusCode ?? 0),
      verifyRemark: String(v.message ?? ''),
    }
  })
  const payload = { lotId: Number(lotId), stationId: Number(stationId), records }

  let successCount = 0
  let failCount = 0
  let failBarcodeToMsg = new Map() // 失败条码 -> 错误信息（用于标记前端哪些行未提交成功）
  const allBarcodes = records.map((r) => r.barcode)

  try {
    console.log('[Loading] POST /api/loading/records 请求体：', payload)
    const data = await createLoadingRecords(payload)
    console.log('[Loading] 批量上料接口原始返回：', data)

    // 兼容返回格式：直接 {successCount, failCount, failDetails?} 或 data.xxx 或顶层 xxx
    const resp = (data && typeof data === 'object') ? data : {}
    const successCountVal = Number(resp.successCount ?? resp.SuccessCount ?? (resp.createdIds?.length) ?? 0)
    const failCountVal = Number(resp.failCount ?? resp.FailCount ?? 0)
    const failDetails = Array.isArray(resp.failDetails)
      ? resp.failDetails
      : (Array.isArray(resp.FailDetails) ? resp.FailDetails : [])
    successCount = successCountVal
    failCount = failCountVal
    failDetails.forEach((d) => {
      const bc = d.barcode ?? d.Barcode
      if (bc) failBarcodeToMsg.set(bc, d.message ?? d.Message ?? '上料失败')
    })
    // 若响应未提供计数，则根据 failDetails + 总数反推
    if (!successCount && !failCount) {
      failCount = failBarcodeToMsg.size
      successCount = Math.max(0, allBarcodes.length - failCount)
    }
  } catch (error) {
    console.warn('[Loading] 批量上料接口失败：', error)
    // 接口失败：所有待提交行都标记为失败，保留方便用户重试
    failCount = validRows.length
    validRows.forEach((row) => {
      failBarcodeToMsg.set(row.barcode, '上料接口暂不可用，请稍后重试')
    })
    ElMessage.error('批量上料接口暂不可用，请稍后重试')
  }

  // 消息提示
  if (successCount > 0) {
    ElMessage.success(`成功上料 ${successCount} 个物料批次${failCount > 0 ? `，${failCount} 个失败` : ''}`)
    // 上料成功后物料批次库存/状态已变化，标记切回「物料批次管理」Tab 时需要重新拉列表
    lotListDirty.value = true
  } else if (failCount > 0 && !failBarcodeToMsg.size) {
    ElMessage.error(`上料失败：${failCount} 个物料批次未提交`)
  }
  // 展示失败明细（如果超过 1 条）
  if (failBarcodeToMsg.size) {
    const msgs = []
    for (const [bc, msg] of failBarcodeToMsg) msgs.push(`• ${bc}：${msg}`)
    if (msgs.length <= 5) {
      ElMessage.warning({ message: msgs.join('\n'), duration: 5000, offset: 50, showClose: true })
    } else {
      ElMessage.warning(`${msgs.length} 个物料批次上料失败，已在表格中标记，请查看详细错误`)
    }
  }
  // 仅移除已成功的行，失败的行保留（方便重试）
  loadingRows.value = loadingRows.value.filter((row) => {
    if (!row.validationResult?.ok) return true // 未校验通过行保留
    const bc = row.barcode
    if (failBarcodeToMsg.has(bc)) {
      // 把失败原因写回 validationResult，便于用户看到
      row.validationResult = {
        ...row.validationResult,
        ok: false,
        type: 'error',
        title: '❌ 提交失败',
        details: [failBarcodeToMsg.get(bc) || '上料失败'],
        code: 'SUBMIT_FAIL',
      }
      return true // 保留，让用户重试
    }
    return false
  })
  submitting.value = false
}

function getOperatorLabel(user) {
  if (!user) return '-'
  const name = user.fullName || user.FullName || user.username || user.Username || ''
  const position = user.position || user.Position || ''
  const dept = user.department || user.Department || ''
  return [name, position, dept].filter(Boolean).join(' / ')
}

// 上料录入成功后，物料批次库存/状态已变化，标记需要在切回「物料批次管理」Tab 时重新拉列表
const lotListDirty = ref(false)

// 当切换批次时：加载该批次的工站列表，并重置已选工站与上料行
watch(selectedBatchId, async (newBatchId) => {
  selectedStationId.value = null
  loadingRows.value = []
  batchStations.value = []
  if (newBatchId) {
    await loadBatchStations(newBatchId)
  }
})

// 当切换工站时重置上料行
watch(selectedStationId, () => {
  loadingRows.value = []
})

// 切回「物料批次管理」Tab 时，如果上料后已标记 dirty，则重新拉取物料批次列表（库存/状态已更新）
watch(activeTab, (tab) => {
  if (tab === 'materialLot' && lotListDirty.value) {
    lotListDirty.value = false
    loadLotList()
  }
})

// ==================== 工站已上料记录查看 ====================
const stationRecordsDialogVisible = ref(false)
const stationRecordsLoading = ref(false)
const stationRecordsList = ref([])
const stationRecordsOverview = ref({ stationName: '', recordCount: 0, totalLoadedQuantity: 0 })

// 弹窗内「按批次筛选」：默认空 = 查看该工站全部上料记录；选择批次号后本地过滤
const stationRecordsLotFilter = ref('')
// 批次选项：从已加载的记录里去重提取（排除 "-" 无批次）
const stationRecordsLotOptions = computed(() => {
  const set = new Set()
  stationRecordsList.value.forEach((r) => {
    const code = r.BatchNo
    if (code && code !== '-') set.add(code)
  })
  return Array.from(set).map((code) => ({ value: code, label: code }))
})
// 过滤后的记录列表
const filteredStationRecordsList = computed(() => {
  const f = stationRecordsLotFilter.value
  if (!f) return stationRecordsList.value
  return stationRecordsList.value.filter((r) => r.BatchNo === f)
})

// 校验状态码 → Element Plus tag type 映射
function getVerifyStatusTagType(code) {
  switch (Number(code)) {
    case 1: return 'success'
    case 2: return 'danger'
    case 0:
    default: return 'info'
  }
}

function normalizeStationRecord(item) {
  if (!item) return null
  const id = item.id ?? item.Id
  const barcode = item.barcode ?? item.Barcode ?? '-'
  const materialCode = item.materialCode ?? item.MaterialCode ?? '-'
  // 接口说明：lotCode/packageCode 为空时返回 "-"
  const lotCode = item.lotCode ?? item.LotCode ?? item.BatchNo ?? '-'
  const packageCode = item.packageCode ?? item.PackageCode ?? item.PackageType ?? '-'
  const supplier = item.supplier ?? item.Supplier ?? '-'
  const loadedQuantity = item.loadedQuantity
    ?? item.LoadedQuantity
    ?? item.ActualQuantity
    ?? item.ActualQty
    ?? 0
  const verifyStatusCode = item.verifyStatusCode
    ?? item.VerifyStatusCode
    ?? (item.VerifyStatusTag === 'success' ? 1 : item.VerifyStatusTag === 'danger' ? 2 : 0)
  const verifyStatusText = item.verifyStatusText ?? item.VerifyStatusText ?? '未校验'
  const operatorName = item.operatorName ?? item.OperatorName ?? '-'
  const loadingTime = item.loadingTime ?? item.LoadingTime ?? '-'
  return {
    ...item,
    id,
    // PascalCase 字段保持与模板 Dialog 表格列兼容
    Barcode: barcode,
    MaterialCode: materialCode,
    BatchNo: lotCode,
    PackageType: packageCode,
    Supplier: supplier,
    ActualQuantity: loadedQuantity,
    VerifyStatusCode: verifyStatusCode,
    VerifyStatusText: verifyStatusText,
    VerifyStatusTag: getVerifyStatusTagType(verifyStatusCode),
    OperatorName: operatorName,
    LoadingTime: loadingTime,
  }
}

function normalizeStationOverview(ov) {
  if (!ov || typeof ov !== 'object') {
    return { stationName: '', recordCount: 0, totalLoadedQuantity: 0 }
  }
  return {
    stationName: ov.stationName ?? ov.StationName ?? currentStation.value?.stationName ?? '',
    recordCount: Number(ov.recordCount ?? ov.RecordCount ?? 0),
    totalLoadedQuantity: Number(ov.totalLoadedQuantity ?? ov.TotalLoadedQuantity ?? 0),
  }
}

async function viewStationLoadingRecords() {
  if (!currentStation.value) return
  stationRecordsDialogVisible.value = true
  stationRecordsLoading.value = true
  stationRecordsLotFilter.value = '' // 打开弹窗时重置批次筛选，默认查看全部
  stationRecordsOverview.value = {
    stationName: currentStation.value.stationName || '',
    recordCount: 0,
    totalLoadedQuantity: 0,
  }
  stationRecordsList.value = []
  try {
    // 传 stationId（接口契约要求），后端以工站维度关联查询
    const stationId = currentStation.value.stationId ?? currentStation.value.id ?? currentStation.value.routeStepId
    console.log('[Loading] GET /api/loading/stations/records 参数：', { stationId })
    const data = await getStationLoadingRecordsApi({ stationId })
    console.log('[Loading] 工站已上料记录原始返回：', data)

    // 兼容 data 为对象（{overview, records}）或 直接数组
    let overview = null
    let recordsRaw = []
    if (Array.isArray(data)) {
      recordsRaw = data
    } else if (data && typeof data === 'object') {
      overview = data.overview ?? data.Overview ?? null
      if (Array.isArray(data.records)) recordsRaw = data.records
      else if (Array.isArray(data.Records)) recordsRaw = data.Records
      else if (Array.isArray(data.list)) recordsRaw = data.list
      else if (Array.isArray(data.rows)) recordsRaw = data.rows
      else if (Array.isArray(data.items)) recordsRaw = data.items
      else if (Array.isArray(data.data)) recordsRaw = data.data
    }
    stationRecordsOverview.value = normalizeStationOverview(overview)
    // 兜底：若 overview.recordCount 缺失，用数组长度；total 缺失则累加
    if (!stationRecordsOverview.value.recordCount) stationRecordsOverview.value.recordCount = recordsRaw.length
    const list = recordsRaw.map(normalizeStationRecord).filter(Boolean)
    stationRecordsList.value = list
    if (!stationRecordsOverview.value.totalLoadedQuantity) {
      stationRecordsOverview.value.totalLoadedQuantity = list.reduce((s, r) => s + (r.ActualQuantity || 0), 0)
    }
    console.log('[Loading] 工站已上料记录解析条数：', list.length, '概览：', stationRecordsOverview.value)
  } catch (error) {
    console.warn('[Loading] 工站已上料记录接口失败：', error)
    stationRecordsList.value = []
    stationRecordsOverview.value = {
      stationName: currentStation.value.stationName || '',
      recordCount: 0,
      totalLoadedQuantity: 0,
    }
    ElMessage.warning('工站已上料记录接口暂不可用，请稍后重试')
  } finally {
    stationRecordsLoading.value = false
  }
}

const stationRecordsTotal = computed(() => {
  // 跟随批次筛选：选了批次只统计该批次的上料总量，否则统计全部
  return filteredStationRecordsList.value.reduce((sum, r) => sum + (Number(r.ActualQuantity) || 0), 0)
})

onMounted(async () => {
  await Promise.all([loadOperatorList(), loadMaterialOptions(), loadLotList(), loadBarcodeOptions(), loadBatchList()])
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">上料管理</h1>
      </div>
      <div class="table-actions">
        <el-button type="primary" plain @click="router.push('/execution/check-in')">
          <el-icon style="margin-right: 4px"><Promotion /></el-icon>去进站
        </el-button>
        <el-button type="warning" plain @click="router.push('/execution/unloading')">
          <el-icon style="margin-right: 4px"><Download /></el-icon>去下料
        </el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab" class="loading-tabs">
      <!-- ==================== Tab 1: 物料批次管理 ==================== -->
      <el-tab-pane name="materialLot">
        <template #label>
          <span class="tab-label">物料批次管理</span>
        </template>
        <SectionCard title="物料批次列表">
          <template #actions>
            <el-button type="primary" @click="createDialogVisible = true">
              <el-icon style="margin-right: 4px"><Plus /></el-icon>新建物料批次
            </el-button>
          </template>

          <div class="filter-bar">
            <el-form :inline="true" :model="lotFilters">
              <el-form-item label="物料编码">
                <el-select
                  v-model="lotFilters.MaterialCode"
                  clearable
                  filterable
                  :teleported="false"
                  placeholder="全部物料"
                  style="width: 180px"
                  @change="loadLotList"
                >
                  <el-option
                    v-for="m in materialOptions"
                    :key="String(m.value)"
                    :label="String(m.label || m.value || '')"
                    :value="m.value"
                    :disabled="!m.value"
                  />
                </el-select>
              </el-form-item>
              <el-form-item label="状态">
                <el-select
                  v-model="lotFilters.Status"
                  clearable
                  :teleported="false"
                  placeholder="全部状态"
                  style="width: 120px"
                  @change="loadLotList"
                >
                  <el-option
                    v-for="s in lotStatusOptions.filter((o) => o.value)"
                    :key="String(s.value)"
                    :label="String(s.label || s.value || '')"
                    :value="s.value"
                    :disabled="!s.value"
                  />
                </el-select>
              </el-form-item>
              <el-form-item label="批次号/条码">
                <el-input
                  v-model="lotFilters.BatchNo"
                  clearable
                  placeholder="输入批次号或条码"
                  style="width: 180px"
                  @keyup.enter="loadLotList"
                  @clear="loadLotList"
                />
              </el-form-item>
              <el-form-item label="供应商">
                <el-input
                  v-model="lotFilters.Supplier"
                  clearable
                  placeholder="输入供应商"
                  style="width: 140px"
                  @keyup.enter="loadLotList"
                  @clear="loadLotList"
                />
              </el-form-item>
              <el-form-item label="有效期">
                <el-date-picker
                  v-model="lotFilters.ExpiryDateRange"
                  type="daterange"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  value-format="YYYY-MM-DD"
                  style="width: 240px"
                  @change="loadLotList"
                />
              </el-form-item>
              <el-form-item label="入库日期">
                <el-date-picker
                  v-model="lotFilters.InboundDateRange"
                  type="daterange"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  value-format="YYYY-MM-DD"
                  style="width: 240px"
                  @change="loadLotList"
                />
              </el-form-item>
              <el-form-item>
                <div class="filter-actions">
                  <el-button type="primary" @click="loadLotList">查询</el-button>
                  <el-button @click="resetFilters">重置</el-button>
                </div>
              </el-form-item>
            </el-form>
          </div>

          <el-table v-loading="lotListLoading" :data="pagedLotList" border stripe>
            <el-table-column label="条码" min-width="200" align="center" fixed="left">
              <template #default="{ row }">
                <el-link type="primary" :underline="false" @click="copyBarcode(row)">
                  <el-icon style="margin-right: 4px"><CopyDocument /></el-icon>{{ row.Barcode }}
                </el-link>
              </template>
            </el-table-column>
            <el-table-column prop="MaterialCode" label="物料编码" min-width="120" align="center" />
            <el-table-column prop="BatchNo" label="批次号" min-width="140" align="center" />
            <el-table-column prop="Supplier" label="供应商" min-width="90" align="center" />
            <el-table-column prop="SupplierBatchNo" label="供应商批次号" min-width="130" align="center">
              <template #default="{ row }">{{ row.SupplierBatchNo || '-' }}</template>
            </el-table-column>
            <el-table-column label="库存（总/已用/剩余）" min-width="170" align="center">
              <template #default="{ row }">
                <span class="qty-display">
                  {{ row.Quantity }} / {{ row.UsedQuantity }} /
                  <span :class="['qty-remaining', { zero: remainingQuantity(row) === 0 }]">{{ remainingQuantity(row) }}</span>
                </span>
              </template>
            </el-table-column>
            <el-table-column label="生产日期" min-width="110" align="center">
              <template #default="{ row }">{{ _fmtDate(row.ProductionDate) || '-' }}</template>
            </el-table-column>
            <el-table-column label="入库日期" min-width="160" align="center">
              <template #default="{ row }">{{ formatDateTime(row.InboundDate) || '-' }}</template>
            </el-table-column>
            <el-table-column label="有效期" min-width="150" align="center">
              <template #default="{ row }">
                <span v-if="!row.ExpiryDate" style="color: var(--rtm-text-muted)">-</span>
                <template v-else>
                  <span :class="{ 'expiry-warning': isExpired(row) }">{{ _fmtDate(row.ExpiryDate) }}</span>
                  <el-tag v-if="isExpired(row)" type="danger" size="small" effect="dark" style="margin-left: 4px">过期</el-tag>
                </template>
              </template>
            </el-table-column>
            <el-table-column prop="MslLevel" label="MSL" width="70" align="center">
              <template #default="{ row }">
                <span v-if="row.MslLevel" class="msl-badge">M{{ row.MslLevel }}</span>
                <span v-else style="color: var(--rtm-text-muted)">-</span>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template #default="{ row }">
                <el-tag :type="lotStatusTagType(row.Status)" effect="light" round>{{ row.Status }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="180" align="center" fixed="right">
              <template #default="{ row }">
                <div v-if="row.Status === '在库'" class="action-buttons">
                  <el-button size="small" type="warning" plain @click="handleStatusChange(row, '已冻结')">
                    <el-icon style="margin-right: 2px"><WarningFilled /></el-icon>冻结
                  </el-button>
                  <el-button size="small" type="danger" plain @click="handleStatusChange(row, '已报废')">
                    <el-icon style="margin-right: 2px"><CircleCloseFilled /></el-icon>报废
                  </el-button>
                </div>
                <el-button v-else-if="row.Status === '已冻结'" size="small" type="success" plain @click="handleStatusChange(row, '在库')">
                  <el-icon style="margin-right: 2px"><CircleCheckFilled /></el-icon>解冻
                </el-button>
                <span v-else style="color: var(--rtm-text-muted)">-</span>
              </template>
            </el-table-column>
          </el-table>

          <div class="table-pagination">
            <el-pagination
              v-model:current-page="lotPagination.pageNum"
              v-model:page-size="lotPagination.pageSize"
              :page-sizes="[10, 20, 50]"
              :total="lotPagination.total"
              layout="total, sizes, prev, pager, next, jumper"
              @current-change="handleLotPageChange"
              @size-change="handleLotSizeChange"
            />
          </div>
        </SectionCard>
      </el-tab-pane>

      <!-- ==================== Tab 2: 上料操作 ==================== -->
      <el-tab-pane name="loading">
        <template #label>
          <span class="tab-label">上料操作</span>
        </template>

        <!-- 步骤 1: 选择已投产批次 -->
        <SectionCard title="① 选择已投产批次">
          <div class="station-flex" v-loading="batchListLoading">
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
                <span class="station-seq">批次</span>
                <span class="station-code" :title="batch.lotCode">{{ batch.lotCode }}</span>
                <el-tag
                  v-if="isValidDisplay(batch.currentOperation)"
                  size="small"
                  type="success"
                  effect="plain"
                  round
                  class="operation-tag"
                >{{ batch.currentOperation }}</el-tag>
              </div>
              <div class="station-card-body">
                <div class="station-info-row" v-if="isValidDisplay(batch.productName)">
                  <span class="label">产品</span>
                  <span class="value" :title="batch.productName">{{ ellipsis(batch.productName, 12) }}</span>
                </div>
                <div class="station-info-row" v-if="isValidDisplay(batch.workOrderCode)">
                  <span class="label">工单</span>
                  <span class="value" :title="batch.workOrderCode">{{ ellipsis(batch.workOrderCode, 12) }}</span>
                </div>
                <div class="station-info-row" v-if="isValidDisplay(batch.lineName)">
                  <span class="label">产线</span>
                  <span class="value" :title="batch.lineName">{{ ellipsis(batch.lineName, 12) }}</span>
                </div>
              </div>
            </div>
          </div>
        </SectionCard>

        <!-- 步骤 2: 选择工站 -->
        <SectionCard v-if="currentBatch" title="② 选择工站" class="mt-16">
          <div class="station-flex" v-loading="batchStationsLoading">
            <el-empty
              v-if="!batchStationsLoading && !batchStations.length"
              description="该批次暂无工站数据"
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
                <el-tag
                  v-if="isValidDisplay(station.operationName)"
                  size="small"
                  type="info"
                  effect="plain"
                  round
                  class="operation-tag"
                >{{ station.operationName }}</el-tag>
              </div>
              <div class="station-card-body">
                <div class="station-info-row" v-if="isValidDisplay(station.stationName)">
                  <span class="label">工站</span>
                  <span class="value" :title="station.stationName">{{ ellipsis(station.stationName, 10) }}</span>
                </div>
                <div class="station-info-row" v-if="isValidDisplay(station.equipmentTypeName)">
                  <span class="label">设备类型</span>
                  <span class="value" :title="station.equipmentTypeName">{{ ellipsis(station.equipmentTypeName, 10) }}</span>
                </div>
              </div>
            </div>
          </div>
        </SectionCard>

        <!-- 步骤 3: 上料录入 -->
        <SectionCard v-if="currentStation" title="③ 上料录入" class="mt-16">
          <template #actions>
            <el-button size="small" plain @click="viewStationLoadingRecords">
              <el-icon style="margin-right: 4px"><View /></el-icon>查看工站已上料记录
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

          <el-empty v-if="!loadingRows.length" description="点击下方「新增上料记录」开始录入" :image-size="80" />

          <div v-else class="loading-rows">
            <div v-for="(row, index) in loadingRows" :key="index" class="loading-row">
              <div class="loading-row-header">
                <span class="row-index">#{{ index + 1 }}</span>
                <el-button text type="danger" size="small" @click="removeLoadingRow(index)">
                  <el-icon><Delete /></el-icon>移除
                </el-button>
              </div>
              <div class="loading-row-form">
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
                    remote
                    clearable
                    :reserve-keyword="false"
                    :remote-method="barcodeRemoteSearch"
                    :loading="!!barcodeOptionsLoading"
                    :popper-options="{ strategy: 'fixed' }"
                    :empty-text="barcodeOptionsLoading ? '加载中...' : '暂无数据'"
                    placeholder="选择或搜索物料批次条码"
                    style="width: 100%"
                    @change="validateRow(row)"
                    @visible-change="handleBarcodeVisibleChange"
                  >
                    <el-option
                      v-for="opt in barcodeOptions"
                      :key="opt.value"
                      :label="opt.label"
                      :value="opt.value"
                      :disabled="!opt.value"
                    />
                  </el-select>
                  <el-input
                    v-show="row.inputMode !== 'select'"
                    v-model="row.barcode"
                    placeholder="手动输入物料批次条码"
                    style="width: 100%"
                    @blur="validateRow(row)"
                  >
                    <template #prefix><el-icon><Search /></el-icon></template>
                  </el-input>
                </div>

                <div class="form-item">
                  <label class="form-label">上料数量</label>
                  <el-input-number v-model="row.loadingQuantity" :min="1" style="width: 130px" @change="validateRow(row)" />
                </div>

                <div class="form-item">
                  <label class="form-label">操作人</label>
                  <el-select
                    v-model="row.operatorId"
                    filterable
                    clearable
                    :popper-options="{ strategy: 'fixed' }"
                    placeholder="选择操作人"
                    style="width: 180px"
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

                <div class="form-item form-item-validate">
                  <el-button type="primary" plain size="default" @click="validateRow(row)">
                    <el-icon style="margin-right: 4px"><CircleCheck /></el-icon>校验
                  </el-button>
                </div>
              </div>

              <!-- 校验结果展示 -->
              <div
                v-if="validationDisplay(row)"
                class="validation-result"
                :class="[
                  validationDisplay(row).type,
                  { 'with-msl-warn': validationDisplay(row).warning },
                ]"
              >
                <div class="validation-title">
                  <template v-if="row.validationResult?.ok">
                    <el-icon style="margin-right: 6px" class="icon-ok">
                      <CircleCheckFilled />
                    </el-icon>
                    <el-icon v-if="validationDisplay(row).warning" class="icon-warn-inline" style="margin-left: 2px; margin-right: 4px;">
                      <WarningFilled />
                    </el-icon>
                  </template>
                  <el-icon v-else style="margin-right: 6px" class="icon-fail"><CircleCloseFilled /></el-icon>
                  {{ validationDisplay(row).title }}
                </div>
                <div class="validation-details">
                  <div v-for="(detail, i) in validationDisplay(row).details" :key="i" class="validation-detail-line">
                    {{ detail }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="loading-actions">
            <el-button type="primary" plain @click="addLoadingRow">
              <el-icon style="margin-right: 4px"><Plus /></el-icon>新增上料记录
            </el-button>
            <el-button
              type="primary"
              size="large"
              :loading="submitting"
              :disabled="!loadingRows.length"
              @click="submitBatchLoading"
            >
              <el-icon style="margin-right: 6px"><Check /></el-icon>提交上料
            </el-button>
          </div>
        </SectionCard>
      </el-tab-pane>
    </el-tabs>

    <!-- ==================== 创建物料批次对话框 ==================== -->
    <el-dialog
      v-model="createDialogVisible"
      title="创建物料批次"
      width="720px"
      class="create-dialog"
      @close="resetCreateForm"
    >
      <!-- 创建成功后展示后端返回信息 -->
      <div v-if="createdLotInfo" class="create-success-panel">
        <el-icon class="success-icon"><CircleCheckFilled /></el-icon>
        <div class="success-text">
          <div class="success-title">物料批次创建成功</div>
          <div class="success-detail">
            <div class="success-detail-row">
              <span class="detail-label">批次号</span>
              <span class="detail-value">{{ createdLotInfo.BatchNo }}</span>
            </div>
            <div class="success-detail-row">
              <span class="detail-label">条码</span>
              <span class="detail-value">{{ createdLotInfo.Barcode }}</span>
            </div>
          </div>
        </div>
      </div>

      <el-form v-else label-position="top" :model="createForm" class="create-form">
        <!-- 分组 1: 物料信息 -->
        <div class="form-section">
          <div class="form-section-title">
            <el-icon><Box /></el-icon>物料信息
          </div>
          <el-form-item label="物料编码" required>
            <el-select
              v-model="createForm.MaterialCode"
              filterable
              remote
              clearable
              :reserve-keyword="false"
              :remote-method="materialRemoteSearch"
              :loading="!!materialOptionsLoading"
              :teleported="false"
              :empty-text="materialOptionsLoading ? '加载中...' : '暂无数据'"
              placeholder="输入物料编码或名称搜索"
              style="width: 100%"
            >
              <el-option
                v-for="m in materialOptions"
                :key="String(m.value)"
                :label="String(m.label || m.value || '')"
                :value="m.value"
                :disabled="!m.value"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="入库数量" required>
            <el-input-number v-model="createForm.Quantity" :min="1" style="width: 100%" placeholder="入库数量" />
          </el-form-item>
        </div>

        <!-- 分组 2: 供应商信息 -->
        <div class="form-section">
          <div class="form-section-title">
            <el-icon><OfficeBuilding /></el-icon>供应商信息
          </div>
          <el-row :gutter="16">
            <el-col :span="12">
              <el-form-item label="供应商">
                <el-input v-model="createForm.Supplier" placeholder="供应商名称" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="供应商批次号">
                <el-input v-model="createForm.SupplierBatchNo" placeholder="供应商侧批次号" />
              </el-form-item>
            </el-col>
          </el-row>
        </div>

        <!-- 分组 3: 日期与有效期 -->
        <div class="form-section">
          <div class="form-section-title">
            <el-icon><Calendar /></el-icon>日期与有效期
          </div>
          <el-row :gutter="16">
            <el-col :span="8">
              <el-form-item label="入库日期" required>
                <el-date-picker v-model="createForm.InboundDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" placeholder="选择入库日期" />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="生产日期">
                <el-date-picker v-model="createForm.ProductionDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="有效期">
                <el-date-picker v-model="createForm.ExpiryDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
              </el-form-item>
            </el-col>
          </el-row>
          <el-form-item label="MSD 湿敏等级">
            <el-input-number v-model="createForm.MslLevel" :min="1" :max="6" style="width: 120px" />
          </el-form-item>
        </div>
      </el-form>

      <template #footer>
        <el-button @click="createDialogVisible = false">关闭</el-button>
        <el-button v-if="!createdLotInfo" type="primary" :loading="createSubmitting" @click="submitCreateLot">
          <el-icon style="margin-right: 4px"><Check /></el-icon>创建
        </el-button>
        <el-button v-else type="primary" @click="resetCreateForm">
          <el-icon style="margin-right: 4px"><Plus /></el-icon>继续创建
        </el-button>
      </template>
    </el-dialog>

    <!-- ==================== 工站已上料记录对话框 ==================== -->
    <el-dialog
      v-model="stationRecordsDialogVisible"
      title="工站已上料记录"
      width="1300px"
      class="station-records-dialog"
    >
      <!-- 摘要信息卡片 -->
      <div class="records-summary-cards">
        <div class="summary-card-item">
          <div class="summary-card-icon station"><el-icon><Monitor /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">工站</span>
            <span class="summary-card-value">{{ currentStation?.stationName }}</span>
          </div>
        </div>
        <div class="summary-card-item">
          <div class="summary-card-icon count"><el-icon><Document /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">上料记录数</span>
            <span class="summary-card-value">{{ filteredStationRecordsList.length }} 条</span>
          </div>
        </div>
      </div>

      <!-- 批次筛选：默认查看该工站全部上料记录，可选择批次号缩小范围 -->
      <div class="records-filter-bar">
        <span class="filter-label">按批次筛选</span>
        <el-select
          v-model="stationRecordsLotFilter"
          placeholder="全部批次"
          clearable
          style="width: 260px"
          :disabled="stationRecordsLoading || !stationRecordsList.length"
        >
          <el-option
            v-for="opt in stationRecordsLotOptions"
            :key="opt.value"
            :label="opt.label"
            :value="opt.value"
          />
        </el-select>
        <span v-if="stationRecordsLotFilter" class="filter-tip">
          当前仅展示批次「{{ stationRecordsLotFilter }}」的上料记录，清空可查看全部
        </span>
      </div>

      <!-- 记录列表 -->
      <el-table v-loading="stationRecordsLoading" :data="filteredStationRecordsList" border stripe max-height="420" style="margin-top: 16px">
        <el-table-column label="物料批次条码" min-width="200" align="center" fixed="left">
          <template #default="{ row }">
            <el-link type="primary" :underline="false">
              <el-icon style="margin-right: 4px"><CopyDocument /></el-icon>{{ row.Barcode }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column prop="MaterialCode" label="物料编码" min-width="120" align="center" />
        <el-table-column prop="BatchNo" label="批次号" min-width="140" align="center" />
        <el-table-column prop="PackageType" label="封装" width="80" align="center">
          <template #default="{ row }">
            <el-tag size="small" effect="plain">{{ row.PackageType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="Supplier" label="供应商" min-width="90" align="center" />
        <el-table-column label="校验状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.VerifyStatusTag" size="small" effect="light" round>{{ row.VerifyStatusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="OperatorName" label="操作人" min-width="80" align="center" />
        <el-table-column label="上料时间" min-width="160" align="center" fixed="right">
          <template #default="{ row }">{{ formatDateTime(row.LoadingTime) || '-' }}</template>
        </el-table-column>
      </el-table>

      <el-empty
        v-if="!stationRecordsLoading && !filteredStationRecordsList.length"
        :description="stationRecordsList.length ? '当前筛选条件下无上料记录，清空批次可查看全部' : '该工站暂无上料记录'"
        :image-size="80"
      />

      <template #footer>
        <el-button @click="stationRecordsDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.loading-tabs :deep(.el-tabs__header) {
  margin-bottom: 16px;
}

.loading-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 600;
  height: 44px;
  padding: 0 24px;
}

.loading-tabs :deep(.el-tabs__item.is-active) {
  color: var(--rtm-primary);
  font-weight: 700;
}

.mt-16 {
  margin-top: 16px;
}

/* 筛选栏 */
.filter-bar {
  margin-bottom: 16px;
  padding: 12px 16px;
  background: var(--rtm-panel-soft, #f8fafc);
  border-radius: var(--rtm-radius);
  border: 1px solid var(--rtm-line);
}

.filter-bar :deep(.el-form--inline .el-form-item) {
  margin-right: 16px;
  margin-bottom: 8px;
}

.filter-actions {
  display: flex;
  gap: 8px;
}

/* 表格内的样式 */
.expiry-warning {
  color: #f56c6c;
  font-weight: 700;
}

.qty-display {
  font-variant-numeric: tabular-nums;
  color: var(--rtm-text);
}

.qty-remaining {
  color: #67c23a;
  font-weight: 700;
}

.qty-remaining.zero {
  color: var(--rtm-text-muted);
}

.msl-badge {
  display: inline-block;
  padding: 1px 8px;
  border-radius: 10px;
  background: #eef2f7;
  color: #5f6b7a;
  font-size: 12px;
  font-weight: 700;
}

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

/* ===== 工站卡片（flex 布局，适配侧边栏展开/收缩） ===== */
.station-flex {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 14px;
}

.station-card {
  position: relative;
  min-width: 0;
  border: 2px solid var(--rtm-line);
  border-radius: 10px;
  padding: 14px 16px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #fff;
  box-sizing: border-box;
}

.station-card:hover {
  border-color: var(--rtm-primary);
  box-shadow: 0 4px 12px rgba(31, 95, 153, 0.12);
  transform: translateY(-1px);
}

.station-card.active {
  border-color: var(--rtm-primary);
  background: linear-gradient(135deg, #ecf5ff 0%, #f0f9ff 100%);
  box-shadow: 0 4px 14px rgba(31, 95, 153, 0.18);
}

.station-card.active::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  border-radius: 10px 10px 0 0;
  background: var(--rtm-primary);
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
  background: var(--rtm-primary);
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}

.station-card.active .station-seq {
  background: var(--rtm-primary-dark);
}

/* 批次卡片：序号方块用绿色调与工站卡片区分 */
.batch-card .station-seq {
  background: #67c23a;
  width: 28px;
  font-size: 11px;
}

.batch-card.active .station-seq {
  background: #529b2e;
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
  flex: 1 1 auto;
  min-width: 0;
  word-break: break-all;
  line-height: 1.4;
}

/* 批次卡片（batch-card）里的批次号允许换行显示完整内容，不要省略号 */
.batch-card .station-code {
  white-space: normal;
  overflow: visible;
  text-overflow: clip;
}

.operation-tag {
  flex-shrink: 0;
  max-width: 100px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
  min-width: 56px;
  color: var(--rtm-text-muted);
  flex-shrink: 0;
  text-align: right;
}

.station-info-row .value {
  color: var(--rtm-text);
  font-weight: 500;
  min-width: 0;
  flex: 1 1 auto;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* ===== 当前上下文信息条 ===== */
.current-context-bar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 10px 16px;
  background: linear-gradient(90deg, #ecf5ff 0%, #f8fafc 100%);
  border: 1px solid #d4e4f7;
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

/* ===== 上料录入行 ===== */
.loading-rows {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-bottom: 16px;
}

.loading-row {
  border: 1px solid var(--rtm-line);
  border-radius: 10px;
  background: #fff;
  overflow: hidden;
  transition: box-shadow 0.2s;
}

.loading-row:hover {
  box-shadow: 0 2px 10px rgba(23, 32, 44, 0.06);
}

.loading-row-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  background: var(--rtm-panel-soft, #f8fafc);
  border-bottom: 1px solid var(--rtm-line);
}

.row-index {
  font-size: 13px;
  font-weight: 700;
  color: var(--rtm-primary);
}

.loading-row-form {
  display: flex;
  flex-wrap: wrap;
  gap: 16px 20px;
  align-items: flex-end;
  padding: 16px;
}

.form-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-item-barcode {
  flex: 1;
  min-width: 260px;
}

.form-label {
  font-size: 12px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.form-item-validate {
  padding-bottom: 0;
}

/* 校验结果 */
.validation-result {
  margin: 0 16px 16px;
  padding: 14px 16px;
  border-radius: 8px;
  font-size: 13px;
  line-height: 1.8;
}

.validation-result.success {
  background: linear-gradient(135deg, #f0f9eb 0%, #f5fde8 100%);
  border: 1px solid #c2e7b0;
}

/* 校验通过但含 MSL 警告：底色仍为绿色，左侧加一条橙黄色警示条，明显区分纯通过 */
.validation-result.success.with-msl-warn {
  background: linear-gradient(135deg, #f0f9eb 0%, #fff8e6 100%);
  border: 1px solid #c2e7b0;
  border-left: 4px solid #f3a01f;
  box-shadow: inset 4px 0 0 rgba(243, 160, 31, 0.08);
}

.validation-result.success .icon-ok {
  color: #529b2e;
}

.validation-result.success.with-msl-warn .icon-warn-inline {
  color: #f3a01f;
  font-size: 15px;
}

.validation-result.error .icon-fail {
  color: #c45656;
}

.validation-result.error {
  background: linear-gradient(135deg, #fef0f0 0%, #fff4f4 100%);
  border: 1px solid #f9c4c4;
  animation: shake 0.4s ease;
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-4px); }
  75% { transform: translateX(4px); }
}

.validation-title {
  display: flex;
  align-items: center;
  font-weight: 700;
  margin-bottom: 8px;
  font-size: 14px;
}

.validation-result.success .validation-title {
  color: #529b2e;
}

.validation-result.error .validation-title {
  color: #c45656;
}

.validation-detail-line {
  color: var(--rtm-text-soft);
  padding-left: 22px;
}

.loading-actions {
  display: flex;
  gap: 12px;
  align-items: center;
  padding-top: 8px;
  border-top: 1px dashed var(--rtm-line);
}

/* ===== 创建对话框 ===== */
.create-dialog :deep(.el-dialog__body) {
  padding: 20px 24px;
}

.material-ref-info {
  display: flex;
  align-items: center;
  margin-top: 6px;
  padding: 6px 10px;
  background: var(--rtm-panel-soft, #f8fafc);
  border-radius: 6px;
  font-size: 12px;
  color: var(--rtm-text-soft);
}

.form-hint {
  margin-top: 4px;
  font-size: 12px;
  color: var(--rtm-text-muted);
}

/* 创建成功面板 */
.create-success-panel {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 24px;
  background: linear-gradient(135deg, #f0f9eb 0%, #f5fde8 100%);
  border: 1px solid #c2e7b0;
  border-radius: 10px;
}

.success-icon {
  font-size: 40px;
  color: #67c23a;
  flex-shrink: 0;
}

.success-title {
  font-size: 16px;
  font-weight: 700;
  color: #529b2e;
  margin-bottom: 12px;
}

.success-detail {
  background: rgba(255, 255, 255, 0.7);
  border-radius: 8px;
  padding: 12px 16px;
}

.success-detail-row {
  display: flex;
  align-items: center;
  gap: 8px;
  line-height: 2;
}

.detail-label {
  font-size: 13px;
  color: var(--rtm-text-soft);
  min-width: 140px;
}

.detail-value {
  font-size: 14px;
  font-weight: 700;
  color: var(--rtm-text);
  font-family: 'Consolas', 'Monaco', monospace;
}

/* 响应式：工站卡片在不同屏宽下的列数调整 */
@media (max-width: 1400px) {
  .station-flex {
    grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
  }
}

@media (max-width: 1200px) {
  .station-flex {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  }
}

@media (max-width: 900px) {
  .loading-row-form {
    flex-direction: column;
    align-items: stretch;
  }

  .form-item-barcode {
    min-width: 100%;
  }

  .station-flex {
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  }

  .current-context-bar {
    flex-wrap: wrap;
  }
}

@media (max-width: 600px) {
  .station-flex {
    grid-template-columns: 1fr 1fr;
  }
}

/* ===== 创建表单分组 ===== */
.form-section {
  margin-bottom: 20px;
  padding: 16px;
  background: var(--rtm-panel-soft, #f8fafc);
  border: 1px solid var(--rtm-line);
  border-radius: 8px;
}

.form-section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 700;
  color: var(--rtm-primary);
  margin-bottom: 14px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--rtm-line);
}

.form-hint-inline {
  margin-left: 12px;
  font-size: 12px;
  color: var(--rtm-text-muted);
}

/* ===== 操作列按钮组 ===== */
.action-buttons {
  display: flex;
  gap: 6px;
  justify-content: center;
  flex-wrap: wrap;
}

/* ===== 工站已上料记录对话框（全屏） ===== */
.station-records-dialog :deep(.el-dialog__body) {
  padding: 20px 24px;
}

.records-filter-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 16px;
}
.records-filter-bar .filter-label {
  font-size: 13px;
  color: var(--el-text-color-secondary);
  white-space: nowrap;
}
.records-filter-bar .filter-tip {
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.records-summary-cards {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
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
  background: #fdf6ec;
  color: #e6a23c;
}

.summary-card-icon.count {
  background: #f0f9eb;
  color: #67c23a;
}

.summary-card-icon.qty {
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

@media (max-width: 700px) {
  .records-summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
