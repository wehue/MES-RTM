<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { useUserStore } from '@/stores/user'
import { getOperators } from '@/api/user'
import { getPendingLoadingList, getBatchDetail } from '@/api/batch'

const router = useRouter()
const userStore = useUserStore()
const form = reactive({
  LotCode: '',
  MaterialCode: '',
  ActualQuantity: 0,
  OperatorId: '',
})
const operatorList = ref([])
// 待上料批次列表（来自后端 /api/lots/pending-loading/list）
const pendingLoadingList = ref([])
const listLoading = ref(false)
const listPagination = reactive({ pageNum: 1, pageSize: 5, total: 0 })
// 当前选中批次的详情（来自后端 /api/lots/detail）
const batchDetail = ref(null)
const detailLoading = ref(false)

async function loadPendingLoadingList() {
  listLoading.value = true
  try {
    const data = await getPendingLoadingList()
    pendingLoadingList.value = Array.isArray(data) ? data : []
    listPagination.total = pendingLoadingList.value.length
    // 若当前列表有数据但还没选中批次，自动选中第一条
    if (!form.LotCode && pendingLoadingList.value.length) {
      form.LotCode = pendingLoadingList.value[0].lotCode
    }
  } catch (error) {
    console.error('Failed to load pending loading list:', error)
    pendingLoadingList.value = []
    listPagination.total = 0
  } finally {
    listLoading.value = false
  }
}

function handlePageChange(pageNum) {
  listPagination.pageNum = pageNum
}

function handleSizeChange(pageSize) {
  listPagination.pageSize = pageSize
  listPagination.pageNum = 1
}

// 当前页（前端切片）
const pagedList = computed(() => {
  const start = (listPagination.pageNum - 1) * listPagination.pageSize
  const end = start + listPagination.pageSize
  return pendingLoadingList.value.slice(start, end)
})

