<script setup>
import { computed, reactive, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, PROCESS_STATUS, statusMeta } from '@/utils/constants'
import { batches, devices, getBatchLoadingSummary, getBatchPendingQty, getCurrentProcessStatus, processRoutes, requestBatchLoading, submitBatchCheckIn, validateBatchLoading, workOrders } from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const form = reactive({
  batchId: String(route.query.batchId || ''),
  deviceId: '',
  qty: 800,
  operator: userStore.userInfo.name || '张工',
  remark: '',
})

const availableBatches = computed(() => batches.filter((item) => getCurrentProcessStatus(item.id) === 'wait_in'))
const currentBatch = computed(() => availableBatches.value.find((item) => item.id === form.batchId) || availableBatches.value[0] || null)
const currentWorkOrder = computed(() => currentBatch.value ? workOrders.find((item) => item.id === currentBatch.value.workOrderId) || null : null)
const currentRoute = computed(() => currentWorkOrder.value ? processRoutes.find((item) => item.id === currentWorkOrder.value.routeId) || null : null)
const currentStepIndex = computed(() => {
  if (!currentBatch.value || !currentRoute.value) return -1
  return currentRoute.value.steps.findIndex((item) => item.step === currentBatch.value.currentStep)
})
const previousStepLabel = computed(() => {
  if (!currentBatch.value) return '-'
  if (!currentRoute.value || currentStepIndex.value <= 0) return '无上一工序'
  return currentRoute.value.steps[currentStepIndex.value - 1].step
})
const processCompliance = computed(() => {
  if (!currentBatch.value) {
    return { pass: false, type: 'info', message: '暂无可进站批次。' }
  }
  if (currentBatch.value.status === 'locked') {
    return { pass: false, type: 'error', message: '批次已锁定，需完成异常处理后才可进站。' }
  }
  if (currentBatch.value.status === 'paused') {
    return { pass: false, type: 'warning', message: '批次当前为暂停状态，请先恢复后再执行进站。' }
  }
  if (!['pending', 'running'].includes(currentBatch.value.status)) {
    return { pass: false, type: 'warning', message: `批次当前状态为${statusMeta(BATCH_STATUS, currentBatch.value.status).label}，不满足进站条件。` }
  }
  if (getCurrentProcessStatus(currentBatch.value.id) !== 'wait_in') {
    return { pass: false, type: 'warning', message: '当前工序不是待进站状态。' }
  }
  if (!currentRoute.value || currentStepIndex.value <= 0) {
    return { pass: true, type: 'success', message: '当前为首道工序，可直接执行进站校验。' }
  }
  return { pass: true, type: 'success', message: `上一工序 ${previousStepLabel.value} 已完成，当前工序允许进站。` }
})
const availableDevices = computed(() => devices.filter((item) => item.line === currentBatch.value?.line && item.status !== 'fault' && item.status !== 'offline'))
const loadingSummary = computed(() => currentBatch.value ? getBatchLoadingSummary(currentBatch.value.id) : { percentage: 0 })
const loadingValidation = computed(() => currentBatch.value ? validateBatchLoading(currentBatch.value.id) : { pass: false, missing: [], message: '暂无待进站批次' })
const canSubmit = computed(() => Boolean(currentBatch.value && form.deviceId && processCompliance.value.pass && loadingValidation.value.pass))

watch(currentBatch, (batch) => {
  if (!batch) {
    form.batchId = ''
    form.qty = 1
    form.deviceId = ''
    return
  }
  form.batchId = batch.id
  form.qty = Math.max(getBatchPendingQty(batch.id), 1)
  form.deviceId = ''
}, { immediate: true })

function selectBatch(batch) {
  if (!batch?.id) return
  form.batchId = batch.id
}

