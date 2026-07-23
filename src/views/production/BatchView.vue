<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox, ElLoading } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  findUser,
  getWorkOrderRoute,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { getBatchList, getBatchStatusStats, updateBatchStatus, createBatch } from '@/api/batch'
import { getLineList } from '@/api/line'
import { getReleasedWorkOrders, getReleasedWorkOrderDetail } from '@/api/workOrder'

const router = useRouter()
const userStore = useUserStore()
const filters = reactive({ keyword: '', WorkOrderCode: '', ProductName: '', Status: '', LineCode: '' })
const createDialogVisible = ref(false)
const createForm = reactive({
  WorkOrderId: '',
  BatchCount: 1,
  OwnerId: 3,
})
const batchLineSelections = ref([])
const batchQuantities = ref([])
const statusStats = ref({
  pendingCount: 0,
  inProductionCount: 0,
  pausedCount: 0,
  lockedCount: 0,
  repairingCount: 0,
  completedCount: 0,
  totalCount: 0,
})
const lineList = ref([])
const batchRows = ref([])
const listLoading = ref(false)
const pagination = reactive({ pageNum: 1, pageSize: 5, total: 0 })
const workOrderDetail = ref({})

const canPlanBatch = computed(() => userStore.hasAnyRole(['PRODUCTION_SUPERVISOR']))
const canCoordinateBatch = computed(() => userStore.hasAnyRole(['PRODUCTION_SUPERVISOR', 'LEADER']))
const canQualityLock = computed(() => userStore.hasAnyRole(['QUALITY_ENGINEER', 'PRODUCTION_SUPERVISOR']))
const currentUserId = computed(() => findUser(userStore.userInfo.username || userStore.userInfo.name)?.Id || 3)
const batchStatusCodes = Object.keys(BATCH_STATUS).map(Number)

async function loadStatusStats() {
  try {
    const data = await getBatchStatusStats()
    statusStats.value = data || {
      pendingCount: 0,
      inProductionCount: 0,
      pausedCount: 0,
      lockedCount: 0,
      repairingCount: 0,
      completedCount: 0,
      totalCount: 0,
    }
  } catch (error) {
    console.error('Failed to load status stats:', error)
  }
}

async function loadLines() {
  try {
    const data = await getLineList()
    lineList.value = data || []
  } catch (error) {
    console.error('Failed to load lines:', error)
  }
}

const releasedWorkOrders = ref([])

async function loadWorkOrders() {
  try {
    const data = await getReleasedWorkOrders()
    releasedWorkOrders.value = data.map(item => ({
      ...item,
      Id: item.id,
      WorkOrderCode: item.workOrderCode,
      ProductName: item.productName,
      PlannedQuantity: item.plannedQuantity || 0,
    })) || []
  } catch (error) {
    console.error('Failed to load released work orders:', error)
    releasedWorkOrders.value = []
  }
}

async function loadWorkOrderDetail(workOrderId) {
  if (!workOrderId) {
    workOrderDetail.value = {}
    return
  }
  try {
    const data = await getReleasedWorkOrderDetail(workOrderId)
    workOrderDetail.value = data
  } catch (error) {
    console.error('Failed to load work order detail:', error)
    workOrderDetail.value = {}
  }
}

