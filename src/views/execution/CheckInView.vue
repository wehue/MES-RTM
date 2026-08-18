<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, PROCESS_STATUS, statusMeta } from '@/utils/constants'
import { useUserStore } from '@/stores/user'
import { getStationInList, getStationInDetail, createStationIn } from '@/api/batch'
import { getOperators } from '@/api/user'
import { formatDateTime } from '@/utils/format'

// 批次状态中文名 → 数字编码（StatusTag 依赖数字编码通过 statusMeta 查颜色/描述）
const LOT_STATUS_NAME_MAP = { '待生产': 1, '生产中': 2, '暂停': 3, '维修中': 4, '已锁定': 5, '已完成': 6 }
// 工序状态中文名 → 数字编码
const OPERATION_STATUS_NAME_MAP = { '待进站': 1, '已进站': 2, '已出站': 3, '暂停': 4, '锁定': 5, '跳过': 6 }

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const form = reactive({
  LotCode: String(route.query.LotCode || route.query.batchId || ''),
  StationInQuantity: 800,
  OperatorId: '',
})

const stationInList = ref([])
const listLoading = ref(false)
const stationInDetail = ref(null)
const detailLoading = ref(false)
const submitting = ref(false)
const listPagination = reactive({ pageNum: 1, pageSize: 5, total: 0 })
const operatorList = ref([])

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

// 归一化真实接口 GET /api/station-in/list 返回的单条待进站批次数据
function normalizeStationInItem(item) {
  if (!item) return null
  const lotStatusName = item.lotStatusName ?? item.LotStatusName ?? ''
  return {
    id: Number(item.lotId ?? item.LotId ?? 0),
    lotId: Number(item.lotId ?? item.LotId ?? 0),
    lotCode: item.lotCode ?? item.LotCode ?? '',
    productCode: item.productCode ?? item.ProductCode ?? '',
    productName: item.productName ?? item.ProductName ?? '',
    lineName: item.lineName ?? item.LineName ?? '',
    lineId: item.lineId ?? item.LineId ?? null,
    plannedQuantity: Number(item.plannedQuantity ?? item.PlannedQuantity ?? 0),
    completedQuantity: Number(item.completedQuantity ?? item.CompletedQuantity ?? 0),
    pendingStationInQuantity: Number(item.pendingStationInQuantity ?? item.PendingStationInQuantity ?? 0),
    currentOperation: item.currentPendingOperationName ?? item.CurrentPendingOperationName ?? item.currentOperation ?? '',
    lotStatusName,
    lotStatus: LOT_STATUS_NAME_MAP[lotStatusName] ?? null,
    createdAt: item.createdAt ?? item.CreatedAt ?? '',
    // 表格兼容字段
    workOrderCode: item.workOrderCode ?? item.WorkOrderCode ?? '',
    currentStationName: item.currentStationName ?? item.CurrentStationName ?? item.stationName ?? '',
  }
}

// 从接口返回结构中提取 list（兼容多种包装：data.list / list / rows / records / content / Array）
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

async function loadStationInList() {
  listLoading.value = true
  try {
    const params = {
      pageNum: Number(listPagination.pageNum || 1),
      pageSize: Number(listPagination.pageSize || 5),
    }
    console.log('[CheckIn] GET /api/station-in/list 参数：', params)
    const raw = await getStationInList(params)
    console.log('[CheckIn] GET /api/station-in/list 原始返回：', raw)
    const list = extractListPayload(raw).map(normalizeStationInItem).filter(Boolean)
    const meta = extractPaginationMeta(raw)
    stationInList.value = list
    listPagination.total = meta.total > 0 ? meta.total : list.length
    // 若后端未返回 total（旧兼容），但有 list，兜底用 list 长度；分页信息有 pageSize/pageNum 时回填
    if (meta.pageSize > 0) listPagination.pageSize = meta.pageSize
    if (meta.pageNum > 0) listPagination.pageNum = meta.pageNum
    if (!form.LotCode && stationInList.value.length) {
      form.LotCode = stationInList.value[0].lotCode
    }
  } catch (error) {
    console.warn('[CheckIn] 待进站批次列表接口失败：', error)
    // 失败时清空（不再 fallback mock），避免展示假数据
    stationInList.value = []
    listPagination.total = 0
    ElMessage.warning('待进站批次列表接口暂不可用，请稍后重试')
  } finally {
    listLoading.value = false
  }
}

