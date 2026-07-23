<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, PROCESS_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  PROCESS_STATUS_CODE,
  batches,
  findStation,
  findStationByLineOperation,
  getBatchLine,
  getBatchPendingQty,
  getBatchWorkOrder,
  getCurrentProcess,
  getRouteStepRows,
  getStationEquipment,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { getStationInList, getStationInDetail, createStationIn } from '@/api/batch'
import { getOperators } from '@/api/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const form = reactive({
  LotCode: String(route.query.LotCode || route.query.batchId || ''),
  StationInQuantity: 800,
  OperatorId: '',
  VerifyRemark: '',
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

async function loadStationInList() {
  listLoading.value = true
  try {
    const data = await getStationInList()
    stationInList.value = Array.isArray(data) ? data : []
    listPagination.total = stationInList.value.length
    if (!form.LotCode && stationInList.value.length) {
      form.LotCode = stationInList.value[0].lotCode
    }
  } catch (error) {
    console.error('Failed to load station-in list:', error)
    stationInList.value = []
    listPagination.total = 0
  } finally {
    listLoading.value = false
  }
}

function handlePageChange(pageNum) {
  listPagination.pageNum = pageNum
}

function handleSizeChange(pageSize) {
  listPagination.pageSize = pageSize
  listPagination.pageNum = 1
}

const pagedStationInList = computed(() => {
  const start = (listPagination.pageNum - 1) * listPagination.pageSize
  const end = start + listPagination.pageSize
  return stationInList.value.slice(start, end)
})

