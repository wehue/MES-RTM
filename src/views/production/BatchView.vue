<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  WORK_ORDER_STATUS_CODE,
  batchLockState,
  batches,
  getBatchDefectQuantity,
  getBatchLine,
  getBatchLockInfo,
  getBatchProduct,
  getBatchRouteProgress,
  getCurrentOperationName,
  findUser,
  getWorkOrderCompletedQuantity,
  getWorkOrderProduct,
  getWorkOrderReleasedBatchCount,
  getWorkOrderRoute,
  getUserDisplayName,
  getUserOptionLabel,
  lineOptions,
  lines,
  releaseBatchToFirstProcess,
  users,
  workOrders,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const filters = reactive({ keyword: '', WorkOrderCode: '', ProductName: '', Status: '', LineCode: '' })
const query = reactive({ keyword: '', WorkOrderCode: '', ProductName: '', Status: '', LineCode: '' })
const createDialogVisible = ref(false)
const createForm = reactive({
  WorkOrderId: '',
  BatchCount: 1,
  OwnerId: 3,
})
const batchLineSelections = ref([])

const canPlanBatch = computed(() => userStore.hasAnyRole(['production_manager']))
const canCoordinateBatch = computed(() => userStore.hasAnyRole(['production_manager', 'team_leader']))
const canQualityLock = computed(() => userStore.hasAnyRole(['quality_engineer', 'production_manager']))
const currentUserId = computed(() => findUser(userStore.userInfo.username || userStore.userInfo.name)?.Id || 3)
const batchStatusCodes = [1, 2, 3, 4, 5, 6]

function getCreatedQuantity(order) {
  return batches
    .filter((batch) => batch.WorkOrderId === order.Id)
    .reduce((sum, batch) => sum + (batch.PlannedQuantity || 0), 0)
}

const availableWorkOrders = computed(() => workOrders.filter((item) => {
  const remaining = Math.max((item.PlannedQuantity || 0) - getCreatedQuantity(item), 0)
  return remaining > 0 && [WORK_ORDER_STATUS_CODE.released, WORK_ORDER_STATUS_CODE.running].includes(item.Status)
}))
const selectedWorkOrder = computed(() => workOrders.find((item) => item.Id === Number(createForm.WorkOrderId)) || null)
const selectedRoute = computed(() => selectedWorkOrder.value ? getWorkOrderRoute(selectedWorkOrder.value) : null)
const remainingQty = computed(() => {
  if (!selectedWorkOrder.value) return 0
  return Math.max((selectedWorkOrder.value.PlannedQuantity || 0) - getCreatedQuantity(selectedWorkOrder.value), 0)
})
const selectedOrderCode = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.WorkOrderCode : '未选择')
const selectedOrderProduct = computed(() => {
  const product = selectedWorkOrder.value ? getWorkOrderProduct(selectedWorkOrder.value) : null
  return product ? `${product.ProductName} / ${product.Model}` : '请选择可创建批次的工单'
})
const selectedOrderPlanned = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.PlannedQuantity : '-')
const selectedRouteName = computed(() => selectedRoute.value ? selectedRoute.value.RouteName : '-')
const selectedFirstStep = computed(() => selectedRoute.value ? '投产后生成首道工序' : '待排产')
const generatedBatchRows = computed(() => {
  const count = Math.max(Number(createForm.BatchCount) || 1, 1)
  const total = remainingQty.value
  if (!selectedWorkOrder.value) return []
  const base = Math.floor(total / count)
  const rest = total % count
  return Array.from({ length: count }, (_, index) => ({
    Index: index + 1,
    PlannedQuantity: base + (index < rest ? 1 : 0),
    LineCode: batchLineSelections.value[index] || lineOptions[0],
  }))
})

watch(
  () => [createForm.WorkOrderId, createForm.BatchCount],
  () => {
    const count = Math.max(Number(createForm.BatchCount) || 1, 1)
    const defaultLine = lineOptions[0]
    batchLineSelections.value = Array.from({ length: count }, (_, index) => batchLineSelections.value[index] || defaultLine)
  },
)

