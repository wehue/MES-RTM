<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import { BATCH_STATUS_CODE, batches, getBatchRouteProgress, lineOptions, processRoutes, products, releaseBatchToFirstProcess, workOrders } from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const filters = reactive({ keyword: '', workOrderId: '', productModel: '', status: '', line: '' })
const query = reactive({ keyword: '', workOrderId: '', productModel: '', status: '', line: '' })
const createDialogVisible = ref(false)
const createForm = reactive({
  workOrderId: '',
  batchCount: 1,
  owner: '张工',
})
const batchLineSelections = ref([])

const canOperateBatch = computed(() => userStore.hasAnyRole(['production_manager', 'team_leader', 'quality_engineer']))
const batchWorkOrderIds = computed(() => new Set(batches.map((item) => item.workOrderId)))
const availableWorkOrders = computed(() => workOrders.filter((item) => {
  const hasBatchRecord = batchWorkOrderIds.value.has(item.id) || item.releasedBatches > 0
  const remaining = Math.max((item.planned || 0) - (item.completed || 0), 0)
  return !hasBatchRecord && remaining > 0 && !['completed', 'closed'].includes(item.status)
}))
const selectedWorkOrder = computed(() => workOrders.find((item) => item.id === createForm.workOrderId) || null)
const selectedRoute = computed(() => processRoutes.find((item) => item.id === (selectedWorkOrder.value && selectedWorkOrder.value.routeId)) || null)
const remainingQty = computed(() => {
  if (!selectedWorkOrder.value) return 0
  return Math.max((selectedWorkOrder.value.planned || 0) - (selectedWorkOrder.value.completed || 0), 0)
})
const selectedOrderId = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.id : '未选择')
const selectedOrderProduct = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.productModel + ' / ' + selectedWorkOrder.value.productName : '请选择未创建批次的工单')
const selectedOrderPlanned = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.planned : '-')
const selectedRouteName = computed(() => selectedRoute.value ? selectedRoute.value.name : '-')
const selectedFirstStep = computed(() => selectedRoute.value && selectedRoute.value.steps.length ? selectedRoute.value.steps[0].step : '待排产')
const generatedBatchRows = computed(() => {
  const count = Math.max(Number(createForm.batchCount) || 1, 1)
  const total = remainingQty.value
  if (!selectedWorkOrder.value) return []
  const base = Math.floor(total / count)
  const rest = total % count
  return Array.from({ length: count }, (_, index) => ({
    index: index + 1,
    planned: base + (index < rest ? 1 : 0),
    line: batchLineSelections.value[index] || selectedWorkOrder.value.line,
  }))
})

watch(
  () => [createForm.workOrderId, createForm.batchCount],
  () => {
    const count = Math.max(Number(createForm.batchCount) || 1, 1)
    const defaultLine = selectedWorkOrder.value ? selectedWorkOrder.value.line : lineOptions[0]
    batchLineSelections.value = Array.from({ length: count }, (_, index) => batchLineSelections.value[index] || defaultLine)
  },
)

const filteredBatches = computed(() => batches.filter((item) => {
  const keyword = !query.keyword || item.id.includes(query.keyword)
  const wo = !query.workOrderId || item.workOrderId.includes(query.workOrderId)
  const model = !query.productModel || item.productModel === query.productModel
  const status = !query.status || item.status === query.status
  const line = !query.line || item.line === query.line
  return keyword && wo && model && status && line
}))

const statusCardKeys = ['pending', 'running', 'paused', 'repair', 'locked', 'completed']

const statusCards = computed(() => statusCardKeys.map((key) => ({
  key,
  ...BATCH_STATUS[key],
  count: batches.filter((item) => item.status === key).length,
})))

function rowClass({ row }) {
  if (row.status === 'locked' || row.status === 'repair') return 'danger-row'
  if (row.status === 'paused' || row.status === 'pending') return 'warning-row'
  return ''
}

function handleSearch() {
  Object.assign(query, { ...filters })
  ElMessage.success('已按筛选条件查询批次')
}

function handleReset() {
  Object.assign(filters, { keyword: '', workOrderId: '', productModel: '', status: '', line: '' })
  Object.assign(query, { keyword: '', workOrderId: '', productModel: '', status: '', line: '' })
  ElMessage.info('筛选条件已重置')
}

function openCreateDialog() {
  const defaultOrder = availableWorkOrders.value[0] || null
  createForm.workOrderId = defaultOrder ? defaultOrder.id : ''
  createForm.batchCount = 1
  createForm.owner = defaultOrder ? '张工' : ''
  batchLineSelections.value = [defaultOrder ? defaultOrder.line : lineOptions[0]]
  createDialogVisible.value = true
}

function splitBatchNo(orderId, index) {
  return 'B' + orderId.slice(2) + '-' + String(index).padStart(2, '0')
}

function workOrderOptionLabel(order) {
  return order.id + ' / ' + order.productModel
}

function batchDetailPath(id) {
  return '/production/batch/' + id
}

function updateBatchStatus(row, status, reason = '-') {
  row.status = status
  row.Status = BATCH_STATUS_CODE[status] || status
  row.lockReason = reason
  row.autoLocked = false
}

