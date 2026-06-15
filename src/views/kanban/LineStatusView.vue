<script setup>
import { useRouter } from 'vue-router'
import MetricCard from '@/components/MetricCard.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { DEVICE_STATUS, statusMeta } from '@/utils/constants'
import { alerts, dashboardMetrics, lines, workOrders, percent } from '@/utils/mockData'

const router = useRouter()
const metrics = dashboardMetrics()
</script>

<template>
  <div class="kanban-page">
    <div class="kanban-header">
      <div>
        <h1>产线状态综合看板</h1>
        <p>实时刷新：30s / 当前大屏模式 / SMT-MES RTM</p>
      </div>
      <el-button @click="router.push('/dashboard')">返回系统</el-button>
    </div>

    <div class="stat-cards">
      <MetricCard title="总产线数量" :value="lines.length" unit="条" />
      <MetricCard title="运行产线" :value="lines.filter((item) => item.status === 'running').length" unit="条" tone="success" />
      <MetricCard title="整体稼动率" value="78.4" unit="%" tone="success" />
      <MetricCard title="当日总产量" :value="lines.reduce((sum, item) => sum + item.completed, 0)" unit="PCS" />
      <MetricCard title="整体直通率" :value="metrics.firstPassYield" unit="%" tone="warning" />
    </div>

    <div class="kanban-lines">
      <div v-for="line in lines" :key="line.id" class="kanban-line" :class="line.status">
        <div class="line-top">
          <strong>{{ line.name }}</strong>
          <span>{{ statusMeta(DEVICE_STATUS, line.status).label }}</span>
        </div>
        <p>{{ line.workOrder }} / {{ line.productModel }}</p>
        <el-progress :percentage="percent(line.completed, line.planned)" :stroke-width="12" />
        <div class="line-bottom">
          <span>{{ line.completed }} / {{ line.planned }}</span>
          <span>预计 {{ line.dueTime }}</span>
        </div>
        <div class="device-dots">
          <span v-for="(device, index) in line.devices" :key="index" :style="{ backgroundColor: statusMeta(DEVICE_STATUS, device).color }" />
        </div>
      </div>
    </div>

    <div class="content-grid">
      <el-card class="kanban-card span-4" shadow="never">
        <template #header>异常告警滚动区</template>
        <div class="ticker">
          <div v-for="alert in alerts" :key="alert.id">{{ alert.time }} {{ alert.type }}：{{ alert.title }}</div>
        </div>
      </el-card>
      <el-card class="kanban-card span-8" shadow="never">
        <template #header>当日工单进度排行</template>
        <SimpleChart theme="dark" type="bar" :x="workOrders.map((item) => item.id)" :series="[{ name: '完成率', data: workOrders.map((item) => percent(item.completed, item.planned)) }]" height="300px" />
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

  &.fault {
    border-left-color: #dc2626;
  }

  &.standby {
    border-left-color: #d97706;
  }

  &.offline {
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
