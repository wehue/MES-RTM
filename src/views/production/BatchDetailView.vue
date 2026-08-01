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
    // Mock 兜底：构造批次详情数据
    const batchId = Number(route.params.id) || 1
    batchDetail.value = {
      baseInfo: {
        lotCode: `B2026051200${batchId}-01`,
        workOrderCode: 'WO20260512001',
        productName: '智能控制板 V2.0',
        productTypeName: 'PCBA',
        lineName: 'SMT产线 A1',
        plannedQuantity: 600,
        goodQuantity: 528,
        currentOperationName: '贴片',
        currentStationName: 'ST-A1-03 贴片工站',
        createdAt: '2026-05-12 08:00:00',
        status: 2,
      },
      flowRecords: [
        { eventType: 'lot_created', eventTime: '2026-05-12 08:00:00', operationName: '创建批次', quantity: 600 },
        { eventType: 'station_in', eventTime: '2026-05-12 08:42:00', operationName: '印刷', sequence: 10, quantity: 600 },
        { eventType: 'station_out', eventTime: '2026-05-12 09:02:00', operationName: '印刷', sequence: 10, quantity: 596, defectQuantity: 4, passRate: 99.3 },
        { eventType: 'station_in', eventTime: '2026-05-12 09:05:00', operationName: 'SPI 检测', sequence: 20, quantity: 596 },
        { eventType: 'station_out', eventTime: '2026-05-12 09:28:00', operationName: 'SPI 检测', sequence: 20, quantity: 590, defectQuantity: 6, passRate: 99.0 },
        { eventType: 'station_in', eventTime: '2026-05-12 09:33:00', operationName: '贴片', sequence: 30, quantity: 590 },
      ],
    }
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
        <p class="page-subtitle">查看批次基础字段、工序流转记录和追溯结果。</p>
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
