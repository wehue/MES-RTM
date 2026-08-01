<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Box,
  Download,
  Goods,
  Top,
} from '@element-plus/icons-vue'
import SectionCard from '@/components/SectionCard.vue'
import { getOperators } from '@/api/user'
import {
  createUnloading,
  getStationUnloadableRecords as getStationUnloadableRecordsApi,
  getStationHistory as getStationHistoryApi,
} from '@/api/unloading'
import {
  findStation,
  findOperation,
  findEquipment,
  findEquipmentType,
  routeSteps,
  users,
  UNLOAD_REASON,
  UNLOAD_REASON_TEXT,
  getStationUnloadableRecords,
  getUnloadableQuantity,
  addUnloadingRecord,
  getStationLoadingAndUnloadingHistory,
} from '@/utils/mockData'
import { useUserStore } from '@/stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// ==================== Tab 切换 ====================
const activeTab = ref('unloading')

// ==================== 操作人列表 ====================
const operatorList = ref([])

function buildMockOperatorList() {
  return users.map((u) => ({
    id: u.Id,
    Id: u.Id,
    username: u.Username,
    Username: u.Username,
    fullName: u.FullName,
    FullName: u.FullName,
    position: u.Position,
    Position: u.Position,
    department: u.Department,
    Department: u.Department,
  }))
}

async function loadOperatorList() {
  try {
    const data = await getOperators()
    operatorList.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.warn('[Unloading] API 获取操作人列表失败，使用 Mock 数据：', error)
    operatorList.value = buildMockOperatorList()
  }
}

function getOperatorLabel(user) {
  if (!user) return '-'
  const name = user.fullName || user.FullName || user.username || user.Username || ''
  const position = user.position || user.Position || ''
  const dept = user.department || user.Department || ''
  return [name, position, dept].filter(Boolean).join(' / ')
}

// ==================== 工站列表 ====================
const selectedStationId = ref(null)

const stationList = computed(() => {
  return routeSteps
    .slice()
    .sort((a, b) => a.Sequence - b.Sequence)
    .map((step) => {
      const station = findStation(step.StationId)
      const operation = findOperation(step.OperationId)
      const equip = findEquipment(step.EquipmentId)
      const equipType = findEquipmentType(step.EquipmentTypeId)
      return {
        routeStepId: step.Id,
        stationId: step.StationId,
        equipmentId: step.EquipmentId,
        equipmentTypeId: step.EquipmentTypeId,
        sequence: step.Sequence,
        stationCode: station?.StationCode || '-',
        stationName: station?.StationName || '-',
        operationName: operation?.OperationName || '-',
        equipmentCode: equip?.EquipmentCode || '-',
        equipmentName: equip?.EquipmentName || '-',
        equipmentTypeName: equipType?.EquipmentTypeName || '-',
      }
    })
})

const currentStation = computed(() => {
  if (!selectedStationId.value) return null
  return stationList.value.find((s) => s.routeStepId === selectedStationId.value) || null
})

// ==================== Tab 1: 下料操作 ====================
const unloadableList = ref([])
const unloadableLoading = ref(false)
const selectedLoadingRecordIds = ref([])

// 下料表单（字段对齐数据库 smt_unloading_records）
const unloadForm = reactive({
  unloadQuantity: 0,
  reasonCode: '',        // 对应数据库 Reason tinyint: 1-4
  remark: '',            // 对应数据库 Remark varchar(200)
  operatorId: '',
})
const submitting = ref(false)

// 下料原因下拉选项（对齐数据库 1-4 枚举）
const unloadReasonOptions = Object.values(UNLOAD_REASON).map((item) => ({
  value: item.code,
  label: item.label,
}))

async function loadUnloadableList() {
  if (!currentStation.value) {
    unloadableList.value = []
    return
  }
  unloadableLoading.value = true
  try {
    const params = {
      routeStepId: currentStation.value.routeStepId,
      stationId: currentStation.value.stationId,
    }
    const data = await getStationUnloadableRecordsApi(params)
    unloadableList.value = Array.isArray(data) ? data : (data?.records || data?.list || [])
  } catch (error) {
    console.warn('[Unloading] API 获取工站可下料记录失败，使用 Mock 数据：', error)
    unloadableList.value = getStationUnloadableRecords(currentStation.value.routeStepId)
  } finally {
    unloadableLoading.value = false
  }
}

// 当选中的上料记录变化时，自动汇总下料数量
const selectedRecords = computed(() =>
  unloadableList.value.filter((rec) => selectedLoadingRecordIds.value.includes(rec.Id)),
)

