<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { WORK_ORDER_STATUS, BATCH_STATUS, statusMeta } from '@/utils/constants'
import { batches, bomItems, processTimeline, routeById, workOrders, percent } from '@/utils/mockData'

const route = useRoute()
const router = useRouter()
const order = computed(() => workOrders.find((item) => item.id === route.params.id) || workOrders[0])
const orderRoute = computed(() => routeById(order.value.routeId))
const orderRouteSteps = computed(() => orderRoute.value.steps)
const orderBatches = computed(() => batches.filter((item) => item.workOrderId === order.value.id))

const stepSeries = [{
  name: '工序完工数量',
  data: processTimeline.map((item) => item.qty),
}]
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ order.id }} 工单详情</h1>
        <p class="page-subtitle">只读展示 BOM、工艺路线与工单批次流转，静态主数据来源于 MDM。</p>
      </div>
      <div class="table-actions">
        <el-button @click="ElMessage.success('已调用打印生产任务单')">打印任务单</el-button>
      </div>
    </div>

    <SectionCard title="工单基础信息">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="工单号">{{ order.id }}</el-descriptions-item>
        <el-descriptions-item label="产品">{{ order.productModel }} / {{ order.productName }}</el-descriptions-item>
        <el-descriptions-item label="计划数量">{{ order.planned }}</el-descriptions-item>
        <el-descriptions-item label="完成率">{{ percent(order.completed, order.planned) }}%</el-descriptions-item>
        <el-descriptions-item label="交货期">{{ order.dueDate }}</el-descriptions-item>
        <el-descriptions-item label="工艺路线">{{ order.routeName || orderRoute.name }}</el-descriptions-item>
        <el-descriptions-item label="创建 / 释放">{{ order.createdAt }} / {{ order.releasedAt }}</el-descriptions-item>
        <el-descriptions-item label="状态"><StatusTag :meta="statusMeta(WORK_ORDER_STATUS, order.status)" /></el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <div class="content-grid">
      <SectionCard class="span-12" title="产品 BOM 信息" subtitle="只读物料清单">
        <el-table :data="bomItems" border size="small">
          <el-table-column prop="material" label="元件料号" />
          <el-table-column prop="position" label="位号" />
          <el-table-column prop="qty" label="用量" width="80" />
          <el-table-column prop="packageType" label="封装" width="90" />
          <el-table-column prop="substitute" label="替代料规则" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="工艺路线信息" :subtitle="`${order.routeName || orderRoute.name} / 默认产线 ${orderRoute.line}`">
        <el-table :data="orderRouteSteps" border size="small">
          <el-table-column type="index" label="#" width="50" />
          <el-table-column prop="step" label="工序" />
          <el-table-column prop="device" label="对应设备" />
          <el-table-column prop="standardTime" label="标准工时" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="批次列表">
        <el-table :data="orderBatches" border :row-class-name="({ row }) => row.status === 'locked' ? 'danger-row' : ''">
          <el-table-column prop="id" label="批次号" min-width="160">
            <template #default="{ row }">
              <el-link type="primary" @click="router.push(`/production/batch/${row.id}`)">{{ row.id }}</el-link>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="105">
            <template #default="{ row }"><StatusTag :meta="statusMeta(BATCH_STATUS, row.status)" /></template>
          </el-table-column>
          <el-table-column prop="planned" label="计划数量" width="95" />
          <el-table-column prop="completed" label="完工数量" width="95" />
          <el-table-column prop="currentStep" label="当前工序" />
          <el-table-column prop="onlineAt" label="上线时间" />
          <el-table-column prop="eta" label="预计下线" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="工单进度跟踪">
        <div class="progress-section">
          <el-progress type="dashboard" :percentage="percent(order.completed, order.planned)" />
          <SimpleChart type="bar" :x="processTimeline.map((item) => item.step)" :series="stepSeries" height="260px" />
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.progress-section {
  display: grid;
  grid-template-columns: 220px minmax(0, 1fr);
  align-items: center;
  gap: 24px;
}

@media (max-width: 720px) {
  .progress-section {
    grid-template-columns: 1fr;
    justify-items: center;
  }
}
</style>