function handlePageChange(pageNum) {
  listPagination.pageNum = pageNum
  loadStationInList()
}

function handleSizeChange(pageSize) {
  listPagination.pageSize = pageSize
  listPagination.pageNum = 1
  loadStationInList()
}

// 后端分页：stationInList.value 即当前页数据，不再做前端二次 slice
const pagedStationInList = computed(() => stationInList.value)

// 归一化 GET /api/station-in/detail 进站批次基础资料
function normalizeStationInDetail(raw) {
  if (!raw) return null
  // 兼容：直接返回对象 / 外层包了 data / axios 已经在拦截器里取过 data
  const obj = (raw && raw.data !== undefined && typeof raw.data === 'object' && raw.data !== null) ? raw.data : raw
  if (!obj || typeof obj !== 'object') return null

  const detail = {
    lotId: Number(obj.lotId ?? obj.LotId ?? 0),
    lotCode: obj.lotCode ?? obj.LotCode ?? '',
    productId: Number(obj.productId ?? obj.ProductId ?? 0) || null,
    productCode: obj.productCode ?? obj.ProductCode ?? '',
    productName: obj.productName ?? obj.ProductName ?? '',
    lineId: Number(obj.lineId ?? obj.LineId ?? 0) || null,
    lineName: obj.lineName ?? obj.LineName ?? '',
    plannedQuantity: Number(obj.plannedQuantity ?? obj.PlannedQuantity ?? 0),
    completedQuantity: Number(obj.completedQuantity ?? obj.CompletedQuantity ?? 0),
    pendingStationInQuantity: Number(obj.pendingStationInQuantity ?? obj.PendingStationInQuantity ?? 0),
    currentPendingRouteStepId: Number(obj.currentPendingRouteStepId ?? obj.CurrentPendingRouteStepId ?? 0) || null,
    currentPendingOperationName: obj.currentPendingOperationName ?? obj.CurrentPendingOperationName ?? '',
    currentPendingStationId: Number(obj.currentPendingStationId ?? obj.CurrentPendingStationId ?? 0) || null,
    currentPendingStationName: obj.currentPendingStationName ?? obj.CurrentPendingStationName ?? '',
    previousOperationName: obj.previousOperationName ?? obj.PreviousOperationName ?? '',
    currentPendingOperationStatusName: obj.currentPendingOperationStatusName ?? obj.CurrentPendingOperationStatusName ?? '',
    equipmentName: obj.equipmentName ?? obj.EquipmentName ?? '',
    lotStatusName: obj.lotStatusName ?? obj.LotStatusName ?? '',
    createdAt: obj.createdAt ?? obj.CreatedAt ?? '',
    bomVerifyPassed: obj.bomVerifyPassed === true || obj.bomVerifyPassed === 'true' || obj.BomVerifyPassed === true,
    bomVerifyMessage: obj.bomVerifyMessage ?? obj.BomVerifyMessage ?? '',
  }

  // 兼容字段（供模板、旧逻辑仍在引用的字段兜底）：
  detail.currentOperation = detail.currentPendingOperationName
  detail.stationId = detail.currentPendingStationId
  detail.stationName = detail.currentPendingStationName
  // 工站编码暂时后端没给，后续有的话补上，这里用 stationId 做展示后缀（不展示也行）
  detail.stationCode = ''

  // 批次状态数字编码反映射（StatusTag 依赖数字编码通过 statusMeta 查颜色/描述）
  detail.lotStatus = LOT_STATUS_NAME_MAP[detail.lotStatusName] ?? null

  // 工序状态数字编码反映射
  detail.operationStatus = OPERATION_STATUS_NAME_MAP[detail.currentPendingOperationStatusName] ?? null

  return detail
}

async function loadStationInDetail(lotCode) {
  if (!lotCode) {
    stationInDetail.value = null
    return
  }
  detailLoading.value = true
  try {
    console.log('[CheckIn] GET /api/station-in/detail 参数：', { lotCode })
    const raw = await getStationInDetail(lotCode)
    console.log('[CheckIn] GET /api/station-in/detail 原始返回：', raw)
    stationInDetail.value = normalizeStationInDetail(raw)
  } catch (error) {
    console.warn('[CheckIn] 进站批次基础资料接口失败：', error)
    stationInDetail.value = null
    ElMessage.warning('进站批次基础资料接口暂不可用，请稍后重试')
  } finally {
    detailLoading.value = false
  }
}

