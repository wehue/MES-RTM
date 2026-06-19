<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { WORK_ORDER_STATUS, statusMeta } from '@/utils/constants'
import { getProductList } from '@/api/product'
import { getRouteList } from '@/api/route'
import {
  closeWorkOrder,
  createWorkOrder,
  getWorkOrderList,
  getWorkOrderStatusStats,
  pauseWorkOrder,
  releaseWorkOrder,
  resumeWorkOrder,
} from '@/api/workOrder'
import {
  WORK_ORDER_STATUS_CODE,
  products,
  routeOptionsByProduct,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const dialogVisible = ref(false)
const submitting = ref(false)
const listLoading = ref(false)
const optionLoading = ref(false)
const operatingOrderId = ref(null)
const operatingAction = ref('')
const filters = reactive({ workOrderCode: '', productId: '', status: '' })
const form = reactive({ ProductId: '', RouteId: '', PlannedQuantity: 1000, DueDate: '' })
const workOrderStatusCodes = [1, 2, 3, 4, 5, 6]
const productOptions = ref([...products])
const routeOptions = ref([])
const workOrderRows = ref([])
const pagination = reactive({ pageNum: 1, pageSize: 5, total: 0 })
const statusStats = reactive({
  draftCount: 0,
  releasedCount: 0,
  inProductionCount: 0,
  pausedCount: 0,
  completedCount: 0,
  closedCount: 0,
  totalCount: 0,
})

const canManage = computed(() => userStore.hasAnyRole(['production_manager']))
const selectedProduct = computed(() => productOptions.value.find((product) => product.Id === Number(form.ProductId)))
const availableRoutes = computed(() => {
  if (!selectedProduct.value) return []
  const productTypeId = selectedProduct.value.ProductTypeId
  const matchedRoutes = routeOptions.value.filter((route) => !productTypeId || route.ProductTypeId === productTypeId)
  if (matchedRoutes.length) return matchedRoutes
  return routeOptionsByProduct(Number(form.ProductId))
})
const selectedRoute = computed(() => availableRoutes.value.find((route) => route.Id === Number(form.RouteId)))
const actionConfig = {
  release: {
    allow: WORK_ORDER_STATUS_CODE.draft,
    request: releaseWorkOrder,
    success: '工单已释放成功',
  },
  pause: {
    allow: WORK_ORDER_STATUS_CODE.running,
    request: pauseWorkOrder,
    success: (order) => `${order.WorkOrderCode} 已暂停`,
  },
  resume: {
    allow: WORK_ORDER_STATUS_CODE.paused,
    request: resumeWorkOrder,
    success: (order) => `${order.WorkOrderCode} 已恢复生产`,
  },
  close: {
    allow: WORK_ORDER_STATUS_CODE.completed,
    request: closeWorkOrder,
    success: (order) => `${order.WorkOrderCode} 已关闭`,
  },
}

const isOperating = (order, action) => operatingOrderId.value === order.Id && operatingAction.value === action

const statusCountKeys = {
  1: 'draftCount',
  2: 'releasedCount',
  3: 'inProductionCount',
  4: 'pausedCount',
  5: 'completedCount',
  6: 'closedCount',
}
const statusCards = computed(() => workOrderStatusCodes.map((code) => ({
  key: code,
  ...WORK_ORDER_STATUS[code],
  count: statusStats[statusCountKeys[code]] || 0,
})))

watch(() => form.ProductId, () => {
  form.RouteId = selectedProduct.value?.DefaultRouteId || availableRoutes.value[0]?.Id || ''
})

function formatDate(value) {
  if (!value) return '-'
  if (typeof value === 'string') return value.slice(0, 10)
  const date = new Date(value)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
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

function normalizeProduct(product) {
  return {
    ...product,
    Id: product.id,
    ProductCode: product.productCode,
    ProductName: product.productName,
    Model: product.model,
    ProductTypeId: product.productTypeId,
    DefaultRouteId: product.defaultRouteId,
  }
}

function normalizeRoute(route) {
  return {
    ...route,
    Id: route.id,
    RouteCode: route.routeCode,
    RouteName: route.routeName,
    ProductTypeId: route.productTypeId,
    Status: route.status,
  }
}

function normalizeWorkOrder(order) {
  return {
    ...order,
    Id: order.id,
    WorkOrderCode: order.workOrderCode,
    ProductName: order.productName,
    ProductTypeName: order.productTypeName,
    RouteName: order.routeName,
    PlannedQuantity: order.plannedQuantity,
    DueDate: formatDateTime(order.dueDate),
    Status: order.status,
    CreatedAt: formatDateTime(order.createdAt),
    CreatedBy: order.createdBy,
    UpdatedAt: formatDateTime(order.updatedAt),
    UpdatedBy: order.updatedBy,
  }
}

async function loadStatusStats() {
  const stats = await getWorkOrderStatusStats()
  Object.assign(statusStats, stats)
}

async function loadWorkOrders() {
  listLoading.value = true
  try {
    const result = await getWorkOrderList({
      workOrderCode: filters.workOrderCode || undefined,
      productId: filters.productId || undefined,
      status: filters.status || undefined,
      pageNum: pagination.pageNum,
      pageSize: pagination.pageSize,
    })
    workOrderRows.value = result.list.map(normalizeWorkOrder)
    pagination.total = result.total || 0
  } finally {
    listLoading.value = false
  }
}

async function loadCreateOptions() {
  optionLoading.value = true
  try {
    const [productList, routeList] = await Promise.all([getProductList(), getRouteList()])
    productOptions.value = productList.map(normalizeProduct)
    routeOptions.value = routeList.map(normalizeRoute).filter((route) => route.Status === 2)
  } catch (error) {
    console.warn('Failed to load work order create options:', error)
  } finally {
    optionLoading.value = false
  }
}

async function openCreateDialog() {
  dialogVisible.value = true
  if (!routeOptions.value.length) {
    await loadCreateOptions()
  }
}

async function submitCreate() {
  if (!canManage.value) {
    ElMessage.warning('当前角色仅可查看，无法新建工单')
    return
  }
  if (!selectedProduct.value || !selectedRoute.value || !form.PlannedQuantity || !form.DueDate) {
    ElMessage.warning('请完整选择产品、工艺路线、计划数量和交货期')
    return
  }

  submitting.value = true
  try {
    await createWorkOrder({
      productId: selectedProduct.value.Id,
      routeId: selectedRoute.value.Id,
      plannedQuantity: form.PlannedQuantity,
      dueDate: `${formatDate(form.DueDate)}T18:00:00`,
      status: WORK_ORDER_STATUS_CODE.draft,
    })
    Object.assign(form, { ProductId: '', RouteId: '', PlannedQuantity: 1000, DueDate: '' })
    ElMessage.success('工单已生成')
    dialogVisible.value = false
    await Promise.all([loadWorkOrders(), loadStatusStats()])
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  loadCreateOptions()
  loadWorkOrders()
  loadStatusStats()
})

function handleSearch() {
  pagination.pageNum = 1
  loadWorkOrders()
}

function handleReset() {
  Object.assign(filters, { workOrderCode: '', productId: '', status: '' })
  pagination.pageNum = 1
  loadWorkOrders()
}

async function operate(order, action) {
  if (!canManage.value) {
    ElMessage.warning('当前角色仅有查看权限，操作已拦截')
    return
  }

  const config = actionConfig[action]
  if (!config || order.Status !== config.allow) {
    ElMessage.warning('当前工单状态不支持该操作')
    return
  }

  operatingOrderId.value = order.Id
  operatingAction.value = action
  try {
    await config.request(order.Id)
    const successMessage = typeof config.success === 'function' ? config.success(order) : config.success
    ElMessage.success(successMessage)
    await Promise.all([loadWorkOrders(), loadStatusStats()])
  } finally {
    operatingOrderId.value = null
    operatingAction.value = ''
  }
}

function handlePageChange(pageNum) {
  pagination.pageNum = pageNum
  loadWorkOrders()
}

function handleSizeChange(pageSize) {
  pagination.pageSize = pageSize
  pagination.pageNum = 1
  loadWorkOrders()
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">工单管理</h1>
      </div>
      <div class="table-actions">
        <el-button @click="ElMessage.success('已导出当前筛选工单数据')">导出 Excel</el-button>
        <el-button type="primary" :disabled="!canManage" @click="openCreateDialog">新建工单</el-button>
      </div>
    </div>

    <div class="status-card-grid">
      <MetricCard v-for="card in statusCards" :key="card.key" :title="card.label" :value="card.count" unit="单" :tone="card.type === 'danger' ? 'danger' : card.type" />
    </div>

    <div class="filter-bar">
      <el-form :inline="true" :model="filters">
        <el-form-item label="工单号">
          <el-input v-model="filters.workOrderCode" clearable placeholder="输入工单号" />
        </el-form-item>
        <el-form-item label="产品名称">
          <el-select v-model="filters.productId" clearable filterable placeholder="全部产品" style="width: 190px">
            <el-option v-for="product in productOptions" :key="product.Id" :label="product.ProductName" :value="product.Id" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width: 130px">
            <el-option v-for="code in workOrderStatusCodes" :key="code" :label="WORK_ORDER_STATUS[code].label" :value="code" />
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
      <el-table v-loading="listLoading" :data="workOrderRows" border>
        <el-table-column prop="WorkOrderCode" label="工单号" width="230">
          <template #default="{ row }">
            <el-link type="primary" @click="router.push(`/production/work-order/${row.Id}`)">{{ row.WorkOrderCode }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="ProductName" label="产品名称" width="190" />
        <el-table-column prop="ProductTypeName" label="产品类型" width="170" />
        <el-table-column prop="PlannedQuantity" label="计划数量" width="150" />
        <el-table-column prop="DueDate" label="交货期" width="180" />
        <el-table-column prop="RouteName" label="工艺路线" width="230" />
        <el-table-column label="状态" width="140">
          <template #default="{ row }">
            <StatusTag :meta="statusMeta(WORK_ORDER_STATUS, row.Status)" />
          </template>
        </el-table-column>
        <el-table-column prop="CreatedBy" label="创建人" width="150" />
        <el-table-column prop="CreatedAt" label="创建时间" width="210" />
        <el-table-column fixed="right" label="操作" width="310">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button link type="primary" @click="router.push(`/production/work-order/${row.Id}`)">详情</el-button>
              <el-button link type="success" :loading="isOperating(row, 'release')" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.draft" @click="operate(row, 'release')">释放</el-button>
              <el-button link type="warning" :loading="isOperating(row, 'pause')" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.running" @click="operate(row, 'pause')">暂停</el-button>
              <el-button link type="success" :loading="isOperating(row, 'resume')" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.paused" @click="operate(row, 'resume')">恢复</el-button>
              <el-button link type="danger" :loading="isOperating(row, 'close')" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.completed" @click="operate(row, 'close')">关闭</el-button>
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

    <el-dialog v-model="dialogVisible" title="新建工单" width="520px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="产品名称">
          <el-select v-model="form.ProductId" :loading="optionLoading" filterable placeholder="选择产品名称" class="full">
            <el-option v-for="product in productOptions" :key="product.Id" :label="`${product.ProductName} / ${product.Model || '-'}`" :value="product.Id" />
          </el-select>
        </el-form-item>
        <el-form-item label="工艺路线">
          <el-select v-model="form.RouteId" :disabled="!form.ProductId" :loading="optionLoading" filterable placeholder="先选择产品名称" class="full">
            <el-option
              v-for="route in availableRoutes"
              :key="route.Id"
              :label="route.RouteName"
              :value="route.Id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="计划数量">
          <el-input-number v-model="form.PlannedQuantity" :min="1" :step="100" />
        </el-form-item>
        <el-form-item label="交货期">
          <el-date-picker v-model="form.DueDate" type="date" placeholder="选择交货期" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitCreate">提交生成</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.full {
  width: 100%;
}

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