function formatDateTime(value) {
  if (!value) return '-'
  const normalized = typeof value === 'string' ? value.replace('T', ' ') : value
  const date = new Date(normalized)
  if (Number.isNaN(date.getTime())) {
    return String(value).replace('T', ' ').slice(0, 16)
  }
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}`
}

function normalizeBatch(batch) {
  return {
    ...batch,
    Id: batch.id,
    LotCode: batch.lotCode,
    WorkOrderCode: batch.workOrderCode,
    ProductName: batch.productName,
    ProductTypeName: batch.productTypeName,
    LineName: batch.lineName,
    PlannedQuantity: batch.plannedQuantity,
    FinishedQuantity: batch.finishedQuantity,
    DefectQuantity: batch.defectQuantity,
    CurrentOperationName: batch.currentOperationName,
    CurrentStationName: batch.currentStationName || batch.stationName || '',
    EstimatedCompletionTime: formatDateTime(batch.estimatedCompletionTime),
    StartTime: formatDateTime(batch.startTime),
    EndTime: formatDateTime(batch.endTime),
    Status: batch.status,
  }
}

async function loadBatches() {
  listLoading.value = true
  try {
    const result = await getBatchList({
      lotCode: filters.keyword || undefined,
      workOrderCode: filters.WorkOrderCode || undefined,
      productName: filters.ProductName || undefined,
      status: filters.Status || undefined,
      lineName: filters.LineCode || undefined,
      pageNum: pagination.pageNum,
      pageSize: pagination.pageSize,
    })
    batchRows.value = result.list.map(normalizeBatch)
    pagination.total = result.total || 0
  } catch (error) {
    console.error('Failed to load batches:', error)
    batchRows.value = []
    pagination.total = 0
  } finally {
    listLoading.value = false
  }
}

onMounted(() => {
  loadStatusStats()
  loadLines()
  loadBatches()
  loadWorkOrders()
})

function getCreatedQuantity(order) {
  return batchRows.value
    .filter((batch) => batch.WorkOrderId === order.Id)
    .reduce((sum, batch) => sum + (batch.PlannedQuantity || 0), 0)
}

const availableWorkOrders = computed(() => releasedWorkOrders.value)
const batchLineOptions = computed(() => lineList.value.map(item => item.lineName || item.LineName).filter(Boolean))
const selectedWorkOrder = computed(() => releasedWorkOrders.value.find((item) => item.Id === Number(createForm.WorkOrderId)) || null)
const selectedRoute = computed(() => selectedWorkOrder.value ? getWorkOrderRoute(selectedWorkOrder.value) : null)
const remainingQty = computed(() => {
  if (!workOrderDetail.value.plannedQuantity) return 0
  return Math.max(workOrderDetail.value.plannedQuantity - getCreatedQuantity(selectedWorkOrder.value), 0)
})
const selectedOrderCode = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.WorkOrderCode : '未选择')
const selectedOrderProduct = computed(() => {
  return selectedWorkOrder.value?.ProductName || '请选择可创建批次的工单'
})
const selectedOrderPlanned = computed(() => selectedWorkOrder.value ? selectedWorkOrder.value.PlannedQuantity : '-')
const selectedRouteName = computed(() => selectedRoute.value ? selectedRoute.value.RouteName : '-')
const selectedFirstStep = computed(() => selectedRoute.value ? '投产后生成首道工序' : '待排产')
const generatedBatchRows = computed(() => {
  const count = Math.max(Number(createForm.BatchCount) || 1, 1)
  if (!selectedWorkOrder.value || !workOrderDetail.value.plannedQuantity) return []
  return Array.from({ length: count }, (_, index) => ({
    Index: index + 1,
    PlannedQuantity: Math.max(0, Number(batchQuantities.value[index]) || 0),
    LineCode: batchLineSelections.value[index] || batchLineOptions.value[0],
  }))
})

const allocatedTotal = computed(() => generatedBatchRows.value.reduce((sum, item) => sum + item.PlannedQuantity, 0))
const allocationOverLimit = computed(() => allocatedTotal.value > remainingQty.value)
const allocationIncomplete = computed(() => allocatedTotal.value < remainingQty.value)

// 按当前工单计划数量与批次数自动平均分配（余数依次加到前若干个批次）
function autoDistributeQuantities() {
  const count = Math.max(Number(createForm.BatchCount) || 1, 1)
  const totalQty = Number(workOrderDetail.value.plannedQuantity) || 0
  const baseQty = Math.floor(totalQty / count)
  const remainder = totalQty % count
  batchQuantities.value = Array.from({ length: count }, (_, index) => baseQty + (index < remainder ? 1 : 0))
}

watch(
  () => createForm.WorkOrderId,
  async (newId) => {
    await loadWorkOrderDetail(newId)
    const count = Math.max(Number(createForm.BatchCount) || 1, 1)
    const defaultLine = batchLineOptions.value[0]
    batchLineSelections.value = Array.from({ length: count }, (_, index) => batchLineSelections.value[index] || defaultLine)
    autoDistributeQuantities()
  },
  { immediate: true }
)

watch(
  () => createForm.BatchCount,
  () => {
    const count = Math.max(Number(createForm.BatchCount) || 1, 1)
    const defaultLine = batchLineOptions.value[0]
    batchLineSelections.value = Array.from({ length: count }, (_, index) => batchLineSelections.value[index] || defaultLine)
    // 批次数变化时，保留已编辑的数量；新增批次给 0 默认值
    if (batchQuantities.value.length < count) {
      batchQuantities.value = [
        ...batchQuantities.value,
        ...Array.from({ length: count - batchQuantities.value.length }, () => 0),
      ]
    } else if (batchQuantities.value.length > count) {
      batchQuantities.value = batchQuantities.value.slice(0, count)
    }
  },
)

const statusCards = computed(() => {
  const statusMapping = {
    1: { key: 1, ...BATCH_STATUS[1], count: statusStats.value.pendingCount },
    2: { key: 2, ...BATCH_STATUS[2], count: statusStats.value.inProductionCount },
    3: { key: 3, ...BATCH_STATUS[3], count: statusStats.value.pausedCount },
    4: { key: 4, ...BATCH_STATUS[4], count: statusStats.value.repairingCount },
    5: { key: 5, ...BATCH_STATUS[5], count: statusStats.value.lockedCount },
    6: { key: 6, ...BATCH_STATUS[6], count: statusStats.value.completedCount },
  }
  return batchStatusCodes.map((code) => statusMapping[code])
})

function rowClass({ row }) {
  if ([BATCH_STATUS_CODE.locked, BATCH_STATUS_CODE.repair].includes(row.Status)) return 'danger-row'
  if ([BATCH_STATUS_CODE.paused, BATCH_STATUS_CODE.pending].includes(row.Status)) return 'warning-row'
  return ''
}

function handleSearch() {
  pagination.pageNum = 1
  loadBatches()
  ElMessage.success('已按筛选条件查询批次')
}

function handleReset() {
  Object.assign(filters, { keyword: '', WorkOrderCode: '', ProductName: '', Status: '', LineCode: '' })
  pagination.pageNum = 1
  loadBatches()
  ElMessage.info('筛选条件已重置')
}

function handlePageChange(pageNum) {
  pagination.pageNum = pageNum
  loadBatches()
}

function handleSizeChange(pageSize) {
  pagination.pageSize = pageSize
  pagination.pageNum = 1
  loadBatches()
}

function openCreateDialog() {
  const defaultOrder = availableWorkOrders.value[0] || null
  createForm.WorkOrderId = defaultOrder ? defaultOrder.Id : ''
  createForm.BatchCount = 1
  createForm.OwnerId = currentUserId.value
  batchLineSelections.value = [batchLineOptions.value[0]]
  batchQuantities.value = []
  createDialogVisible.value = true
  // 等工单详情加载完成后会通过 watch 自动平均分配
  if (defaultOrder && workOrderDetail.value?.plannedQuantity) {
    autoDistributeQuantities()
  }
}

function splitBatchNo(orderCode, index) {
  return 'B' + orderCode.slice(2) + '-' + String(index).padStart(2, '0')
}

function workOrderOptionLabel(order) {
  return `${order.WorkOrderCode} / ${order.ProductName || '-'}`
}

function batchDetailPath(batchId) {
  return '/production/batch/' + batchId
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
  batchQuantities.value.push(0)
  batchLineSelections.value.push(batchLineOptions.value[0])
  createForm.BatchCount += 1
}

function removeBatchRow(index) {
  if (createForm.BatchCount <= 1) {
    ElMessage.warning('至少保留 1 个批次')
    return
  }
  batchLineSelections.value.splice(index - 1, 1)
  batchQuantities.value.splice(index - 1, 1)
  createForm.BatchCount -= 1
}

async function submitCreateBatch() {
  if (!selectedWorkOrder.value) {
    ElMessage.warning('请先选择可创建批次的工单')
    return
  }
  if (!generatedBatchRows.value.length) {
    ElMessage.warning('批次数量不能为空')
    return
  }
  if (generatedBatchRows.value.some((item) => item.PlannedQuantity <= 0)) {
    ElMessage.warning('每个批次计划数量必须大于 0')
    return
  }
  if (allocationOverLimit.value) {
    ElMessage.warning(`已分配数量 ${allocatedTotal.value} 超过可拆数量 ${remainingQty.value}，请调整`)
    return
  }
  if (allocationIncomplete.value) {
    ElMessage.warning(`还有 ${remainingQty.value - allocatedTotal.value} 未分配完，请调整或增加批次`)
    return
  }
  if (generatedBatchRows.value.some((item) => !item.LineCode)) {
    ElMessage.warning('请为每个批次选择产线')
    return
  }

  const createLoading = ElLoading.service({ target: '.batch-create', text: '创建中...' })

  try {
    for (const row of generatedBatchRows.value) {
      const line = lineList.value.find(l => l.lineName === row.LineCode || l.LineName === row.LineCode)
      const lotCode = 'LOT' + selectedWorkOrder.value.WorkOrderCode.slice(2) + '-' + String(row.Index).padStart(2, '0')

      await createBatch({
        lotCode,
        workOrderId: Number(createForm.WorkOrderId),
        lineId: line?.id || 1,
        plannedQuantity: row.PlannedQuantity,
        status: 1
      })
    }

    ElMessage.success(`已为 ${selectedWorkOrder.value.WorkOrderCode} 创建 ${generatedBatchRows.value.length} 个批次`)
    createDialogVisible.value = false
    await Promise.all([loadBatches(), loadStatusStats(), loadWorkOrders()])
  } catch (error) {
    ElMessage.error(`创建失败: ${error.message}`)
  } finally {
    createLoading.close()
  }
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
    try {
      await updateBatchStatus(row.Id, BATCH_STATUS_CODE.running)
      row.Status = BATCH_STATUS_CODE.running
      row.UpdatedAt = new Date().toISOString().slice(0, 16).replace('T', ' ')
      ElMessage.success(`${row.LotCode} 已投产，首道工序已进入待进站`)
      await Promise.all([loadBatches(), loadStatusStats()])
    } catch (error) {
      ElMessage.error(`投产失败: ${error.message}`)
    }
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
  
  let targetStatus
  if (action === '锁定') targetStatus = BATCH_STATUS_CODE.locked
  if (action === '解锁') targetStatus = BATCH_STATUS_CODE.running
  if (action === '暂停') targetStatus = BATCH_STATUS_CODE.paused
  if (action === '恢复') targetStatus = BATCH_STATUS_CODE.running
  
  try {
    await updateBatchStatus(row.Id, targetStatus)
    row.Status = targetStatus
    row.UpdatedAt = new Date().toISOString().slice(0, 16).replace('T', ' ')
    ElMessage.success(`${row.LotCode} 已${action}`)
    await Promise.all([loadBatches(), loadStatusStats()])
  } catch (error) {
    ElMessage.error(`${action}失败: ${error.message}`)
  }
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
            <el-option v-for="line in lineList" :key="line.id" :label="line.lineName" :value="line.id" />
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
      <el-table v-loading="listLoading" :data="batchRows" border :row-class-name="rowClass">
        <el-table-column prop="LotCode" label="批次号" width="170px" align="center">
          <template #default="{ row }"><el-link type="primary" @click="router.push(batchDetailPath(row.Id))">{{ row.LotCode }}</el-link></template>
        </el-table-column>
        <el-table-column prop="WorkOrderCode" label="所属工单" width="190" align="center"/>
        <el-table-column prop="ProductName" label="产品名称" width="190" align="center"/>
        <el-table-column prop="ProductTypeName" label="产品类型" width="170" align="center"/>
        <el-table-column prop="LineName" label="分配产线" width="150" align="center"/>
        <el-table-column prop="PlannedQuantity" label="计划数量" width="150" align="center"/>
        <el-table-column prop="FinishedQuantity" label="已完工数量" width="130" align="center"/>
        <el-table-column prop="DefectQuantity" label="不良数量" width="110" align="center"/>
        <el-table-column prop="CurrentOperationName" label="当前工序" width="150" align="center"/>
        <el-table-column prop="CurrentStationName" label="当前工站" width="160" align="center">
          <template #default="{ row }">
            <span v-if="row.CurrentStationName">{{ row.CurrentStationName }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="EstimatedCompletionTime" label="预计完成时间" width="210" align="center"/>
        <el-table-column prop="StartTime" label="上线时间" width="210" align="center"/>
        <el-table-column label="状态" width="140" align="center">
          <template #default="{ row }"><StatusTag :meta="statusMeta(BATCH_STATUS, row.Status)" /></template>
        </el-table-column>

        <el-table-column fixed="right" label="操作" width="360">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button link type="primary" @click="router.push(batchDetailPath(row.Id))">详情</el-button>
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
      <div class="table-pagination">
        <el-pagination
          v-model:current-page="pagination.pageNum"
          v-model:page-size="pagination.pageSize"
          :page-sizes="[5, 10, 20, 50]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @current-change="handlePageChange"
          @size-change="handleSizeChange"
        />
      </div>
    </el-card>

    <el-dialog v-model="createDialogVisible" title="新建批次" width="1200px" class="batch-create-dialog" destroy-on-close>
      <el-empty v-if="!availableWorkOrders.length" description="当前没有可继续拆分批次的已释放工单" />
      <div v-else class="batch-create">
        <div class="batch-create__summary">
          <div>
            <span class="summary-label">当前工单</span>
            <strong>{{ workOrderDetail.workOrderCode || selectedOrderCode }}</strong>
            <p>{{ workOrderDetail.productName || selectedOrderProduct }}</p>
          </div>
          <div class="summary-metrics">
            <div>
              <span>计划数量</span>
              <strong>{{ workOrderDetail.plannedQuantity || selectedOrderPlanned }}</strong>
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
            </el-form>
            <div class="route-info">
              <span>工艺路线</span>
              <strong>{{ workOrderDetail.routeName || selectedRouteName }}</strong>
              <small>首工序：{{ workOrderDetail.firstOperationName || selectedFirstStep }}</small>
            </div>
          </div>

          <div class="preview-panel">
            <div class="panel-title">
              <span>拆分预览</span>
              <el-button size="small" type="primary" plain @click="autoDistributeQuantities">平均分配</el-button>
            </div>
            <div class="allocation-summary" :class="{ 'is-over': allocationOverLimit, 'is-incomplete': allocationIncomplete }">
              <span>已分配：<strong>{{ allocatedTotal }}</strong></span>
              <span>可拆数量：<strong>{{ remainingQty }}</strong></span>
              <span v-if="allocationOverLimit" class="allocation-warning">超出 {{ allocatedTotal - remainingQty }}，请调整</span>
              <span v-else-if="allocationIncomplete" class="allocation-hint">未分完，剩余 {{ remainingQty - allocatedTotal }} 需分配完才能创建</span>
              <span v-else class="allocation-ok">分配完成</span>
            </div>
            <el-table :data="generatedBatchRows" border size="small" max-height="380">
              <el-table-column type="index" label="#" width="56" />
              <el-table-column label="批次号" min-width="210">
                <template #default="{ row }">
                  <span v-if="selectedWorkOrder">{{ splitBatchNo(selectedWorkOrder.WorkOrderCode, row.Index) }}</span>
                  <span v-else>-</span>
                </template>
              </el-table-column>
              <el-table-column label="计划数量" width="140">
                <template #default="{ row }">
                  <el-input-number
                    v-model="batchQuantities[row.Index - 1]"
                    :min="0"
                    :max="remainingQty"
                    :precision="0"
                    controls-position="right"
                    size="small"
                    style="width: 110px"
                  />
                </template>
              </el-table-column>
              <el-table-column label="产线" width="170">
                <template #default="{ row }">
                  <el-select v-model="batchLineSelections[row.Index - 1]" placeholder="选择产线">
                    <el-option v-for="line in batchLineOptions" :key="line" :label="line" :value="line" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="120">
                <template #default>
                  <StatusTag :meta="statusMeta(BATCH_STATUS, 1)" />
                </template>
              </el-table-column>
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
          <el-button type="primary" :disabled="!selectedWorkOrder || !availableWorkOrders.length || !canPlanBatch || allocationOverLimit || allocationIncomplete" @click="submitCreateBatch">确认创建</el-button>
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
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.allocation-summary {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: center;
  margin-bottom: 12px;
  padding: 10px 12px;
  border-radius: 6px;
  background: #f8fafc;
  color: #475569;
  font-size: 13px;
}

.allocation-summary strong {
  color: #111827;
  font-size: 15px;
}

.allocation-summary.is-over,
.allocation-summary.is-incomplete {
  background: #fef2f2;
  color: #b91c1c;
}

.allocation-summary.is-over strong,
.allocation-summary.is-incomplete strong {
  color: #b91c1c;
}

.allocation-summary.is-incomplete {
  background: #fffbeb;
  color: #b45309;
}

.allocation-summary.is-incomplete strong {
  color: #b45309;
}

.allocation-warning {
  color: #b91c1c;
  font-weight: 600;
}

.allocation-hint {
  color: #b45309;
}

.allocation-ok {
  color: #15803d;
  font-weight: 600;
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

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
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
