<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { WORK_ORDER_STATUS, statusMeta } from '@/utils/constants'
import { WORK_ORDER_STATUS_CODE, lineOptions, products, routeOptionsByProduct, workOrders, percent } from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const dialogVisible = ref(false)
const filters = reactive({ keyword: '', productModel: '', status: '', line: '', due: [] })
const query = reactive({ keyword: '', productModel: '', status: '', line: '', due: [] })
const form = reactive({ productModel: '', routeId: '', planned: 1000, dueDate: '' })
const workOrderStatusKeys = ['pending', 'released', 'running', 'paused', 'completed', 'closed']

const canManage = computed(() => userStore.hasAnyRole(['production_manager']))
const availableRoutes = computed(() => routeOptionsByProduct(form.productModel))
const selectedProduct = computed(() => products.find((product) => product.model === form.productModel))
const selectedRoute = computed(() => availableRoutes.value.find((route) => route.id === form.routeId))

const filteredOrders = computed(() => workOrders.filter((item) => {
  const keyword = !query.keyword || item.id.includes(query.keyword)
  const model = !query.productModel || item.productModel === query.productModel
  const status = !query.status || item.status === query.status
  const line = !query.line || item.line === query.line
  return keyword && model && status && line
}))

const statusCards = computed(() => workOrderStatusKeys.map((key) => ({
  key,
  ...WORK_ORDER_STATUS[key],
  count: workOrders.filter((item) => item.status === key).length,
})))

watch(() => form.productModel, () => {
  form.routeId = availableRoutes.value[0]?.id || ''
})

