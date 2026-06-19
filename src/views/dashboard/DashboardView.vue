<script setup>
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { DataAnalysis, Finished, Operation } from '@element-plus/icons-vue'
import MetricCard from '@/components/MetricCard.vue'
import SectionCard from '@/components/SectionCard.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import StatusTag from '@/components/StatusTag.vue'
import { DEVICE_STATUS, statusMeta } from '@/utils/constants'
import { alerts, dashboardMetrics, getLineDashboardRows, getWorkOrderCompletedQuantity, qualityTrend, workOrders, percent } from '@/utils/mockData'

const router = useRouter()
const filters = ref({ workshop: '', line: '', date: [new Date(), new Date()] })
const query = ref({ workshop: '', line: '', date: [new Date(), new Date()] })
const metrics = dashboardMetrics()
const lineRows = computed(() => getLineDashboardRows())

const filteredLines = computed(() => lineRows.value.filter((line) => {
  const matchWorkshop = !query.value.workshop || line.Workshop === query.value.workshop
  const matchLine = !query.value.line || line.LineCode === query.value.line
  return matchWorkshop && matchLine
}))

const trendX = qualityTrend.map((item) => item.hour)
const trendSeries = [
  { name: 'SPI 直通率', data: qualityTrend.map((item) => item.spi) },
  { name: 'AOI 直通率', data: qualityTrend.map((item) => item.aoi) },
  { name: '批次良率', data: qualityTrend.map((item) => item.batchYield) },
]

const progressSeries = [{ name: '完成率', data: workOrders.map((item) => percent(getWorkOrderCompletedQuantity(item), item.PlannedQuantity)) }]

function handleSearch() {
  query.value = { ...filters.value }
  ElMessage.success('已按筛选条件刷新驾驶舱')
}

function handleReset() {
  const next = { workshop: '', line: '', date: [new Date(), new Date()] }
  filters.value = next
  query.value = { ...next }
  ElMessage.info('筛选条件已重置')
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">生产驾驶舱</h1>
        <p class="page-subtitle">按车间、产线和日期查看实时生产、设备、质量与异常状态。</p>
      </div>
      <el-button type="primary" @click="router.push('/kanban/line-status')">进入大屏看板</el-button>
    </div>

    <div class="stat-cards">
      <MetricCard title="当日工单总数" :value="metrics.totalOrders" unit="单" trend="较昨日 +2" :icon="DataAnalysis" />
      <MetricCard title="在制批次数量" :value="metrics.inProcessBatches" unit="批" tone="warning" trend="含锁定批次" :icon="Operation" />
      <MetricCard title="整体直通率" :value="metrics.firstPassYield" unit="%" tone="success" trend="目标 97.0%" :icon="Finished" />
    </div>

    <div class="content-grid">
      <SectionCard class="span-8" title="产线状态总览" subtitle="点击产线可进入对应状态看板">
        <div class="line-grid">
          <button v-for="line in filteredLines" :key="line.LineCode" class="line-card" @click="router.push('/kanban/line-status')">
            <div class="line-head">
              <div>
                <strong>{{ line.LineName }}</strong>
                <p>{{ line.WorkOrderCode }} / {{ line.ProductCode }}</p>
              </div>
              <StatusTag :meta="statusMeta(DEVICE_STATUS, line.Status)" />
            </div>
            <el-progress :percentage="percent(line.CompletedQuantity, line.PlannedQuantity)" :stroke-width="10" />
            <div class="line-meta">
              <span>计划 {{ line.PlannedQuantity }}</span>
              <span>完工 {{ line.CompletedQuantity }}</span>
              <span>OEE {{ line.Oee }}%</span>
            </div>
            <div class="device-dots">
              <span v-for="(device, index) in line.EquipmentStatuses" :key="index" :style="{ backgroundColor: statusMeta(DEVICE_STATUS, device).color }" />
            </div>
          </button>
        </div>
      </SectionCard>

      <SectionCard class="span-4" title="异常告警专区" subtitle="未处理异常置顶展示">
        <div class="alert-list">
          <button v-for="alert in alerts" :key="alert.Id" class="alert-item" :class="alert.Level" @click="router.push(alert.TargetUrl)">
            <el-tag :type="alert.Level">{{ alert.AlertType }}</el-tag>
            <span>{{ alert.Title }}</span>
            <small>{{ alert.AlertTime }}</small>
          </button>
        </div>
      </SectionCard>

      <SectionCard class="span-6" title="当日生产进度" subtitle="按工单完成率排行">
        <SimpleChart type="bar" :x="workOrders.map((item) => item.WorkOrderCode)" :series="progressSeries" height="300px" />
      </SectionCard>

      <SectionCard class="span-6" title="质量趋势图" subtitle="小时线 SPI / AOI 直通率与批次良率">
        <SimpleChart :x="trendX" :series="trendSeries" height="300px" />
      </SectionCard>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.line-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 12px;
}

.line-card {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px;
  border: 1px solid var(--rtm-line);
  border-left: 4px solid var(--rtm-primary);
  border-radius: var(--rtm-radius);
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  text-align: left;
  cursor: pointer;
  box-shadow: var(--rtm-shadow);

  &:hover {
    border-color: #9bb9d2;
    border-left-color: var(--rtm-primary-dark);
  }
}

.line-head {
  display: flex;
  justify-content: space-between;
  gap: 10px;

  p {
    margin-top: 4px;
    color: var(--rtm-text-soft);
    font-size: 12px;
  }
}

.line-meta,
.device-dots {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  color: var(--rtm-text-soft);
  font-size: 12px;
}

.device-dots span {
  width: 18px;
  height: 18px;
  border: 1px solid rgba(23, 32, 44, 0.12);
  border-radius: 3px;
}

.alert-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.alert-item {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 8px;
  padding: 11px;
  border: 1px solid #e5c27c;
  border-left: 4px solid var(--rtm-warning);
  border-radius: var(--rtm-radius);
  background: #fff8e6;
  text-align: left;
  cursor: pointer;

  &.danger {
    border-color: #d9a29a;
    border-left-color: var(--rtm-danger);
    background: #fff4f2;
  }

  span {
    color: var(--rtm-text);
    font-size: 13px;
    line-height: 1.45;
  }

  small {
    color: var(--rtm-text-soft);
  }
}
</style>
