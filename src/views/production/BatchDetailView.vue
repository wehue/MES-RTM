<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import { batches, getBatchLoadingTasks, getBatchTrace } from '@/utils/mockData'

const route = useRoute()
const router = useRouter()
const batch = computed(() => batches.find((item) => item.id === route.params.id) || batches[0])
const loadingTasks = computed(() => getBatchLoadingTasks(batch.value.id))
const traces = computed(() => getBatchTrace(batch.value.id))
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ batch.id }} 批次详情</h1>
        <p class="page-subtitle">查看批次基础信息、工序流转、上料记录和追溯结果。</p>
      </div>
      <div class="table-actions">
        <el-button type="primary" @click="router.push('/execution/check-in')">进站操作</el-button>
        <el-button @click="router.push('/execution/check-out')">出站操作</el-button>
        <el-button @click="router.push('/execution/loading')">上料管理</el-button>
        <el-button @click="router.push('/execution/tracking')">批次跟踪</el-button>
      </div>
    </div>

    <SectionCard title="批次基础信息">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="批次号">{{ batch.id }}</el-descriptions-item>
        <el-descriptions-item label="工单号">{{ batch.workOrderId }}</el-descriptions-item>
        <el-descriptions-item label="产品">{{ batch.productModel }} / {{ batch.productName }}</el-descriptions-item>
        <el-descriptions-item label="产线">{{ batch.line }}</el-descriptions-item>
        <el-descriptions-item label="计划数量">{{ batch.planned }}</el-descriptions-item>
        <el-descriptions-item label="良品 / 不良 / 报废">{{ batch.completed }} / {{ batch.defective }} / {{ batch.scrap }}</el-descriptions-item>
        <el-descriptions-item label="当前工序">{{ batch.currentStep }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <StatusTag :meta="statusMeta(BATCH_STATUS, batch.status)" />
        </el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <SectionCard title="批次流转记录">
      <el-timeline>
        <el-timeline-item v-for="item in traces" :key="item.id" :timestamp="item.time">
          <strong>{{ item.step }}</strong>
          <p class="muted">{{ item.message }}</p>
        </el-timeline-item>
      </el-timeline>
    </SectionCard>

    <SectionCard title="当前工序上料">
      <el-table :data="loadingTasks" border size="small">
        <el-table-column prop="station" label="站位" />
        <el-table-column prop="material" label="物料" />
        <el-table-column prop="required" label="应上数量" />
        <el-table-column prop="loaded" label="已上数量" />
        <el-table-column prop="status" label="状态" />
      </el-table>
    </SectionCard>
  </div>
</template>
