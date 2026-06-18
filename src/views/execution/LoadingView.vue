<script setup>
import { computed, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { batches, fillBatchMaterial, getBatchLoadingSummary, getBatchLoadingTasks, getCurrentProcessStatus, validateBatchLoading } from '@/utils/mockData'

const router = useRouter()
const form = reactive({ batchId: '', materialCode: '', stationCode: 'F-001', loadedQty: 0, operator: '张工' })
const availableBatches = computed(() => batches.filter((item) => getCurrentProcessStatus(item.id) === 'wait_in'))
const currentBatch = computed(() => availableBatches.value.find((item) => item.id === form.batchId) || availableBatches.value[0] || null)
const tasks = computed(() => currentBatch.value ? getBatchLoadingTasks(currentBatch.value.id) : [])
const progress = computed(() => currentBatch.value ? getBatchLoadingSummary(currentBatch.value.id).percentage : 0)
const loadingValidation = computed(() => currentBatch.value ? validateBatchLoading(currentBatch.value.id) : { pass: false, missing: [], message: '暂无待上料批次' })
const selectedTask = computed(() => tasks.value.find((item) => item.station === form.stationCode) || tasks.value[0] || null)
const recentLoadingRecords = computed(() =>
  tasks.value
    .flatMap((item) =>
      (item.loadingRecords || []).map((record) => ({
        station: item.station,
        bomMaterial: item.material,
        ...record,
      }))
    )
    .sort((a, b) => String(b.loadedAt).localeCompare(String(a.loadedAt)))
)

watch(currentBatch, (batch) => {
  form.batchId = batch?.id || ''
}, { immediate: true })

async function submitLoading() {
  const target = tasks.value.find((item) => item.station === form.stationCode)
  if (!target) {
    await ElMessageBox.alert('站位码不存在，请确认当前批次与站位信息。', '提交失败', { type: 'error' })
    return
  }
  if (!form.materialCode.trim()) {
    await ElMessageBox.alert('请先输入物料条码或料号。', '提交失败', { type: 'error' })
    return
  }
  const result = fillBatchMaterial(currentBatch.value.id, {
    station: form.stationCode,
    materialCode: form.materialCode,
    loaded: Number(form.loadedQty) || target.required,
    loadedAt: '2026-05-20 15:10',
    operator: form.operator,
  })
  if (!result.ok) {
    await ElMessageBox.alert(result.message, '上料校验失败', { type: 'error' })
    return
  }
  const nextValidation = validateBatchLoading(currentBatch.value.id)
  ElMessage.success(nextValidation.pass ? '物料已齐套，请返回进站操作。' : `${target.station} 已补料，记录已保存。`)
  form.materialCode = ''
  form.loadedQty = Math.max(target.required - target.loaded, 0)
}

function autoFillTask(task) {
  form.stationCode = task.station
  form.materialCode = ''
  form.loadedQty = Math.max(task.required - task.loaded, 0)
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">上料管理</h1>
        <p class="page-subtitle">对待进站批次录入上料信息，首道进站时统一与 MDM BOM 做齐套校验。</p>
      </div>
      <div class="table-actions">
        <el-button @click="router.push('/execution/check-in')">返回进站操作</el-button>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="待上料批次">
        <el-table :data="availableBatches" border highlight-current-row row-key="id" :current-row-key="form.batchId" @row-click="(row) => form.batchId = row.id">
          <el-table-column prop="id" label="批次号" min-width="180" />
          <el-table-column prop="workOrderId" label="工单号" min-width="180" />
          <el-table-column prop="productModel" label="产品型号" min-width="160" />
          <el-table-column prop="line" label="产线" width="100" align="center" />
          <el-table-column label="上料完成率" width="120" align="center">
            <template #default="{ row }">{{ getBatchLoadingSummary(row.id).percentage }}%</template>
          </el-table-column>
        </el-table>
      </SectionCard>

      <template v-if="currentBatch">
        <SectionCard class="span-12" title="批次概览">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="当前批次">{{ currentBatch.id }}</el-descriptions-item>
            <el-descriptions-item label="产品型号">{{ currentBatch.productModel }}</el-descriptions-item>
            <el-descriptions-item label="当前工序">{{ currentBatch.currentStep }}</el-descriptions-item>
            <el-descriptions-item label="BOM 校验结果">
              <el-tag :type="loadingValidation.pass ? 'success' : 'warning'">{{ loadingValidation.pass ? '齐套' : '待补料' }}</el-tag>
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
          subtitle="点击待补料项可直接带入右侧补料录入区"
        >
          <el-table :data="tasks" border :row-class-name="({ row }) => row.loaded < row.required ? 'warning-row' : ''" @row-click="autoFillTask">
            <el-table-column prop="station" label="站位号" width="88" align="center" />
            <el-table-column prop="material" label="物料料号" min-width="130" />
            <el-table-column prop="spec" label="物料规格" min-width="160" />
            <el-table-column prop="packageType" label="封装" width="88" align="center" />
            <el-table-column prop="required" label="应上数量" width="96" align="center" />
            <el-table-column prop="loaded" label="已上数量" width="96" align="center" />
            <el-table-column label="待补数量" width="96" align="center">
              <template #default="{ row }">{{ Math.max(row.required - row.loaded, 0) }}</template>
            </el-table-column>
            <el-table-column prop="substitute" label="替代料信息" min-width="130" />
            <el-table-column prop="status" label="上料状态" width="104" align="center">
              <template #default="{ row }">
                <el-tag :type="row.loaded >= row.required ? 'success' : 'warning'">{{ row.loaded >= row.required ? '已齐套' : row.status }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </SectionCard>

        <SectionCard class="span-12" title="补料录入">
          <el-empty v-if="!selectedTask" description="请先选择一个待补料站位" />
          <template v-else>
            <el-form label-position="top" class="supply-form">
              <el-form-item label="补充物料条码">
                <el-input v-model="form.materialCode" size="large" :placeholder="`例如：${selectedTask.material}#LOT20260520-01`" />
              </el-form-item>
              <el-form-item label="补充数量">
                <el-input-number v-model="form.loadedQty" size="large" :min="0" :max="Math.max(selectedTask.required - selectedTask.loaded, 0)" />
              </el-form-item>
              <el-form-item label="补料人">
                <el-input v-model="form.operator" size="large" />
              </el-form-item>
              <div class="form-actions">
                <el-button type="primary" size="large" class="big-action" @click="submitLoading">保存上料</el-button>
              </div>
            </el-form>

            <div class="record-panel">
              <div class="record-title">最近补料记录</div>
              <el-empty v-if="!recentLoadingRecords.length" description="暂无补料记录" />
              <el-table v-else :data="recentLoadingRecords" border size="small">
                <el-table-column prop="station" label="站位" width="80" align="center" />
                <el-table-column prop="bomMaterial" label="BOM 物料" min-width="140" />
                <el-table-column prop="materialCode" label="补充物料条码" min-width="180" />
                <el-table-column prop="addedQty" label="补充数量" width="96" align="center" />
                <el-table-column prop="operator" label="补料人" width="88" align="center" />
                <el-table-column prop="loadedAt" label="补料时间" min-width="140" />
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
