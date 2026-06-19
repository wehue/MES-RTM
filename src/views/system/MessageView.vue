<script setup>
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { messages } from '@/utils/mockData'

const router = useRouter()
const active = ref('全部')
const list = ref([...messages])
const detail = ref(null)
const tabs = ['全部', '告警通知', '生产通知', '质量通知', '系统通知']

const filtered = computed(() => active.value === '全部' ? list.value : list.value.filter((item) => item.Category === active.value))

function markAllRead() {
  list.value.forEach((item) => { item.IsUnread = false })
  ElMessage.success('已全部标记为已读')
}

async function remove(item) {
  await ElMessageBox.confirm(`确认删除消息：${item.Title}？`, '删除消息')
  list.value = list.value.filter((row) => row.Id !== item.Id)
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">消息通知中心</h1>
        <p class="page-subtitle">告警、生产、质量、系统通知集中处理，支持关联跳转。</p>
      </div>
      <el-button type="primary" @click="markAllRead">全部已读</el-button>
    </div>

    <SectionCard title="通知列表">
      <el-tabs v-model="active">
        <el-tab-pane v-for="tab in tabs" :key="tab" :label="tab" :name="tab" />
      </el-tabs>

      <el-table :data="filtered" border :row-class-name="({ row }) => row.Category === '告警通知' ? 'danger-row' : ''">
        <el-table-column label="状态" width="80"><template #default="{ row }"><el-badge is-dot :hidden="!row.IsUnread"><el-tag :type="row.IsUnread ? 'danger' : 'info'">{{ row.IsUnread ? '未读' : '已读' }}</el-tag></el-badge></template></el-table-column>
        <el-table-column prop="Category" label="分类" width="110" />
        <el-table-column prop="Title" label="标题" min-width="150" />
        <el-table-column prop="Content" label="内容" min-width="260" />
        <el-table-column prop="MessageTime" label="触发时间" min-width="150" />
        <el-table-column label="操作" width="190">
          <template #default="{ row }">
            <el-button link type="primary" @click="detail = row; row.IsUnread = false">详情</el-button>
            <el-button link type="success" @click="router.push(row.LinkUrl)">跳转</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </SectionCard>

    <el-dialog v-model="detail" title="消息详情" width="520px">
      <template v-if="detail">
        <h3>{{ detail.Title }}</h3>
        <p style="margin-top: 12px; line-height: 1.8">{{ detail.Content }}</p>
        <p class="muted" style="margin-top: 12px">{{ detail.MessageTime }}</p>
      </template>
      <template #footer>
        <el-button @click="detail = null">关闭</el-button>
        <el-button type="primary" @click="router.push(detail.LinkUrl)">前往业务页面</el-button>
      </template>
    </el-dialog>
  </div>
</template>