function submit() {
  if (!canSubmit.value) {
    if (!processCompliance.value.pass) {
      ElMessage.error(processCompliance.value.message)
      return
    }
    if (!form.deviceId) {
      ElMessage.error('未选择可用设备，进站提交已拦截')
      return
    }
    if (!loadingValidation.value.pass) {
      requestBatchLoading(form.batchId, loadingValidation.value.message)
      ElMessage.error('BOM 物料未齐套，已生成补料请求，请到上料管理补齐。')
      router.push('/execution/loading')
      return
    }
    ElMessage.error('当前批次不满足进站条件')
    return
  }
  const result = submitBatchCheckIn(form.batchId, {
    qty: form.qty,
    deviceId: form.deviceId,
    operator: form.operator,
    inAt: '2026-05-20 14:50',
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
        <p class="page-subtitle">选择待进站批次，完成工序状态校验、物料校验和设备绑定后提交进站。</p>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="待进站批次列表">
        <el-table
          :data="availableBatches"
          border
          highlight-current-row
          row-key="id"
          :current-row-key="form.batchId"
          @current-change="selectBatch"
          @row-click="selectBatch"
        >
          <el-table-column prop="id" label="批次号" min-width="160" />
          <el-table-column prop="workOrderId" label="工单号" min-width="160" />
          <el-table-column prop="productModel" label="产品型号" min-width="150" />
          <el-table-column prop="line" label="产线" width="100" />
          <el-table-column label="待进站数量" width="120">
            <template #default="{ row }">{{ getBatchPendingQty(row.id) }}</template>
          </el-table-column>
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <StatusTag :meta="statusMeta(PROCESS_STATUS, getCurrentProcessStatus(row.id))" />
            </template>
          </el-table-column>
        </el-table>
      </SectionCard>

      <template v-if="currentBatch">
      <SectionCard class="span-12" title="批次选择与基础信息">
        <el-form label-position="top">
          <el-form-item label="扫码 / 输入批次号">
            <el-select v-model="form.batchId" filterable class="full">
              <el-option v-for="batch in availableBatches" :key="batch.id" :label="batch.id" :value="batch.id" />
            </el-select>
          </el-form-item>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="产品型号">{{ currentBatch.productModel }}</el-descriptions-item>
            <el-descriptions-item label="计划数量">{{ currentBatch.planned }}</el-descriptions-item>
            <el-descriptions-item label="待进站数量">{{ getBatchPendingQty(currentBatch.id) }}</el-descriptions-item>
            <el-descriptions-item label="当前工序">{{ currentBatch.currentStep }}</el-descriptions-item>
            <el-descriptions-item label="上一工序">{{ previousStepLabel }}</el-descriptions-item>
            <el-descriptions-item label="批次状态">
              <StatusTag :meta="statusMeta(BATCH_STATUS, currentBatch.status)" />
            </el-descriptions-item>
            <el-descriptions-item label="工序状态">
              <StatusTag :meta="statusMeta(PROCESS_STATUS, getCurrentProcessStatus(currentBatch.id))" />
            </el-descriptions-item>
          </el-descriptions>
        </el-form>
      </SectionCard>

      <SectionCard class="span-12" title="进站校验与信息填写">
        <el-alert :title="processCompliance.message" :type="processCompliance.type" show-icon :closable="false" />
        <el-alert
          style="margin-top: 10px"
          :title="form.deviceId ? '设备选择完成，可执行进站。' : '未选择设备：请选择当前工序对应的可用设备。'"
          :type="form.deviceId ? 'success' : 'error'"
          show-icon
          :closable="false"
        />
        <el-alert
          style="margin-top: 10px"
          :title="loadingValidation.pass ? `上料完成率 ${loadingSummary.percentage}% ，当前工序 BOM 校验通过。` : loadingValidation.message"
          :type="loadingValidation.pass ? 'success' : 'warning'"
          show-icon
          :closable="false"
        />

        <el-form :model="form" label-width="96px" class="operation-form">
          <el-form-item label="设备条码">
            <el-select v-model="form.deviceId" placeholder="扫描或选择设备" class="full">
              <el-option v-for="device in availableDevices" :key="device.id" :label="`${device.id} / ${device.name}`" :value="device.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="进站数量">
            <el-input-number v-model="form.qty" :min="1" :max="currentBatch.planned" />
          </el-form-item>
          <el-form-item label="操作人">
            <el-input v-model="form.operator" />
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="form.remark" type="textarea" />
          </el-form-item>
          <el-form-item>
            <div class="table-actions">
              <el-button size="large" @click="router.push('/execution/loading')">上料管理</el-button>
              <el-button size="large" @click="Object.assign(form, { deviceId: '', qty: currentBatch.planned, remark: '' })">信息重置</el-button>
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