const totalUnloadableQuantity = computed(() =>
  selectedRecords.value.reduce((sum, rec) => sum + (rec.UnloadableQuantity || 0), 0),
)

function handleSelectionChange(ids) {
  selectedLoadingRecordIds.value = ids
  // 默认填入全部可下料数量
  const total = selectedRecords.value.reduce((sum, rec) => sum + (rec.UnloadableQuantity || 0), 0)
  unloadForm.unloadQuantity = total
}

function handleRecordSelect(rec) {
  const idx = selectedLoadingRecordIds.value.indexOf(rec.Id)
  if (idx >= 0) {
    selectedLoadingRecordIds.value.splice(idx, 1)
  } else {
    selectedLoadingRecordIds.value.push(rec.Id)
  }
  const total = selectedRecords.value.reduce((sum, r) => sum + (r.UnloadableQuantity || 0), 0)
  unloadForm.unloadQuantity = total
}

function isRecordSelected(rec) {
  return selectedLoadingRecordIds.value.includes(rec.Id)
}

function clampUnloadQuantity(value) {
  return Math.max(0, Math.min(Number(value) || 0, totalUnloadableQuantity.value))
}

function syncUnloadQuantity(value) {
  unloadForm.unloadQuantity = clampUnloadQuantity(value)
}

async function submitUnloading() {
  if (!selectedLoadingRecordIds.value.length) {
    ElMessage.warning('请先选择待下料的上料记录')
    return
  }
  if (!currentStation.value) {
    ElMessage.warning('请先选择工站')
    return
  }
  if (!unloadForm.unloadQuantity || unloadForm.unloadQuantity <= 0) {
    ElMessage.error('下料数量必须大于 0')
    return
  }
  if (unloadForm.unloadQuantity > totalUnloadableQuantity.value) {
    ElMessage.error(`下料数量不能超过可下料数量（${totalUnloadableQuantity.value}）`)
    return
  }
  const reasonCode = Number(unloadForm.reasonCode)
  if (![1, 2, 3, 4].includes(reasonCode)) {
    ElMessage.error('请选择下料原因')
    return
  }
  // "4-其他"原因必须填写备注
  const finalRemark = String(unloadForm.remark || '').trim()
  if (reasonCode === 4 && !finalRemark) {
    ElMessage.error('选择"其他"原因时必须填写备注说明具体原因')
    return
  }
  if (!unloadForm.operatorId) {
    ElMessage.error('请选择操作人')
    return
  }

  submitting.value = true

  // 多条记录时按比例分配下料数量；单条直接使用输入值
  const records = selectedRecords.value
  const totalQty = unloadForm.unloadQuantity

  let successCount = 0
  let failCount = 0
  let allocated = 0

  for (let i = 0; i < records.length; i++) {
    const rec = records[i]
    const isLast = i === records.length - 1
    const qty = isLast
      ? totalQty - allocated
      : Math.min(rec.UnloadableQuantity, Math.floor((totalQty * rec.UnloadableQuantity) / totalUnloadableQuantity.value))
    allocated += qty
    if (qty <= 0) continue

    // payload 字段对齐数据库 smt_unloading_records
    const payload = {
      loadingRecordId: rec.Id,
      unloadQuantity: qty,
      reasonCode,
      remark: finalRemark,
      operatorId: Number(unloadForm.operatorId),
    }

    try {
      await createUnloading(payload)
      successCount++
    } catch (error) {
      console.warn('[Unloading] API 下料提交失败，使用 Mock 模拟：', error)
      const result = addUnloadingRecord(payload)
      if (result.ok) {
        successCount++
      } else {
        failCount++
        ElMessage.error(result.message || '下料失败')
      }
    }
  }

  if (successCount > 0) {
    ElMessage.success(`成功下料 ${successCount} 条记录${failCount > 0 ? `，${failCount} 条失败` : ''}，可重新上料`)
  }

  // 重置表单
  selectedLoadingRecordIds.value = []
  unloadForm.unloadQuantity = 0
  unloadForm.reasonCode = ''
  unloadForm.remark = ''
  // 重新加载可下料记录
  await loadUnloadableList()
  submitting.value = false
}

// ==================== Tab 2: 工站上下料记录 ====================
const historyStationId = ref(null)
const historyLoading = ref(false)
const historyList = ref([])

const historyStation = computed(() => {
  if (!historyStationId.value) return null
  return stationList.value.find((s) => s.routeStepId === historyStationId.value) || null
})