function formatDate(value) {
  if (!value) return '-'
  if (typeof value === 'string') return value
  const date = new Date(value)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function submitCreate() {
  if (!canManage.value) {
    ElMessage.warning('当前角色仅可查看，无法新建工单')
    return
  }
  if (!form.productModel || !form.routeId || !form.planned || !form.dueDate) {
    ElMessage.warning('请完整选择产品型号、工艺路线、计划数量和交货期')
    return
  }

  const route = selectedRoute.value
  const product = selectedProduct.value
  const nextId = `WO${new Date().getFullYear()}${String(60512000 + workOrders.length + 1)}`
  workOrders.unshift({
    Id: Date.now(),
    WorkOrderCode: nextId,
    ProductId: product.Id,
    RouteId: route.Id,
    PlannedQuantity: form.planned,
    DueDate: form.dueDate + ' 23:59',
    Status: WORK_ORDER_STATUS_CODE.pending,
    id: nextId,
    productModel: product.model,
    productName: product.name,
    planned: form.planned,
    completed: 0,
    dueDate: formatDate(form.dueDate),
    line: route.line,
    routeId: route.id,
    routeName: route.name,
    releasedBatches: 0,
    completedBatches: 0,
    status: 'pending',
    creator: '王主管',
    createdAt: formatDate(new Date()),
    releasedAt: '-',
    closedAt: '-',
  })
  Object.assign(form, { productModel: '', routeId: '', planned: 1000, dueDate: '' })
  ElMessage.success('工单已生成')
  dialogVisible.value = false
}

function handleSearch() {
  Object.assign(query, { ...filters })
  ElMessage.success('已按筛选条件查询工单')
}

function handleReset() {
  Object.assign(filters, { keyword: '', productModel: '', status: '', line: '', due: [] })
  Object.assign(query, { keyword: '', productModel: '', status: '', line: '', due: [] })
  ElMessage.info('筛选条件已重置')
}

function setOrderStatus(order, status) {
  order.status = status
  order.Status = WORK_ORDER_STATUS_CODE[status] || order.Status
}

function operate(order, action) {
  if (!canManage.value) {
    ElMessage.warning('班组长仅有查看权限，操作已拦截')
    return
  }
  if (action === 'release' && order.status === 'pending') {
    setOrderStatus(order, 'released')
    if (order.releasedAt === '-') {
      order.releasedAt = new Date().toISOString().slice(0, 16).replace('T', ' ')
    }
    ElMessage.success('工艺路线、BOM、参数模板校验完整，工单已释放')
    return
  }
  if (action === '暂停' && order.status === 'running') {
    setOrderStatus(order, 'paused')
    ElMessage.success(`${order.id} 已暂停`)
    return
  }
  if (action === '恢复' && order.status === 'paused') {
    setOrderStatus(order, 'running')
    ElMessage.success(`${order.id} 已恢复生产`)
    return
  }
  if (action === '关闭' && order.status === 'completed') {
    setOrderStatus(order, 'closed')
    order.closedAt = new Date().toISOString().slice(0, 16).replace('T', ' ')
    ElMessage.success(`${order.id} 已关闭`)
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
        <p class="page-subtitle">覆盖新建、释放、暂停、恢复、关闭、详情查看与导出操作。</p>
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
        <el-form-item label="产品型号">
          <el-select v-model="filters.productModel" clearable placeholder="全部型号" style="width: 170px">
            <el-option v-for="product in products" :key="product.model" :label="product.model" :value="product.model" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width: 130px">
            <el-option v-for="key in workOrderStatusKeys" :key="key" :label="WORK_ORDER_STATUS[key].label" :value="key" />
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
      <el-table :data="filteredOrders" border>
        <el-table-column prop="id" label="工单号" width="230">
          <template #default="{ row }">
            <el-link type="primary" @click="router.push(`/production/work-order/${row.id}`)">{{ row.id }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="productModel" label="产品型号" width="190" />
        <el-table-column prop="productName" label="产品名称" width="190" />
        <el-table-column prop="planned" label="计划数量" width="150" />
        <el-table-column prop="completed" label="已完工" width="130" />
        <el-table-column label="完成率" width="180">
          <template #default="{ row }">
            <el-progress :percentage="percent(row.completed, row.planned)" />
          </template>
        </el-table-column>
        <el-table-column prop="releasedBatches" label="已释放批次" width="170" />
        <el-table-column prop="completedBatches" label="完成批次" width="150" />
        <el-table-column prop="dueDate" label="交货期" width="160" />
        <el-table-column prop="routeName" label="工艺路线" width="230" />
        <el-table-column label="状态" width="140">
          <template #default="{ row }">
            <StatusTag :meta="statusMeta(WORK_ORDER_STATUS, row.status)" />
          </template>
        </el-table-column>
        <el-table-column prop="creator" label="创建人" width="130" />
        <el-table-column prop="createdAt" label="创建时间" width="230" />
        <el-table-column prop="releasedAt" label="释放时间" width="230" />
        <el-table-column fixed="right" label="操作" width="310">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button link type="primary" @click="router.push(`/production/work-order/${row.id}`)">详情</el-button>
              <el-button link type="success" :disabled="row.status !== 'pending'" @click="operate(row, 'release')">释放</el-button>
              <el-button link type="warning" :disabled="row.status !== 'running'" @click="operate(row, '暂停')">暂停</el-button>
              <el-button link type="success" :disabled="row.status !== 'paused'" @click="operate(row, '恢复')">恢复</el-button>
              <el-button link type="danger" :disabled="row.status !== 'completed'" @click="operate(row, '关闭')">关闭</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
      <p class="readonly-note" style="margin-top: 12px">
        权限规则：生产主管可新建、释放、暂停、关闭；班组长仅查看负责产线。已关闭工单仅允许查看。
      </p>
    </el-card>

    <el-dialog v-model="dialogVisible" title="新建工单" width="520px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="产品型号">
          <el-select v-model="form.productModel" placeholder="选择产品型号" class="full">
            <el-option v-for="product in products" :key="product.model" :label="`${product.model} / ${product.name}`" :value="product.model" />
          </el-select>
        </el-form-item>
        <el-form-item label="分配工艺路线" label-width="112px">
          <el-select v-model="form.routeId" :disabled="!form.productModel" placeholder="先选择产品型号" class="full">
            <el-option
              v-for="route in availableRoutes"
              :key="route.id"
              :label="`${route.name} / ${route.line}`"
              :value="route.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="计划数量">
          <el-input-number v-model="form.planned" :min="1" :step="100" />
        </el-form-item>
        <el-form-item label="交货期">
          <el-date-picker v-model="form.dueDate" type="date" placeholder="选择交货期" />
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
