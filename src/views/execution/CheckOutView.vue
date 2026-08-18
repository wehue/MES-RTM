<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, PROCESS_STATUS, statusMeta } from '@/utils/constants'
import { formatDateTime } from '@/utils/format'
import {
  BATCH_STATUS_CODE,
  DISPOSAL_TYPE_CODE,
  getInspectionThreshold,
  isInspectionProcess,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { getStationOutList, getStationOutDetail, createStationOut } from '@/api/batch'
import { getOperators } from '@/api/user'

// 批次状态中文名 → 数字编码（StatusTag 依赖数字编码）
const LOT_STATUS_NAME_MAP = { '待生产': 1, '生产中': 2, '暂停': 3, '维修中': 4, '已锁定': 5, '已完成': 6 }
// 工序状态中文名 → 数字编码
const OPERATION_STATUS_NAME_MAP = { '待进站': 1, '已进站': 2, '已出站': 3, '暂停': 4, '锁定': 5, '跳过': 6 }

const router = useRouter()
const userStore = useUserStore()
const form = reactive({
  LotCode: '',
  FinishedQuantity: 0,
  DefectQuantity: 0,
  PassRate: 100,
  QualityAction: 'normal',
  DisposalType: DISPOSAL_TYPE_CODE.repair,
  ForceReason: '',
  OperatorId: '',
  DisposalRemark: '',
})

const stationOutList = ref([])
const listLoading = ref(false)
const stationOutDetail = ref(null)
const detailLoading = ref(false)
const listPagination = reactive({ pageNum: 1, pageSize: 5, total: 0 })
const operatorList = ref([])
const submitting = ref(false)

async function loadOperatorList() {
  try {
    const data = await getOperators()
    operatorList.value = Array.isArray(data) ? data : []
    const currentUsername = userStore.userInfo?.username || userStore.userInfo?.name
    const matchedUser = operatorList.value.find(u =>
      (u.username || u.Username) === currentUsername ||
      (u.fullName || u.FullName) === currentUsername
    )
    if (matchedUser) {
      form.OperatorId = matchedUser.id || matchedUser.Id
    } else if (operatorList.value.length) {
      form.OperatorId = operatorList.value[0].id || operatorList.value[0].Id
    }
  } catch (error) {
    console.error('Failed to load operator list:', error)
    operatorList.value = []
  }
}

function getOperatorLabel(user) {
  if (!user) return '-'
  const name = user.fullName || user.FullName || user.username || user.Username || ''
  const position = user.position || user.Position || ''
  const dept = user.department || user.Department || ''
  return [name, position, dept].filter(Boolean).join(' / ')
}

// 归一化 GET /api/station-out/list 返回的单条可出站批次
function normalizeStationOutItem(item) {
  if (!item) return null
  const lotStatusName = item.lotStatusName ?? item.LotStatusName ?? ''
  return {
    lotId: Number(item.lotId ?? item.LotId ?? 0),
    lotCode: item.lotCode ?? item.LotCode ?? '',
    productCode: item.productCode ?? item.ProductCode ?? '',
    productName: item.productName ?? item.ProductName ?? '',
    lineName: item.lineName ?? item.LineName ?? '',
    plannedQuantity: Number(item.plannedQuantity ?? item.PlannedQuantity ?? 0),
    completedQuantity: Number(item.completedQuantity ?? item.CompletedQuantity ?? 0),
    pendingStationOutQuantity: Number(item.pendingStationOutQuantity ?? item.PendingStationOutQuantity ?? 0),
    currentOperation: item.currentPendingOperationName ?? item.CurrentPendingOperationName ?? item.currentOperation ?? '',
    lotStatusName,
    lotStatus: LOT_STATUS_NAME_MAP[lotStatusName] ?? null,
    createdAt: item.createdAt ?? item.CreatedAt ?? '',
  }
}

function extractListPayload(data) {
  if (!data) return []
  if (Array.isArray(data)) return data
  const payload = (data.data !== undefined) ? data.data : data
  if (Array.isArray(payload)) return payload
  if (!payload || typeof payload !== 'object') return []
  if (Array.isArray(payload.list)) return payload.list
  if (Array.isArray(payload.rows)) return payload.rows
  if (Array.isArray(payload.records)) return payload.records
  if (Array.isArray(payload.content)) return payload.content
  return []
}

function extractPaginationMeta(data) {
  const payload = (data && data.data !== undefined) ? data.data : data
  const obj = (payload && typeof payload === 'object') ? payload : {}
  return {
    total: Number(obj.total ?? obj.Total ?? 0),
    totalPages: Number(obj.totalPages ?? obj.TotalPages ?? 0),
    pageNum: Number(obj.pageNum ?? obj.PageNum ?? 1),
    pageSize: Number(obj.pageSize ?? obj.PageSize ?? 20),
  }
}

async function loadStationOutList() {
  listLoading.value = true
  try {
    const params = {
      pageNum: Number(listPagination.pageNum || 1),
      pageSize: Number(listPagination.pageSize || 5),
    }
    console.log('[CheckOut] GET /api/station-out/list 参数：', params)
    const raw = await getStationOutList(params)
    console.log('[CheckOut] GET /api/station-out/list 原始返回：', raw)
    const list = extractListPayload(raw).map(normalizeStationOutItem).filter(Boolean)
    const meta = extractPaginationMeta(raw)
    stationOutList.value = list
    listPagination.total = meta.total > 0 ? meta.total : list.length
    if (meta.pageSize > 0) listPagination.pageSize = meta.pageSize
    if (meta.pageNum > 0) listPagination.pageNum = meta.pageNum
    if (!form.LotCode && stationOutList.value.length) {
      form.LotCode = stationOutList.value[0].lotCode
    }
  } catch (error) {
    console.warn('[CheckOut] 可出站批次列表接口失败：', error)
    stationOutList.value = []
    listPagination.total = 0
    ElMessage.warning('可出站批次列表接口暂不可用，请稍后重试')
  } finally {
    listLoading.value = false
  }
}

// 归一化 GET /api/station-out/detail 出站批次基础资料
function normalizeStationOutDetail(raw) {
  if (!raw) return null
  // 兼容：直接返回对象 / 外层包了 data / axios 已经在拦截器里取过 data
  const obj = (raw && raw.data !== undefined && typeof raw.data === 'object' && raw.data !== null) ? raw.data : raw
  if (!obj || typeof obj !== 'object') return null

  const detail = {
    lotId: Number(obj.lotId ?? obj.LotId ?? 0),
    lotCode: obj.lotCode ?? obj.LotCode ?? '',
    productCode: obj.productCode ?? obj.ProductCode ?? '',
    productName: obj.productName ?? obj.ProductName ?? '',
    lineName: obj.lineName ?? obj.LineName ?? '',
    plannedQuantity: Number(obj.plannedQuantity ?? obj.PlannedQuantity ?? 0),
    completedQuantity: Number(obj.completedQuantity ?? obj.CompletedQuantity ?? 0),
    pendingStationOutQuantity: Number(obj.pendingStationOutQuantity ?? obj.PendingStationOutQuantity ?? 0),
    currentPendingOperationName: obj.currentPendingOperationName ?? obj.CurrentPendingOperationName ?? '',
    currentPendingStationName: obj.currentPendingStationName ?? obj.CurrentPendingStationName ?? '',
    previousOperationName: obj.previousOperationName ?? obj.PreviousOperationName ?? '',
    currentPendingOperationStatusName: obj.currentPendingOperationStatusName ?? obj.CurrentPendingOperationStatusName ?? '',
    equipmentName: obj.equipmentName ?? obj.EquipmentName ?? '',
    lotStatusName: obj.lotStatusName ?? obj.LotStatusName ?? '',
    createdAt: obj.createdAt ?? obj.CreatedAt ?? '',
  }

  // 兼容字段（供模板、旧逻辑仍在引用的字段兜底）：
  detail.currentOperation = detail.currentPendingOperationName
  detail.stationName = detail.currentPendingStationName
  detail.stationId = null // 新接口暂未返回 stationId，用 stationName 展示即可
  detail.stationCode = ''
  // 进站数量：出站场景下，待出站数量即为当前工序进站数量（累计进站 - 历史完工出站）
  detail.stationInQuantity = detail.pendingStationOutQuantity

  // 批次状态数字编码反映射（StatusTag 依赖数字编码通过 statusMeta 查颜色/描述）
  detail.lotStatus = LOT_STATUS_NAME_MAP[detail.lotStatusName] ?? null

  // 工序状态数字编码反映射
  detail.operationStatus = OPERATION_STATUS_NAME_MAP[detail.currentPendingOperationStatusName] ?? null

  return detail
}

async function loadStationOutDetail(lotCode) {
  if (!lotCode) {
    stationOutDetail.value = null
    return
  }
  detailLoading.value = true
  try {
    console.log('[CheckOut] GET /api/station-out/detail 参数：', { lotCode })
    const raw = await getStationOutDetail(lotCode)
    console.log('[CheckOut] GET /api/station-out/detail 原始返回：', raw)
    stationOutDetail.value = normalizeStationOutDetail(raw)
  } catch (error) {
    console.warn('[CheckOut] 出站批次基础资料接口失败：', error)
    stationOutDetail.value = null
    ElMessage.warning('出站批次基础资料接口暂不可用，请稍后重试')
  } finally {
    detailLoading.value = false
  }
}

onMounted(() => {
  loadStationOutList()
  loadOperatorList()
})

function handlePageChange(pageNum) {
  listPagination.pageNum = pageNum
  loadStationOutList()
}

function handleSizeChange(pageSize) {
  listPagination.pageSize = pageSize
  listPagination.pageNum = 1
  loadStationOutList()
}

// 后端分页：stationOutList 即当前页数据
const availableBatches = computed(() => stationOutList.value)

const currentBatch = computed(() => {
  return stationOutList.value.find(item => item.lotCode === form.LotCode) || null
})

const canForce = computed(() => userStore.hasAnyRole(['PRODUCTION_SUPERVISOR']))
const isLocked = computed(() => stationOutDetail.value?.lotStatus === BATCH_STATUS_CODE.locked)
const currentInQty = computed(() => {
  // 优先取 station-out/detail 返回的 pendingStationOutQuantity（即待出站数量 = 进站数量 - 已完工出站）
  if (stationOutDetail.value?.pendingStationOutQuantity != null) {
    return Number(stationOutDetail.value.pendingStationOutQuantity) || 0
  }
  if (stationOutDetail.value?.stationInQuantity != null) {
    return Number(stationOutDetail.value.stationInQuantity) || 0
  }
  return Number(currentBatch.value?.pendingStationOutQuantity) || 0
})
const currentOperationName = computed(() =>
  stationOutDetail.value?.currentPendingOperationName
  || stationOutDetail.value?.currentOperation
  || currentBatch.value?.currentOperation
  || '-'
)
const previousStepLabel = computed(() => {
  const name = stationOutDetail.value?.previousOperationName
  return name && String(name).trim() ? name : '-'
})
const currentStation = computed(() => {
  const d = stationOutDetail.value
  if (!d) return null
  // 新接口 station-out/detail 返回 currentPendingStationName（工站名称）
  if (d.currentPendingStationName || d.stationName || d.currentPendingStationId) {
    return {
      Id: d.currentPendingStationId || d.stationId || d.StationId,
      StationName: d.currentPendingStationName || d.stationName || '-',
      StationCode: d.stationCode || '',
    }
  }
  return null
})
const currentStationEquipment = computed(() => {
  const d = stationOutDetail.value
  // 新接口返回 equipmentName（设备名称）
  if (d?.equipmentName) {
    return {
      EquipmentName: d.equipmentName,
      EquipmentCode: d.equipmentCode || '',
    }
  }
  if (d?.equipmentCode) {
    return {
      EquipmentCode: d.equipmentCode,
      EquipmentName: '-',
    }
  }
  return null
})
const isInspection = computed(() => currentOperationName.value ? isInspectionProcess(currentOperationName.value) : false)
const inspectionThreshold = computed(() => currentOperationName.value ? getInspectionThreshold(currentOperationName.value) : 0)
const inspectionPass = computed(() => form.PassRate >= inspectionThreshold.value)
const checkoutTotal = computed(() => form.FinishedQuantity + form.DefectQuantity)
const quantityValid = computed(() => checkoutTotal.value === currentInQty.value)

watch(() => form.LotCode, (lotCode) => {
  loadStationOutDetail(lotCode)
  const qty = currentInQty.value
  Object.assign(form, {
    FinishedQuantity: qty,
    DefectQuantity: 0,
    PassRate: 100,
    QualityAction: 'normal',
    ForceReason: '',
    DisposalType: DISPOSAL_TYPE_CODE.repair,
  })
}, { immediate: true })

watch(inspectionPass, (pass) => {
  if (pass) form.QualityAction = 'normal'
})

function selectBatch(row) {
  if (!row?.lotCode) return
  form.LotCode = row.lotCode
}

function clampQuantity(value) {
  return Math.max(0, Math.min(Number(value) || 0, currentInQty.value))
}

function syncFinishedQuantity(value) {
  const finishedQuantity = clampQuantity(value)
  form.FinishedQuantity = finishedQuantity
  form.DefectQuantity = currentInQty.value - finishedQuantity
  if (form.DefectQuantity === 0) {
    form.DisposalType = DISPOSAL_TYPE_CODE.repair
    form.ForceReason = ''
  }
}

function syncDefectQuantity(value) {
  const defectQuantity = clampQuantity(value)
  form.DefectQuantity = defectQuantity
  form.FinishedQuantity = currentInQty.value - defectQuantity
  if (defectQuantity === 0) {
    form.DisposalType = DISPOSAL_TYPE_CODE.repair
    form.ForceReason = ''
  }
}

// 归一化 POST /api/station-out/confirm 出站确认结果
function normalizeStationOutResult(raw) {
  if (!raw) return null
  const obj = (raw && raw.data !== undefined && typeof raw.data === 'object' && raw.data !== null) ? raw.data : raw
  if (!obj || typeof obj !== 'object') return null
  return {
    lotId: Number(obj.lotId ?? obj.LotId ?? 0),
    lotCode: obj.lotCode ?? obj.LotCode ?? '',
    routeStepId: Number(obj.routeStepId ?? obj.RouteStepId ?? 0) || null,
    operationName: obj.operationName ?? obj.OperationName ?? '',
    stationName: obj.stationName ?? obj.StationName ?? '',
    equipmentId: Number(obj.equipmentId ?? obj.EquipmentId ?? 0) || null,
    stationOutTime: obj.stationOutTime ?? obj.StationOutTime ?? '',
    finishedQuantity: Number(obj.finishedQuantity ?? obj.FinishedQuantity ?? 0),
    defectQuantity: Number(obj.defectQuantity ?? obj.DefectQuantity ?? 0),
    round: Number(obj.round ?? obj.Round ?? 1),
    isNormal: Number(obj.isNormal ?? obj.IsNormal ?? 1),
    spiPassRate: obj.spiPassRate ?? obj.SpiPassRate ?? null,
    aoiPassRate: obj.aoiPassRate ?? obj.AoiPassRate ?? null,
    disposalType: obj.disposalType ?? obj.DisposalType ?? null,
    // 兼容旧字段（若后端后续补充）
    lastStationOut: obj.lastStationOut ?? obj.LastStationOut ?? false,
    lotStatus: obj.lotStatus ?? obj.LotStatus ?? null,
  }
}

// 根据工序名判断检测类型：SPI / AOI / 通用检测
function detectInspectionType(opName) {
  const name = String(opName || '').toUpperCase()
  if (name.includes('SPI')) return 'SPI'
  if (name.includes('AOI')) return 'AOI'
  return 'GENERIC'
}

async function submit() {
  if (submitting.value) return
  if (!currentBatch.value) {
    ElMessage.error('当前没有可出站批次')
    return
  }
  if (isLocked.value) {
    ElMessage.error('批次已锁定')
    return
  }
  const operatorId = Number(form.OperatorId)
  if (!operatorId) {
    ElMessage.error('请选择操作人')
    return
  }
  const lotId = stationOutDetail.value?.lotId ?? currentBatch.value?.lotId ?? 0
  if (!lotId) {
    ElMessage.error('未找到当前批次 ID，无法提交出站')
    return
  }
  if (!isInspection.value && !quantityValid.value) {
    ElMessage.error(`数量不匹配：进站数量 ${currentInQty.value}，出站合计 ${checkoutTotal.value}`)
    return
  }
  // 普通工序：有不良且选了「强制出站」→ 角色权限 + 原因必填
  if (!isInspection.value && form.DefectQuantity > 0 && form.DisposalType === DISPOSAL_TYPE_CODE.force && !canForce.value) {
    ElMessage.error('当前角色没有强制出站权限')
    return
  }
  if (!isInspection.value && form.DefectQuantity > 0 && form.DisposalType === DISPOSAL_TYPE_CODE.force && !form.ForceReason.trim()) {
    ElMessage.error('请填写强制出站原因')
    return
  }
  // 检测工序：低于阈值 → 必须选 强制出站 或 批次锁定
  if (isInspection.value && !inspectionPass.value && !['force', 'lock'].includes(form.QualityAction)) {
    ElMessage.error('检测通过率低于阈值，请选择强制出站或批次锁定')
    return
  }
  if (isInspection.value && !inspectionPass.value && form.QualityAction === 'force' && !canForce.value) {
    ElMessage.error('当前角色没有强制出站权限')
    return
  }
  if (isInspection.value && !inspectionPass.value && !form.ForceReason.trim()) {
    ElMessage.error(form.QualityAction === 'lock' ? '请填写批次锁定原因' : '请填写强制出站原因')
    return
  }

  // ========== 严格对齐 POST /api/station-out/confirm 契约 ==========
  const submitData = {
    lotId: Number(lotId),
    operatorId,
  }

  let actionFlags = { isRepair: false, isLock: false }

  if (isInspection.value) {
    // ---- 检测工序：传 spiPassRate / aoiPassRate；不传 finished/defect ----
    const inspType = detectInspectionType(currentOperationName.value)
    const passRateVal = Number(form.PassRate)
    if (inspType === 'SPI') submitData.spiPassRate = passRateVal
    else if (inspType === 'AOI') submitData.aoiPassRate = passRateVal
    else {
      // 通用检测（未明确 SPI/AOI）：两个都传，后端按工序类型自行取对应字段
      submitData.spiPassRate = passRateVal
      submitData.aoiPassRate = passRateVal
    }

    if (inspectionPass.value) {
      submitData.isNormal = 1
    } else {
      submitData.isNormal = 0
      // isNormal=0 时 disposalType 必填：3-强制出站（含 lock，区别在 disposalRemark）
      submitData.disposalType = DISPOSAL_TYPE_CODE.force
      submitData.disposalRemark = form.ForceReason || ''
      if (form.QualityAction === 'lock') actionFlags.isLock = true
    }
  } else {
    // ---- 普通工序：传 finishedQuantity / defectQuantity；不传 spi/aoi ----
    const finishedQuantity = Number(form.FinishedQuantity)
    const defectQuantity = Number(form.DefectQuantity)

    if (!(finishedQuantity > 0)) {
      ElMessage.error('完工出站数量必须大于 0')
      return
    }
    if (finishedQuantity + defectQuantity !== currentInQty.value) {
      ElMessage.error(`数量不匹配：进站数量 ${currentInQty.value}，出站合计 ${finishedQuantity + defectQuantity}`)
      return
    }
    submitData.finishedQuantity = finishedQuantity
    if (defectQuantity > 0) {
      submitData.defectQuantity = defectQuantity
      submitData.isNormal = 0
      // defectQuantity>0 时 disposalType 必填（接口契约：1维修 2报废 3强制出站）
      submitData.disposalType = Number(form.DisposalType) || DISPOSAL_TYPE_CODE.repair
      // defectQuantity>0 时 disposalRemark 必填
      submitData.disposalRemark = (form.DisposalRemark || form.ForceReason || '').trim()
      if (!submitData.disposalRemark) {
        const dtName =
          submitData.disposalType === DISPOSAL_TYPE_CODE.scrap ? '报废' :
          submitData.disposalType === DISPOSAL_TYPE_CODE.force ? '强制出站' : '维修'
        ElMessage.error(`请填写${dtName}原因/备注`)
        return
      }
      if (submitData.disposalType === DISPOSAL_TYPE_CODE.repair) actionFlags.isRepair = true
    } else {
      submitData.isNormal = 1
    }
  }

  submitting.value = true
  try {
    console.log('[CheckOut] POST /api/station-out/confirm 参数：', submitData)
    const raw = await createStationOut(submitData)
    console.log('[CheckOut] POST /api/station-out/confirm 原始返回：', raw)
    const result = normalizeStationOutResult(raw)

    // --- 1) 维修处置 → 跳维修管理 ---
    if (actionFlags.isRepair || (result?.disposalType === DISPOSAL_TYPE_CODE.repair && (result.defectQuantity > 0 || form.DefectQuantity > 0))) {
      ElMessage.success('出站完成，已生成维修任务，即将跳转到维修管理。')
      router.push('/execution/repair')
      return
    }

    // --- 2) 检测工序锁定批次 → 跳批次管理 ---
    if (actionFlags.isLock) {
      ElMessage.warning('通过率低于阈值，批次已锁定，即将跳转到批次管理。')
      router.push('/production/batch')
      return
    }

    // --- 3) 最后一道工序出站 → 跳批次管理 ---
    //     （若后端后续补充 lastStationOut=true，则走该分支；否则默认跳下一站进站）
    const lotCode = result?.lotCode || form.LotCode
    const operationName = result?.operationName || stationOutDetail.value?.currentPendingOperationName || ''
    const stationName = result?.stationName || stationOutDetail.value?.currentPendingStationName || ''
    const round = result?.round || 1
    const timeStr = result?.stationOutTime || ''
    const timeLabel = timeStr ? `（${formatDateTime(timeStr)}）` : ''

    if (result?.lastStationOut === true) {
      ElMessage.success(
        `出站完成：批次「${lotCode}」「${operationName || '工序'}」@${stationName || '工站'}` +
        (round > 1 ? ` · 第${round}轮` : '') +
        `，当前批次全部工序已结束。${timeLabel}`
      )
      router.push('/production/batch')
    } else {
      ElMessage.success(
        `出站完成：批次「${lotCode}」「${operationName || '工序'}」@${stationName || '工站'}` +
        (round > 1 ? ` · 第${round}轮` : '') +
        `，即将跳转到进站操作。${timeLabel}`
      )
      router.push({
        path: '/execution/check-in',
        query: { LotCode: lotCode },
      })
    }
  } catch (error) {
    console.warn('[CheckOut] 出站提交失败：', error)
    // 锁定动作失败兜底：仍尝试跳转批次管理（便于用户继续处理异常）
    if (actionFlags.isLock) {
      router.push('/production/batch')
      return
    }
    const message = (error && error.message) ? error.message : '出站提交失败，请稍后重试'
    ElMessage.error(message)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">出站操作</h1>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="可出站批次列表">
        <el-table
          v-loading="listLoading"
          :data="availableBatches"
          border
          highlight-current-row
          row-key="lotCode"
          :current-row-key="form.LotCode"
          @current-change="selectBatch"
          @row-click="selectBatch"
        >
          <el-table-column prop="lotCode" label="批次号" min-width="160" align="center"/>
          <el-table-column prop="productCode" label="产品编码" min-width="120" align="center"/>
          <el-table-column prop="productName" label="产品名称" min-width="150" align="center"/>
          <el-table-column prop="lineName" label="产线" min-width="120" align="center"/>
          <el-table-column prop="plannedQuantity" label="计划数量" width="110" align="center"/>
          <el-table-column prop="completedQuantity" label="已完成数量" width="120" align="center"/>
          <el-table-column prop="pendingStationOutQuantity" label="待出站数量" width="120" align="center"/>
          <el-table-column prop="currentOperation" label="当前待出站工序" min-width="130" align="center"/>
          <el-table-column label="批次状态" min-width="110" align="center">
            <template #default="{ row }">
              <StatusTag v-if="row.lotStatus" :meta="statusMeta(BATCH_STATUS, row.lotStatus)" />
              <span v-else>{{ row.lotStatusName || '-' }}</span>
            </template>
          </el-table-column>
        </el-table>
        <div class="table-pagination">
          <el-pagination
            v-model:current-page="listPagination.pageNum"
            v-model:page-size="listPagination.pageSize"
            :page-sizes="[5, 10, 20, 50]"
            :total="listPagination.total"
            layout="total, sizes, prev, pager, next, jumper"
            @current-change="handlePageChange"
            @size-change="handleSizeChange"
          />
        </div>
      </SectionCard>

      <SectionCard v-if="currentBatch" class="span-12" title="批次与出站信息">
        <el-form label-position="top">
          <el-form-item label="扫码 / 输入批次号">
            <el-select v-model="form.LotCode" filterable class="full lot-select">
              <el-option v-for="item in stationOutList" :key="item.lotCode" :label="item.lotCode" :value="item.lotCode" />
            </el-select>
          </el-form-item>
        </el-form>
        <el-alert v-if="isLocked" title="批次已锁定" type="error" show-icon :closable="false" />
        <el-descriptions :column="1" border label-width="130px" style="margin-top: 10px" v-loading="detailLoading">

          <el-descriptions-item label="待出站数量">
            <span>{{ currentInQty }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="当前待出站工序">{{ currentOperationName }}</el-descriptions-item>

          <el-descriptions-item label="当前工站">
            <span v-if="currentStation?.StationName">
              {{ currentStation.StationName }}
              <span v-if="currentStation.StationCode" class="station-code">（{{ currentStation.StationCode }}）</span>
            </span>
            <span v-else>-</span>
          </el-descriptions-item>
          <el-descriptions-item label="上一工序">{{ previousStepLabel }}</el-descriptions-item>
          <el-descriptions-item label="设备名称">{{ currentStationEquipment?.EquipmentName || stationOutDetail?.equipmentName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="批次状态">
            <StatusTag v-if="stationOutDetail?.lotStatus" :meta="statusMeta(BATCH_STATUS, stationOutDetail.lotStatus)" />
            <span v-else>{{ stationOutDetail?.lotStatusName || currentBatch?.lotStatusName || '-' }}</span>
          </el-descriptions-item>
           <el-descriptions-item label="工序状态">
            <StatusTag v-if="stationOutDetail?.operationStatus" :meta="statusMeta(PROCESS_STATUS, stationOutDetail.operationStatus)" />
            <span v-else>{{ stationOutDetail?.currentPendingOperationStatusName || '-' }}</span>
          </el-descriptions-item>
          <el-descriptions-item v-if="isInspection" label="检测阈值">{{ inspectionThreshold }}%</el-descriptions-item>
        </el-descriptions>

        <el-alert
          v-if="!isInspection"
          style="margin-top: 12px"
          :title="quantityValid ? '数量关系校验通过：进站数量 = 良品 + 不良。' : `数量关系校验失败：进站数量 ${currentInQty}，出站合计 ${checkoutTotal}。`"
          :type="quantityValid ? 'success' : 'error'"
          show-icon
          :closable="false"
        />
        <el-alert
          v-else
          style="margin-top: 12px"
          :title="inspectionPass ? `检测通过率 ${form.PassRate}% 达到阈值 ${inspectionThreshold}%，可正常出站。` : `检测通过率 ${form.PassRate}% 低于阈值 ${inspectionThreshold}%，请选择强制出站或批次锁定。`"
          :type="inspectionPass ? 'success' : 'error'"
          show-icon
          :closable="false"
        />

        <el-form v-if="!isInspection" :model="form" label-width="110px" class="checkout-form">
          <el-form-item label="良品数量">
            <el-input-number :model-value="form.FinishedQuantity" :min="0" :max="currentInQty" @update:model-value="syncFinishedQuantity" />
          </el-form-item>
          <el-form-item label="不良数量">
            <el-input-number :model-value="form.DefectQuantity" :min="0" :max="currentInQty" @update:model-value="syncDefectQuantity" />
          </el-form-item>
          <el-form-item v-if="form.DefectQuantity > 0" label="不良处置">
            <el-select v-model="form.DisposalType" class="full">
              <el-option label="维修" :value="DISPOSAL_TYPE_CODE.repair" />
              <el-option label="报废" :value="DISPOSAL_TYPE_CODE.scrap" />
              <el-option label="强制出站" :value="DISPOSAL_TYPE_CODE.force" />
            </el-select>
          </el-form-item>
          <el-form-item v-if="form.DisposalType === DISPOSAL_TYPE_CODE.force" label="强制原因">
            <el-input v-model="form.ForceReason" type="textarea" />
          </el-form-item>
          <el-form-item label="操作人">
            <el-select v-model="form.OperatorId" filterable placeholder="请选择操作人" class="full">
              <el-option v-for="user in operatorList" :key="user.id || user.Id" :label="getOperatorLabel(user)" :value="user.id || user.Id" />
            </el-select>
          </el-form-item>
          <el-form-item label="处置备注"><el-input v-model="form.DisposalRemark" type="textarea" /></el-form-item>
          <el-button type="primary" size="large" class="big-action" @click="submit" :loading="submitting" :disabled="submitting">提交出站</el-button>
        </el-form>

        <el-form v-else :model="form" label-width="120px" class="checkout-form">
          <el-form-item label="检测通过率">
            <el-input-number v-model="form.PassRate" :min="0" :max="100" :precision="1" :step="0.1" />
          </el-form-item>
          <el-form-item label="出站处理">
            <el-radio-group v-model="form.QualityAction" :disabled="inspectionPass">
              <el-radio-button label="normal">正常出站</el-radio-button>
              <el-radio-button label="force">强制出站</el-radio-button>
              <el-radio-button label="lock">批次锁定</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="!inspectionPass && form.QualityAction !== 'normal'" :label="form.QualityAction === 'lock' ? '锁定原因' : '强制原因'">
            <el-input v-model="form.ForceReason" type="textarea" />
          </el-form-item>
          <el-form-item label="操作人">
            <el-select v-model="form.OperatorId" filterable placeholder="请选择操作人" class="full">
              <el-option v-for="user in operatorList" :key="user.id || user.Id" :label="getOperatorLabel(user)" :value="user.id || user.Id" />
            </el-select>
          </el-form-item>
          <el-form-item label="处置备注"><el-input v-model="form.DisposalRemark" type="textarea" /></el-form-item>
          <el-button type="primary" size="large" class="big-action" @click="submit" :loading="submitting" :disabled="submitting">提交出站</el-button>
        </el-form>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.full {
  width: 100%;
}

.lot-select {
  max-width: 720px;
}

.checkout-form {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px 24px;
  margin-top: 18px;
}

.checkout-form :deep(.el-form-item) {
  margin-bottom: 0;
}

@media (max-width: 1100px) {
  .checkout-form {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 900px) {
  .lot-select {
    max-width: 100%;
  }
}

@media (max-width: 720px) {
  .checkout-form {
    grid-template-columns: 1fr;
  }
}

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

.station-code {
  font-weight: 400;
  color: #64748b;
  font-size: 13px;
}
</style>
