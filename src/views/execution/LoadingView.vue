<script setup>
import { computed, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import {
  PROCESS_STATUS_CODE,
  VERIFY_STATUS_CODE,
  batches,
  fillBatchMaterial,
  findUser,
  getBatchLine,
  getBatchLoadingSummary,
  getBatchLoadingTasks,
  getBatchProduct,
  getBatchWorkOrder,
  getCurrentOperationName,
  getCurrentProcessStatus,
  getUserDisplayName,
  getUserOptionLabel,
  users,
  validateBatchLoading,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const form = reactive({
  LotCode: '',
  MaterialCode: '',
  StationCode: 'F-001',
  ActualQuantity: 0,
  OperatorId: findUser(userStore.userInfo.username || userStore.userInfo.name)?.Id || 3,
})
const availableBatches = computed(() => batches.filter((item) => getCurrentProcessStatus(item.LotCode) === PROCESS_STATUS_CODE.wait_in))
const currentBatch = computed(() => availableBatches.value.find((item) => item.LotCode === form.LotCode) || availableBatches.value[0] || null)
const tasks = computed(() => currentBatch.value ? getBatchLoadingTasks(currentBatch.value.LotCode) : [])
const progress = computed(() => currentBatch.value ? getBatchLoadingSummary(currentBatch.value.LotCode).Percentage : 0)
const loadingValidation = computed(() => currentBatch.value ? validateBatchLoading(currentBatch.value.LotCode) : { pass: false, missing: [], message: '暂无待上料批次' })
const bomVerifyStatus = computed(() => {
  if (!tasks.value.length || tasks.value.some((item) => item.VerifyStatus === VERIFY_STATUS_CODE.pending)) {
    return { label: '未校验', type: 'info' }
  }
  if (tasks.value.some((item) => item.VerifyStatus === VERIFY_STATUS_CODE.failed)) {
    return { label: '校验失败', type: 'danger' }
  }
  return { label: '校验通过', type: 'success' }
})
const selectedTask = computed(() => tasks.value.find((item) => item.StationCode === form.StationCode) || tasks.value[0] || null)
const recentLoadingRecords = computed(() =>
  tasks.value
    .flatMap((item) =>
      (item.LoadingRecords || []).map((record) => ({
        StationCode: item.StationCode,
        BomMaterialCode: item.MaterialCode,
        ...record,
      }))
    )
    .sort((a, b) => String(b.LoadingTime).localeCompare(String(a.LoadingTime)))
)

watch(currentBatch, (batch) => {
  form.LotCode = batch?.LotCode || ''
}, { immediate: true })

async function submitLoading() {
  const target = tasks.value.find((item) => item.StationCode === form.StationCode)
  if (!target) {
    await ElMessageBox.alert('站位码不存在，请确认当前批次与站位信息。', '提交失败', { type: 'error' })
    return
  }
  if (!form.MaterialCode.trim()) {
    await ElMessageBox.alert('请先输入物料条码或料号。', '提交失败', { type: 'error' })
    return
  }
  const result = fillBatchMaterial(currentBatch.value.LotCode, {
    StationCode: form.StationCode,
    MaterialCode: form.MaterialCode,
    ActualQuantity: Number(form.ActualQuantity) || target.RequiredQuantity,
    LoadingTime: '2026-05-20 15:10',
    OperatorId: Number(form.OperatorId),
  })
  if (!result.ok) {
    await ElMessageBox.alert(result.message, '上料校验失败', { type: 'error' })
    return
  }
  const nextValidation = validateBatchLoading(currentBatch.value.LotCode)
  ElMessage.success(nextValidation.pass ? '物料已齐套，请返回进站操作。' : `${target.StationCode} 已补料，记录已保存。`)
  form.MaterialCode = ''
  form.ActualQuantity = Math.max(target.RequiredQuantity - target.LoadedQuantity, 0)
}

function autoFillTask(task) {
  form.StationCode = task.StationCode
  form.MaterialCode = task.MaterialCode || ''
  form.ActualQuantity = Math.max(task.RequiredQuantity - task.LoadedQuantity, 0)
}

function verifyStatusMeta(status) {
  if (status === VERIFY_STATUS_CODE.passed) return { label: '校验通过', type: 'success' }
  if (status === VERIFY_STATUS_CODE.failed) return { label: '校验失败', type: 'danger' }
  return { label: '未校验', type: 'info' }
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">上料管理</h1>
        <p class="page-subtitle">页面展示 BOM 齐套任务，保存时写入 smt_loading_records 标准字段。</p>
      </div>
      <div class="table-actions">
        <el-button @click="router.push('/execution/check-in')">返回进站操作</el-button>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="待上料批次">
        <el-table :data="availableBatches" border highlight-current-row row-key="LotCode" :current-row-key="form.LotCode" @row-click="(row) => form.LotCode = row.LotCode">
          <el-table-column prop="LotCode" label="批次号" min-width="180" />
          <el-table-column label="工单号" min-width="180">
            <template #default="{ row }">{{ getBatchWorkOrder(row)?.WorkOrderCode || '-' }}</template>
          </el-table-column>
          <el-table-column label="产品名称" min-width="180">
            <template #default="{ row }">{{ getBatchProduct(row)?.ProductName || '-' }}</template>
          </el-table-column>
          <el-table-column label="产线" width="180" align="center">
            <template #default="{ row }">{{ getBatchLine(row)?.LineCode || '-' }}</template>
          </el-table-column>
          <el-table-column label="上料完成率" width="180" align="center">
            <template #default="{ row }">{{ getBatchLoadingSummary(row.LotCode).Percentage }}%</template>
          </el-table-column>
        </el-table>
      </SectionCard>

      <template v-if="currentBatch">
        <SectionCard class="span-12" title="批次概览">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="当前批次">{{ currentBatch.LotCode }}</el-descriptions-item>
            <el-descriptions-item label="产品名称">{{ getBatchProduct(currentBatch)?.ProductName }}</el-descriptions-item>
            <el-descriptions-item label="当前工序">{{ getCurrentOperationName(currentBatch) }}</el-descriptions-item>
            <el-descriptions-item label="BOM 校验结果">
              <el-tag :type="bomVerifyStatus.type">{{ bomVerifyStatus.label }}</el-tag>
            </el-descriptions-item>
          </el-descriptions>

          <div class="progress-box">
            <span>上料完成率</span>
            <el-progress :percentage="progress" :stroke-width="12" />
          </div>
        </SectionCard>

        <SectionCard
          class="span-12"
          title="批次 BOM 上料完整清单"
          subtitle="由 BOM 明细和上料记录组合生成，非独立数据库表字段"
        >
          <el-table :data="tasks" border :row-class-name="({ row }) => row.LoadedQuantity < row.RequiredQuantity ? 'warning-row' : ''" @row-click="autoFillTask">
            <el-table-column prop="MaterialCode" label="元件料号" min-width="130" />
            <el-table-column prop="PackageType" label="BOM封装类型" min-width="110" />
            <el-table-column prop="MaterialPackageType" label="物料封装类型" min-width="120" />
            <el-table-column prop="Brand" label="品牌" min-width="100" />
            <el-table-column prop="RequiredQuantity" label="单板用量" width="96" align="center" />
            <el-table-column prop="LoadedQuantity" label="已上数量" width="96" align="center" />
            <el-table-column label="待补数量" width="96" align="center">
              <template #default="{ row }">{{ Math.max(row.RequiredQuantity - row.LoadedQuantity, 0) }}</template>
            </el-table-column>
            <el-table-column label="状态" width="104" align="center">
              <template #default="{ row }">
                <el-tag :type="verifyStatusMeta(row.VerifyStatus).type">{{ verifyStatusMeta(row.VerifyStatus).label }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </SectionCard>

        <SectionCard class="span-12" title="补料录入">
          <el-empty v-if="!selectedTask" description="请先选择一个待补料站位" />
          <template v-else>
            <el-form label-position="top" class="supply-form">
              <el-form-item label="元件料号">
                <el-input v-model="form.MaterialCode" size="large" :placeholder="selectedTask.MaterialCode" />
              </el-form-item>
              <el-form-item label="补充数量">
                <el-input-number v-model="form.ActualQuantity" size="large" :min="0" :max="Math.max(selectedTask.RequiredQuantity - selectedTask.LoadedQuantity, 0)" />
              </el-form-item>
              <el-form-item label="操作人">
                <el-select v-model="form.OperatorId" filterable size="large" placeholder="请选择操作人">
                  <el-option v-for="user in users" :key="user.Id" :label="getUserOptionLabel(user)" :value="user.Id" />
                </el-select>
              </el-form-item>
              <div class="form-actions">
                <el-button type="primary" size="large" class="big-action" @click="submitLoading">保存上料</el-button>
              </div>
            </el-form>

            <div class="record-panel">
              <div class="record-title">最近补料记录</div>
              <el-empty v-if="!recentLoadingRecords.length" description="暂无补料记录" />
              <el-table v-else :data="recentLoadingRecords" border size="small">
                <el-table-column prop="BomMaterialCode" label="元件料号" min-width="160" />
                <el-table-column prop="ActualQuantity" label="补充数量" width="96" align="center" />
                <el-table-column label="操作人" width="150" align="center">
                  <template #default="{ row }">{{ getUserDisplayName(row.OperatorId) }}</template>
                </el-table-column>
                <el-table-column prop="LoadingTime" label="补料时间" min-width="140" />
              </el-table>
            </div>
          </template>
        </SectionCard>
      </template>
    </div>
  </div>
</template>

<style scoped>
.progress-box {
  margin: 18px 0;
}

.supply-form {
  display: grid;
  grid-template-columns: minmax(0, 1.8fr) minmax(220px, 0.8fr) minmax(220px, 1fr);
  gap: 18px 24px;
  align-items: end;
}

.supply-form :deep(.el-form-item) {
  margin-bottom: 0;
}

.form-actions {
  grid-column: 1 / -1;
  display: flex;
  justify-content: flex-end;
}

.record-panel {
  margin-top: 18px;
}

.record-title {
  margin-bottom: 10px;
  color: var(--rtm-text);
  font-size: 14px;
  font-weight: 700;
}

@media (max-width: 900px) {
  .supply-form {
    grid-template-columns: 1fr;
  }

  .form-actions {
    justify-content: flex-start;
  }
}
</style>
