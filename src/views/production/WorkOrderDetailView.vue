<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { getProductList } from '@/api/product'
import { getWorkOrderDetail } from '@/api/workOrder'
import { BATCH_STATUS, WORK_ORDER_STATUS, statusMeta } from '@/utils/constants'

const route = useRoute()
const router = useRouter()
const loading = ref(false)
const productList = ref([])
const detail = ref({
  baseInfo: {},
  bom: { items: [] },
  routeSteps: [],
  lots: [],
  progress: [],
  completionRate: 0,
})

const baseInfo = computed(() => detail.value.baseInfo || {})
const currentProduct = computed(() => {
  const productId = detail.value.bom?.productId
  const productName = baseInfo.value.productName
  return productList.value.find((product) => product.id === productId)
    || productList.value.find((product) => product.productName === productName)
    || {}
})
const bomRows = computed(() => (detail.value.bom?.items || []).map((item) => ({
  ...item,
  MaterialCode: item.materialCode || '-',
  PackageType: item.packageType,
  MaterialPackageType: item.materialPackageType || '-',
  Quantity: item.quantity,
  Brand: item.brand || '-',
})))
const routeStepRows = computed(() => (detail.value.routeSteps || []).map((item) => ({
  ...item,
  Sequence: formatRouteSequence(item.sequence),
  OperationCode: item.operationCode,
  OperationName: item.operationName,
  EquipmentTypeName: item.equipmentTypeName,
  StandardTimeText: item.standardTime ? `${item.standardTime} 秒` : '-',
})))
const lotRows = computed(() => (detail.value.lots || []).map((item) => ({
  ...item,
  Id: item.id,
  LotCode: item.lotCode,
  Status: item.status,
  PlannedQuantity: item.plannedQuantity,
  CompletedQuantity: item.completedQuantity,
  LineName: item.lineName,
  CurrentOperation: item.currentOperation,
  StartTime: formatDateTime(item.startTime),
  EstimatedCompletionTime: formatDateTime(item.estimatedCompletionTime),
})))
const progressRows = computed(() => detail.value.progress || [])
const completionPercent = computed(() => Math.round(Number(detail.value.completionRate || 0) * 100))

const stepSeries = computed(() => [{
  name: '工序完工数量',
  data: progressRows.value.map((item) => item.finishedQuantity || 0),
}])

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

function formatRouteSequence(value) {
  const sequence = Number(value)
  if (!Number.isFinite(sequence)) return value || '-'
  return sequence / 10
}

function formatValue(value, suffix = '') {
  if (value === null || value === undefined || value === '') return '-'
  return `${value}${suffix}`
}

async function loadDetail() {
  loading.value = true
  try {
    const workOrderDetail = await getWorkOrderDetail(route.params.id)
    detail.value = workOrderDetail
    productList.value = await getProductList()
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadDetail()
})
</script>

