<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { BATCH_STATUS, WORK_ORDER_STATUS, statusMeta } from '@/utils/constants'
import {
  findWorkOrder,
  getBatchLine,
  getBatchProduct,
  getBatchRouteProgress,
  getBomDisplayItems,
  getCurrentOperationName,
  getRouteStepRows,
  getWorkOrderCompletedQuantity,
  getWorkOrderLots,
  getWorkOrderProduct,
  getWorkOrderRoute,
  percent,
  processTimeline,
  workOrders,
} from '@/utils/mockData'

const route = useRoute()
const router = useRouter()
const order = computed(() => findWorkOrder(route.params.id) || workOrders[0])
const product = computed(() => getWorkOrderProduct(order.value))
const orderRoute = computed(() => getWorkOrderRoute(order.value))
const orderRouteSteps = computed(() => getRouteStepRows(order.value.RouteId))
const orderBatches = computed(() => getWorkOrderLots(order.value))
const bomRows = computed(() => getBomDisplayItems(product.value?.Id))
const completedQuantity = computed(() => getWorkOrderCompletedQuantity(order.value))

const stepSeries = [{
  name: '工序完工数量',
  data: processTimeline.map((item) => item.StationInQuantity),
}]
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ order.WorkOrderCode }} 工单详情</h1>
        <p class="page-subtitle">展示工单字段、产品 BOM、工艺路线和拆分批次，页面展示字段均由 SQL 表关联得到。</p>
      </div>
      <div class="table-actions">
        <el-button @click="ElMessage.success('已调用打印生产任务单')">打印任务单</el-button>
      </div>
    </div>

    <SectionCard title="工单基础信息">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="工单号">{{ order.WorkOrderCode }}</el-descriptions-item>
        <el-descriptions-item label="产品名称">{{ product?.ProductName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品型号">{{ product?.Model || '-' }}</el-descriptions-item>
        <el-descriptions-item label="计划数量">{{ order.PlannedQuantity }}</el-descriptions-item>
        <el-descriptions-item label="完成率">{{ percent(completedQuantity, order.PlannedQuantity) }}%</el-descriptions-item>
        <el-descriptions-item label="交货期">{{ order.DueDate }}</el-descriptions-item>
        <el-descriptions-item label="工艺路线">{{ orderRoute?.RouteName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ order.CreatedAt }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ order.UpdatedAt }}</el-descriptions-item>
        <el-descriptions-item label="状态"><StatusTag :meta="statusMeta(WORK_ORDER_STATUS, order.Status)" /></el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <div class="content-grid">
      <SectionCard class="span-12" title="产品 BOM 信息" subtitle="字段来自 smt_bom_items，物料信息来自 smt_materials">
        <el-table :data="bomRows" border size="small">
          <el-table-column prop="MaterialCode" label="物料编码" />
          <el-table-column prop="ReferenceDesignator" label="位号" />
          <el-table-column prop="Quantity" label="用量" width="80" />
          <el-table-column prop="PackageType" label="封装" width="90" />
          <el-table-column prop="SubstituteMaterialCodes" label="替代料" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="工艺路线信息" :subtitle="orderRoute?.RouteName || '-'">
        <el-table :data="orderRouteSteps" border size="small">
          <el-table-column prop="Sequence" label="顺序" width="80" />
          <el-table-column prop="OperationCode" label="工序编码" />
          <el-table-column prop="OperationName" label="工序名称" />
          <el-table-column prop="EquipmentTypeName" label="设备类型" />
          <el-table-column prop="StandardTimeText" label="标准工时" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="批次列表">
        <el-table :data="orderBatches" border :row-class-name="({ row }) => row.Status === 5 ? 'danger-row' : ''">
          <el-table-column prop="LotCode" label="批次号" min-width="160">
            <template #default="{ row }">
              <el-link type="primary" @click="router.push(`/production/batch/${row.LotCode}`)">{{ row.LotCode }}</el-link>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="105">
            <template #default="{ row }"><StatusTag :meta="statusMeta(BATCH_STATUS, row.Status)" /></template>
          </el-table-column>
          <el-table-column prop="PlannedQuantity" label="计划数量" width="95" />
          <el-table-column prop="CompletedQuantity" label="完工数量" width="95" />
          <el-table-column label="当前工序">
            <template #default="{ row }">{{ getCurrentOperationName(row) }}</template>
          </el-table-column>
          <el-table-column label="产线">
            <template #default="{ row }">{{ getBatchLine(row)?.LineCode || '-' }}</template>
          </el-table-column>
          <el-table-column prop="StartTime" label="上线时间" />
          <el-table-column prop="EstimatedCompletionTime" label="预计下线" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="工单进度跟踪">
        <div class="progress-section">
          <div class="progress-gauge">
            <el-progress type="dashboard" :width="180" :stroke-width="10" :percentage="percent(completedQuantity, order.PlannedQuantity)" />
          </div>
          <SimpleChart type="bar" :x="processTimeline.map((item) => item.OperationName)" :series="stepSeries" height="260px" />
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
