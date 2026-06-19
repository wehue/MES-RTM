<script setup>
import { computed, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import {
  batches,
  findBatch,
  getBatchLoadingTasks,
  getBatchProduct,
  getBatchTrace,
  getBatchWorkOrder,
  getCurrentOperationName,
} from '@/utils/mockData'

const form = reactive({ LotCode: 'B20260512001-01' })
const loadingTasks = computed(() => getBatchLoadingTasks(form.LotCode))
const currentBatch = computed(() => findBatch(form.LotCode) || null)
const traces = computed(() => getBatchTrace(form.LotCode))
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">批次追溯</h1>
        <p class="page-subtitle">查看批次从进站、出站、维修到流转下一工序的全过程记录。</p>
      </div>
      <el-button @click="ElMessage.success('批次追溯报告已导出')">导出追溯报告</el-button>
    </div>

    <div class="filter-bar">
      <el-select v-model="form.LotCode" size="large" style="max-width: 360px">
        <el-option v-for="item in batches" :key="item.LotCode" :label="item.LotCode" :value="item.LotCode" />
      </el-select>
    </div>

    <SectionCard title="批次基础信息">
      <el-empty v-if="!currentBatch" description="未找到批次" />
      <el-descriptions v-else :column="2" border>
        <el-descriptions-item label="批次号">{{ currentBatch.LotCode }}</el-descriptions-item>
        <el-descriptions-item label="工单号">{{ getBatchWorkOrder(currentBatch)?.WorkOrderCode }}</el-descriptions-item>
        <el-descriptions-item label="产品">{{ getBatchProduct(currentBatch)?.Model }} / {{ getBatchProduct(currentBatch)?.ProductName }}</el-descriptions-item>
        <el-descriptions-item label="当前工序">{{ getCurrentOperationName(currentBatch) }}</el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <SectionCard title="批次流转记录">
      <el-timeline>
        <el-timeline-item v-for="item in traces" :key="item.Id" :timestamp="item.EventTime" :type="item.EventType === 'repair' ? 'warning' : 'primary'">
          <el-card shadow="never">
            <strong>{{ item.OperationName }}</strong>
            <p class="muted">{{ item.Message }}</p>
            <p v-if="item.Quantity || item.FinishedQuantity || item.DefectQuantity || item.ScrapQuantity" class="muted">
              数量：{{ item.Quantity || 0 }} / 良品 {{ item.FinishedQuantity || 0 }} / 不良 {{ item.DefectQuantity || 0 }} / 报废 {{ item.ScrapQuantity || 0 }}
            </p>
          </el-card>
        </el-timeline-item>
      </el-timeline>
    </SectionCard>

    <SectionCard title="当前工序上料记录">
      <el-table :data="loadingTasks" border size="small">
        <el-table-column prop="StationCode" label="站位" />
        <el-table-column prop="MaterialCode" label="物料" />
        <el-table-column prop="LoadedQuantity" label="已上数量" />
        <el-table-column label="状态">
          <template #default="{ row }">{{ row.LoadedQuantity >= row.RequiredQuantity ? '已齐套' : '待补料' }}</template>
        </el-table-column>
      </el-table>
    </SectionCard>
  </div>
</template>