function addBatchRow() {
  if (!selectedWorkOrder.value) {
    ElMessage.warning('请先选择未创建批次的工单')
    return
  }
  if (createForm.batchCount >= remainingQty.value) {
    ElMessage.warning('批次数量不能超过可拆数量')
    return
  }
  createForm.batchCount += 1
}

function removeBatchRow(index) {
  if (createForm.batchCount <= 1) {
    ElMessage.warning('至少保留 1 个批次')
    return
  }
  batchLineSelections.value.splice(index - 1, 1)
  createForm.batchCount -= 1
}

function submitCreateBatch() {
  if (!selectedWorkOrder.value) {
    ElMessage.warning('请先选择未创建批次的工单')
    return
  }
  if (!generatedBatchRows.value.length) {
    ElMessage.warning('批次数量不能为空')
    return
  }
  if (generatedBatchRows.value.some((item) => item.planned <= 0)) {
    ElMessage.warning('批次数量超出可分配数量，请减少批次数')
    return
  }
  if (generatedBatchRows.value.some((item) => !item.line)) {
    ElMessage.warning('请为每个批次选择产线')
    return
  }

  const route = selectedRoute.value
  const now = new Date().toISOString().slice(0, 16).replace('T', ' ')
  const newItems = generatedBatchRows.value.map((row) => ({
    id: splitBatchNo(selectedWorkOrder.value.id, row.index),
    workOrderId: selectedWorkOrder.value.id,
    productModel: selectedWorkOrder.value.productModel,
    productName: selectedWorkOrder.value.productName,
    line: row.line,
    planned: row.planned,
    completed: 0,
    defective: 0,
    scrap: 0,
    currentStep: '-',
    eta: selectedWorkOrder.value.dueDate ? selectedWorkOrder.value.dueDate + ' 23:59' : '-',
    onlineAt: '-',
    status: 'pending',
    lockReason: '-',
    owner: createForm.owner || '张工',
    autoLocked: false,
  }))

  newItems.forEach((item, index) => {
    item.Id = Date.now() + index
    item.LotCode = item.id
    item.WorkOrderId = selectedWorkOrder.value.Id
    item.LineId = 1
    item.PlannedQuantity = item.planned
    item.CompletedQuantity = item.completed
    item.Status = BATCH_STATUS_CODE.pending
    item.EstimatedCompletionTime = item.eta
    item.StartTime = null
    item.EndTime = null
  })

  batches.push(...newItems)
  const order = workOrders.find((item) => item.id === selectedWorkOrder.value.id)
  if (order) {
    order.releasedBatches += newItems.length
    if (order.status === 'pending') order.status = 'running'
    if (order.releasedAt === '-') order.releasedAt = now
  }

  createDialogVisible.value = false
  ElMessage.success('已为 ' + selectedWorkOrder.value.id + ' 创建 ' + newItems.length + ' 个批次')
}