async function loadHistory() {
  if (!historyStation.value) {
    historyList.value = []
    return
  }
  historyLoading.value = true
  try {
    const params = { routeStepId: historyStation.value.routeStepId }
    const data = await getStationHistoryApi(params)
    historyList.value = Array.isArray(data) ? data : (data?.records || data?.list || [])
  } catch (error) {
    console.warn('[Unloading] API 获取工站上下料历史失败，使用 Mock 数据：', error)
    historyList.value = getStationLoadingAndUnloadingHistory(historyStation.value.routeStepId)
  } finally {
    historyLoading.value = false
  }
}

const historySummary = computed(() => {
  const loadingCount = historyList.value.filter((r) => r.RecordType === 'loading').length
  const unloadingCount = historyList.value.filter((r) => r.RecordType === 'unloading').length
  const loadingQty = historyList.value
    .filter((r) => r.RecordType === 'loading')
    .reduce((sum, r) => sum + (r.Quantity || 0), 0)
  const unloadingQty = historyList.value
    .filter((r) => r.RecordType === 'unloading')
    .reduce((sum, r) => sum + (r.Quantity || 0), 0)
  return { loadingCount, unloadingCount, loadingQty, unloadingQty }
})

// ==================== 监听与初始化 ====================
watch(selectedStationId, () => {
  selectedLoadingRecordIds.value = []
  unloadForm.unloadQuantity = 0
  unloadForm.reasonCode = ''
  unloadForm.remark = ''
  loadUnloadableList()
})

watch(historyStationId, () => {
  loadHistory()
})

watch(operatorList, (list) => {
  if (list.length && !unloadForm.operatorId) {
    const currentUsername = userStore.userInfo?.username || userStore.userInfo?.name
    const matchedUser = list.find(u =>
      (u.username || u.Username) === currentUsername ||
      (u.fullName || u.FullName) === currentUsername
    )
    if (matchedUser) {
      unloadForm.operatorId = matchedUser.id || matchedUser.Id
    } else {
      unloadForm.operatorId = list[0].id || list[0].Id
    }
  }
})

