<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import SectionCard from '@/components/SectionCard.vue'
import { repairTasks, submitRepairResult } from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const selected = ref(repairTasks[0] || null)
const form = reactive({
  result: 'repair_pass',
  repairQty: selected.value?.badQty || 0,
  scrapQty: 0,
  reason: '',
  prevention: '',
  repairman: userStore.userInfo.name || '维修员',
})
const canAudit = computed(() => userStore.hasAnyRole(['quality_engineer', 'production_manager']))

watch(selected, (task) => {
  if (!task) return
  form.result = 'repair_pass'
  form.repairQty = task.badQty || 0
  form.scrapQty = 0
  form.reason = ''
  form.prevention = ''
})

function submitRepair() {
  if (!selected.value) {
    ElMessage.error('当前没有维修任务')
    return
  }
  if (!canAudit.value) {
    ElMessage.error('当前角色不能提交维修结果')
    return
  }
  const result = submitRepairResult(selected.value.batchId, {
    result: form.result,
    repairQty: form.repairQty,
    scrapQty: form.scrapQty,
    completedAt: '2026-05-20 15:20',
  })
  if (!result.ok) {
    ElMessage.error(result.message)
    return
  }
  ElMessage.success(form.result === 'repair_pass' ? '维修完成，批次已返回待进站。' : '维修结束，批次已关闭。')
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">维修管理</h1>
        <p class="page-subtitle">承接出站生成的维修任务，完成处理后让批次回流或关闭。</p>
      </div>
    </div>

    <div class="stat-cards">
      <MetricCard title="待维修任务" :value="repairTasks.filter((item) => item.status !== '已完成').length" unit="批" tone="danger" />
      <MetricCard title="已完成维修" :value="repairTasks.filter((item) => item.status === '已完成').length" unit="批" tone="success" />
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="维修任务列表">
        <el-table :data="repairTasks" border highlight-current-row @current-change="selected = $event">
          <el-table-column prop="batchId" label="批次号" min-width="160" />
          <el-table-column prop="productModel" label="产品型号" />
          <el-table-column prop="line" label="产线" />
          <el-table-column prop="process" label="工序" />
          <el-table-column prop="badQty" label="不良数量" />
          <el-table-column prop="status" label="状态" />
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="维修处理">
        <el-empty v-if="!selected" description="暂无维修任务" />
        <template v-else>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="当前批次">{{ selected.batchId }}</el-descriptions-item>
            <el-descriptions-item label="工序">{{ selected.process }}</el-descriptions-item>
            <el-descriptions-item label="不良数量">{{ selected.badQty }}</el-descriptions-item>
          </el-descriptions>
          <el-form :model="form" label-width="100px" class="repair-form">
            <el-form-item label="处理结果">
              <el-select v-model="form.result" class="full">
                <el-option label="维修合格回流" value="repair_pass" />
                <el-option label="转报废关闭" value="close" />
              </el-select>
            </el-form-item>
            <el-form-item label="维修数量"><el-input-number v-model="form.repairQty" :min="0" /></el-form-item>
            <el-form-item label="报废数量"><el-input-number v-model="form.scrapQty" :min="0" /></el-form-item>
            <el-form-item label="原因分析"><el-input v-model="form.reason" type="textarea" /></el-form-item>
            <el-form-item label="预防措施"><el-input v-model="form.prevention" type="textarea" /></el-form-item>
          </el-form>
          <div class="table-actions">
            <el-button type="primary" @click="submitRepair">提交维修结果</el-button>
          </div>
        </template>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.full {
  width: 100%;
}

.repair-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px 24px;
  margin-top: 18px;
}

.repair-form :deep(.el-form-item) {
  margin-bottom: 0;
}

@media (max-width: 900px) {
  .repair-form {
    grid-template-columns: 1fr;
  }
}
</style>
