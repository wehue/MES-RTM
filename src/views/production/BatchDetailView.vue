<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import { getBatchDetail } from '@/api/batch'

const route = useRoute()
const router = useRouter()
const loading = ref(true)
const batchDetail = ref({
  baseInfo: {},
  flowRecords: []
})

async function loadDetail() {
  loading.value = true
  try {
    const result = await getBatchDetail(route.params.id)
    batchDetail.value = result
  } catch (error) {
    console.error('Failed to load batch detail:', error)
    batchDetail.value = { baseInfo: {}, flowRecords: [] }
  } finally {
    loading.value = false
  }
}

function formatTime(timeStr) {
  if (!timeStr) return '-'
  return timeStr.replace('T', ' ').substring(0, 19)
}

function getEventTypeText(type) {
  const map = {
    'station_in': '进站',
    'station_out': '出站',
    'lot_created': '创建批次',
    'lot_completed': '批次完成',
    'status': '状态变更'
  }
  return map[type] || type
}

onMounted(() => {
  loadDetail()
})
</script>

<template>
  <div class="page-container" v-loading="loading">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ batchDetail.baseInfo.lotCode }} 批次详情</h1>
      </div>
      <div class="table-actions">
        <el-button type="primary" @click="router.push('/execution/check-in')">进站操作</el-button>
        <el-button @click="router.push('/execution/check-out')">出站操作</el-button>
        <el-button @click="router.push('/execution/loading')">上料管理</el-button>
        <el-button @click="router.push('/execution/tracking')">批次追溯</el-button>
      </div>
    </div>

    <SectionCard title="批次基础信息">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="批次号">{{ batchDetail.baseInfo.lotCode }}</el-descriptions-item>
        <el-descriptions-item label="工单号">{{ batchDetail.baseInfo.workOrderCode || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品名称">{{ batchDetail.baseInfo.productName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品类型">{{ batchDetail.baseInfo.productTypeName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产线">{{ batchDetail.baseInfo.lineName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="计划数量">{{ batchDetail.baseInfo.plannedQuantity }}</el-descriptions-item>
        <el-descriptions-item label="良品数量">{{ batchDetail.baseInfo.goodQuantity }}</el-descriptions-item>
        <el-descriptions-item label="当前工序">{{ batchDetail.baseInfo.currentOperationName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="当前工站">{{ batchDetail.baseInfo.currentStationName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ formatTime(batchDetail.baseInfo.createdAt) }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <StatusTag :meta="statusMeta(BATCH_STATUS, batchDetail.baseInfo.status)" />
        </el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <SectionCard title="批次流转记录">
      <el-timeline>
        <el-timeline-item
          v-for="(item, index) in batchDetail.flowRecords"
          :key="index"
          :timestamp="formatTime(item.eventTime)"
        >
          <strong>{{ getEventTypeText(item.eventType) }}</strong>
          <span v-if="item.operationName"> - {{ item.operationName }}</span>
          <span v-if="item.sequence"> - 工序{{ item.sequence }}</span>
          <p class="muted" v-if="item.quantity">数量: {{ item.quantity }}</p>
          <p class="muted" v-if="item.defectQuantity">不良: {{ item.defectQuantity }}</p>
          <p class="muted" v-if="item.eventType === 'station_out' && item.passRate != null && item.passRate > 0">通过率: {{ item.passRate }}%</p>
        </el-timeline-item>
      </el-timeline>
    </SectionCard>
  </div>
</template>