onMounted(() => {
  loadStationInList()
  loadOperatorList()
})

watch(() => form.LotCode, async (newLotCode) => {
  if (newLotCode) {
    await loadStationInDetail(newLotCode)
  } else {
    stationInDetail.value = null
  }
}, { immediate: true })

const availableBatches = computed(() => pagedStationInList.value)

const currentBatch = computed(() => {
  return stationInList.value.find(item => item.lotCode === form.LotCode) || null
})

const previousStepLabel = computed(() => {
  // 新接口 station-in/detail 返回 previousOperationName（首工序时显示"首工序，无上一道"）
  const name = stationInDetail.value?.previousOperationName
  return name && String(name).trim() ? name : '-'
})
const processCompliance = computed(() => {
  if (!stationInList.value.length) return { pass: false, type: 'info', message: '暂无可进站批次。' }
  if (!stationInDetail.value) return { pass: false, type: 'info', message: '加载中...' }
  const d = stationInDetail.value
  const statusName = String(d.lotStatusName || '')
  // 新接口列表筛选：批次状态 IN (待生产=1, 生产中=2)，正常到达这里状态都合法
  if (statusName && !['待生产', '生产中'].includes(statusName)) {
    if (statusName.includes('暂停')) return { pass: false, type: 'warning', message: '批次当前为暂停状态，请先恢复后再执行进站。' }
    if (statusName.includes('锁定')) return { pass: false, type: 'error', message: '批次已锁定，需完成异常处理后才可进站。' }
    return { pass: false, type: 'warning', message: `批次当前状态为「${statusName}」，不满足进站条件。` }
  }
  // 待进站数量 <= 0 时也不允许
  if (Number(d.pendingStationInQuantity) <= 0) {
    return { pass: false, type: 'warning', message: '当前批次待进站数量为 0，无需进站。' }
  }
  return { pass: true, type: 'success', message: `当前待进站工序「${d.currentPendingOperationName || '-'}」满足进站要求。` }
})
// 当前待进站工站：后端 station-in/detail 直接返回 currentPendingStationId / currentPendingStationName
const currentStation = computed(() => {
  const d = stationInDetail.value
  if (!d) return null
  if (d.currentPendingStationId || d.currentPendingStationName) {
    return {
      Id: d.currentPendingStationId,
      StationName: d.currentPendingStationName || '-',
      StationCode: d.stationCode || '',
    }
  }
  return null
})
const currentStationEquipment = computed(() => {
  const d = stationInDetail.value
  if (d?.equipmentName) return { EquipmentName: d.equipmentName }
  return null
})
// BOM 封装匹配校验：完全依赖后端 station-in/detail 返回的 bomVerifyPassed/bomVerifyMessage
//  - true → 激活 BOM 全部封装类型都在本工序设备类型支持列表中
//  - false → 有 mismatch（可在 mismatchedPackages 列表里查看）
const loadingValidation = computed(() => {
  if (!stationInList.value.length) return { pass: false, type: 'info', message: '暂无可进站批次，无法进行 BOM 校验。' }
  if (!stationInDetail.value) return { pass: false, type: 'info', message: '加载中...' }
  const d = stationInDetail.value
  const passed = d.bomVerifyPassed === true
  const msg = String(d.bomVerifyMessage || '').trim()
  if (passed) {
    return {
      pass: true,
      type: 'success',
      message: msg || 'BOM 封装匹配校验通过。',
    }
  }
  // 失败：后端会把 mismatchedPackages 一起返回，message 里含中文失败原因
  return {
    pass: false,
    type: 'error',
    message: msg || 'BOM 封装匹配校验失败，禁止进站。',
  }
})
const canSubmit = computed(() => Boolean(currentBatch.value && processCompliance.value.pass && loadingValidation.value.pass))

watch(() => form.LotCode, (lotCode) => {
  loadStationInDetail(lotCode)
  // 进站数量优先取 station-in/detail 返回的 pendingStationInQuantity；无则用列表里的
  const pendingFromDetail = stationInDetail.value?.pendingStationInQuantity
  if (pendingFromDetail && Number(pendingFromDetail) > 0) {
    form.StationInQuantity = Number(pendingFromDetail)
    return
  }
  const listBatch = stationInList.value.find((b) => b.lotCode === lotCode)
  if (listBatch?.pendingStationInQuantity > 0) {
    form.StationInQuantity = Number(listBatch.pendingStationInQuantity)
    return
  }
  form.StationInQuantity = 1
}, { immediate: true })

