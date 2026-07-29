<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { getOperators } from '@/api/user'
import { supplementMaterial } from '@/api/batch'
import {
  getMaterialLots,
  createMaterialLot as createMaterialLotApi,
  updateMaterialLotStatus as updateMaterialLotStatusApi,
  validateMaterialLot as validateMaterialLotApi,
  consumeMaterialLot as consumeMaterialLotApi,
} from '@/api/materialLot'
import {
  findStation,
  findOperation,
  findEquipment,
  findEquipmentType,
  materials,
  materialLots,
  routeSteps,
  getMaterialLotList,
  createMaterialLot,
  updateMaterialLotStatus,
  consumeMaterialLot,
  validateMaterialLotForLoading,
  getStationLoadingRecords,
  addStationLoadingRecord,
  users,
} from '@/utils/mockData'

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

// 物料编码下拉选项
const materialOptions = computed(() =>
  materials.map((m) => ({
    value: m.MaterialCode,
    label: `${m.MaterialCode} (${m.MaterialDesc})`,
    PackageType: m.PackageType,
    Brand: m.Brand,
  })),
)

// 选中物料时展示的参考信息
const selectedMaterialInfo = computed(() => {
  if (!createForm.MaterialCode) return null
  const m = materials.find((item) => item.MaterialCode === createForm.MaterialCode)
  return m || null
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
  if (!row.ExpiryDate) return false
  return new Date(row.ExpiryDate) < new Date()
}

// 构建 Mock 筛选参数
function buildMockFilters() {
  const f = {
    MaterialCode: lotFilters.MaterialCode,
    Status: lotFilters.Status,
    BatchNo: lotFilters.BatchNo,
    Supplier: lotFilters.Supplier,
  }
  if (lotFilters.ExpiryDateRange && lotFilters.ExpiryDateRange.length === 2) {
    f.ExpiryDateStart = lotFilters.ExpiryDateRange[0]
    f.ExpiryDateEnd = lotFilters.ExpiryDateRange[1]
  }
  if (lotFilters.InboundDateRange && lotFilters.InboundDateRange.length === 2) {
    f.InboundDateStart = lotFilters.InboundDateRange[0]
    f.InboundDateEnd = lotFilters.InboundDateRange[1]
  }
  return f
}

function resetFilters() {
  lotFilters.MaterialCode = ''
  lotFilters.Status = ''
  lotFilters.BatchNo = ''
  lotFilters.Supplier = ''
  lotFilters.ExpiryDateRange = []
  lotFilters.InboundDateRange = []
  loadLotList()
}

async function loadLotList() {
  lotListLoading.value = true
  try {
    const data = await getMaterialLots(buildMockFilters())
    lotList.value = Array.isArray(data) ? data : (data?.records || data?.list || [])
    lotPagination.total = lotList.value.length
  } catch (error) {
    console.warn('[Loading] API 获取物料批次列表失败，使用 Mock 数据：', error)
    lotList.value = getMaterialLotList(buildMockFilters())
    lotPagination.total = lotList.value.length
  } finally {
    lotListLoading.value = false
  }
}

const pagedLotList = computed(() => {
  const start = (lotPagination.pageNum - 1) * lotPagination.pageSize
  return lotList.value.slice(start, start + lotPagination.pageSize)
})

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
    const payload = {
      MaterialCode: createForm.MaterialCode,
      Supplier: createForm.Supplier,
      SupplierBatchNo: createForm.SupplierBatchNo,
      Quantity: Number(createForm.Quantity),
      ProductionDate: createForm.ProductionDate || null,
      ExpiryDate: createForm.ExpiryDate || null,
      MslLevel: createForm.MslLevel || null,
      InboundDate: createForm.InboundDate || null,
    }
    const data = await createMaterialLotApi(payload)
    // 后端返回包含 BatchNo 和 Barcode
    createdLotInfo.value = data || null
    ElMessage.success('物料批次创建成功')
    await loadLotList()
  } catch (error) {
    console.warn('[Loading] API 创建物料批次失败，使用 Mock 模拟：', error)
    const result = createMaterialLot({
      MaterialCode: createForm.MaterialCode,
      Supplier: createForm.Supplier,
      SupplierBatchNo: createForm.SupplierBatchNo,
      Quantity: Number(createForm.Quantity),
      ProductionDate: createForm.ProductionDate || null,
      ExpiryDate: createForm.ExpiryDate || null,
      MslLevel: createForm.MslLevel || null,
      InboundDate: createForm.InboundDate || null,
    })
    if (!result.ok) {
      ElMessage.error(result.message || '创建失败')
      createSubmitting.value = false
      return
    }
    createdLotInfo.value = result.lot
    ElMessage.success('[Mock] 物料批次创建成功')
    await loadLotList()
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
    console.warn('[Loading] API 修改状态失败，使用 Mock 模拟：', error)
    const result = updateMaterialLotStatus(row.Id, newStatus)
    if (!result.ok) {
      ElMessage.error(result.message || '状态变更失败')
      return
    }
    ElMessage.success('[Mock] 状态变更成功')
    await loadLotList()
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

// 选中的工站
const selectedStationId = ref(null)

// 上料录入行（支持多批次）
const loadingRows = ref([])
const submitting = ref(false)

function buildMockOperatorList() {
  return users.map((u) => ({
    id: u.Id,
    Id: u.Id,
    username: u.Username,
    Username: u.Username,
    fullName: u.FullName,
    FullName: u.FullName,
    position: u.Position,
    Position: u.Position,
    department: u.Department,
    Department: u.Department,
  }))
}

async function loadOperatorList() {
  try {
    const data = await getOperators()
    operatorList.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.warn('[Loading] API 获取操作人列表失败，使用 Mock 数据：', error)
    operatorList.value = buildMockOperatorList()
  }
}

// 工站列表（直接从 routeSteps 获取，不依赖批次）
const stationList = computed(() => {
  return routeSteps
    .slice()
    .sort((a, b) => a.Sequence - b.Sequence)
    .map((step) => {
      const station = findStation(step.StationId)
      const operation = findOperation(step.OperationId)
      const equip = findEquipment(step.EquipmentId)
      const equipType = findEquipmentType(step.EquipmentTypeId)
      return {
        routeStepId: step.Id,
        stationId: step.StationId,
        equipmentId: step.EquipmentId,
        equipmentTypeId: step.EquipmentTypeId,
        sequence: step.Sequence,
        stationCode: station?.StationCode || '-',
        stationName: station?.StationName || '-',
        operationName: operation?.OperationName || '-',
        equipmentCode: equip?.EquipmentCode || '-',
        equipmentName: equip?.EquipmentName || '-',
        equipmentTypeName: equipType?.EquipmentTypeName || '-',
      }
    })
})

// 当前选中的工站
const currentStation = computed(() => {
  if (!selectedStationId.value) return null
  return stationList.value.find((s) => s.routeStepId === selectedStationId.value) || null
})

// 物料批次条码下拉选项（所有在库的物料批次）
const barcodeOptions = computed(() =>
  materialLots.map((lot) => ({
    value: lot.Barcode,
    label: `${lot.Barcode} (${lot.MaterialCode})`,
  })),
)

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

// 校验单行物料批次
async function validateRow(row) {
  if (!row.barcode) {
    row.validationResult = null
    return
  }
  if (!currentStation.value) {
    ElMessage.warning('请先选择工站')
    return
  }

  const equipmentTypeId = currentStation.value.equipmentTypeId

  try {
    const data = await validateMaterialLotApi({
      barcode: row.barcode,
      equipmentTypeId,
      requiredQty: row.loadingQuantity || 0,
    })
    row.validationResult = { ok: true, ...data }
  } catch (error) {
    console.warn('[Loading] API 校验失败，使用 Mock 校验：', error)
    const result = validateMaterialLotForLoading(row.barcode, equipmentTypeId, row.loadingQuantity || 0)
    row.validationResult = result
  }
}

// 校验结果展示信息
function validationDisplay(row) {
  if (!row.validationResult) return null
  const r = row.validationResult
  if (r.ok) {
    const lot = r.lot
    const material = r.material || materials.find((m) => m.MaterialCode === lot?.MaterialCode)
    const checks = r.checks || {}
    const remaining = checks.quantityCheck?.remaining ?? ((lot?.Quantity || 0) - (lot?.UsedQuantity || 0))
    const requiredQty = checks.quantityCheck?.requiredQty ?? row.loadingQuantity ?? 0
    return {
      type: 'success',
      title: '物料批次校验通过（四项校验全部通过）',
      details: [
        `📦 封装类型校验：✅ ${checks.packageCheck?.materialPackageType || material?.PackageType || '-'} 支持当前设备`,
        `📋 物料状态校验：✅ ${checks.statusCheck?.status || lot?.Status || '-'}`,
        `📅 有效期校验：✅ 有效期至 ${checks.expiryCheck?.expiryDate || lot?.ExpiryDate || '无'}`,
        `🔢 库存校验：✅ 剩余 ${remaining}，满足上料需求 ${requiredQty}`,
        `物料编码：${lot?.MaterialCode || '-'}（${material?.MaterialDesc || '-'}）`,
        `批次号：${lot?.BatchNo || '-'}`,
        `供应商：${lot?.Supplier || '-'}`,
        `入库数量：${lot?.Quantity || 0} | 已使用：${lot?.UsedQuantity || 0} | 剩余：${remaining}`,
        `有效期：${lot?.ExpiryDate || '无'}`,
        `MSL 等级：${lot?.MslLevel || '-'}（仅记录，暂不管控）`,
      ],
    }
  }
  const errorCodeMap = {
    NOT_FOUND: '条码无效',
    PACKAGE_MISMATCH: '封装类型不匹配',
    STATUS_INVALID: '物料批次状态异常',
    EXPIRED: '物料批次已过期',
    INSUFFICIENT_QTY: '库存不足',
  }
  const errorLabel = errorCodeMap[r.code] || '校验失败'
  return {
    type: 'error',
    title: `❌ 校验失败（${errorLabel}）`,
    details: [r.message || '校验失败'],
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
    if (!row.loadingQuantity || row.loadingQuantity <= 0) {
      ElMessage.error('上料数量必须大于 0')
      return
    }
    // 提交前再次校验库存是否充足，防止校验后库存被其他操作扣减
    const lot = row.validationResult?.lot
    if (lot) {
      const remaining = (lot.Quantity || 0) - (lot.UsedQuantity || 0)
      if (remaining < row.loadingQuantity) {
        ElMessage.error(`物料批次 ${lot.BatchNo} 剩余库存 ${remaining}，不足需要的 ${row.loadingQuantity}，请调整上料数量`)
        return
      }
    }
  }

  submitting.value = true
  const station = currentStation.value
  let successCount = 0
  let failCount = 0

  for (const row of validRows) {
    // 优先调用后端上料接口（lotId 不再必需，由后端按工站记录）
    const apiPayload = {
      routeStepId: station.routeStepId,
      stationId: station.stationId,
      equipmentId: station.equipmentId,
      materialLotBarcode: row.barcode,
      loadingQuantity: Number(row.loadingQuantity),
      operatorId: Number(row.operatorId),
    }
    try {
      await supplementMaterial({
        materialCode: row.barcode,
        supplementQuantity: Number(row.loadingQuantity),
        operatorId: Number(row.operatorId),
        routeStepId: station.routeStepId,
      })
      // 扣减库存
      try {
        await consumeMaterialLotApi({ barcode: row.barcode, quantity: Number(row.loadingQuantity) })
      } catch (e) {
        console.warn('[Loading] API 扣减库存失败，使用 Mock：', e)
        consumeMaterialLot(row.barcode, Number(row.loadingQuantity))
      }
      successCount++
    } catch (error) {
      console.warn('[Loading] API 上料提交失败，使用 Mock 模拟（工站直选模式）：', error)
      // Mock 模式：使用 addStationLoadingRecord 直接记录到工站
      const result = addStationLoadingRecord(apiPayload)
      if (result.ok) {
        successCount++
      } else {
        failCount++
        ElMessage.error(result.message || '上料失败')
      }
    }
  }

  if (successCount > 0) {
    ElMessage.success(`成功上料 ${successCount} 个物料批次${failCount > 0 ? `，${failCount} 个失败` : ''}`)
  }
  // 清空已提交的行
  loadingRows.value = loadingRows.value.filter((row) => !row.validationResult?.ok)
  submitting.value = false
}

function getOperatorLabel(user) {
  if (!user) return '-'
  const name = user.fullName || user.FullName || user.username || user.Username || ''
  const position = user.position || user.Position || ''
  const dept = user.department || user.Department || ''
  return [name, position, dept].filter(Boolean).join(' / ')
}

// 当切换工站时重置上料行
watch(selectedStationId, () => {
  loadingRows.value = []
})

// ==================== 工站已上料记录查看 ====================
const stationRecordsDialogVisible = ref(false)
const stationRecordsLoading = ref(false)
const stationRecordsList = ref([])

function viewStationLoadingRecords() {
  if (!currentStation.value) return
  stationRecordsDialogVisible.value = true
  stationRecordsLoading.value = true
  // 使用 Mock 数据获取工站已上料记录（不限定批次）
  const routeStepId = currentStation.value.routeStepId
  stationRecordsList.value = getStationLoadingRecords(routeStepId, null)
  stationRecordsLoading.value = false
}

const stationRecordsTotal = computed(() =>
  stationRecordsList.value.reduce((sum, r) => sum + (r.ActualQuantity || 0), 0),
)

onMounted(async () => {
  await Promise.all([loadOperatorList(), loadLotList()])
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">上料管理</h1>
        <p class="page-subtitle">物料批次管理与上料操作，直接选择工站进行扫码上料</p>
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
              <el-icon style="margin-right: 4px"><Plus /></el-icon>新建批次
            </el-button>
          </template>

          <div class="filter-bar">
            <el-form :inline="true" :model="lotFilters">
              <el-form-item label="物料编码">
                <el-select
                  v-model="lotFilters.MaterialCode"
                  clearable
                  filterable
                  placeholder="全部物料"
                  style="width: 180px"
                  @change="loadLotList"
                >
                  <el-option
                    v-for="m in materialOptions"
                    :key="m.value"
                    :label="m.label"
                    :value="m.value"
                  />
                </el-select>
              </el-form-item>
              <el-form-item label="状态">
                <el-select
                  v-model="lotFilters.Status"
                  clearable
                  placeholder="全部状态"
                  style="width: 120px"
                  @change="loadLotList"
                >
                  <el-option
                    v-for="s in lotStatusOptions.filter((o) => o.value)"
                    :key="s.value"
                    :label="s.label"
                    :value="s.value"
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
            <el-table-column prop="ProductionDate" label="生产日期" min-width="110" align="center">
              <template #default="{ row }">{{ row.ProductionDate || '-' }}</template>
            </el-table-column>
            <el-table-column label="有效期" min-width="120" align="center">
              <template #default="{ row }">
                <span v-if="!row.ExpiryDate" style="color: var(--rtm-text-muted)">-</span>
                <template v-else>
                  <span :class="{ 'expiry-warning': isExpired(row) }">{{ row.ExpiryDate }}</span>
                  <el-tag v-if="isExpired(row)" type="danger" size="small" effect="dark" style="margin-left: 4px">过期</el-tag>
                </template>
              </template>
            </el-table-column>
            <el-table-column label="入库日期" min-width="140" align="center">
              <template #default="{ row }">{{ row.InboundDate || '-' }}</template>
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

        <!-- 步骤 1: 选择工站 -->
        <SectionCard title="① 选择工站">
          <div class="station-flex">
            <div
              v-for="station in stationList"
              :key="station.routeStepId"
              class="station-card"
              :class="{ active: selectedStationId === station.routeStepId }"
              @click="selectedStationId = station.routeStepId"
            >
              <div class="station-card-header">
                <span class="station-seq">{{ station.sequence }}</span>
                <span class="station-code">{{ station.stationCode }}</span>
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

        <!-- 步骤 2: 上料录入 -->
        <SectionCard v-if="currentStation" title="② 上料录入" class="mt-16">
          <template #actions>
            <el-button size="small" plain @click="viewStationLoadingRecords">
              <el-icon style="margin-right: 4px"><View /></el-icon>查看工站已上料记录
            </el-button>
          </template>

          <div class="current-context-bar">
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
                    v-if="row.inputMode === 'select'"
                    v-model="row.barcode"
                    filterable
                    placeholder="选择物料批次条码"
                    style="width: 100%"
                    @change="validateRow(row)"
                  >
                    <el-option
                      v-for="opt in barcodeOptions"
                      :key="opt.value"
                      :label="opt.label"
                      :value="opt.value"
                    />
                  </el-select>
                  <el-input
                    v-else
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
                  <el-select v-model="row.operatorId" filterable placeholder="选择操作人" style="width: 180px">
                    <el-option
                      v-for="user in operatorList"
                      :key="user.id || user.Id"
                      :label="getOperatorLabel(user)"
                      :value="user.id || user.Id"
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
              <div v-if="validationDisplay(row)" class="validation-result" :class="validationDisplay(row).type">
                <div class="validation-title">
                  <el-icon v-if="validationDisplay(row).type === 'success'" style="margin-right: 6px"><CircleCheckFilled /></el-icon>
                  <el-icon v-else style="margin-right: 6px"><CircleCloseFilled /></el-icon>
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
              placeholder="选择物料编码"
              style="width: 100%"
            >
              <el-option
                v-for="m in materialOptions"
                :key="m.value"
                :label="m.label"
                :value="m.value"
              />
            </el-select>
            <div v-if="selectedMaterialInfo" class="material-ref-info">
              <el-icon style="margin-right: 4px"><InfoFilled /></el-icon>
              封装类型：{{ selectedMaterialInfo.PackageType }} | 品牌：{{ selectedMaterialInfo.Brand }}
            </div>
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
            <span class="summary-card-value">{{ stationRecordsList.length }} 条</span>
          </div>
        </div>
        <div class="summary-card-item">
          <div class="summary-card-icon qty"><el-icon><Goods /></el-icon></div>
          <div class="summary-card-content">
            <span class="summary-card-label">上料总量</span>
            <span class="summary-card-value">{{ stationRecordsTotal }}</span>
          </div>
        </div>
      </div>

      <!-- 记录列表 -->
      <el-table v-loading="stationRecordsLoading" :data="stationRecordsList" border stripe max-height="420" style="margin-top: 16px">
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
        <el-table-column label="上料数量" width="100" align="center">
          <template #default="{ row }">
            <span style="font-weight: 700; color: var(--rtm-primary)">{{ row.ActualQuantity }}</span>
          </template>
        </el-table-column>
        <el-table-column label="校验状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.VerifyStatusTag" size="small" effect="light" round>{{ row.VerifyStatusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="OperatorName" label="操作人" min-width="80" align="center" />
        <el-table-column prop="LoadingTime" label="上料时间" min-width="140" align="center" fixed="right" />
      </el-table>

      <el-empty v-if="!stationRecordsLoading && !stationRecordsList.length" description="该工站暂无上料记录" :image-size="80" />

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
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
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

@media (max-width: 900px) {
  .loading-row-form {
    flex-direction: column;
    align-items: stretch;
  }

  .form-item-barcode {
    min-width: 100%;
  }

  .station-card {
    flex: 1 0 100%;
    max-width: 100%;
  }

  .current-context-bar {
    flex-wrap: wrap;
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

.records-summary-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
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
