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
  findUser,
  getBatchLine,
  getBatchLoadingSummary,
  getBatchPendingQty,
  getBatchProduct,
  getBatchWorkOrder,
  getCurrentOperationName,
  getCurrentProcess,
  getCurrentProcessStatus,
  getRouteStepRows,
  getUserOptionLabel,
  requestBatchLoading,
  submitBatchCheckIn,
  users,
  validateBatchLoading,
  workOrders,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { getStationInList, getStationInDetail } from '@/api/batch'
import { getEquipmentTypes } from '@/api/device'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const form = reactive({
  LotCode: String(route.query.LotCode || route.query.batchId || ''),
  EquipmentId: '',
  StationInQuantity: 800,
  OperatorId: findUser(userStore.userInfo.username || userStore.userInfo.name)?.Id || 3,
  VerifyRemark: '',
})

const stationInList = ref([])
const listLoading = ref(false)
const stationInDetail = ref(null)
const detailLoading = ref(false)
const listPagination = reactive({ pageNum: 1, pageSize: 5, total: 0 })
const equipmentList = ref([])

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

async function loadEquipmentList() {
  try {
    const data = await getEquipmentTypes()
    equipmentList.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Failed to load equipment list:', error)
    equipmentList.value = []
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
  loadEquipmentList()
})

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
    return { LineName: currentBatch.value.lineName, LineCode: currentBatch.value.lineName }
  }
  return mockBatch.value ? getBatchLine(mockBatch.value) : null
})
const loadingSummary = computed(() => mockBatch.value ? getBatchLoadingSummary(mockBatch.value.LotCode) : { Percentage: 0 })
const loadingValidation = computed(() => mockBatch.value ? validateBatchLoading(mockBatch.value.LotCode) : { pass: false, missing: [], message: '暂无待进站批次' })
const canSubmit = computed(() => Boolean(currentBatch.value && form.EquipmentId && processCompliance.value.pass && loadingValidation.value.pass))

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
  form.EquipmentId = ''
}, { immediate: true })

function selectBatch(batch) {
  if (!batch?.lotCode) return
  form.LotCode = batch.lotCode
}

function submit() {
  if (!canSubmit.value) {
    if (!processCompliance.value.pass) {
      ElMessage.error(processCompliance.value.message)
      return
    }
    if (!form.EquipmentId) {
      ElMessage.error('未选择可用设备，进站提交已拦截')
      return
    }
    if (!loadingValidation.value.pass) {
      requestBatchLoading(form.LotCode, loadingValidation.value.message)
      ElMessage.error('BOM 物料未齐套，已生成补料请求，请到上料管理补齐。')
      router.push('/execution/loading')
      return
    }
    ElMessage.error('当前批次不满足进站条件')
    return
  }
  const result = submitBatchCheckIn(form.LotCode, {
    StationInQuantity: form.StationInQuantity,
    EquipmentId: Number(form.EquipmentId),
    OperatorId: Number(form.OperatorId),
    StationInTime: '2026-05-20 14:50',
    VerifyRemark: form.VerifyRemark,
  })
  if (!result.ok) {
    ElMessage.error(result.message)
    return
  }
  ElMessage.success('进站成功，批次已进入当前工序生产中')
  router.push('/execution/check-out')
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
          <el-table-column prop="lotCode" label="批次号" min-width="160" />
          <el-table-column prop="workOrderCode" label="工单号" min-width="160" />
          <el-table-column prop="productName" label="产品名称" min-width="150" />
          <el-table-column prop="lineName" label="产线" width="100" />
          <el-table-column prop="pendingStationInQuantity" label="待进站数量" width="120" />
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
            :title="form.EquipmentId ? '设备选择完成，可执行进站。' : '未选择设备：请选择当前工序对应的可用设备。'"
            :type="form.EquipmentId ? 'success' : 'error'"
            show-icon
            :closable="false"
          />
          <el-alert
            style="margin-top: 10px"
            :title="loadingValidation.pass ? `上料完成率 ${loadingSummary.Percentage}% ，当前工序 BOM 校验通过。` : loadingValidation.message"
            :type="loadingValidation.pass ? 'success' : 'warning'"
            show-icon
            :closable="false"
          />

          <el-form :model="form" label-width="106px" class="operation-form">
            <el-form-item label="设备">
              <el-select v-model="form.EquipmentId" placeholder="扫描或选择设备" class="full">
                <el-option
                  v-for="equipment in equipmentList"
                  :key="equipment.id"
                  :label="`${equipment.typeCode} / ${equipment.typeName}`"
                  :value="equipment.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="进站数量">
              <el-input-number v-model="form.StationInQuantity" :min="1" :max="stationInDetail?.plannedQuantity || 1" />
            </el-form-item>
            <el-form-item label="操作人">
              <el-select v-model="form.OperatorId" filterable placeholder="请选择操作人" class="full">
                <el-option v-for="user in users" :key="user.Id" :label="getUserOptionLabel(user)" :value="user.Id" />
              </el-select>
            </el-form-item>
            <el-form-item label="校验备注">
              <el-input v-model="form.VerifyRemark" type="textarea" />
            </el-form-item>
            <el-form-item>
              <div class="table-actions">
                <el-button size="large" @click="router.push('/execution/loading')">上料管理</el-button>
                <el-button size="large" @click="Object.assign(form, { EquipmentId: '', StationInQuantity: stationInDetail?.plannedQuantity || 1, VerifyRemark: '' })">信息重置</el-button>
                <el-button type="primary" size="large" class="big-action" @click="submit">提交进站</el-button>
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
</style>
