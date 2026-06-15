<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import MetricCard from '@/components/MetricCard.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { DEVICE_STATUS, DEVICE_TYPES, statusMeta } from '@/utils/constants'
import { devices, lineOptions } from '@/utils/mockData'

const viewMode = ref('table')
const filters = reactive({ type: '', status: '', line: '' })
const query = reactive({ type: '', status: '', line: '' })

const filteredDevices = computed(() => devices.filter((item) => {
  const type = !query.type || item.type === query.type
  const status = !query.status || item.status === query.status
  const line = !query.line || item.line === query.line
  return type && status && line
}))

const counts = computed(() => ({
  total: devices.length,
  running: devices.filter((item) => item.status === 'running').length,
  standby: devices.filter((item) => item.status === 'standby').length,
  fault: devices.filter((item) => item.status === 'fault').length,
  offline: devices.filter((item) => item.status === 'offline').length,
}))

function handleSearch() {
  Object.assign(query, { ...filters })
  ElMessage.success('已按筛选条件查询设备')
}

function handleReset() {
  Object.assign(filters, { type: '', status: '', line: '' })
  Object.assign(query, { type: '', status: '', line: '' })
  ElMessage.info('筛选条件已重置')
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">设备状态监控</h1>
        <p class="page-subtitle">按设备类型、状态、产线筛选，故障与 OEE 低于目标值自动预警。</p>
      </div>
      <el-segmented v-model="viewMode" :options="[{ label: '列表视图', value: 'table' }, { label: '矩阵视图', value: 'matrix' }]" />
    </div>

    <div class="stat-cards">
      <MetricCard title="设备总数" :value="counts.total" unit="台" />
      <MetricCard title="运行中" :value="counts.running" unit="台" tone="success" />
      <MetricCard title="待机中" :value="counts.standby" unit="台" tone="warning" />
      <MetricCard title="故障" :value="counts.fault" unit="台" tone="danger" />
      <MetricCard title="离线" :value="counts.offline" unit="台" tone="primary" />
    </div>

    <div class="filter-bar">
      <el-form :inline="true" :model="filters">
        <el-form-item label="设备类型">
          <el-select v-model="filters.type" clearable placeholder="全部类型" style="width: 170px">
            <el-option v-for="type in DEVICE_TYPES" :key="type" :label="type" :value="type" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width: 130px">
            <el-option v-for="(meta, key) in DEVICE_STATUS" :key="key" :label="meta.label" :value="key" />
          </el-select>
        </el-form-item>
        <el-form-item label="产线">
          <el-select v-model="filters.line" clearable placeholder="全部产线" style="width: 130px">
            <el-option v-for="line in lineOptions" :key="line" :label="line" :value="line" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <div class="filter-actions">
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
          </div>
        </el-form-item>
      </el-form>
    </div>

    <SectionCard title="设备列表 / 矩阵">
      <el-table v-if="viewMode === 'table'" :data="filteredDevices" border :row-class-name="({ row }) => row.status === 'fault' ? 'danger-row' : row.oee < 70 ? 'warning-row' : ''">
        <el-table-column prop="id" label="设备编号" width="190" />
        <el-table-column prop="name" label="设备名称" width="190" />
        <el-table-column prop="type" label="设备类型" width="190" />
        <el-table-column prop="line" label="所属产线" width="150" />
        <el-table-column label="状态" width="140"><template #default="{ row }"><StatusTag :meta="statusMeta(DEVICE_STATUS, row.status)" /></template></el-table-column>
        <el-table-column prop="batch" label="当前批次" width="240" />
        <el-table-column prop="duration" label="运行时长" width="160" />
        <el-table-column prop="oee" label="OEE%" width="130" />
        <el-table-column prop="output" label="当日产量" width="150" />
        <el-table-column prop="throwRate" label="抛料率" width="140" />
        <el-table-column prop="fault" label="故障描述" width="260" />
        <el-table-column fixed="right" label="操作" width="220">
          <template #default>
            <div class="row-actions">
              <el-button link type="primary" @click="ElMessage.success('故障工单已提交')">故障提报</el-button>
              <el-button link type="success" @click="ElMessage.success('保养任务已确认完成')">保养确认</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <div v-else class="device-matrix">
        <div v-for="device in filteredDevices" :key="device.id" class="device-tile" :style="{ borderColor: statusMeta(DEVICE_STATUS, device.status).color }">
          <strong>{{ device.id }}</strong>
          <span>{{ device.name }}</span>
          <StatusTag :meta="statusMeta(DEVICE_STATUS, device.status)" />
          <small>OEE {{ device.oee }}% / {{ device.batch }}</small>
        </div>
      </div>
    </SectionCard>

    <SectionCard title="故障设备详情与保养提醒">
      <el-alert title="SPI-B1-02 故障代码 P-104：参数采集超差，维修状态：已接单，预计 11:30 恢复。" type="error" show-icon :closable="false" />
      <el-alert style="margin-top: 10px" title="MNT-A2-03 吸嘴保养即将到期，计划日期 2026-05-13，保养周期 7 天。" type="warning" show-icon :closable="false" />
    </SectionCard>
  </div>
</template>

<style lang="scss" scoped>
.device-matrix {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: 12px;
}

.device-tile {
  display: flex;
  min-height: 132px;
  flex-direction: column;
  gap: 8px;
  padding: 14px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}
</style>
