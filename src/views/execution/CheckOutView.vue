<script setup>
import { computed, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  DISPOSAL_TYPE_CODE,
  PROCESS_STATUS_CODE,
  batches,
  batchExecutionState,
  findUser,
  getBatchDefectQuantity,
  getBatchProduct,
  getBatchScrapQuantity,
  getBatchWorkOrder,
  getCurrentOperationName,
  getCurrentProcessStatus,
  getInspectionThreshold,
  getUserOptionLabel,
  isInspectionProcess,
  submitBatchCheckOut,
  users,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

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
  OperatorId: findUser(userStore.userInfo.username || userStore.userInfo.name)?.Id || 3,
  DisposalRemark: '',
})

const availableBatches = computed(() => batches.filter((item) => getCurrentProcessStatus(item.LotCode) === PROCESS_STATUS_CODE.checked_in))
const batch = computed(() => availableBatches.value.find((item) => item.LotCode === form.LotCode) || availableBatches.value[0] || null)
const canForce = computed(() => userStore.hasAnyRole(['production_manager']))
const isLocked = computed(() => batch.value?.Status === BATCH_STATUS_CODE.locked)
const currentInQty = computed(() => batch.value ? (batchExecutionState[batch.value.LotCode]?.CurrentInQuantity || batch.value.CompletedQuantity + getBatchDefectQuantity(batch.value) + getBatchScrapQuantity(batch.value)) : 0)
const currentOperationName = computed(() => batch.value ? getCurrentOperationName(batch.value) : '-')
const isInspection = computed(() => batch.value ? isInspectionProcess(currentOperationName.value) : false)
const inspectionThreshold = computed(() => batch.value ? getInspectionThreshold(currentOperationName.value) : 0)
const inspectionPass = computed(() => form.PassRate >= inspectionThreshold.value)
const checkoutTotal = computed(() => form.FinishedQuantity + form.DefectQuantity)
const quantityValid = computed(() => checkoutTotal.value === currentInQty.value)

watch(batch, (current) => {
  if (!current) {
    Object.assign(form, {
      LotCode: '',
      FinishedQuantity: 0,
      DefectQuantity: 0,
      PassRate: 100,
      QualityAction: 'normal',
      ForceReason: '',
    })
    return
  }
  form.LotCode = current.LotCode
  form.FinishedQuantity = currentInQty.value
  form.DefectQuantity = 0
  form.PassRate = 100
  form.QualityAction = 'normal'
  form.DisposalType = DISPOSAL_TYPE_CODE.repair
  form.ForceReason = ''
}, { immediate: true })

watch(inspectionPass, (pass) => {
  if (pass) form.QualityAction = 'normal'
})

function selectBatch(row) {
  if (!row?.LotCode) return
  form.LotCode = row.LotCode
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

function submit() {
  if (!batch.value) {
    ElMessage.error('当前没有可出站批次')
    return
  }
  if (isLocked.value) {
    ElMessage.error('批次已锁定')
    return
  }
  if (!isInspection.value && !quantityValid.value) {
    ElMessage.error(`数量不匹配：进站数量 ${currentInQty.value}，出站合计 ${checkoutTotal.value}`)
    return
  }
  if (!isInspection.value && form.DefectQuantity > 0 && form.DisposalType === DISPOSAL_TYPE_CODE.force && !canForce.value) {
    ElMessage.error('当前角色没有强制出站权限')
    return
  }
  if (!isInspection.value && form.DefectQuantity > 0 && form.DisposalType === DISPOSAL_TYPE_CODE.force && !form.ForceReason.trim()) {
    ElMessage.error('请填写强制出站原因')
    return
  }
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

  const result = submitBatchCheckOut(form.LotCode, {
    FinishedQuantity: form.FinishedQuantity,
    DefectQuantity: form.DefectQuantity,
    SpiPassRate: currentOperationName.value.includes('SPI') ? form.PassRate : null,
    AoiPassRate: currentOperationName.value.includes('AOI') ? form.PassRate : null,
    qualityAction: form.QualityAction,
    DisposalType: form.DisposalType,
    OperatorId: Number(form.OperatorId),
    DisposalRemark: form.DisposalRemark || form.ForceReason,
    StationOutTime: '2026-05-20 15:00',
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
        LotCode: result.batch.LotCode,
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
        <p class="page-subtitle">按 smt_station_out_records 字段提交出站，普通工序确认数量，SPI / AOI 按通过率和阈值处理。</p>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="可出站批次列表">
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
          <el-table-column label="当前工序" min-width="120">
            <template #default="{ row }">{{ getCurrentOperationName(row) }}</template>
          </el-table-column>
          <el-table-column label="进站数量" width="100">
            <template #default="{ row }">{{ batchExecutionState[row.LotCode]?.CurrentInQuantity || row.CompletedQuantity + getBatchDefectQuantity(row) + getBatchScrapQuantity(row) }}</template>
          </el-table-column>
          <el-table-column prop="CompletedQuantity" label="良品" width="90" />
          <el-table-column label="不良" width="90">
            <template #default="{ row }">{{ getBatchDefectQuantity(row) }}</template>
          </el-table-column>
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <StatusTag :meta="statusMeta(BATCH_STATUS, row.Status)" />
            </template>
          </el-table-column>
        </el-table>
      </SectionCard>

      <SectionCard v-if="batch" class="span-12" title="批次与出站信息">
        <el-form label-position="top">
          <el-form-item label="选择批次">
            <el-select v-model="form.LotCode" filterable class="full">
              <el-option v-for="item in availableBatches" :key="item.LotCode" :label="item.LotCode" :value="item.LotCode" />
            </el-select>
          </el-form-item>
        </el-form>
        <el-alert v-if="isLocked" title="批次已锁定" type="error" show-icon :closable="false" />
        <el-descriptions :column="1" border style="margin-top: 10px">
          <el-descriptions-item label="批次号">{{ batch.LotCode }}</el-descriptions-item>
          <el-descriptions-item label="产品型号">{{ getBatchProduct(batch)?.Model }}</el-descriptions-item>
          <el-descriptions-item label="当前工序">{{ currentOperationName }}</el-descriptions-item>
          <el-descriptions-item label="进站数量">{{ currentInQty }}</el-descriptions-item>
          <el-descriptions-item v-if="isInspection" label="检测阈值">{{ inspectionThreshold }}%</el-descriptions-item>
          <el-descriptions-item label="批次状态">
            <StatusTag :meta="statusMeta(BATCH_STATUS, batch.Status)" />
          </el-descriptions-item>
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
              <el-option v-for="user in users" :key="user.Id" :label="getUserOptionLabel(user)" :value="user.Id" />
            </el-select>
          </el-form-item>
          <el-form-item label="处置备注"><el-input v-model="form.DisposalRemark" type="textarea" /></el-form-item>
          <el-button type="primary" size="large" class="big-action" @click="submit">提交出站</el-button>
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
              <el-option v-for="user in users" :key="user.Id" :label="getUserOptionLabel(user)" :value="user.Id" />
            </el-select>
          </el-form-item>
          <el-form-item label="处置备注"><el-input v-model="form.DisposalRemark" type="textarea" /></el-form-item>
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
