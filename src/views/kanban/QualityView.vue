<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import MetricCard from '@/components/MetricCard.vue'
import SimpleChart from '@/components/SimpleChart.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import {
  BATCH_STATUS_CODE,
  batches,
  defectDistribution,
  getBatchDefectQuantity,
  getBatchProduct,
  getCurrentOperationName,
  getLineDashboardRows,
  qualityTrend,
} from '@/utils/mockData'

const router = useRouter()
const lineRows = computed(() => getLineDashboardRows())
const abnormalBatches = computed(() => batches.filter((item) => getBatchDefectQuantity(item) > 0 || [BATCH_STATUS_CODE.repair, BATCH_STATUS_CODE.locked].includes(item.Status)))
</script>

<template>
  <div class="kanban-page">
    <div class="kanban-header">
      <div>
        <h1>实时质量监控看板</h1>
        <p>质量部大屏 / 当日 SPI、AOI、良率、异常批次实时展示</p>
      </div>
      <el-button @click="router.push('/dashboard')">返回系统</el-button>
    </div>

    <div class="stat-cards">
      <MetricCard title="SPI 直通率" value="97.1" unit="%" tone="success" />
      <MetricCard title="AOI 直通率" value="96.8" unit="%" tone="success" />
      <MetricCard title="批次良率" value="98.2" unit="%" tone="success" />
      <MetricCard title="不良率" value="1.8" unit="%" tone="warning" />
      <MetricCard title="异常批次" :value="abnormalBatches.length" unit="批" tone="danger" />
    </div>

    <div class="content-grid" style="margin-top: 18px">
      <el-card class="kanban-card span-7" shadow="never">
        <template #header>直通率实时趋势</template>
        <SimpleChart theme="dark" :x="qualityTrend.map((item) => item.hour)" :series="[{ name: 'SPI', data: qualityTrend.map((item) => item.spi) }, { name: 'AOI', data: qualityTrend.map((item) => item.aoi) }]" height="340px" />
      </el-card>
      <el-card class="kanban-card span-5" shadow="never">
        <template #header>不良类型 Top10 分布</template>
        <SimpleChart theme="dark" type="pie" :data="defectDistribution" height="340px" />
      </el-card>
      <el-card class="kanban-card span-6" shadow="never">
        <template #header>产线质量排行</template>
        <SimpleChart theme="dark" type="bar" :x="lineRows.map((item) => item.LineCode)" :series="[{ name: '良率', data: [98.8, 97.5, 94.1, 98.9] }]" height="300px" />
      </el-card>
      <el-card class="kanban-card span-6" shadow="never">
        <template #header>异常批次明细</template>
        <el-table :data="abnormalBatches" size="small">
          <el-table-column prop="LotCode" label="批次" />
          <el-table-column label="产品">
            <template #default="{ row }">{{ getBatchProduct(row)?.Model || '-' }}</template>
          </el-table-column>
          <el-table-column label="工序">
            <template #default="{ row }">{{ getCurrentOperationName(row) }}</template>
          </el-table-column>
          <el-table-column label="不良数">
            <template #default="{ row }">{{ getBatchDefectQuantity(row) }}</template>
          </el-table-column>
          <el-table-column label="状态">
            <template #default="{ row }">{{ statusMeta(BATCH_STATUS, row.Status).label }}</template>
          </el-table-column>
        </el-table>
      </el-card>
    </div>
  </div>
</template>
