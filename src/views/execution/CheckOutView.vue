<script setup>
import { computed, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import { batches, batchExecutionState, getCurrentProcessStatus, getInspectionThreshold, isInspectionProcess, submitBatchCheckOut } from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const form = reactive({
  batchId: '',
  goodQty: 0,
  badQty: 0,
  scrapQty: 0,
  passRate: 100,
  qualityAction: 'normal',
  disposal: 'repair',
  forceReason: '',
  operator: userStore.userInfo.name || '张工',
  remark: '',
})

const availableBatches = computed(() => batches.filter((item) => getCurrentProcessStatus(item.id) === 'checked_in'))
const batch = computed(() => availableBatches.value.find((item) => item.id === form.batchId) || availableBatches.value[0] || null)
const canForce = computed(() => userStore.hasAnyRole(['production_manager']))
const isLocked = computed(() => batch.value?.status === 'locked')
const currentInQty = computed(() => batch.value ? (batchExecutionState[batch.value.id]?.currentInQty || batch.value.completed + batch.value.defective + batch.value.scrap) : 0)
const isInspection = computed(() => batch.value ? isInspectionProcess(batch.value.currentStep) : false)
const inspectionThreshold = computed(() => batch.value ? getInspectionThreshold(batch.value.currentStep) : 0)
const inspectionPass = computed(() => form.passRate >= inspectionThreshold.value)
const quantityValid = computed(() => form.goodQty + form.badQty + form.scrapQty === currentInQty.value)

watch(batch, (current) => {
  if (!current) {
    form.batchId = ''
    form.goodQty = 0
    form.badQty = 0
    form.scrapQty = 0
    form.passRate = 100
    form.qualityAction = 'normal'
    form.forceReason = ''
    return
  }
  form.batchId = current.id
  form.goodQty = current.completed
  form.badQty = current.defective
  form.scrapQty = current.scrap
  form.passRate = currentInQty.value ? Number(((current.completed / currentInQty.value) * 100).toFixed(1)) : 100
  form.qualityAction = 'normal'
  form.disposal = current.defective > 0 ? 'repair' : 'scrap'
  form.forceReason = ''
}, { immediate: true })

watch(inspectionPass, (pass) => {
  if (pass) {
    form.qualityAction = 'normal'
  }
})

function selectBatch(row) {
  if (!row?.id) return
  form.batchId = row.id
}

function submit() {
  if (!batch.value) {
    ElMessage.error('当前没有可出站批次')
    return
  }
  if (isLocked.value) {
    ElMessage.error(`批次已锁定：${batch.value.lockReason}`)
    return
  }
  if (!isInspection.value && !quantityValid.value) {
    ElMessage.error(`数量不匹配：进站数量 ${currentInQty.value}，出站合计 ${form.goodQty + form.badQty + form.scrapQty}`)
    return
  }
  if (!isInspection.value && form.disposal === 'force' && !canForce.value) {
    ElMessage.error('当前角色没有强制出站权限')
    return
  }
  if (!isInspection.value && form.disposal === 'force' && !form.forceReason.trim()) {
    ElMessage.error('请填写强制出站原因')
    return
  }
  if (isInspection.value && !inspectionPass.value && !['force', 'lock'].includes(form.qualityAction)) {
    ElMessage.error('检测通过率低于阈值，请选择强制出站或批次锁定')
    return
  }
  if (isInspection.value && !inspectionPass.value && form.qualityAction === 'force' && !canForce.value) {
    ElMessage.error('当前角色没有强制出站权限')
    return
  }
  if (isInspection.value && !inspectionPass.value && !form.forceReason.trim()) {
    ElMessage.error(form.qualityAction === 'lock' ? '请填写批次锁定原因' : '请填写强制出站原因')
    return
  }

  const result = submitBatchCheckOut(form.batchId, {
    goodQty: form.goodQty,
    badQty: form.badQty,
    scrapQty: form.scrapQty,
    passRate: form.passRate,
    qualityAction: form.qualityAction,
    disposal: form.disposal,
    operator: form.operator,
    remark: form.remark || form.forceReason,
    outAt: '2026-05-20 15:00',
  })

  if (!result.ok) {
    ElMessage.error(result.message)
    return
  }

  if (result.status === 'repair') {
    ElMessage.success('出站完成，已生成维修任务，请到维修管理处理。')
    return
  }
  if (result.status === 'locked') {
    ElMessage.warning('检测通过率低于阈值，批次已锁定，等待质量评审。')
    return
  }
  if (result.status === 'wait_in') {
    ElMessage.success(`出站完成，批次已流转至下一工序：${result.nextStep}，即将跳转到进站操作。`)
    router.push({
      path: '/execution/check-in',
      query: {
        batchId: result.batch.id,
      },
    })
    return
  }
  ElMessage.success('出站完成，当前批次全部工序已结束。')
  router.push('/production/batch')
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">出站操作</h1>
        <p class="page-subtitle">选择当前工序已完成的批次，普通工序确认数量，SPI / AOI 检测工序按通过率和阈值执行出站或锁定。</p>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="可出站批次列表">
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
          <el-table-column prop="currentStep" label="当前工序" min-width="120" />
          <el-table-column label="进站数量" width="100">
            <template #default="{ row }">{{ batchExecutionState[row.id]?.currentInQty || row.completed + row.defective + row.scrap }}</template>
          </el-table-column>
          <el-table-column prop="completed" label="良品" width="90" />
          <el-table-column prop="defective" label="不良" width="90" />
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <StatusTag :meta="statusMeta(BATCH_STATUS, row.status)" />
            </template>
          </el-table-column>
        </el-table>
      </SectionCard>

      <SectionCard v-if="batch" class="span-12" title="批次与出站信息">
        <el-form label-position="top">
          <el-form-item label="选择批次">
            <el-select v-model="form.batchId" filterable class="full">
              <el-option v-for="item in availableBatches" :key="item.id" :label="item.id" :value="item.id" />
            </el-select>
          </el-form-item>
        </el-form>
        <el-alert v-if="isLocked" :title="`批次已锁定：${batch.lockReason}`" type="error" show-icon :closable="false" />
        <el-descriptions :column="1" border style="margin-top: 10px">
          <el-descriptions-item label="批次号">{{ batch.id }}</el-descriptions-item>
          <el-descriptions-item label="产品型号">{{ batch.productModel }}</el-descriptions-item>
          <el-descriptions-item label="当前工序">{{ batch.currentStep }}</el-descriptions-item>
          <el-descriptions-item label="进站数量">{{ currentInQty }}</el-descriptions-item>
          <el-descriptions-item v-if="isInspection" label="检测阈值">{{ inspectionThreshold }}%</el-descriptions-item>
          <el-descriptions-item label="批次状态">
            <StatusTag :meta="statusMeta(BATCH_STATUS, batch.status)" />
          </el-descriptions-item>
        </el-descriptions>

        <el-alert
          v-if="!isInspection"
          style="margin-top: 12px"
          :title="quantityValid ? '数量关系校验通过：进站数量 = 良品 + 不良 + 报废。' : `数量关系校验失败：进站数量 ${currentInQty}，出站合计 ${form.goodQty + form.badQty + form.scrapQty}。`"
          :type="quantityValid ? 'success' : 'error'"
          show-icon
          :closable="false"
        />
        <el-alert
          v-else
          style="margin-top: 12px"
          :title="inspectionPass ? `检测通过率 ${form.passRate}% 达到阈值 ${inspectionThreshold}%，可正常出站。` : `检测通过率 ${form.passRate}% 低于阈值 ${inspectionThreshold}%，请选择强制出站或批次锁定。`"
          :type="inspectionPass ? 'success' : 'error'"
          show-icon
          :closable="false"
        />

        <el-form v-if="!isInspection" :model="form" label-width="100px" class="checkout-form">
          <el-form-item label="良品数量"><el-input-number v-model="form.goodQty" :min="0" /></el-form-item>
          <el-form-item label="不良数量"><el-input-number v-model="form.badQty" :min="0" /></el-form-item>
          <el-form-item label="报废数量"><el-input-number v-model="form.scrapQty" :min="0" /></el-form-item>
          <el-form-item v-if="form.badQty > 0" label="不良处置">
            <el-select v-model="form.disposal" class="full">
              <el-option label="维修" value="repair" />
              <el-option label="报废" value="scrap" />
              <el-option label="强制出站" value="force" />
            </el-select>
          </el-form-item>
          <el-form-item v-if="form.disposal === 'force'" label="强制原因">
            <el-input v-model="form.forceReason" type="textarea" />
          </el-form-item>
          <el-form-item label="操作人"><el-input v-model="form.operator" /></el-form-item>
          <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" /></el-form-item>
          <el-button type="primary" size="large" class="big-action" @click="submit">提交出站</el-button>
        </el-form>

        <el-form v-else :model="form" label-width="120px" class="checkout-form">
          <el-form-item label="检测通过率">
            <el-input-number v-model="form.passRate" :min="0" :max="100" :precision="1" :step="0.1" />
          </el-form-item>
          <el-form-item label="出站处理">
            <el-radio-group v-model="form.qualityAction" :disabled="inspectionPass">
              <el-radio-button label="normal">正常出站</el-radio-button>
              <el-radio-button label="force">强制出站</el-radio-button>
              <el-radio-button label="lock">批次锁定</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="!inspectionPass && form.qualityAction !== 'normal'" :label="form.qualityAction === 'lock' ? '锁定原因' : '强制原因'">
            <el-input v-model="form.forceReason" type="textarea" />
          </el-form-item>
          <el-form-item label="操作人"><el-input v-model="form.operator" /></el-form-item>
          <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" /></el-form-item>
          <el-button type="primary" size="large" class="big-action" @click="submit">提交出站</el-button>
        </el-form>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.full {
  width: 100%;
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

@media (max-width: 720px) {
  .checkout-form {
    grid-template-columns: 1fr;
  }
}
</style>
