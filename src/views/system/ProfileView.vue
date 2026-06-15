<script setup>
import { reactive } from 'vue'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/SectionCard.vue'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import { ROLES } from '@/utils/constants'

const userStore = useUserStore()
const appStore = useAppStore()
const password = reactive({ old: '', current: '', confirm: '' })
const prefs = reactive({ defaultPage: '/dashboard', pageSize: appStore.pageSize, refreshInterval: appStore.refreshInterval })
const roleLabel = ROLES.find((item) => item.value === userStore.userInfo.role)?.label || '工厂管理层'
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">个人中心</h1>
        <p class="page-subtitle">查看个人信息、修改密码、维护个性化设置和近期操作日志。</p>
      </div>
    </div>

    <div class="content-grid">
      <SectionCard class="span-6" title="个人基础信息">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="账号">{{ userStore.userInfo.username }}</el-descriptions-item>
          <el-descriptions-item label="姓名">{{ userStore.userInfo.name }}</el-descriptions-item>
          <el-descriptions-item label="所属部门">{{ userStore.userInfo.department }}</el-descriptions-item>
          <el-descriptions-item label="岗位">{{ userStore.userInfo.post }}</el-descriptions-item>
          <el-descriptions-item label="角色">{{ roleLabel }}</el-descriptions-item>
        </el-descriptions>
      </SectionCard>

      <SectionCard class="span-6" title="密码修改">
        <el-form :model="password" label-width="90px">
          <el-form-item label="旧密码"><el-input v-model="password.old" type="password" show-password /></el-form-item>
          <el-form-item label="新密码"><el-input v-model="password.current" type="password" show-password /></el-form-item>
          <el-form-item label="确认密码"><el-input v-model="password.confirm" type="password" show-password /></el-form-item>
          <el-button type="primary" @click="ElMessage.success('密码修改请求已提交')">提交修改</el-button>
        </el-form>
      </SectionCard>

      <SectionCard class="span-6" title="个性化设置">
        <el-form :model="prefs" label-width="110px">
          <el-form-item label="默认首页">
            <el-select v-model="prefs.defaultPage" class="full">
              <el-option label="生产驾驶舱" value="/dashboard" />
              <el-option label="产线状态看板" value="/kanban/line-status" />
            </el-select>
          </el-form-item>
          <el-form-item label="每页条数"><el-input-number v-model="prefs.pageSize" :min="10" :max="100" /></el-form-item>
          <el-form-item label="刷新频率">
            <el-select v-model="prefs.refreshInterval" class="full">
              <el-option label="15 秒" :value="15000" />
              <el-option label="30 秒" :value="30000" />
              <el-option label="60 秒" :value="60000" />
            </el-select>
          </el-form-item>
          <el-button type="primary" @click="appStore.setPageSize(prefs.pageSize); appStore.setRefreshInterval(prefs.refreshInterval); ElMessage.success('个性化设置已保存')">保存设置</el-button>
        </el-form>
      </SectionCard>

      <SectionCard class="span-6" title="操作日志">
        <el-timeline>
          <el-timeline-item timestamp="2026-05-12 10:42">查看质量拦截详情</el-timeline-item>
          <el-timeline-item timestamp="2026-05-12 09:30">导出工单列表</el-timeline-item>
          <el-timeline-item timestamp="2026-05-12 08:30">登录系统</el-timeline-item>
        </el-timeline>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.full {
  width: 100%;
}
</style>
