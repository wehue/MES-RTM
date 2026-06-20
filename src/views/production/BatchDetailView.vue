<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { BATCH_STATUS, statusMeta } from '@/utils/constants'
import {
  batches,
  findBatch,
  getBatchDefectQuantity,
  getBatchLine,
  getBatchLoadingTasks,
  getBatchProduct,
  getBatchScrapQuantity,
  getBatchTrace,
  getBatchWorkOrder,
  getCurrentOperationName,
} from '@/utils/mockData'

const route = useRoute()
const router = useRouter()
const batch = computed(() => findBatch(route.params.id) || batches[0])
const workOrder = computed(() => getBatchWorkOrder(batch.value))
const product = computed(() => getBatchProduct(batch.value))
const line = computed(() => getBatchLine(batch.value))
const loadingTasks = computed(() => getBatchLoadingTasks(batch.value.LotCode))
const traces = computed(() => getBatchTrace(batch.value.LotCode))

function verifyStatusText(status) {
  if (status === 1) return '校验通过'
  if (status === 2) return '校验失败'
  return '未校验'
}

function verifyStatusType(status) {
  if (status === 1) return 'success'
  if (status === 2) return 'danger'
  return 'info'
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ batch.LotCode }} 批次详情</h1>
        <p class="page-subtitle">查看批次基础字段、工序流转、上料记录和追溯结果。</p>
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
        <el-descriptions-item label="批次号">{{ batch.LotCode }}</el-descriptions-item>
        <el-descriptions-item label="工单号">{{ workOrder?.WorkOrderCode || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品名称">{{ product?.ProductName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品型号">{{ product?.Model || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产线">{{ line?.LineCode || '-' }}</el-descriptions-item>
        <el-descriptions-item label="计划数量">{{ batch.PlannedQuantity }}</el-descriptions-item>
        <el-descriptions-item label="良品数量">{{ batch.CompletedQuantity }}</el-descriptions-item>
        <el-descriptions-item label="不良数量">{{ getBatchDefectQuantity(batch) }}</el-descriptions-item>
        <el-descriptions-item label="报废数量">{{ getBatchScrapQuantity(batch) }}</el-descriptions-item>
        <el-descriptions-item label="当前工序">{{ getCurrentOperationName(batch) }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <StatusTag :meta="statusMeta(BATCH_STATUS, batch.Status)" />
        </el-descriptions-item>
      </el-descriptions>
    </SectionCard>

    <SectionCard title="批次流转记录">
      <el-timeline>
        <el-timeline-item v-for="item in traces" :key="item.Id" :timestamp="item.EventTime">
          <strong>{{ item.OperationName }}</strong>
          <p class="muted">{{ item.Message }}</p>
        </el-timeline-item>
      </el-timeline>
    </SectionCard>

    <SectionCard title="当前工序上料">
      <el-table :data="loadingTasks" border size="small">
        <el-table-column prop="MaterialCode" label="元件料号" />
        <el-table-column prop="PackageType" label="BOM封装类型" />
        <el-table-column prop="MaterialPackageType" label="物料封装类型" />
        <el-table-column prop="Brand" label="品牌" />
        <el-table-column prop="RequiredQuantity" label="单板用量" />
        <el-table-column prop="LoadedQuantity" label="已上数量" />
        <el-table-column label="状态">
          <template #default="{ row }">
            <el-tag :type="verifyStatusType(row.VerifyStatus)">{{ verifyStatusText(row.VerifyStatus) }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </SectionCard>
  </div>
</template>
