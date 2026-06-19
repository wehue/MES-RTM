<script setup>
import { computed, reactive, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, PROCESS_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  PROCESS_STATUS_CODE,
  batches,
  devices,
  findUser,
  getBatchLine,
  getBatchLoadingSummary,
  getBatchPendingQty,
  getBatchProduct,
  getBatchWorkOrder,
  getCurrentOperationName,
  getCurrentProcess,
  getCurrentProcessStatus,
  getEquipmentTypeName,
  getRouteStepRows,
  getUserOptionLabel,
  requestBatchLoading,
  submitBatchCheckIn,
  users,
  validateBatchLoading,
  workOrders,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

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

const availableBatches = computed(() => batches.filter((item) => getCurrentProcessStatus(item.LotCode) === PROCESS_STATUS_CODE.wait_in))
const currentBatch = computed(() => availableBatches.value.find((item) => item.LotCode === form.LotCode) || availableBatches.value[0] || null)
const currentWorkOrder = computed(() => currentBatch.value ? getBatchWorkOrder(currentBatch.value) || null : null)
const currentRouteSteps = computed(() => currentWorkOrder.value ? getRouteStepRows(currentWorkOrder.value.RouteId) : [])
const currentStepIndex = computed(() => {
  const process = currentBatch.value ? getCurrentProcess(currentBatch.value) : null
  return currentRouteSteps.value.findIndex((item) => item.Id === process?.RouteStepId)
})
const previousStepLabel = computed(() => {
  if (!currentBatch.value) return '-'
  if (currentStepIndex.value <= 0) return '无上一工序'
  return currentRouteSteps.value[currentStepIndex.value - 1].OperationName
})
const processCompliance = computed(() => {
  if (!currentBatch.value) return { pass: false, type: 'info', message: '暂无可进站批次。' }
  if (currentBatch.value.Status === BATCH_STATUS_CODE.locked) return { pass: false, type: 'error', message: '批次已锁定，需完成异常处理后才可进站。' }
  if (currentBatch.value.Status === BATCH_STATUS_CODE.paused) return { pass: false, type: 'warning', message: '批次当前为暂停状态，请先恢复后再执行进站。' }
  if (![BATCH_STATUS_CODE.pending, BATCH_STATUS_CODE.running].includes(currentBatch.value.Status)) {
    return { pass: false, type: 'warning', message: `批次当前状态为${statusMeta(BATCH_STATUS, currentBatch.value.Status).label}，不满足进站条件。` }
  }
  if (getCurrentProcessStatus(currentBatch.value.LotCode) !== PROCESS_STATUS_CODE.wait_in) {
    return { pass: false, type: 'warning', message: '当前工序不是待进站状态。' }
  }
  if (currentStepIndex.value <= 0) return { pass: true, type: 'success', message: '当前为首道工序，可直接执行进站校验。' }
  return { pass: true, type: 'success', message: `上一工序 ${previousStepLabel.value} 已完成，当前工序允许进站。` }
})
const currentLine = computed(() => currentBatch.value ? getBatchLine(currentBatch.value) : null)
const availableDevices = computed(() => devices.filter((item) => item.LineId === currentLine.value?.Id && ![3, 5, 6].includes(item.Status)))
const loadingSummary = computed(() => currentBatch.value ? getBatchLoadingSummary(currentBatch.value.LotCode) : { Percentage: 0 })
const loadingValidation = computed(() => currentBatch.value ? validateBatchLoading(currentBatch.value.LotCode) : { pass: false, missing: [], message: '暂无待进站批次' })
const canSubmit = computed(() => Boolean(currentBatch.value && form.EquipmentId && processCompliance.value.pass && loadingValidation.value.pass))

watch(currentBatch, (batch) => {
  if (!batch) {
    form.LotCode = ''
    form.StationInQuantity = 1
    form.EquipmentId = ''
    return
  }
  form.LotCode = batch.LotCode
  form.StationInQuantity = Math.max(getBatchPendingQty(batch.LotCode), 1)
  form.EquipmentId = ''
}, { immediate: true })

function selectBatch(batch) {
  if (!batch?.LotCode) return
  form.LotCode = batch.LotCode
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
          :data="availableBatches"
          border
          highlight-current-row
          row-key="LotCode"
          :current-row-key="form.LotCode"
          @current-change="selectBatch"
          @row-click="selectBatch"
        >
          <el-table-column prop="LotCode" label="批次号" min-width="160" />
          <el-table-column label="工单号" min-width="160">
            <template #default="{ row }">{{ getBatchWorkOrder(row)?.WorkOrderCode || '-' }}</template>
          </el-table-column>
          <el-table-column label="产品型号" min-width="150">
            <template #default="{ row }">{{ getBatchProduct(row)?.Model || '-' }}</template>
          </el-table-column>
          <el-table-column label="产线" width="100">
            <template #default="{ row }">{{ getBatchLine(row)?.LineCode || '-' }}</template>
          </el-table-column>
          <el-table-column label="待进站数量" width="120">
            <template #default="{ row }">{{ getBatchPendingQty(row.LotCode) }}</template>
          </el-table-column>
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <StatusTag :meta="statusMeta(PROCESS_STATUS, getCurrentProcessStatus(row.LotCode))" />
            </template>
          </el-table-column>
        </el-table>
      </SectionCard>

      <template v-if="currentBatch">
        <SectionCard class="span-12" title="批次选择与基础信息">
          <el-form label-position="top">
            <el-form-item label="扫码 / 输入批次号">
              <el-select v-model="form.LotCode" filterable class="full">
                <el-option v-for="batch in availableBatches" :key="batch.LotCode" :label="batch.LotCode" :value="batch.LotCode" />
              </el-select>
            </el-form-item>
            <el-descriptions :column="1" border>
              <el-descriptions-item label="产品型号">{{ getBatchProduct(currentBatch)?.Model }}</el-descriptions-item>
              <el-descriptions-item label="计划数量">{{ currentBatch.PlannedQuantity }}</el-descriptions-item>
              <el-descriptions-item label="待进站数量">{{ getBatchPendingQty(currentBatch.LotCode) }}</el-descriptions-item>
              <el-descriptions-item label="当前工序">{{ getCurrentOperationName(currentBatch) }}</el-descriptions-item>
              <el-descriptions-item label="上一工序">{{ previousStepLabel }}</el-descriptions-item>
              <el-descriptions-item label="批次状态">
                <StatusTag :meta="statusMeta(BATCH_STATUS, currentBatch.Status)" />
              </el-descriptions-item>
              <el-descriptions-item label="工序状态">
                <StatusTag :meta="statusMeta(PROCESS_STATUS, getCurrentProcessStatus(currentBatch.LotCode))" />
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
            <el-form-item label="设备ID">
              <el-select v-model="form.EquipmentId" placeholder="扫描或选择设备" class="full">
                <el-option
                  v-for="device in availableDevices"
                  :key="device.Id"
                  :label="`${device.EquipmentCode} / ${device.EquipmentName} / ${getEquipmentTypeName(device.EquipmentTypeId)}`"
                  :value="device.Id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="进站数量">
              <el-input-number v-model="form.StationInQuantity" :min="1" :max="currentBatch.PlannedQuantity" />
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
                <el-button size="large" @click="Object.assign(form, { EquipmentId: '', StationInQuantity: currentBatch.PlannedQuantity, VerifyRemark: '' })">信息重置</el-button>
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
</style>
