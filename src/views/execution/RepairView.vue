<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import SectionCard from '@/components/SectionCard.vue'
import {
  REPAIR_STATUS_CODE,
  findBatch,
  findOperation,
  findRouteStep,
  getBatchLine,
  getBatchProduct,
  repairTasks,
  submitRepairResult,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'
import { getOperators } from '@/api/user'

const userStore = useUserStore()
const selected = ref(repairTasks[0] || null)
const form = reactive({
  RepairResult: 1,
  RepairedQuantity: selected.value?.RepairQuantity || 0,
  ScrapQuantity: 0,
  RepairDescription: '',
  Prevention: '',
  RepairBy: '',
})
const operatorList = ref([])

async function loadOperatorList() {
  try {
    const data = await getOperators()
    operatorList.value = Array.isArray(data) ? data : []
    const currentUsername = userStore.userInfo?.username || userStore.userInfo?.name
    const matchedUser = operatorList.value.find(u =>
      (u.username || u.Username) === currentUsername ||
      (u.fullName || u.FullName) === currentUsername
    )
    if (matchedUser) {
      form.RepairBy = matchedUser.id || matchedUser.Id
    } else if (operatorList.value.length) {
      form.RepairBy = operatorList.value[0].id || operatorList.value[0].Id
    }
  } catch (error) {
    console.error('Failed to load operator list:', error)
    operatorList.value = []
  }
}

function getOperatorLabel(user) {
  if (!user) return '-'
  const name = user.fullName || user.FullName || user.username || user.Username || ''
  const position = user.position || user.Position || ''
  const dept = user.department || user.Department || ''
  return [name, position, dept].filter(Boolean).join(' / ')
}

onMounted(() => {
  loadOperatorList()
})
const canManageRepair = computed(() => userStore.hasAnyRole(['QUALITY_ENGINEER']))

function getRepairBatch(task) {
  return findBatch(task?.LotId)
}

function getRepairOperation(task) {
  const step = findRouteStep(task?.RouteStepId)
  return findOperation(step?.OperationId)
}

watch(selected, (task) => {
  if (!task) return
  form.RepairResult = 1
  form.RepairedQuantity = task.RepairQuantity || 0
  form.ScrapQuantity = 0
  form.RepairDescription = task.RepairDescription || ''
  form.Prevention = ''
})

function submitRepair() {
  if (!selected.value) {
    ElMessage.error('当前没有维修任务')
    return
  }
  if (!canManageRepair.value) {
    ElMessage.error('当前角色只能查看维修记录，质量工程师可提交维修处理结果')
    return
  }
  const batch = getRepairBatch(selected.value)
  const result = submitRepairResult(batch.LotCode, {
    RepairResult: form.RepairResult,
    result: form.RepairResult === 1 ? 'repair_pass' : 'close',
    RepairedQuantity: form.RepairedQuantity,
    ScrapQuantity: form.ScrapQuantity,
    RepairBy: Number(form.RepairBy),
    RepairEndTime: '2026-05-20 15:20',
  })
  if (!result.ok) {
    ElMessage.error(result.message)
    return
  }
  ElMessage.success(form.RepairResult === 1 ? '维修完成，批次已返回待进站。' : '维修结束，批次已关闭。')
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">维修管理</h1>
        <p class="page-subtitle">维修任务按 smt_repair_records 字段展示和提交，批次、产品、产线通过关联查询获得。</p>
      </div>
    </div>

    <div class="stat-cards">
      <MetricCard title="待维修任务" :value="repairTasks.filter((item) => item.Status !== REPAIR_STATUS_CODE.completed).length" unit="批" tone="danger" />
      <MetricCard title="已完成维修" :value="repairTasks.filter((item) => item.Status === REPAIR_STATUS_CODE.completed).length" unit="批" tone="success" />
    </div>

    <div class="content-grid">
      <SectionCard class="span-12" title="维修任务列表">
        <el-table :data="repairTasks" border highlight-current-row @current-change="selected = $event">
          <el-table-column label="批次号" min-width="160" align="center">
            <template #default="{ row }">{{ getRepairBatch(row)?.LotCode || '-' }}</template>
          </el-table-column>
          <el-table-column label="产品型号" align="center" min-width="160">
            <template #default="{ row }">{{ getBatchProduct(getRepairBatch(row))?.Model || '-' }}</template>
          </el-table-column>
          <el-table-column label="产线" align="center" min-width="160">
            <template #default="{ row }">{{ getBatchLine(getRepairBatch(row))?.LineCode || '-' }}</template>
          </el-table-column>
          <el-table-column label="工序" align="center" min-width="160">
            <template #default="{ row }">{{ getRepairOperation(row)?.OperationName || '-' }}</template>
          </el-table-column>
          <el-table-column prop="RepairQuantity" label="送修数量" align="center"/>
          <el-table-column prop="Status" label="状态" align="center"/>
        </el-table>
      </SectionCard>

      <SectionCard class="span-12" title="维修处理">
        <el-empty v-if="!selected" description="暂无维修任务" />
        <template v-else>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="当前批次">{{ getRepairBatch(selected)?.LotCode }}</el-descriptions-item>
            <el-descriptions-item label="工序">{{ getRepairOperation(selected)?.OperationName }}</el-descriptions-item>
            <el-descriptions-item label="送修数量">{{ selected.RepairQuantity }}</el-descriptions-item>
          </el-descriptions>
          <el-form :model="form" label-width="110px" class="repair-form">
            <el-form-item label="处理结果">
              <el-select v-model="form.RepairResult" class="full">
                <el-option label="维修合格回流" :value="1" />
                <el-option label="转报废关闭" :value="2" />
              </el-select>
            </el-form-item>
            <el-form-item label="维修数量"><el-input-number v-model="form.RepairedQuantity" :min="0" /></el-form-item>
            <el-form-item label="报废数量"><el-input-number v-model="form.ScrapQuantity" :min="0" /></el-form-item>
            <el-form-item label="维修人">
              <el-select v-model="form.RepairBy" filterable placeholder="请选择维修人" class="full">
                <el-option v-for="user in operatorList" :key="user.id || user.Id" :label="getOperatorLabel(user)" :value="user.id || user.Id" />
              </el-select>
            </el-form-item>
            <el-form-item label="原因分析"><el-input v-model="form.RepairDescription" type="textarea" /></el-form-item>
            <el-form-item label="预防措施"><el-input v-model="form.Prevention" type="textarea" /></el-form-item>
          </el-form>
          <div class="table-actions">
            <el-button type="primary" :disabled="!canManageRepair" @click="submitRepair">提交维修结果</el-button>
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