function selectBatch(batch) {
  if (!batch?.lotCode) return
  form.LotCode = batch.lotCode
}

async function submit() {
  if (!canSubmit.value) {
    if (!processCompliance.value.pass) {
      ElMessage.error(processCompliance.value.message)
      return
    }
    if (!loadingValidation.value.pass) {
      ElMessage.error(loadingValidation.value.message)
      return
    }
    ElMessage.error('当前批次不满足进站条件')
    return
  }
  // lotId 优先取 station-in/detail 返回的（唯一真实来源），兜底取列表里的
  const lotId = stationInDetail.value?.lotId ?? currentBatch.value?.id
  if (!lotId) {
    ElMessage.error('未找到当前批次 ID，无法提交进站')
    return
  }
  const operatorId = Number(form.OperatorId)
  const stationInQuantity = Number(form.StationInQuantity)
  // 前置校验（接口 POST /station-in/confirm 契约要求）
  if (!operatorId) {
    ElMessage.error('请选择操作人')
    return
  }
  if (!stationInQuantity || stationInQuantity <= 0) {
    ElMessage.error('进站数量必须大于 0')
    return
  }
  const pendingLimit = Number(stationInDetail.value?.pendingStationInQuantity ?? currentBatch.value?.pendingStationInQuantity ?? 0)
  if (pendingLimit > 0 && stationInQuantity > pendingLimit) {
    ElMessage.error(`进站数量不能超过待进站数量 ${pendingLimit}`)
    return
  }
  // Body 严格对齐新接口契约：lotId / operatorId / stationInQuantity，不传 remark
  const payload = {
    lotId: Number(lotId),
    operatorId,
    stationInQuantity,
  }
  submitting.value = true
  try {
    console.log('[CheckIn] POST /api/station-in/confirm 参数：', payload)
    const raw = await createStationIn(payload)
    console.log('[CheckIn] POST /api/station-in/confirm 原始返回：', raw)
    // 归一化返回结果（data 可能在外层 raw.data 或 axios 已解包）
    const result = (raw && raw.data && typeof raw.data === 'object') ? raw.data : raw
    const lotCode = result?.lotCode ?? result?.LotCode ?? stationInDetail.value?.lotCode ?? form.LotCode
    const operationName = result?.operationName ?? stationInDetail.value?.currentPendingOperationName ?? ''
    const stationName = result?.stationName ?? stationInDetail.value?.currentPendingStationName ?? ''
    const round = result?.round ?? 1
    const qty = result?.stationInQuantity ?? stationInQuantity
    const timeStr = result?.stationInTime ?? ''
    const timeLabel = timeStr ? `（${formatDateTime(timeStr)}）` : ''
    ElMessage.success(
      `进站成功：批次「${lotCode}」「${operationName || '工序'}」@${stationName || '工站'}` +
      (round > 1 ? ` · 第${round}轮` : '') +
      ` · ${qty}件 ${timeLabel}`
    )
    // 进站成功后跳转到出站管理页继续出站
    router.push('/execution/check-out')
  } catch (error) {
    const message = (error && error.message) ? error.message : '进站提交失败，请稍后重试'
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
        <h1 class="page-title">进站操作</h1>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="待进站批次列表">
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
          <el-table-column prop="productCode" label="产品编码" min-width="140" align="center"/>
          <el-table-column prop="productName" label="产品名称" min-width="140" align="center"/>
          <el-table-column prop="lineName" label="产线" min-width="120" align="center"/>
          <el-table-column prop="plannedQuantity" label="计划数量" width="110" align="center"/>
          <el-table-column prop="completedQuantity" label="已完成数量" width="120" align="center"/>
          <el-table-column prop="pendingStationInQuantity" label="待进站数量" width="120" align="center"/>
          <el-table-column prop="currentOperation" label="当前待进站工序" min-width="140" align="center"/>
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

      <template v-if="currentBatch">
        <SectionCard class="span-12" title="批次选择与基础信息">
          <el-form label-position="top">
            <el-form-item label="扫码 / 输入批次号">
              <el-select v-model="form.LotCode" filterable class="full lot-select">
                <el-option v-for="batch in stationInList" :key="batch.lotCode" :label="batch.lotCode" :value="batch.lotCode" />
              </el-select>
            </el-form-item>
            <el-descriptions :column="1" border v-loading="detailLoading">
              <el-descriptions-item label="产品名称">{{ stationInDetail?.productName || '-' }}</el-descriptions-item>
              <el-descriptions-item label="计划数量">{{ stationInDetail?.plannedQuantity ?? '-' }}</el-descriptions-item>
              <el-descriptions-item label="待进站数量">{{ stationInDetail?.pendingStationInQuantity ?? '-' }}</el-descriptions-item>
              <el-descriptions-item label="当前工序">{{ stationInDetail?.currentOperation || '-' }}</el-descriptions-item>
              <el-descriptions-item label="当前工站">
                <span v-if="currentStation?.StationName" class="station-highlight">
                  {{ currentStation.StationName }}
                  <span v-if="currentStation.StationCode" class="station-code">（{{ currentStation.StationCode }}）</span>
                </span>
                <span v-else>-</span>
              </el-descriptions-item>
              <el-descriptions-item label="设备名称">{{ currentStationEquipment?.EquipmentName || stationInDetail?.equipmentName || '-' }}</el-descriptions-item>
              <el-descriptions-item label="上一工序">{{ previousStepLabel }}</el-descriptions-item>
              <el-descriptions-item label="批次状态">
                <StatusTag v-if="stationInDetail?.lotStatus" :meta="statusMeta(BATCH_STATUS, stationInDetail.lotStatus)" />
                <span v-else>-</span>
              </el-descriptions-item>
              <el-descriptions-item label="工序状态">
                <StatusTag v-if="stationInDetail?.operationStatus" :meta="statusMeta(PROCESS_STATUS, stationInDetail.operationStatus)" />
                <span v-else>-</span>
              </el-descriptions-item>
            </el-descriptions>
          </el-form>
        </SectionCard>

        <SectionCard class="span-12" title="进站校验与信息填写">
          <el-alert :title="processCompliance.message" :type="processCompliance.type" show-icon :closable="false" />
          <el-alert
            style="margin-top: 10px"
            :title="loadingValidation.message"
            :type="loadingValidation.type"
            show-icon
            :closable="false"
          />

          <el-form :model="form" label-width="120px" class="operation-form">
            <el-form-item label="进站数量">
              <el-input-number
                v-model="form.StationInQuantity"
                :min="1"
                :max="(stationInDetail?.pendingStationInQuantity ?? currentBatch?.pendingStationInQuantity) || 1"
                controls-position="right"
                class="full"
              />
            </el-form-item>
            <el-form-item label="操作人">
              <el-select v-model="form.OperatorId" filterable placeholder="请选择操作人" class="full">
                <el-option v-for="user in operatorList" :key="user.id || user.Id" :label="getOperatorLabel(user)" :value="user.id || user.Id" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <div class="table-actions">
                <el-button size="large" @click="router.push('/execution/loading')">上料管理</el-button>
                <el-button
                  size="large"
                  @click="Object.assign(form, { StationInQuantity: stationInDetail?.pendingStationInQuantity || currentBatch?.pendingStationInQuantity || 1 })"
                >信息重置</el-button>
                <el-button type="primary" size="large" class="big-action" :loading="submitting" @click="submit">提交进站</el-button>
              </div>
            </el-form-item>
          </el-form>
        </SectionCard>
      </template>
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

.operation-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px 32px;
  margin-top: 18px;
  padding: 0 24px;
}

.operation-form :deep(.el-input-number) {
  width: 100%;
}

.operation-form :deep(.el-form-item) {
  margin-bottom: 0;
}

.operation-form :deep(.el-form-item:last-child) {
  grid-column: span 2;
}

@media (max-width: 900px) {
  .operation-form {
    grid-template-columns: 1fr;
    padding: 0 8px;
  }

  .operation-form :deep(.el-form-item:last-child) {
    grid-column: span 1;
  }

  .lot-select {
    max-width: 100%;
  }
}

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

.bom-packages-section {
  margin-top: 16px;
  padding: 12px 14px;
  background: var(--el-bg-color-page, #f8fafc);
  border: 1px solid var(--el-border-color-lighter, #e2e8f0);
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.package-row {
  display: flex;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 4px;
}

.package-label {
  min-width: 144px;
  flex-shrink: 0;
  padding-top: 2px;
  color: var(--rtm-text-muted, #64748b);
  font-size: 13px;
  font-weight: 500;
}
</style>
