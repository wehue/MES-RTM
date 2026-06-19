<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import MetricCard from '@/components/MetricCard.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { WORK_ORDER_STATUS, statusMeta } from '@/utils/constants'
import { getLineDashboardRows, getWorkOrderCompletedQuantity, workOrders, percent } from '@/utils/mockData'

const router = useRouter()
const lineRows = computed(() => getLineDashboardRows())
</script>

<template>
  <div class="kanban-page">
    <div class="kanban-header">
      <div>
        <h1>生产进度追踪看板</h1>
        <p>交货期预警、计划与实际进度、工单完成率、产能达成率集中展示。</p>
      </div>
      <el-button @click="router.push('/dashboard')">返回系统</el-button>
    </div>

    <div class="stat-cards">
      <MetricCard title="7 天内交货" value="5" unit="单" tone="warning" />
      <MetricCard title="已完成" :value="workOrders.filter((item) => item.Status === 5).length" unit="单" tone="success" />
      <MetricCard title="未完成" :value="workOrders.filter((item) => item.Status !== 5).length" unit="单" tone="danger" />
      <MetricCard title="延期预警" value="1" unit="单" tone="danger" />
    </div>

    <div class="content-grid" style="margin-top: 18px">
      <el-card class="kanban-card span-12" shadow="never">
        <template #header>工单进度甘特图</template>
        <div class="gantt">
          <div v-for="(order, index) in workOrders" :key="order.Id" class="gantt-row">
            <span>{{ order.WorkOrderCode }}</span>
            <div class="gantt-track">
              <div class="gantt-plan" :style="{ width: `${80 - index * 8}%` }" />
              <div class="gantt-real" :style="{ width: `${percent(getWorkOrderCompletedQuantity(order), order.PlannedQuantity)}%` }" />
            </div>
            <strong>{{ percent(getWorkOrderCompletedQuantity(order), order.PlannedQuantity) }}%</strong>
          </div>
        </div>
      </el-card>

      <el-card class="kanban-card span-7" shadow="never">
        <template #header>工单完成率明细</template>
        <el-table :data="workOrders" size="small" :row-class-name="({ row }) => row.DueDate <= '2026-05-13' && row.Status !== 5 ? 'danger-row' : ''">
          <el-table-column prop="WorkOrderCode" label="工单" />
          <el-table-column prop="PlannedQuantity" label="计划" />
          <el-table-column label="完工">
            <template #default="{ row }">{{ getWorkOrderCompletedQuantity(row) }}</template>
          </el-table-column>
          <el-table-column prop="DueDate" label="交货期" />
          <el-table-column label="状态">
            <template #default="{ row }">{{ statusMeta(WORK_ORDER_STATUS, row.Status).label }}</template>
          </el-table-column>
        </el-table>
      </el-card>

      <el-card class="kanban-card span-5" shadow="never">
        <template #header>产线产能达成率</template>
        <SimpleChart
          theme="dark"
          type="bar"
          :x="lineRows.map((item) => item.LineCode)"
          :series="[{ name: '当日达成率', data: lineRows.map((item) => percent(item.CompletedQuantity, item.PlannedQuantity)) }, { name: '当月达成率', data: [91, 86, 76, 94] }]"
          height="300px"
        />
      </el-card>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.gantt {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.gantt-row {
  display: grid;
  grid-template-columns: 160px 1fr 56px;
  align-items: center;
  gap: 12px;
  color: #dbeafe;
}

.gantt-track {
  position: relative;
  height: 28px;
  border-radius: 6px;
  background: rgba(148, 163, 184, 0.16);
  overflow: hidden;
}

.gantt-plan,
.gantt-real {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
}

.gantt-plan {
  background: rgba(96, 165, 250, 0.32);
}

.gantt-real {
  height: 14px;
  margin: 7px 0;
  border-radius: 0 6px 6px 0;
  background: linear-gradient(90deg, #22c55e, #38bdf8);
}
</style>