const filteredBatches = computed(() => batches.filter((item) => {
  const order = workOrders.find((workOrder) => workOrder.Id === item.WorkOrderId)
  const product = getBatchProduct(item)
  const line = getBatchLine(item)
  const keyword = !query.keyword || item.LotCode.includes(query.keyword)
  const workOrder = !query.WorkOrderCode || order?.WorkOrderCode.includes(query.WorkOrderCode)
  const productMatched = !query.ProductName || product?.ProductName.includes(query.ProductName)
  const status = !query.Status || item.Status === Number(query.Status)
  const lineMatched = !query.LineCode || line?.LineCode === query.LineCode
  return keyword && workOrder && productMatched && status && lineMatched
}))

const statusCards = computed(() => batchStatusCodes.map((code) => ({
  key: code,
  ...BATCH_STATUS[code],
  count: batches.filter((item) => item.Status === code).length,
})))

function rowClass({ row }) {
  if ([BATCH_STATUS_CODE.locked, BATCH_STATUS_CODE.repair].includes(row.Status)) return 'danger-row'
  if ([BATCH_STATUS_CODE.paused, BATCH_STATUS_CODE.pending].includes(row.Status)) return 'warning-row'
  return ''
}

function handleSearch() {
  Object.assign(query, { ...filters })
  ElMessage.success('已按筛选条件查询批次')
}

function handleReset() {
  Object.assign(filters, { keyword: '', WorkOrderCode: '', ProductName: '', Status: '', LineCode: '' })
  Object.assign(query, { keyword: '', WorkOrderCode: '', ProductName: '', Status: '', LineCode: '' })
  ElMessage.info('筛选条件已重置')
}

function openCreateDialog() {
  const defaultOrder = availableWorkOrders.value[0] || null
  createForm.WorkOrderId = defaultOrder ? defaultOrder.Id : ''
  createForm.BatchCount = 1
  createForm.OwnerId = currentUserId.value
  batchLineSelections.value = [lineOptions[0]]
  createDialogVisible.value = true
}

function splitBatchNo(orderCode, index) {
  return 'B' + orderCode.slice(2) + '-' + String(index).padStart(2, '0')
}

function workOrderOptionLabel(order) {
  const product = getWorkOrderProduct(order)
  return `${order.WorkOrderCode} / ${product?.ProductName || '-'}`
}

function batchDetailPath(lotCode) {
  return '/production/batch/' + lotCode
}

function updateBatchStatus(row, status, reason = '-') {
  row.Status = status
  row.UpdatedAt = new Date().toISOString().slice(0, 16).replace('T', ' ')
  batchLockState[row.LotCode] = {
    ...(batchLockState[row.LotCode] || {}),
    LockReason: reason,
    AutoLocked: false,
    OwnerId: createForm.OwnerId || 3,
  }
}

function addBatchRow() {
  if (!selectedWorkOrder.value) {
    ElMessage.warning('请先选择可创建批次的工单')
    return
  }
  if (createForm.BatchCount >= remainingQty.value) {
    ElMessage.warning('批次数量不能超过可拆数量')
    return
  }
  createForm.BatchCount += 1
}

function removeBatchRow(index) {
  if (createForm.BatchCount <= 1) {
    ElMessage.warning('至少保留 1 个批次')
    return
  }
  batchLineSelections.value.splice(index - 1, 1)
  createForm.BatchCount -= 1
}

function submitCreateBatch() {
  if (!selectedWorkOrder.value) {
    ElMessage.warning('请先选择可创建批次的工单')
    return
  }
  if (!generatedBatchRows.value.length) {
    ElMessage.warning('批次数量不能为空')
    return
  }
  if (generatedBatchRows.value.some((item) => item.PlannedQuantity <= 0)) {
    ElMessage.warning('批次数量超出可分配数量，请减少批次数')
    return
  }
  if (generatedBatchRows.value.some((item) => !item.LineCode)) {
    ElMessage.warning('请为每个批次选择产线')
    return
  }

  const now = new Date().toISOString().slice(0, 16).replace('T', ' ')
  const newItems = generatedBatchRows.value.map((row, index) => {
    const line = lines.find((item) => item.LineCode === row.LineCode) || lines[0]
    const lotCode = splitBatchNo(selectedWorkOrder.value.WorkOrderCode, row.Index)
    batchLockState[lotCode] = { LockReason: '-', AutoLocked: false, OwnerId: createForm.OwnerId || 3 }
    return {
      Id: Date.now() + index,
      LotCode: lotCode,
      WorkOrderId: selectedWorkOrder.value.Id,
      LineId: line.Id,
      PlannedQuantity: row.PlannedQuantity,
      CompletedQuantity: 0,
      Status: BATCH_STATUS_CODE.pending,
      EstimatedCompletionTime: selectedWorkOrder.value.DueDate,
      StartTime: null,
      EndTime: null,
      CreatedAt: now,
      CreatedBy: 1,
      UpdatedAt: now,
      UpdatedBy: 1,
      IsDeleted: 0,
      LastOperationType: 'CREATE',
      LastOperationRemark: '前端原型新建批次',
    }
  })

  batches.push(...newItems)
  if (selectedWorkOrder.value.Status === WORK_ORDER_STATUS_CODE.released) {
    selectedWorkOrder.value.Status = WORK_ORDER_STATUS_CODE.running
    selectedWorkOrder.value.UpdatedAt = now
  }

  createDialogVisible.value = false
  ElMessage.success(`已为 ${selectedWorkOrder.value.WorkOrderCode} 创建 ${newItems.length} 个批次`)
}