onMounted(async () => {
  await loadOperatorList()
  // 支持从 URL 参数自动选中工站（进站校验失败跳转场景）
  const stationIdParam = route.query.stationId
  if (stationIdParam) {
    const target = stationList.value.find((s) => s.stationId === Number(stationIdParam))
    if (target) {
      selectedStationId.value = target.routeStepId
    }
  }
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">下料管理</h1>
      </div>
      <div class="table-actions">
        <el-button type="primary" plain @click="router.push('/execution/loading')">
          <el-icon style="margin-right: 4px"><Top /></el-icon>去上料
        </el-button>
        <el-button type="success" plain @click="router.push('/execution/check-in')">
          <el-icon style="margin-right: 4px"><Promotion /></el-icon>去进站
        </el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab" class="unloading-tabs">
      <!-- ==================== Tab 1: 下料操作 ==================== -->
      <el-tab-pane name="unloading">
        <template #label>
          <span class="tab-label">下料操作</span>
        </template>

        <!-- 步骤 1: 选择工站 -->
        <SectionCard title="① 选择工站">
          <div class="station-flex">
            <div
              v-for="station in stationList"
              :key="station.routeStepId"
              class="station-card"
              :class="{ active: selectedStationId === station.routeStepId }"
              @click="selectedStationId = station.routeStepId"
            >
              <div class="station-card-header">
                <span class="station-seq">{{ station.sequence }}</span>
                <span class="station-code">{{ station.stationCode }}</span>
                <el-tag size="small" type="info" effect="plain" round>{{ station.operationName }}</el-tag>
              </div>
              <div class="station-card-body">
                <div class="station-info-row">
                  <span class="label">工站</span>
                  <span class="value">{{ station.stationName }}</span>
                </div>
                <div class="station-info-row">
                  <span class="label">设备类型</span>
                  <span class="value">{{ station.equipmentTypeName }}</span>
                </div>
              </div>
            </div>
          </div>
        </SectionCard>

        <!-- 步骤 2: 下料录入 -->
        <SectionCard v-if="currentStation" title="② 下料录入" class="mt-16">
          <div class="current-context-bar">
            <div class="context-item">
              <span class="context-label">工站</span>
              <span class="context-value">{{ currentStation.stationName }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">工序</span>
              <span class="context-value">{{ currentStation.operationName }}</span>
            </div>
            <el-divider direction="vertical" />
            <div class="context-item">
              <span class="context-label">设备类型</span>
              <el-tag size="small" type="warning" effect="plain">{{ currentStation.equipmentTypeName }}</el-tag>
            </div>
          </div>

          <!-- 工站可下料的上料记录 -->
          <div class="unloadable-section">
            <div class="section-title">
              <span>工站已上料记录</span>
              <el-tag v-if="unloadableList.length" type="info" size="small" effect="plain">
                共 {{ unloadableList.length }} 条
              </el-tag>
            </div>

            <el-empty
              v-if="!unloadableLoading && !unloadableList.length"
              description="该工站暂无可下料的上料记录"
              :image-size="80"
            />

            <el-table
              v-else
              v-loading="unloadableLoading"
              :data="unloadableList"
              border
              stripe
              size="small"
              row-key="Id"
              @selection-change="(rows) => handleSelectionChange(rows.map(r => r.Id))"
            >
              <el-table-column type="selection" width="42" align="center" :selectable="() => true" />
              <el-table-column label="物料批次条码" min-width="200" align="center">
                <template #default="{ row }">
                  <span class="barcode-text">{{ row.Barcode }}</span>
                </template>
              </el-table-column>
              <el-table-column prop="MaterialCode" label="物料编码" min-width="120" align="center" />
              <el-table-column prop="BatchNo" label="批次号" min-width="140" align="center" />
              <el-table-column label="封装" width="80" align="center">
                <template #default="{ row }">
                  <el-tag size="small" effect="plain">{{ row.PackageType }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="Supplier" label="供应商" min-width="90" align="center" />
              <el-table-column label="上料数量" width="100" align="center">
                <template #default="{ row }">
                  <span style="font-weight: 700; color: var(--rtm-primary)">{{ row.ActualQuantity }}</span>
                </template>
              </el-table-column>
              <el-table-column label="可下料数量" width="110" align="center">
                <template #default="{ row }">
                  <span style="font-weight: 700; color: #e6a23c">{{ row.UnloadableQuantity }}</span>
                </template>
              </el-table-column>
              <el-table-column label="校验状态" width="100" align="center">
                <template #default="{ row }">
                  <el-tag :type="row.VerifyStatusTag" size="small" effect="light" round>{{ row.VerifyStatusText }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="OperatorName" label="操作人" min-width="80" align="center" />
              <el-table-column prop="LoadingTime" label="上料时间" min-width="140" align="center" />
            </el-table>
          </div>

          <!-- 下料表单 -->
          <div v-if="selectedLoadingRecordIds.length" class="unload-form-section">
            <div class="section-title">
              <span>下料表单</span>
              <el-tag type="warning" size="small" effect="plain">
                已选 {{ selectedLoadingRecordIds.length }} 条记录
              </el-tag>
            </div>

            <el-form label-position="top" :model="unloadForm" class="unload-form">
              <el-row :gutter="16">
                <el-col :span="8">
                  <el-form-item label="下料数量" required>
                    <el-input-number
                      :model-value="unloadForm.unloadQuantity"
                      :min="1"
                      :max="totalUnloadableQuantity"
                      style="width: 100%"
                      @update:model-value="syncUnloadQuantity"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="下料原因" required>
                    <el-select v-model="unloadForm.reasonCode" placeholder="选择下料原因" style="width: 100%">
                      <el-option
                        v-for="opt in unloadReasonOptions"
                        :key="opt.value"
                        :label="opt.label"
                        :value="opt.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="操作人" required>
                    <el-select v-model="unloadForm.operatorId" filterable placeholder="选择操作人" style="width: 100%">
                      <el-option
                        v-for="user in operatorList"
                        :key="user.id || user.Id"
                        :label="getOperatorLabel(user)"
                        :value="user.id || user.Id"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
              <!-- 下料备注（所有原因均可填，选"其他"时必填） -->
              <el-form-item label="下料备注" :required="Number(unloadForm.reasonCode) === 4">
                <el-input
                  v-model="unloadForm.remark"
                  type="textarea"
                  :rows="2"
                  maxlength="200"
                  show-word-limit
                  :placeholder="Number(unloadForm.reasonCode) === 4 ? '请填写具体下料原因（必填）' : '请填写下料备注说明（可选）'"
                />
              </el-form-item>
            </el-form>

            <div class="unload-actions">
              <el-button
                type="warning"
                size="large"
                :loading="submitting"
                @click="submitUnloading"
              >
                <el-icon style="margin-right: 6px"><Download /></el-icon>提交下料
              </el-button>
              <el-button type="primary" plain @click="router.push('/execution/loading')">
                <el-icon style="margin-right: 4px"><Top /></el-icon>返回上料管理重新上料
              </el-button>
            </div>
          </div>
        </SectionCard>
      </el-tab-pane>

      <!-- ==================== Tab 2: 工站上下料记录 ==================== -->
      <el-tab-pane name="history">
        <template #label>
          <span class="tab-label">工站上下料记录</span>
        </template>

        <SectionCard title="选择工站">
          <div class="station-flex">
            <div
              v-for="station in stationList"
              :key="station.routeStepId"
              class="station-card"
              :class="{ active: historyStationId === station.routeStepId }"
              @click="historyStationId = station.routeStepId"
            >
              <div class="station-card-header">
                <span class="station-seq">{{ station.sequence }}</span>
                <span class="station-code">{{ station.stationCode }}</span>
                <el-tag size="small" type="info" effect="plain" round>{{ station.operationName }}</el-tag>
              </div>
              <div class="station-card-body">
                <div class="station-info-row">
                  <span class="label">工站</span>
                  <span class="value">{{ station.stationName }}</span>
                </div>
              </div>
            </div>
          </div>
        </SectionCard>

        <SectionCard v-if="historyStation" title="上下料历史记录" class="mt-16">
          <!-- 摘要信息卡片 -->
          <div class="history-summary-cards">
            <div class="summary-card-item">
              <div class="summary-card-icon loading"><el-icon><Top /></el-icon></div>
              <div class="summary-card-content">
                <span class="summary-card-label">上料记录数</span>
                <span class="summary-card-value">{{ historySummary.loadingCount }} 条</span>
              </div>
            </div>
            <div class="summary-card-item">
              <div class="summary-card-icon loading-qty"><el-icon><Goods /></el-icon></div>
              <div class="summary-card-content">
                <span class="summary-card-label">上料总量</span>
                <span class="summary-card-value">{{ historySummary.loadingQty }}</span>
              </div>
            </div>
            <div class="summary-card-item">
              <div class="summary-card-icon unloading"><el-icon><Download /></el-icon></div>
              <div class="summary-card-content">
                <span class="summary-card-label">下料记录数</span>
                <span class="summary-card-value">{{ historySummary.unloadingCount }} 条</span>
              </div>
            </div>
            <div class="summary-card-item">
              <div class="summary-card-icon unloading-qty"><el-icon><Box /></el-icon></div>
              <div class="summary-card-content">
                <span class="summary-card-label">下料总量</span>
                <span class="summary-card-value">{{ historySummary.unloadingQty }}</span>
              </div>
            </div>
          </div>

          <!-- 记录列表 -->
          <el-table
            v-loading="historyLoading"
            :data="historyList"
            border
            stripe
            size="small"
            max-height="500"
            style="margin-top: 16px"
          >
            <el-table-column label="类型" width="80" align="center" fixed="left">
              <template #default="{ row }">
                <el-tag :type="row.RecordTypeTag" size="small" effect="light" round>
                  {{ row.RecordTypeText }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="物料批次条码" min-width="200" align="center">
              <template #default="{ row }">
                <span class="barcode-text">{{ row.Barcode }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="MaterialCode" label="物料编码" min-width="120" align="center" />
            <el-table-column prop="BatchNo" label="批次号" min-width="140" align="center" />
            <el-table-column prop="Supplier" label="供应商" min-width="90" align="center" />
            <el-table-column label="数量" width="100" align="center">
              <template #default="{ row }">
                <span
                  :style="{
                    fontWeight: 700,
                    color: row.RecordType === 'loading' ? 'var(--rtm-primary)' : '#e6a23c'
                  }"
                >
                  {{ row.QuantityLabel }}
                </span>
              </template>
            </el-table-column>
            <el-table-column label="下料原因" min-width="120" align="center">
              <template #default="{ row }">
                <span v-if="row.Reason">{{ row.Reason }}</span>
                <span v-else style="color: var(--rtm-text-muted)">-</span>
              </template>
            </el-table-column>
            <el-table-column label="关联上料记录 ID" min-width="130" align="center">
              <template #default="{ row }">
                <span v-if="row.RelatedRecordId" class="related-id">#{{ row.RelatedRecordId }}</span>
                <span v-else style="color: var(--rtm-text-muted)">-</span>
              </template>
            </el-table-column>
            <el-table-column prop="OperatorName" label="操作人" min-width="80" align="center" />
            <el-table-column prop="OperationTime" label="操作时间" min-width="140" align="center" fixed="right" />
          </el-table>

          <el-empty
            v-if="!historyLoading && !historyList.length"
            description="该工站暂无上下料记录"
            :image-size="80"
          />
        </SectionCard>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<style scoped>
.unloading-tabs :deep(.el-tabs__header) {
  margin-bottom: 16px;
}

.unloading-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 600;
  height: 44px;
  padding: 0 24px;
}

.unloading-tabs :deep(.el-tabs__item.is-active) {
  color: var(--rtm-primary);
  font-weight: 700;
}

.mt-16 {
  margin-top: 16px;
}

/* ===== 工站卡片（与上料管理保持一致） ===== */
.station-flex {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
}

.station-card {
  position: relative;
  flex: 1 0 calc(20% - 14px);
  min-width: 180px;
  max-width: 280px;
  border: 2px solid var(--rtm-line);
  border-radius: 10px;
  padding: 14px 16px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #fff;
  box-sizing: border-box;
}

.station-card:hover {
  border-color: var(--rtm-primary);
  box-shadow: 0 4px 12px rgba(31, 95, 153, 0.12);
  transform: translateY(-1px);
}

.station-card.active {
  border-color: #e6a23c;
  background: linear-gradient(135deg, #fdf6ec 0%, #fefaf3 100%);
  box-shadow: 0 4px 14px rgba(230, 162, 60, 0.18);
}

.station-card.active::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  border-radius: 10px 10px 0 0;
  background: #e6a23c;
}

.station-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}

.station-seq {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 6px;
  background: #e6a23c;
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}

.station-code {
  font-weight: 700;
  font-size: 15px;
  color: var(--rtm-text);
  flex: 1;
}

.station-card-body {
  font-size: 13px;
  color: var(--rtm-text-soft);
  line-height: 1.9;
}

.station-info-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.station-info-row .label {
  min-width: 36px;
  color: var(--rtm-text-muted);
  flex-shrink: 0;
  text-align: right;
}

.station-info-row .value {
  color: var(--rtm-text);
  font-weight: 500;
}

/* ===== 当前上下文信息条 ===== */
.current-context-bar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 10px 16px;
  background: linear-gradient(90deg, #fdf6ec 0%, #f8fafc 100%);
  border: 1px solid #f5dab1;
  border-radius: 8px;
  margin-bottom: 16px;
}

.context-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.context-label {
  font-size: 11px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.context-value {
  font-size: 14px;
  color: var(--rtm-text);
  font-weight: 700;
}

/* ===== 区块标题 ===== */
.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  color: var(--rtm-text);
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--rtm-line);
}

.unloadable-section {
  margin-bottom: 20px;
}

.unload-form-section {
  padding-top: 16px;
  border-top: 1px dashed var(--rtm-line);
}

.barcode-text {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  color: var(--rtm-primary);
  font-weight: 600;
}

/* ===== 下料表单 ===== */
.unload-form {
  margin-bottom: 16px;
}

.form-hint {
  margin-top: 4px;
  font-size: 12px;
  color: var(--rtm-text-muted);
}

.unload-actions {
  display: flex;
  gap: 12px;
  align-items: center;
  padding-top: 8px;
  border-top: 1px dashed var(--rtm-line);
}

/* ===== 历史摘要卡片 ===== */
.history-summary-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.summary-card-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: var(--rtm-panel-soft, #f8fafc);
  border: 1px solid var(--rtm-line);
  border-radius: 8px;
}

.summary-card-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  font-size: 18px;
  flex-shrink: 0;
}

.summary-card-icon.loading {
  background: #ecf5ff;
  color: #409eff;
}

.summary-card-icon.loading-qty {
  background: #f0f9eb;
  color: #67c23a;
}

.summary-card-icon.unloading {
  background: #fdf6ec;
  color: #e6a23c;
}

.summary-card-icon.unloading-qty {
  background: #fef0f0;
  color: #f56c6c;
}

.summary-card-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow: hidden;
}

.summary-card-label {
  font-size: 11px;
  color: var(--rtm-text-muted);
  font-weight: 600;
}

.summary-card-value {
  font-size: 14px;
  color: var(--rtm-text);
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.related-id {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  color: #e6a23c;
  font-weight: 600;
}

@media (max-width: 900px) {
  .station-card {
    flex: 1 0 100%;
    max-width: 100%;
  }

  .current-context-bar {
    flex-wrap: wrap;
  }

  .history-summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
