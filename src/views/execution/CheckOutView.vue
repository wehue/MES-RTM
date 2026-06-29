<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  DISPOSAL_TYPE_CODE,
  batches,
  batchExecutionState,
  getBatchDefectQuantity,
  getBatchScrapQuantity,
  getCurrentOperationName,
  getInspectionThreshold,
  isInspectionProcess,
  getUserDisplayName,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { getStationOutList, getStationOutDetail, createStationOut } from '@/api/batch'
import { getOperators } from '@/api/user'

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

async function loadStationOutList() {
  listLoading.value = true
  try {
    const data = await getStationOutList()
    stationOutList.value = Array.isArray(data) ? data : []
    listPagination.total = stationOutList.value.length
    if (!form.LotCode && stationOutList.value.length) {
      form.LotCode = stationOutList.value[0].lotCode
    }
  } catch (error) {
    console.error('Failed to load station-out list:', error)
    stationOutList.value = []
    listPagination.total = 0
  } finally {
    listLoading.value = false
  }
}

async function loadStationOutDetail(lotCode) {
  if (!lotCode) {
    stationOutDetail.value = null
    return
  }
  detailLoading.value = true
  try {
    const data = await getStationOutDetail(lotCode)
    stationOutDetail.value = data
  } catch (error) {
    console.error('Failed to load station-out detail:', error)
    stationOutDetail.value = null
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
}

function handleSizeChange(pageSize) {
  listPagination.pageSize = pageSize
  listPagination.pageNum = 1
}

const pagedStationOutList = computed(() => {
  const start = (listPagination.pageNum - 1) * listPagination.pageSize
  const end = start + listPagination.pageSize
  return stationOutList.value.slice(start, end)
})

const availableBatches = computed(() => pagedStationOutList.value)

const currentBatch = computed(() => {
  return stationOutList.value.find(item => item.lotCode === form.LotCode) || null
})

const mockBatch = computed(() => batches.find(item => item.LotCode === form.LotCode) || null)

const canForce = computed(() => userStore.hasAnyRole(['production_manager']))
const isLocked = computed(() => stationOutDetail.value?.lotStatus === BATCH_STATUS_CODE.locked)
const currentInQty = computed(() => {
  if (stationOutDetail.value?.stationInQuantity) {
    return stationOutDetail.value.stationInQuantity
  }
  if (mockBatch.value) {
    return batchExecutionState[mockBatch.value.LotCode]?.CurrentInQuantity || 
           mockBatch.value.CompletedQuantity + getBatchDefectQuantity(mockBatch.value) + getBatchScrapQuantity(mockBatch.value)
  }
  return 0
})
const currentOperationName = computed(() => stationOutDetail.value?.currentOperation || (mockBatch.value ? getCurrentOperationName(mockBatch.value) : '-'))
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

  const lotId = currentBatch.value?.lotId || stationOutDetail.value?.lotId || (mockBatch.value?.Id || 0)

  const submitData = {
    lotId: Number(lotId),
    routeStepId: currentBatch.value?.routeStepId || stationOutDetail.value?.routeStepId || null,
    operatorId: Number(form.OperatorId),
  }

  if (isInspection.value) {
    submitData.passRate = form.PassRate
    if (inspectionPass.value) {
      submitData.stationOutHandle = 0
    } else if (form.QualityAction === 'force') {
      submitData.stationOutHandle = 1
      submitData.disposalRemark = form.ForceReason
    } else if (form.QualityAction === 'lock') {
      submitData.stationOutHandle = 2
      submitData.disposalRemark = form.ForceReason
    }
  } else {
    submitData.finishedQuantity = form.FinishedQuantity
    submitData.defectQuantity = form.DefectQuantity
    if (form.DefectQuantity > 0) {
      submitData.disposalType = form.DisposalType
      submitData.disposalRemark = form.DisposalRemark || form.ForceReason || ''
    }
  }

  submitting.value = true
  try {
    console.log('=== 出站提交数据 ===')
    console.log('stationOutHandle:', submitData.stationOutHandle)
    console.log('QualityAction:', form.QualityAction)
    console.log('isInspection:', isInspection.value)
    
    const result = await createStationOut(submitData)

        console.log('=== 出站响应数据 ===')
    console.log('result:', JSON.stringify(result, null, 2))
    console.log('result.lotStatus:', result.lotStatus, typeof result.lotStatus)
    console.log('BATCH_STATUS_CODE.locked:', BATCH_STATUS_CODE.locked)
    console.log('stationOutHandle === 2:', submitData.stationOutHandle === 2)
    console.log('result.lotStatus === locked:', result.lotStatus === BATCH_STATUS_CODE.locked)

    if (result.disposalType === DISPOSAL_TYPE_CODE.repair && form.DefectQuantity > 0) {
      ElMessage.success('出站完成，已生成维修任务，即将跳转到维修管理。')
      router.push('/execution/repair')
      return
    }

    if (submitData.stationOutHandle === 2 || result.lotStatus === BATCH_STATUS_CODE.locked || result.lotStatus === 'locked') {
      ElMessage.warning('通过率低于阈值，批次已锁定，即将跳转到批次管理。')
      router.push('/production/batch')
      return
    }

    if (result.lastStationOut) {
      ElMessage.success('出站完成，当前批次全部工序已结束。')
      router.push('/production/batch')
    } else {
      ElMessage.success(`出站完成，当前工序：${result.operationName || ''}，即将跳转到进站操作。`)
      router.push({
        path: '/execution/check-in',
        query: {
          LotCode: result.lotCode || form.LotCode,
        },
      })
    }
  } catch (error) {
    console.log('=== 出站响应失败 ===')
    console.log('error:', error)
    console.log('error.response:', error.response ? JSON.stringify(error.response.data, null, 2) : 'undefined')
    console.log('error.message:', error.message)
    if (submitData.stationOutHandle === 2 || form.QualityAction === 'lock') {
      // ElMessage.warning('批次已锁定，即将跳转到批次管理。')
      router.push('/production/batch')
      return
    }
    ElMessage.error(error.message || '出站失败')
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
        <p class="page-subtitle">按 smt_station_out_records 字段提交出站，普通工序确认数量，SPI / AOI 按通过率和阈值处理。</p>
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
          <el-table-column prop="workOrderCode" label="工单号" min-width="160" align="center"/>
          <el-table-column prop="productName" label="产品名称" min-width="150" align="center"/>
          <el-table-column prop="currentOperation" label="当前工序" min-width="160" align="center"/>
          <el-table-column prop="stationInQuantity" label="进站数量" width="180" align="center"/>
          <el-table-column label="状态" width="120" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.isNormal === false" type="danger">参数不正常</el-tag>
              <el-tag v-else-if="row.isNormal === true" type="success">正常</el-tag>
              <span v-else>-</span>
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
          <el-form-item label="选择批次">
            <el-select v-model="form.LotCode" filterable class="full">
              <el-option v-for="item in stationOutList" :key="item.lotCode" :label="item.lotCode" :value="item.lotCode" />
            </el-select>
          </el-form-item>
        </el-form>
        <el-alert v-if="isLocked" title="批次已锁定" type="error" show-icon :closable="false" />
        <el-descriptions :column="1" border style="margin-top: 10px" v-loading="detailLoading">
          <el-descriptions-item label="批次号">{{ currentBatch.lotCode }}</el-descriptions-item>
          <el-descriptions-item label="产品名称">{{ stationOutDetail?.productName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="当前工序">{{ currentOperationName }}</el-descriptions-item>
          <el-descriptions-item label="进站数量">{{ currentInQty }}</el-descriptions-item>
          <el-descriptions-item v-if="isInspection" label="检测阈值">{{ inspectionThreshold }}%</el-descriptions-item>
          <el-descriptions-item label="批次状态">
            <StatusTag v-if="stationOutDetail?.lotStatus" :meta="statusMeta(BATCH_STATUS, stationOutDetail.lotStatus)" />
            <span v-else>-</span>
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

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}
</style>
