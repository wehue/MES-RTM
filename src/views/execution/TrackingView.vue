<script setup>
import { computed, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { batches, getBatchLoadingTasks, getBatchTrace } from '@/utils/mockData'

const form = reactive({ batchId: 'B20260512001-01' })
const loadingTasks = computed(() => getBatchLoadingTasks(form.batchId))
const currentBatch = computed(() => batches.find((item) => item.id === form.batchId) || null)
const traces = computed(() => getBatchTrace(form.batchId))
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">批次跟踪</h1>
        <p class="page-subtitle">查看批次从进站、出站、维修到流转下一工序的全过程记录。</p>
      </div>
      <el-button @click="ElMessage.success('批次追溯报告已导出')">导出追溯报告</el-button>
    </div>

    <div class="filter-bar">
      <el-select v-model="form.batchId" size="large" style="max-width: 360px">
        <el-option v-for="item in batches" :key="item.id" :label="item.id" :value="item.id" />
      </el-select>
    </div>

    <SectionCard title="批次基础信息">
      <el-empty v-if="!currentBatch" description="未找到批次" />
      <el-descriptions v-else :column="2" border>
        <el-descriptions-item label="批次号">{{ currentBatch.id }}</el-descriptions-item>
        <el-descriptions-item label="工单号">{{ currentBatch.workOrderId }}</el-descriptions-item>
        <el-descriptions-item label="产品">{{ currentBatch.productModel }} / {{ currentBatch.productName }}</el-descriptions-item>
        <el-descriptions-item label="当前工序">{{ currentBatch.currentStep }}</el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <SectionCard title="批次流转记录">
      <el-timeline>
        <el-timeline-item v-for="item in traces" :key="item.id" :timestamp="item.time" :type="item.type === 'repair' ? 'warning' : 'primary'">
          <el-card shadow="never">
            <strong>{{ item.step }}</strong>
            <p class="muted">{{ item.message }}</p>
            <p v-if="item.qty || item.goodQty || item.badQty || item.scrapQty" class="muted">
              数量：{{ item.qty || 0 }} / 良品 {{ item.goodQty || 0 }} / 不良 {{ item.badQty || 0 }} / 报废 {{ item.scrapQty || 0 }}
            </p>
          </el-card>
        </el-timeline-item>
      </el-timeline>
    </SectionCard>

    <SectionCard title="当前工序上料记录">
      <el-table :data="loadingTasks" border size="small">
        <el-table-column prop="station" label="站位" />
        <el-table-column prop="material" label="物料" />
        <el-table-column prop="loaded" label="已上数量" />
        <el-table-column prop="status" label="状态" />
      </el-table>
    </SectionCard>
  </div>
</template>