<template>
  <div v-loading="loading" class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ baseInfo.workOrderCode || '-' }} 工单详情</h1>
        <p class="page-subtitle">展示工单字段、产品 BOM、工艺路线和拆分批次，页面展示字段均由 SQL 表关联得到。</p>
      </div>
      <div class="table-actions">
        <el-button @click="ElMessage.success('已调用打印生产任务单')">打印任务单</el-button>
      </div>
    </div>

    <SectionCard title="工单基础信息">
      <el-descriptions class="base-descriptions" :column="2" border>
        <el-descriptions-item label="工单号">{{ baseInfo.workOrderCode || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品名称">{{ baseInfo.productName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品型号">{{ formatValue(currentProduct.model) }}</el-descriptions-item>
        <el-descriptions-item label="设计版本">{{ formatValue(currentProduct.version) }}</el-descriptions-item>
        <el-descriptions-item label="PCB尺寸">{{ formatValue(currentProduct.pcbDimensions) }}</el-descriptions-item>
        <el-descriptions-item label="PCB厚度">{{ formatValue(currentProduct.pcbThickness) }}</el-descriptions-item>
        <el-descriptions-item label="工艺路线">{{ baseInfo.routeName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="计划数量">{{ baseInfo.plannedQuantity || 0 }}</el-descriptions-item>
        <el-descriptions-item label="完成率">{{ completionPercent }}%</el-descriptions-item>
        <el-descriptions-item label="交货期">{{ formatDateTime(baseInfo.dueDate) }}</el-descriptions-item>
        <el-descriptions-item label="拼板数量">{{ formatValue(currentProduct.panelCount) }}</el-descriptions-item>
        <el-descriptions-item label="SPI检测直通率阈值">{{ formatValue(currentProduct.spiThreshold, '%') }}</el-descriptions-item>
        <el-descriptions-item label="AOI检测直通率阈值">{{ formatValue(currentProduct.aoiThreshold, '%') }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ formatDateTime(baseInfo.createdAt) }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ formatDateTime(baseInfo.updatedAt) }}</el-descriptions-item>
        <el-descriptions-item label="状态"><StatusTag :meta="statusMeta(WORK_ORDER_STATUS, baseInfo.status)" /></el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <div class="content-grid">
      <SectionCard class="span-12" title="产品 BOM 信息" :subtitle="detail.bom?.bomVersion || '-'">
        <el-table :data="bomRows" border size="small">
          <el-table-column prop="MaterialCode" label="元件料号" min-width="120" align="center"/>
          <el-table-column prop="PackageType" label="BOM封装类型" min-width="120" align="center"/>
          <el-table-column prop="MaterialPackageType" label="物料封装类型" min-width="120" align="center"/>
          <el-table-column prop="Quantity" label="单板用量" min-width="120" align="center"/>
          <el-table-column prop="Brand" label="品牌" min-width="120" align="center"/>
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="工艺路线信息" :subtitle="baseInfo.routeName || '-'">
        <el-table :data="routeStepRows" border size="small">
          <el-table-column prop="Sequence" label="顺序" width="80" align="center"/>
          <el-table-column prop="OperationCode" label="工序编码" align="center"/>
          <el-table-column prop="OperationName" label="工序名称" align="center"/>
          <el-table-column prop="EquipmentTypeName" label="设备类型" align="center"/>
          <el-table-column prop="StandardTimeText" label="标准工时" align="center"/>
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="批次列表">
        <el-table :data="lotRows" border>
          <el-table-column prop="LotCode" label="批次号" min-width="120"align="center">
            <template #default="{ row }">
              <el-link type="primary" @click="router.push(`/production/batch/${row.Id}`)">{{ row.LotCode }}</el-link>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="120" align="center">
            <template #default="{ row }"><StatusTag :meta="statusMeta(BATCH_STATUS, row.Status)" /></template>
          </el-table-column>
          <el-table-column prop="PlannedQuantity" label="计划数量" width="110" align="center"/>
          <el-table-column prop="CompletedQuantity" label="完工数量" width="110" align="center"/>
          <el-table-column prop="CurrentOperation" label="当前工序" align="center"/>
          <el-table-column prop="LineName" label="产线" align="center"/>
          <el-table-column prop="StartTime" label="上线时间" align="center"/>
          <el-table-column prop="EstimatedCompletionTime" label="预计下线" align="center"/>
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="工单进度跟踪">
        <div class="progress-section">
          <div class="progress-gauge">
            <el-progress type="dashboard" :width="180" :stroke-width="10" :percentage="completionPercent" />
          </div>
          <SimpleChart type="bar" :x="progressRows.map((item) => item.operationName)" :series="stepSeries" height="260px" />
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.progress-section {
  display: grid;
  grid-template-columns: minmax(220px, 280px) minmax(0, 1fr);
  align-items: stretch;
  gap: 24px;
}

.progress-gauge {
  display: grid;
  min-height: 260px;
  place-items: center;
  justify-self: stretch;
}

.base-descriptions {
  :deep(.el-descriptions__label) {
    width: 240px !important;
    min-width: 240px !important;
    white-space: nowrap !important;
    word-break: keep-all;
    font-size: 13px;
  }
}

@media (max-width: 720px) {
  .progress-section {
    grid-template-columns: 1fr;
    justify-items: center;
  }

  .progress-gauge {
    width: 100%;
  }
}
</style>
