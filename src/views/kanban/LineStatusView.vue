<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import MetricCard from '@/components/MetricCard.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { DEVICE_STATUS, statusMeta } from '@/utils/constants'
import { alerts, dashboardMetrics, getLineDashboardRows, getWorkOrderCompletedQuantity, workOrders, percent } from '@/utils/mockData'

const router = useRouter()
const metrics = dashboardMetrics()
const lineRows = computed(() => getLineDashboardRows())
</script>

<template>
  <div class="kanban-page">
    <div class="kanban-header">
      <div>
        <h1>产线状态综合看板</h1>
        <p>实时刷新，30s / 当前大屏模式 / SMT-MES RTM</p>
      </div>
      <el-button @click="router.push('/dashboard')">返回系统</el-button>
    </div>

    <div class="stat-cards">
      <MetricCard title="总产线数量" :value="lineRows.length" unit="条" />
      <MetricCard title="运行产线" :value="lineRows.filter((item) => item.Status === 1).length" unit="条" tone="success" />
      <MetricCard title="整体稼动率" value="78.4" unit="%" tone="success" />
      <MetricCard title="当日总产量" :value="lineRows.reduce((sum, item) => sum + item.CompletedQuantity, 0)" unit="PCS" />
      <MetricCard title="整体直通率" :value="metrics.firstPassYield" unit="%" tone="warning" />
    </div>

    <div class="kanban-lines">
      <div v-for="line in lineRows" :key="line.LineCode" class="kanban-line" :class="statusMeta(DEVICE_STATUS, line.Status).type">
        <div class="line-top">
          <strong>{{ line.LineName }}</strong>
          <span>{{ statusMeta(DEVICE_STATUS, line.Status).label }}</span>
        </div>
        <p>{{ line.WorkOrderCode }} / {{ line.ProductCode }}</p>
        <el-progress :percentage="percent(line.CompletedQuantity, line.PlannedQuantity)" :stroke-width="12" />
        <div class="line-bottom">
          <span>{{ line.CompletedQuantity }} / {{ line.PlannedQuantity }}</span>
          <span>预计 {{ line.DueTime }}</span>
        </div>
        <div class="device-dots">
          <span v-for="(device, index) in line.EquipmentStatuses" :key="index" :style="{ backgroundColor: statusMeta(DEVICE_STATUS, device).color }" />
        </div>
      </div>
    </div>

    <div class="content-grid">
      <el-card class="kanban-card span-4" shadow="never">
        <template #header>异常告警滚动区</template>
        <div class="ticker">
          <div v-for="alert in alerts" :key="alert.Id">{{ alert.AlertTime }} {{ alert.AlertType }}：{{ alert.Title }}</div>
        </div>
      </el-card>
      <el-card class="kanban-card span-8" shadow="never">
        <template #header>当日工单进度排行</template>
        <SimpleChart
          theme="dark"
          type="bar"
          :x="workOrders.map((item) => item.WorkOrderCode)"
          :series="[{ name: '完成率', data: workOrders.map((item) => percent(getWorkOrderCompletedQuantity(item), item.PlannedQuantity)) }]"
          height="300px"
        />
      </el-card>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.kanban-lines {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 16px;
  margin: 22px 0;
}

.kanban-line {
  padding: 22px;
  border: 1px solid #2d5f99;
  border-left: 6px solid #16a34a;
  border-radius: 8px;
  background: #0e2138;
  box-shadow: none;
  opacity: 1;
  filter: none;

  &.danger {
    border-left-color: #dc2626;
  }

  &.warning {
    border-left-color: #d97706;
  }

  &.info {
    border-left-color: #6b7280;
  }

  p {
    margin: 8px 0 14px;
    color: #d7e5f5;
    font-size: 18px;
  }
}

.line-top,
.line-bottom,
.device-dots {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.device-dots {
  justify-content: flex-start;
  margin-top: 16px;

  span {
    width: 28px;
    height: 28px;
    border: 1px solid #ffffff;
    border-radius: 6px;
  }
}

.ticker {
  display: flex;
  flex-direction: column;
  gap: 12px;
  color: #fecaca;
  font-size: 20px;
  line-height: 1.6;
}
</style>