async function operate(row, action) {
  if (!canOperateBatch.value) {
    ElMessage.warning('当前角色仅可查看批次，操作已拦截')
    return
  }
  if (action === '投产') {
    if (row.status !== 'pending') {
      ElMessage.warning('只有待生产批次可以执行投产')
      return
    }
    const result = releaseBatchToFirstProcess(row.id)
    if (!result.ok) {
      ElMessage.error(result.message)
      return
    }
    ElMessage.success(row.id + ' 已投产，首道工序已进入待进站')
    return
  }
  if (action === '解锁' && row.autoLocked && !userStore.hasAnyRole(['quality_engineer'])) {
    ElMessage.error('系统自动锁定批次需质量工程师完成异常处置后解锁')
    return
  }
  const { value } = await ElMessageBox.prompt('请输入' + action + '原因', row.id + ' ' + action, { inputPlaceholder: '原因必填' })
  if (action === '锁定') {
    updateBatchStatus(row, 'locked', value)
    row.lockReason = value
    row.autoLocked = false
  }
  if (action === '解锁') {
    updateBatchStatus(row, 'running')
  }
  if (action === '暂停') {
    updateBatchStatus(row, 'paused', row.lockReason)
  }
  if (action === '恢复') {
    updateBatchStatus(row, 'running', row.lockReason)
  }
  ElMessage.success(row.id + ' 已' + action + '，原因：' + value)
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">批次管理</h1>
        <p class="page-subtitle">支持批次投产、锁定 / 解锁、暂停 / 恢复、批量操作与详情下钻；只有已投产批次才可进入上料与进站生产。</p>
      </div>
      <div class="table-actions">
        <el-button type="primary" :disabled="!canOperateBatch" @click="openCreateDialog">新建批次</el-button>
        <el-button :disabled="!canOperateBatch" @click="ElMessage.success('同产线批次已批量暂停')">批量暂停</el-button>
        <el-button :disabled="!canOperateBatch" @click="ElMessage.success('同产线批次已批量恢复')">批量恢复</el-button>
      </div>
    </div>

    <div class="status-card-grid">
      <MetricCard v-for="card in statusCards" :key="card.key" :title="card.label" :value="card.count" unit="批" :tone="card.type" />
    </div>

    <div class="filter-bar">
      <el-form :inline="true" :model="filters">
        <el-form-item label="批次号"><el-input v-model="filters.keyword" clearable placeholder="输入批次号" /></el-form-item>
        <el-form-item label="工单号"><el-input v-model="filters.workOrderId" clearable placeholder="输入工单号" /></el-form-item>
        <el-form-item label="产品型号">
          <el-select v-model="filters.productModel" clearable placeholder="全部型号" style="width: 165px">
            <el-option v-for="product in products" :key="product.model" :label="product.model" :value="product.model" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width: 130px">
            <el-option v-for="(meta, key) in BATCH_STATUS" :key="key" :label="meta.label" :value="key" />
          </el-select>
        </el-form-item>
        <el-form-item label="产线">
          <el-select v-model="filters.line" clearable placeholder="全部产线" style="width: 130px">
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
        <el-table-column prop="id" label="批次号" width="240">
          <template #default="{ row }"><el-link type="primary" @click="router.push(batchDetailPath(row.id))">{{ row.id }}</el-link></template>
        </el-table-column>
        <el-table-column prop="workOrderId" label="所属工单" width="230" />
        <el-table-column prop="productModel" label="产品型号" width="190" />
        <el-table-column prop="line" label="分配产线" width="150" />
        <el-table-column prop="planned" label="计划数量" width="150" />
        <el-table-column prop="completed" label="已完工" width="130" />
        <el-table-column prop="defective" label="不良" width="110" />
        <el-table-column label="完成率" width="180">
          <template #default="{ row }"><el-progress :percentage="getBatchRouteProgress(row.id)" /></template>
        </el-table-column>
        <el-table-column prop="currentStep" label="当前工序" width="150" />
        <el-table-column prop="eta" label="预计完成时间" width="230" />
        <el-table-column prop="onlineAt" label="上线时间" width="230" />
        <el-table-column label="状态" width="140">
          <template #default="{ row }"><StatusTag :meta="statusMeta(BATCH_STATUS, row.status)" /></template>
        </el-table-column>
        <el-table-column prop="lockReason" label="锁定原因" width="220" />
        <el-table-column prop="owner" label="负责人" width="130" />
        <el-table-column fixed="right" label="操作" width="360">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button link type="primary" @click="router.push(batchDetailPath(row.id))">详情</el-button>
              <el-button link type="warning" :disabled="row.status !== 'pending'" @click="operate(row, '投产')">投产</el-button>
              <el-button link type="danger" :disabled="row.status === 'locked'" @click="operate(row, '锁定')">锁定</el-button>
              <el-button link type="success" :disabled="row.status !== 'locked'" @click="operate(row, '解锁')">解锁</el-button>
              <el-button link type="warning" @click="operate(row, row.status === 'paused' ? '恢复' : '暂停')">
                <span v-if="row.status === 'paused'">恢复</span>
                <span v-else>暂停</span>
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="createDialogVisible" title="新建批次" width="1200px" class="batch-create-dialog" destroy-on-close>
      <el-empty v-if="!availableWorkOrders.length" description="当前所有工单均已创建批次，暂无可创建批次的工单" />
      <div v-else class="batch-create">
        <div class="batch-create__summary">
          <div>
            <span class="summary-label">当前工单</span>
            <strong>{{ selectedOrderId }}</strong>
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
              <el-form-item label="未创建批次工单">
                <el-select v-model="createForm.workOrderId" filterable placeholder="请选择工单" class="full">
                  <el-option v-for="order in availableWorkOrders" :key="order.id" :label="workOrderOptionLabel(order)" :value="order.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="批次数量">
                <div class="batch-count-control">
                  <el-input-number v-model="createForm.batchCount" :min="1" :max="Math.max(remainingQty || 1, 1)" class="full-number" controls-position="right" />
                  <el-button type="primary" plain @click="addBatchRow">添加批次</el-button>
                </div>
              </el-form-item>
              <el-form-item label="负责人">
                <el-input v-model="createForm.owner" placeholder="请输入批次负责人" />
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
                  <span v-if="selectedWorkOrder">{{ splitBatchNo(selectedWorkOrder.id, row.index) }}</span>
                  <span v-else>-</span>
                </template>
              </el-table-column>
              <el-table-column prop="planned" label="计划数量" width="110" />
              <el-table-column label="产线" width="170">
                <template #default="{ row }">
                  <el-select v-model="batchLineSelections[row.index - 1]" placeholder="选择产线">
                    <el-option v-for="line in lineOptions" :key="line" :label="line" :value="line" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="120">待生产</el-table-column>
              <el-table-column label="操作" width="90">
                <template #default="{ row }">
                  <el-button link type="danger" @click="removeBatchRow(row.index)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-actions">
          <el-button @click="createDialogVisible = false">取消</el-button>
          <el-button type="primary" :disabled="!selectedWorkOrder || !availableWorkOrders.length" @click="submitCreateBatch">确认创建</el-button>
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