async function loadStationInDetail(lotCode) {
  if (!lotCode) {
    stationInDetail.value = null
    return
  }
  detailLoading.value = true
  try {
    const data = await getStationInDetail(lotCode)
    stationInDetail.value = data
  } catch (error) {
    console.error('Failed to load station-in detail:', error)
    stationInDetail.value = null
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

const mockBatch = computed(() => batches.find(item => item.LotCode === form.LotCode) || null)

const currentWorkOrder = computed(() => mockBatch.value ? getBatchWorkOrder(mockBatch.value) || null : null)
const currentRouteSteps = computed(() => currentWorkOrder.value ? getRouteStepRows(currentWorkOrder.value.RouteId) : [])
const currentStepIndex = computed(() => {
  const process = mockBatch.value ? getCurrentProcess(mockBatch.value) : null
  return currentRouteSteps.value.findIndex((item) => item.Id === process?.RouteStepId)
})
const previousStepLabel = computed(() => {
  if (stationInDetail.value?.previousOperation) return stationInDetail.value.previousOperation
  if (!mockBatch.value) return '-'
  if (currentStepIndex.value <= 0) return '无上一工序'
  return currentRouteSteps.value[currentStepIndex.value - 1].OperationName
})
const processCompliance = computed(() => {
  if (!stationInList.value.length) return { pass: false, type: 'info', message: '暂无可进站批次。' }
  if (!stationInDetail.value) return { pass: false, type: 'info', message: '加载中...' }
  const lotStatus = stationInDetail.value.lotStatus
  const opStatus = stationInDetail.value.operationStatus
  if (lotStatus === BATCH_STATUS_CODE.locked) return { pass: false, type: 'error', message: '批次已锁定，需完成异常处理后才可进站。' }
  if (lotStatus === BATCH_STATUS_CODE.paused) return { pass: false, type: 'warning', message: '批次当前为暂停状态，请先恢复后再执行进站。' }
  if (![BATCH_STATUS_CODE.pending, BATCH_STATUS_CODE.running].includes(lotStatus)) {
    return { pass: false, type: 'warning', message: `批次当前状态为${statusMeta(BATCH_STATUS, lotStatus).label}，不满足进站条件。` }
  }
  if (opStatus !== PROCESS_STATUS_CODE.wait_in) {
    return { pass: false, type: 'warning', message: '当前工序不是待进站状态。' }
  }
  if (stationInDetail.value.previousOperation === '-' || !stationInDetail.value.previousOperation) {
    return { pass: true, type: 'success', message: '当前为首道工序，可直接执行进站校验。' }
  }
  return { pass: true, type: 'success', message: `上一工序 ${stationInDetail.value.previousOperation} 已完成，当前工序允许进站。` }
})
const currentLine = computed(() => {
  if (currentBatch.value?.lineName) {
    return { LineName: currentBatch.value.lineName, LineCode: currentBatch.value.lineName, Id: currentBatch.value.lineId }
  }
  return mockBatch.value ? getBatchLine(mockBatch.value) : null
})
// 当前工序对应的工站（与工序、设备均为一对一关系）
// 优先使用后端 station-in/detail 返回的 stationId/stationName；
// 后端未返回时，按"当前批次产线 + 当前工序"在 mock stations 中查找
const currentStation = computed(() => {
  if (!stationInDetail.value) return null
  const detail = stationInDetail.value
  // 后端直返字段优先
  const remoteStationId = detail.stationId || detail.StationId
  if (remoteStationId) {
    const station = findStation(remoteStationId)
    if (station) return station
  }
  if (detail.stationName) {
    return { StationName: detail.stationName, StationCode: detail.stationCode || '', EquipmentId: detail.equipmentId }
  }
  // mock 兜底：按产线 + 当前工序查找工站
  const step = currentRouteSteps.value[currentStepIndex.value]
  if (step?.StationId) {
    return findStation(step.StationId)
  }
  const lineId = currentLine.value?.Id
  const operationId = step?.OperationId
  if (lineId && operationId) {
    return findStationByLineOperation(lineId, operationId)
  }
  return null
})
const currentStationEquipment = computed(() => {
  // 优先使用后端返回的设备信息
  const detail = stationInDetail.value
  if (detail?.equipmentCode || detail?.equipmentName) {
    return {
      EquipmentCode: detail.equipmentCode || '',
      EquipmentName: detail.equipmentName || '-',
      EquipmentTypeName: detail.equipmentTypeName || '',
    }
  }
  // mock 兜底
  if (!currentStation.value) return null
  return getStationEquipment(currentStation.value.Id)
})
const equipmentBoundReady = computed(() => Boolean(currentStationEquipment.value))
// BOM 齐套校验（完全依赖后端 /api/lots/station-in/detail 返回的 verifyFailedTotalQuantity：
//  - 0        → 当前工序 BOM 物料全部校验通过
//  - >0       → 当前工序仍有 N 个物料未上料/校验失败
//  - null/undef → 数据还未加载完成
const loadingValidation = computed(() => {
  if (!stationInList.value.length) return { pass: false, type: 'info', message: '暂无可进站批次，无法进行 BOM 校验。' }
  if (!stationInDetail.value) return { pass: false, type: 'info', message: '加载中...' }
  const failedQty = stationInDetail.value.verifyFailedTotalQuantity
  if (failedQty === null || failedQty === undefined) return { pass: false, type: 'info', message: 'BOM 校验结果暂未返回，稍后重试。' }
  if (Number(failedQty) <= 0) return { pass: true, type: 'success', message: '当前工序 BOM 物料校验通过，满足进站条件。' }
  return { pass: false, type: 'warning', message: `BOM 物料未齐套，当前工序仍有 ${Number(failedQty)} 个物料校验失败，请先到上料管理补齐物料。` }
})
const canSubmit = computed(() => Boolean(currentBatch.value && equipmentBoundReady.value && processCompliance.value.pass && loadingValidation.value.pass))

watch(() => form.LotCode, (lotCode) => {
  loadStationInDetail(lotCode)
  const batch = batches.find(b => b.LotCode === lotCode)
  if (batch) {
    form.StationInQuantity = Math.max(getBatchPendingQty(batch.LotCode), 1)
  } else if (stationInDetail.value?.pendingStationInQuantity) {
    form.StationInQuantity = stationInDetail.value.pendingStationInQuantity
  } else {
    form.StationInQuantity = 1
  }
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
    if (!equipmentBoundReady.value) {
      ElMessage.error('当前工站未绑定设备，请联系管理员维护工站-设备关系')
      return
    }
    if (!loadingValidation.value.pass) {
      ElMessage.error(loadingValidation.value.message)
      router.push('/execution/loading')
      return
    }
    ElMessage.error('当前批次不满足进站条件')
    return
  }
  // 以当前选中批次的 id（即 lotId）作为进站提交的主键
  const lotId = currentBatch.value?.id
  if (!lotId) {
    ElMessage.error('未找到当前批次 ID，无法提交进站')
    return
  }
  // 工站与设备为一对一关系，设备由后端根据工站自动识别，无需前端传递 equipmentId
  const payload = {
    lotId: Number(lotId),
    operatorId: Number(form.OperatorId),
    stationInQuantity: Number(form.StationInQuantity),
    remark: form.VerifyRemark || undefined,
  }
  if (!payload.operatorId) {
    ElMessage.error('请选择操作人')
    return
  }
  if (!payload.stationInQuantity || payload.stationInQuantity <= 0) {
    ElMessage.error('进站数量必须大于 0')
    return
  }
  submitting.value = true
  try {
    await createStationIn(payload)
    ElMessage.success('进站成功，批次已进入当前工序生产中')
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
        <p class="page-subtitle">按 smt_station_in_records 字段提交进站，校验当前工序、物料齐套和设备绑定。</p>
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
          <el-table-column prop="workOrderCode" label="工单号" min-width="160" align="center"/>
          <el-table-column prop="productName" label="产品名称" min-width="150" align="center"/>
          <el-table-column prop="lineName" label="产线" width="180" align="center" />
          <el-table-column prop="pendingStationInQuantity" label="待进站数量" width="180" align="center" />
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
              <el-select v-model="form.LotCode" filterable class="full">
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
            :title="equipmentBoundReady ? `工站已绑定设备：${currentStationEquipment?.EquipmentCode || ''} / ${currentStationEquipment?.EquipmentName || '-'}` : '当前工站未绑定设备，无法进站，请联系管理员维护工站-设备关系。'"
            :type="equipmentBoundReady ? 'success' : 'error'"
            show-icon
            :closable="false"
          />
          <el-alert
            style="margin-top: 10px"
            :title="loadingValidation.message"
            :type="loadingValidation.type"
            show-icon
            :closable="false"
          />

          <el-form :model="form" label-width="106px" class="operation-form">
            <el-form-item label="工站">
              <el-input :model-value="currentStation?.StationName || '-'" readonly>
                <template v-if="currentStation?.StationCode" #append>{{ currentStation.StationCode }}</template>
              </el-input>
            </el-form-item>
            <el-form-item label="绑定设备">
              <el-input
                :model-value="currentStationEquipment ? `${currentStationEquipment.EquipmentCode || ''} / ${currentStationEquipment.EquipmentName || '-'}` : '当前工站未绑定设备'"
                readonly
              />
            </el-form-item>
            <el-form-item label="进站数量">
              <el-input-number v-model="form.StationInQuantity" :min="1" :max="stationInDetail?.plannedQuantity || 1" />
            </el-form-item>
            <el-form-item label="操作人">
              <el-select v-model="form.OperatorId" filterable placeholder="请选择操作人" class="full">
                <el-option v-for="user in operatorList" :key="user.id || user.Id" :label="getOperatorLabel(user)" :value="user.id || user.Id" />
              </el-select>
            </el-form-item>
            <el-form-item label="校验备注">
              <el-input v-model="form.VerifyRemark" type="textarea" />
            </el-form-item>
            <el-form-item>
              <div class="table-actions">
                <el-button size="large" @click="router.push('/execution/loading')">上料管理</el-button>
                <el-button size="large" @click="Object.assign(form, { StationInQuantity: stationInDetail?.plannedQuantity || 1, VerifyRemark: '' })">信息重置</el-button>
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

.operation-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px 24px;
  margin-top: 18px;
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
  }

  .operation-form :deep(.el-form-item:last-child) {
    grid-column: span 1;
  }
}

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

.station-highlight {
  font-weight: 600;
  color: #2563eb;
}

.station-code {
  font-weight: 400;
  color: #64748b;
  font-size: 13px;
}
</style>