// 根据批次 ID 拉取详情（含当前工序的上料清单 operationMaterials）
async function loadBatchDetail(lotId) {
  if (!lotId) {
    batchDetail.value = null
    return
  }
  detailLoading.value = true
  try {
    const data = await getBatchDetail(lotId)
    batchDetail.value = data || null
  } catch (error) {
    console.error('Failed to load batch detail:', error)
    batchDetail.value = null
  } finally {
    detailLoading.value = false
  }
}

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
      form.OperatorId = matchedUser.id || matchedUser.Id
    } else if (operatorList.value.length) {
      form.OperatorId = operatorList.value[0].id || operatorList.value[0].Id
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

onMounted(async () => {
  await loadOperatorList()
  await loadPendingLoadingList()
})

// 当前选中批次（从 pending-loading 列表中匹配）
const currentBatch = computed(() => {
  if (form.LotCode) {
    const matched = pendingLoadingList.value.find(item => item.lotCode === form.LotCode)
    if (matched) return matched
  }
  return pendingLoadingList.value[0] || null
})
// 当前工序的上料清单（来自后端 operationMaterials）
const tasks = computed(() => (Array.isArray(batchDetail.value?.operationMaterials) ? batchDetail.value.operationMaterials : []))
// 当前工序的上料完成率（先取 pending-loading 列表里的百分比；没有则按清单自行推算）
const progress = computed(() => {
  if (currentBatch.value?.loadingCompletionRate !== undefined && currentBatch.value?.loadingCompletionRate !== null) {
    return Math.round(Number(currentBatch.value.loadingCompletionRate) || 0)
  }
  if (!tasks.value.length) return 0
  const ok = tasks.value.filter(item => Number(item.verifyStatus) === 1).length
  return Math.round((ok / tasks.value.length) * 100)
})
// BOM 校验结果（优先用 pending-loading 的 bomVerifyResult；否则用 tasks 里的 verifyStatus 汇总）
const bomVerifyStatus = computed(() => {
  const result = currentBatch.value?.bomVerifyResult
  if (result === 1) return { label: '校验通过', type: 'success' }
  if (result === 2) return { label: '校验失败', type: 'danger' }
  if (!tasks.value.length) return { label: '未校验', type: 'info' }
  if (tasks.value.some(item => Number(item.verifyStatus) === 2)) return { label: '校验失败', type: 'danger' }
  if (tasks.value.every(item => Number(item.verifyStatus) === 1)) return { label: '校验通过', type: 'success' }
  return { label: '未校验', type: 'info' }
})

// 当前选中的补料站位（某个物料）
const selectedTask = ref(null)

function verifyStatusMeta(status) {
  if (Number(status) === 1) return { label: '校验通过', type: 'success' }
  if (Number(status) === 2) return { label: '校验失败', type: 'danger' }
  return { label: '未校验', type: 'info' }
}

function remainingQty(row) {
  const bom = Number(row.bomQuantity) || 0
  const loaded = Number(row.actualQuantity) || 0
  return Math.max(bom - loaded, 0)
}

// 点击表格行 → 预填补料表单
function autoFillTask(task) {
  form.MaterialCode = task.materialCode || ''
  form.ActualQuantity = remainingQty(task)
  selectedTask.value = task
}

// 当批次号变化 → 拉取该批次的详情（含上料清单）
watch(() => form.LotCode, async (lotCode, prevLotCode) => {
  selectedTask.value = null
  form.MaterialCode = ''
  form.ActualQuantity = 0
  if (!lotCode) {
    batchDetail.value = null
    return
  }
  const matched = pendingLoadingList.value.find(item => item.lotCode === lotCode)
  await loadBatchDetail(matched?.lotId)
}, { immediate: true })

// pending-loading 列表首次回来时，自动选中第一条
watch(pendingLoadingList, (list, oldList) => {
  if (!oldList?.length && list?.length && !form.LotCode) {
    form.LotCode = list[0].lotCode
  }
}, { immediate: true })

async function submitLoading() {
  if (!selectedTask.value) {
    await ElMessageBox.alert('请先在上方清单中选择一个需要补料的物料。', '提交失败', { type: 'error' })
    return
  }
  if (!form.MaterialCode.trim()) {
    await ElMessageBox.alert('请先输入物料条码或料号。', '提交失败', { type: 'error' })
    return
  }
  if (!Number(form.ActualQuantity) || Number(form.ActualQuantity) <= 0) {
    await ElMessageBox.alert('补充数量必须大于 0。', '提交失败', { type: 'error' })
    return
  }
  // 注意：当前后端没有专门的「新增上料记录」接口，这里仅把本次录入的数量累加到当前选中行的 actualQuantity，
  // 以反馈录入成功；真正写入 smt_loading_records 需由后端补充对应的 POST 接口后再替换此处逻辑。
  const add = Number(form.ActualQuantity)
  const totalNeeded = Number(selectedTask.value.bomQuantity) || 0
  const currentLoaded = Number(selectedTask.value.actualQuantity) || 0
  const next = Math.min(currentLoaded + add, totalNeeded)
  selectedTask.value.actualQuantity = next
  if (next >= totalNeeded) selectedTask.value.verifyStatus = 1
  ElMessage.success(`物料 ${selectedTask.value.materialCode} 已记录补料 ${add}。`)
  form.MaterialCode = ''
  form.ActualQuantity = Math.max(totalNeeded - next, 0)
  // 刷新顶部「待上料批次」列表（展示最新校验状态）
  await loadPendingLoadingList()
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
      <SectionCard class="span-12" title="待上料批次列表">
        <el-table
          v-loading="listLoading"
          :data="pagedList"
          border
          highlight-current-row
          row-key="lotCode"
          :current-row-key="form.LotCode"
          @row-click="(row) => form.LotCode = row.lotCode"
        >
          <el-table-column prop="lotCode" label="批次号" min-width="180" align="center"/>
          <el-table-column prop="workOrderCode" label="工单号" min-width="180" align="center"/>
          <el-table-column prop="productName" label="产品名称" min-width="180" align="center"/>
          <el-table-column prop="lineName" label="产线" width="220" align="center" />
          <el-table-column label="上料完成率" width="250" align="center">
            <template #default="{ row }">
              <el-progress :percentage="Number(row.loadingCompletionRate) || 0" :stroke-width="8" />
            </template>
          </el-table-column>
        </el-table>
        <div class="table-pagination">
          <el-pagination
            v-model:current-page="listPagination.pageNum"
            v-model:page-size="listPagination.pageSize"
            :page-sizes="[5, 10, 20, 50]"
            :total="listPagination.total"
            layout="total, sizes, prev, pager, next, jumper"
            @current-change="handlePageChange"
            @size-change="handleSizeChange"
          />
        </div>
      </SectionCard>

      <template v-if="currentBatch">
        <SectionCard class="span-12" title="批次概览">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="当前批次">{{ currentBatch.lotCode }}</el-descriptions-item>
            <el-descriptions-item label="产品名称">{{ currentBatch.productName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="当前工序">{{ currentBatch.currentOperation || '-' }}</el-descriptions-item>
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
          subtitle="由 smt_bom_items、smt_materials 与 smt_loading_records 汇总生成"
        >
          <el-table
            v-loading="detailLoading"
            :data="tasks"
            border
            :row-class-name="({ row }) => Number(row.actualQuantity) < Number(row.bomQuantity) ? 'warning-row' : ''"
            @row-click="autoFillTask"
          >
            <el-table-column prop="materialCode" label="元件料号" min-width="120" align="center"/>
            <el-table-column prop="bomPackageType" label="BOM 封装类型" min-width="120" align="center"/>
            <el-table-column prop="materialPackageType" label="物料封装类型" min-width="120" align="center"/>
            <el-table-column prop="brand" label="品牌" min-width="110" align="center"/>
            <el-table-column label="单板用量" width="120" align="center">
              <template #default="{ row }">{{ row.bomQuantity }}</template>
            </el-table-column>
            <el-table-column label="已上数量" width="120" align="center">
              <template #default="{ row }">{{ row.actualQuantity }}</template>
            </el-table-column>
            <el-table-column label="待补数量" width="120" align="center">
              <template #default="{ row }">{{ remainingQty(row) }}</template>
            </el-table-column>
            <el-table-column label="校验状态" width="130" align="center">
              <template #default="{ row }">
                <el-tag :type="verifyStatusMeta(row.verifyStatus).type">{{ verifyStatusMeta(row.verifyStatus).label }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </SectionCard>

        <SectionCard class="span-12" title="上料录入">
          <el-empty v-if="!tasks.length" description="当前批次无 BOM 上料任务" />
          <el-empty v-else-if="!selectedTask" description="请先在上方清单中选择一个需要上料的物料" />
          <template v-else>
            <el-form label-position="top" class="supply-form">
              <el-form-item label="元件料号">
                <el-input v-model="form.MaterialCode" size="large" :placeholder="selectedTask.materialCode" />
              </el-form-item>
              <el-form-item label="补充数量">
                <el-input-number v-model="form.ActualQuantity" size="large" :min="0" :max="remainingQty(selectedTask)" />
              </el-form-item>
              <el-form-item label="操作人">
                <el-select v-model="form.OperatorId" filterable size="large" placeholder="请选择操作人">
                  <el-option v-for="user in operatorList" :key="user.id || user.Id" :label="getOperatorLabel(user)" :value="user.id || user.Id" />
                </el-select>
              </el-form-item>
              <div class="form-actions">
                <el-button type="primary" size="large" class="big-action" @click="submitLoading">保存上料</el-button>
              </div>
            </el-form>
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

.table-pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
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