async function operate(row, action) {
  if (action === '投产') {
    if (!canPlanBatch.value) {
      ElMessage.warning('当前角色无批次投产权限')
      return
    }
    if (row.Status !== BATCH_STATUS_CODE.pending) {
      ElMessage.warning('只有待生产批次可以执行投产')
      return
    }
    const result = releaseBatchToFirstProcess(row.LotCode)
    if (!result.ok) {
      ElMessage.error(result.message)
      return
    }
    ElMessage.success(`${row.LotCode} 已投产，首道工序已进入待进站`)
    return
  }
  if (['暂停', '恢复'].includes(action) && !canCoordinateBatch.value) {
    ElMessage.warning('当前角色无批次暂停 / 恢复权限')
    return
  }
  if (['锁定', '解锁'].includes(action) && !canQualityLock.value) {
    ElMessage.warning('当前角色无批次锁定 / 解锁权限')
    return
  }
  const lockInfo = getBatchLockInfo(row)
  if (action === '解锁' && lockInfo.AutoLocked && !userStore.hasAnyRole(['quality_engineer'])) {
    ElMessage.error('系统自动锁定批次需要质量工程师完成异常处置后解锁')
    return
  }
  const { value } = await ElMessageBox.prompt(`请输入${action}原因`, `${row.LotCode} ${action}`, { inputPlaceholder: '原因必填' })
  if (action === '锁定') updateBatchStatus(row, BATCH_STATUS_CODE.locked, value)
  if (action === '解锁') updateBatchStatus(row, BATCH_STATUS_CODE.running, value)
  if (action === '暂停') updateBatchStatus(row, BATCH_STATUS_CODE.paused, value)
  if (action === '恢复') updateBatchStatus(row, BATCH_STATUS_CODE.running, value)
  ElMessage.success(`${row.LotCode} 已${action}，原因：${value}`)
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">批次管理</h1>
        <p class="page-subtitle">批次主数据按 smt_lots 字段维护，产品、工单、产线和当前工序均通过关联查询展示。</p>
      </div>
      <div class="table-actions">
        <el-button type="primary" :disabled="!canPlanBatch" @click="openCreateDialog">新建批次</el-button>
        <el-button :disabled="!canCoordinateBatch" @click="ElMessage.success('同产线批次已批量暂停')">批量暂停</el-button>
        <el-button :disabled="!canCoordinateBatch" @click="ElMessage.success('同产线批次已批量恢复')">批量恢复</el-button>
      </div>
    </div>

    <div class="status-card-grid">
      <MetricCard v-for="card in statusCards" :key="card.key" :title="card.label" :value="card.count" unit="批" :tone="card.type" />
    </div>

    <div class="filter-bar">
      <el-form :inline="true" :model="filters">
        <el-form-item label="批次号"><el-input v-model="filters.keyword" clearable placeholder="输入批次号" /></el-form-item>
        <el-form-item label="工单号"><el-input v-model="filters.WorkOrderCode" clearable placeholder="输入工单号" /></el-form-item>
        <el-form-item label="产品名称">
          <el-input v-model="filters.ProductName" clearable placeholder="输入产品名称" style="width: 165px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.Status" clearable placeholder="全部状态" style="width: 130px">
            <el-option v-for="code in batchStatusCodes" :key="code" :label="BATCH_STATUS[code].label" :value="code" />
          </el-select>
        </el-form-item>
        <el-form-item label="产线">
          <el-select v-model="filters.LineCode" clearable placeholder="全部产线" style="width: 130px">
            <el-option v-for="line in lineOptions" :key="line" :label="line" :value="line" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <div class="filter-actions">
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
          </div>
        </el-form-item>
      </el-form>
    </div>

    <el-card shadow="never">
      <el-table :data="filteredBatches" border :row-class-name="rowClass">
        <el-table-column prop="LotCode" label="批次号" width="240">
          <template #default="{ row }"><el-link type="primary" @click="router.push(batchDetailPath(row.LotCode))">{{ row.LotCode }}</el-link></template>
        </el-table-column>
        <el-table-column label="所属工单" width="190">
          <template #default="{ row }">{{ workOrders.find((item) => item.Id === row.WorkOrderId)?.WorkOrderCode || '-' }}</template>
        </el-table-column>
        <el-table-column label="产品名称" width="190">
          <template #default="{ row }">{{ getBatchProduct(row)?.ProductName || '-' }}</template>
        </el-table-column>
        <el-table-column label="产品型号" width="190">
          <template #default="{ row }">{{ getBatchProduct(row)?.Model || '-' }}</template>
        </el-table-column>
        <el-table-column label="分配产线" width="150">
          <template #default="{ row }">{{ getBatchLine(row)?.LineCode || '-' }}</template>
        </el-table-column>
        <el-table-column prop="PlannedQuantity" label="计划数量" width="150" />
        <el-table-column prop="CompletedQuantity" label="已完工" width="130" />
        <el-table-column label="不良" width="110">
          <template #default="{ row }">{{ getBatchDefectQuantity(row) }}</template>
        </el-table-column>
        <el-table-column label="完成率" width="180">
          <template #default="{ row }"><el-progress :percentage="getBatchRouteProgress(row.LotCode)" /></template>
        </el-table-column>
        <el-table-column label="当前工序" width="150">
          <template #default="{ row }">{{ getCurrentOperationName(row) }}</template>
        </el-table-column>
        <el-table-column prop="EstimatedCompletionTime" label="预计完成时间" width="210" />
        <el-table-column prop="StartTime" label="上线时间" width="210" />
        <el-table-column label="状态" width="140">
          <template #default="{ row }"><StatusTag :meta="statusMeta(BATCH_STATUS, row.Status)" /></template>
        </el-table-column>
        <el-table-column label="锁定原因" width="220">
          <template #default="{ row }">{{ getBatchLockInfo(row).LockReason }}</template>
        </el-table-column>
        <el-table-column label="负责人" width="150">
          <template #default="{ row }">{{ getUserDisplayName(getBatchLockInfo(row).OwnerId) }}</template>
        </el-table-column>
        <el-table-column fixed="right" label="操作" width="360">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button link type="primary" @click="router.push(batchDetailPath(row.LotCode))">详情</el-button>
              <el-button link type="warning" :disabled="row.Status !== BATCH_STATUS_CODE.pending || !canPlanBatch" @click="operate(row, '投产')">投产</el-button>
              <el-button link type="danger" :disabled="row.Status === BATCH_STATUS_CODE.locked || !canQualityLock" @click="operate(row, '锁定')">锁定</el-button>
              <el-button link type="success" :disabled="row.Status !== BATCH_STATUS_CODE.locked || !canQualityLock" @click="operate(row, '解锁')">解锁</el-button>
              <el-button link type="warning" :disabled="!canCoordinateBatch" @click="operate(row, row.Status === BATCH_STATUS_CODE.paused ? '恢复' : '暂停')">
                <span v-if="row.Status === BATCH_STATUS_CODE.paused">恢复</span>
                <span v-else>暂停</span>
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="createDialogVisible" title="新建批次" width="1200px" class="batch-create-dialog" destroy-on-close>
      <el-empty v-if="!availableWorkOrders.length" description="当前没有可继续拆分批次的已释放工单" />
      <div v-else class="batch-create">
        <div class="batch-create__summary">
          <div>
            <span class="summary-label">当前工单</span>
            <strong>{{ selectedOrderCode }}</strong>
            <p>{{ selectedOrderProduct }}</p>
          </div>
          <div class="summary-metrics">
            <div>
              <span>计划数量</span>
              <strong>{{ selectedOrderPlanned }}</strong>
            </div>
          </div>
        </div>

        <div class="batch-create__body">
          <div class="create-panel">
            <div class="panel-title">创建设置</div>
            <el-form label-position="top">
              <el-form-item label="可拆分工单">
                <el-select v-model="createForm.WorkOrderId" filterable placeholder="请选择工单" class="full">
                  <el-option v-for="order in availableWorkOrders" :key="order.Id" :label="workOrderOptionLabel(order)" :value="order.Id" />
                </el-select>
              </el-form-item>
              <el-form-item label="批次数量">
                <div class="batch-count-control">
                  <el-input-number v-model="createForm.BatchCount" :min="1" :max="Math.max(remainingQty || 1, 1)" class="full-number" controls-position="right" />
                  <el-button type="primary" plain @click="addBatchRow">添加批次</el-button>
                </div>
              </el-form-item>
              <el-form-item label="负责人">
                <el-select v-model="createForm.OwnerId" filterable placeholder="请选择负责人" class="full">
                  <el-option v-for="user in users" :key="user.Id" :label="getUserOptionLabel(user)" :value="user.Id" />
                </el-select>
              </el-form-item>
            </el-form>
            <div class="route-info">
              <span>工艺路线</span>
              <strong>{{ selectedRouteName }}</strong>
              <small>首工序：{{ selectedFirstStep }}</small>
            </div>
          </div>

          <div class="preview-panel">
            <div class="panel-title">拆分预览</div>
            <el-table :data="generatedBatchRows" border size="small" max-height="380">
              <el-table-column type="index" label="#" width="56" />
              <el-table-column label="批次号" min-width="210">
                <template #default="{ row }">
                  <span v-if="selectedWorkOrder">{{ splitBatchNo(selectedWorkOrder.WorkOrderCode, row.Index) }}</span>
                  <span v-else>-</span>
                </template>
              </el-table-column>
              <el-table-column prop="PlannedQuantity" label="计划数量" width="110" />
              <el-table-column label="产线" width="170">
                <template #default="{ row }">
                  <el-select v-model="batchLineSelections[row.Index - 1]" placeholder="选择产线">
                    <el-option v-for="line in lineOptions" :key="line" :label="line" :value="line" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="120">待生产</el-table-column>
              <el-table-column label="操作" width="90">
                <template #default="{ row }">
                  <el-button link type="danger" @click="removeBatchRow(row.Index)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-actions">
          <el-button @click="createDialogVisible = false">取消</el-button>
          <el-button type="primary" :disabled="!selectedWorkOrder || !availableWorkOrders.length || !canPlanBatch" @click="submitCreateBatch">确认创建</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.batch-create {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.full {
  width: 100%;
}

.full-number {
  width: 100%;
}

.batch-create__summary,
.create-panel,
.preview-panel {
  border: 1px solid #dbe4f0;
  border-radius: 8px;
  background: #fff;
}

.batch-create__summary {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 24px;
  align-items: center;
  padding: 18px 22px;
  background: linear-gradient(180deg, #f8fbff 0%, #fff 100%);
}

.batch-create__summary strong {
  display: block;
  margin-top: 4px;
  color: #111827;
  font-size: 20px;
}

.batch-create__summary p,
.summary-label,
.summary-metrics span,
.route-info span,
.route-info small {
  color: #64748b;
}

.batch-create__summary p {
  margin: 6px 0 0;
}

.summary-metrics {
  display: grid;
  grid-template-columns: 132px;
  gap: 10px;
}

.summary-metrics > div {
  padding: 10px 12px;
  border-radius: 6px;
  background: #f1f5f9;
}

.summary-metrics strong {
  font-size: 18px;
}

.batch-create__body {
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  gap: 14px;
}

.create-panel,
.preview-panel {
  padding: 18px;
}

.panel-title {
  margin-bottom: 16px;
  color: #111827;
  font-size: 16px;
  font-weight: 700;
}

.batch-count-control {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 104px;
  gap: 10px;
  width: 100%;
}

.route-info {
  display: grid;
  gap: 4px;
  margin-top: 6px;
  padding: 12px;
  border-radius: 6px;
  background: #f8fafc;
}

.route-info strong {
  color: #1f2937;
}

.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

@media (max-width: 960px) {
  .batch-create__summary,
  .batch-create {
    display: flex;
    flex-direction: column;
  }

  .batch-create__body {
    grid-template-columns: 1fr;
  }

  .summary-metrics {
    grid-template-columns: minmax(0, 160px);
  }
}
</style>
