<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { WORK_ORDER_STATUS, statusMeta } from '@/utils/constants'
import {
  WORK_ORDER_STATUS_CODE,
  getWorkOrderCompletedBatchCount,
  getWorkOrderCompletedQuantity,
  getWorkOrderProduct,
  getWorkOrderReleasedBatchCount,
  getWorkOrderRoute,
  findUser,
  getUserDisplayName,
  percent,
  products,
  routeOptionsByProduct,
  workOrders,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const dialogVisible = ref(false)
const filters = reactive({ keyword: '', ProductName: '', Status: '' })
const query = reactive({ keyword: '', ProductName: '', Status: '' })
const form = reactive({ ProductId: '', RouteId: '', PlannedQuantity: 1000, DueDate: '' })
const workOrderStatusCodes = [1, 2, 3, 4, 5, 6]

const canManage = computed(() => userStore.hasAnyRole(['production_manager']))
const availableRoutes = computed(() => routeOptionsByProduct(Number(form.ProductId)))
const selectedProduct = computed(() => products.find((product) => product.Id === Number(form.ProductId)))
const selectedRoute = computed(() => availableRoutes.value.find((route) => route.Id === Number(form.RouteId)))
const currentUserId = computed(() => findUser(userStore.userInfo.username || userStore.userInfo.name)?.Id || 1)

const filteredOrders = computed(() => workOrders.filter((item) => {
  const productInfo = getWorkOrderProduct(item)
  const keyword = !query.keyword || item.WorkOrderCode.includes(query.keyword)
  const productName = !query.ProductName || productInfo?.ProductName.includes(query.ProductName)
  const status = !query.Status || item.Status === Number(query.Status)
  return keyword && productName && status
}))

const statusCards = computed(() => workOrderStatusCodes.map((code) => ({
  key: code,
  ...WORK_ORDER_STATUS[code],
  count: workOrders.filter((item) => item.Status === code).length,
})))

watch(() => form.ProductId, () => {
  form.RouteId = availableRoutes.value[0]?.Id || ''
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

function nowText() {
  return new Date().toISOString().slice(0, 16).replace('T', ' ')
}

function submitCreate() {
  if (!canManage.value) {
    ElMessage.warning('当前角色仅可查看，无法新建工单')
    return
  }
  if (!selectedProduct.value || !selectedRoute.value || !form.PlannedQuantity || !form.DueDate) {
    ElMessage.warning('请完整选择产品、工艺路线、计划数量和交货期')
    return
  }

  const nextCode = `WO${new Date().getFullYear()}${String(60512000 + workOrders.length + 1)}`
  const createdAt = nowText()
  workOrders.unshift({
    Id: Date.now(),
    WorkOrderCode: nextCode,
    ProductId: selectedProduct.value.Id,
    RouteId: selectedRoute.value.Id,
    PlannedQuantity: form.PlannedQuantity,
    DueDate: `${formatDate(form.DueDate)} 23:59`,
    Status: WORK_ORDER_STATUS_CODE.draft,
    CreatedAt: createdAt,
    CreatedBy: currentUserId.value,
    UpdatedAt: createdAt,
    UpdatedBy: currentUserId.value,
    IsDeleted: 0,
    LastOperationType: 'CREATE',
    LastOperationRemark: '前端原型新建工单',
  })
  Object.assign(form, { ProductId: '', RouteId: '', PlannedQuantity: 1000, DueDate: '' })
  ElMessage.success('工单已生成')
  dialogVisible.value = false
}

function handleSearch() {
  Object.assign(query, { ...filters })
  ElMessage.success('已按筛选条件查询工单')
}

function handleReset() {
  Object.assign(filters, { keyword: '', ProductName: '', Status: '' })
  Object.assign(query, { keyword: '', ProductName: '', Status: '' })
  ElMessage.info('筛选条件已重置')
}

function setOrderStatus(order, status) {
  order.Status = status
  order.UpdatedAt = nowText()
}

function operate(order, action) {
  if (!canManage.value) {
    ElMessage.warning('当前角色仅有查看权限，操作已拦截')
    return
  }
  if (action === 'release' && order.Status === WORK_ORDER_STATUS_CODE.draft) {
    setOrderStatus(order, WORK_ORDER_STATUS_CODE.released)
    order.LastOperationType = 'RELEASE'
    order.LastOperationRemark = '工单已释放'
    ElMessage.success('工单已释放成功')
    return
  }
  if (action === 'pause' && order.Status === WORK_ORDER_STATUS_CODE.running) {
    setOrderStatus(order, WORK_ORDER_STATUS_CODE.paused)
    ElMessage.success(`${order.WorkOrderCode} 已暂停`)
    return
  }
  if (action === 'resume' && order.Status === WORK_ORDER_STATUS_CODE.paused) {
    setOrderStatus(order, WORK_ORDER_STATUS_CODE.running)
    ElMessage.success(`${order.WorkOrderCode} 已恢复生产`)
    return
  }
  if (action === 'close' && order.Status === WORK_ORDER_STATUS_CODE.completed) {
    setOrderStatus(order, WORK_ORDER_STATUS_CODE.closed)
    ElMessage.success(`${order.WorkOrderCode} 已关闭`)
    return
  }
  ElMessage.warning('当前工单状态不支持该操作')
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">工单管理</h1>
        <p class="page-subtitle">以 SQL 工单字段为主维护工单，产品、路线、完成进度通过主数据和批次数据关联展示。</p>
      </div>
      <div class="table-actions">
        <el-button @click="ElMessage.success('已导出当前筛选工单数据')">导出 Excel</el-button>
        <el-button type="primary" :disabled="!canManage" @click="dialogVisible = true">新建工单</el-button>
      </div>
    </div>

    <div class="status-card-grid">
      <MetricCard v-for="card in statusCards" :key="card.key" :title="card.label" :value="card.count" unit="单" :tone="card.type === 'danger' ? 'danger' : card.type" />
    </div>

    <div class="filter-bar">
      <el-form :inline="true" :model="filters">
        <el-form-item label="工单号">
          <el-input v-model="filters.keyword" clearable placeholder="输入工单号" />
        </el-form-item>
        <el-form-item label="产品名称">
          <el-input v-model="filters.ProductName" clearable placeholder="输入产品名称" style="width: 180px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.Status" clearable placeholder="全部状态" style="width: 130px">
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
      <el-table :data="filteredOrders" border>
        <el-table-column prop="WorkOrderCode" label="工单号" width="230">
          <template #default="{ row }">
            <el-link type="primary" @click="router.push(`/production/work-order/${row.WorkOrderCode}`)">{{ row.WorkOrderCode }}</el-link>
          </template>
        </el-table-column>
        <el-table-column label="产品名称" width="190">
          <template #default="{ row }">{{ getWorkOrderProduct(row)?.ProductName || '-' }}</template>
        </el-table-column>
        <el-table-column label="产品型号" width="190">
          <template #default="{ row }">{{ getWorkOrderProduct(row)?.Model || '-' }}</template>
        </el-table-column>
        <el-table-column prop="PlannedQuantity" label="计划数量" width="150" />
        <el-table-column label="已完工" width="130">
          <template #default="{ row }">{{ getWorkOrderCompletedQuantity(row) }}</template>
        </el-table-column>
        <el-table-column label="完成率" width="180">
          <template #default="{ row }">
            <el-progress :percentage="percent(getWorkOrderCompletedQuantity(row), row.PlannedQuantity)" />
          </template>
        </el-table-column>
        <el-table-column label="已释放批次" width="170">
          <template #default="{ row }">{{ getWorkOrderReleasedBatchCount(row) }}</template>
        </el-table-column>
        <el-table-column label="完成批次" width="150">
          <template #default="{ row }">{{ getWorkOrderCompletedBatchCount(row) }}</template>
        </el-table-column>
        <el-table-column prop="DueDate" label="交货期" width="180" />
        <el-table-column label="工艺路线" width="230">
          <template #default="{ row }">{{ getWorkOrderRoute(row)?.RouteName || '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="140">
          <template #default="{ row }">
            <StatusTag :meta="statusMeta(WORK_ORDER_STATUS, row.Status)" />
          </template>
        </el-table-column>
        <el-table-column label="创建人" width="150">
          <template #default="{ row }">{{ getUserDisplayName(row.CreatedBy) }}</template>
        </el-table-column>
        <el-table-column prop="CreatedAt" label="创建时间" width="210" />
        <el-table-column fixed="right" label="操作" width="310">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button link type="primary" @click="router.push(`/production/work-order/${row.WorkOrderCode}`)">详情</el-button>
              <el-button link type="success" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.draft" @click="operate(row, 'release')">释放</el-button>
              <el-button link type="warning" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.running" @click="operate(row, 'pause')">暂停</el-button>
              <el-button link type="success" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.paused" @click="operate(row, 'resume')">恢复</el-button>
              <el-button link type="danger" :disabled="row.Status !== WORK_ORDER_STATUS_CODE.completed" @click="operate(row, 'close')">关闭</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
      <p class="readonly-note" style="margin-top: 12px">
        字段说明：列表主体字段来自 smt_work_orders，产品、路线、批次数和完工数通过关联表计算展示。
      </p>
    </el-card>

    <el-dialog v-model="dialogVisible" title="新建工单" width="520px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="产品名称">
          <el-select v-model="form.ProductId" placeholder="选择产品名称" class="full">
            <el-option v-for="product in products" :key="product.Id" :label="`${product.ProductName} / ${product.Model}`" :value="product.Id" />
          </el-select>
        </el-form-item>
        <el-form-item label="工艺路线">
          <el-select v-model="form.RouteId" :disabled="!form.ProductId" placeholder="先选择产品名称" class="full">
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
        <el-button type="primary" @click="submitCreate">提交生成</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.full {
  width: 100%;
}
</style>
