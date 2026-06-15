<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  Bell,
  DataBoard,
  Document,
  Expand,
  Fold,
  Monitor,
  Position,
  Search,
  SwitchButton,
  Tickets,
  TrendCharts,
  User,
} from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import { messages } from '@/utils/mockData'
import { PERMISSION_CODES, ROLES } from '@/utils/constants'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const isCollapsed = ref(false)

const roleLabel = computed(() => {
  const role = ROLES.find((item) => item.value === userStore.userInfo.role)
  return role?.label || '工厂管理层'
})

const displayName = computed(() => userStore.userInfo.name || '系统管理员')
const activeMenu = computed(() => route.path)
const unreadCount = computed(() => messages.filter((item) => item.unread).length)

const allMenuItems = [
  { index: '/dashboard', icon: DataBoard, title: '首页', permission: PERMISSION_CODES.DASHBOARD },
  {
    index: '/kanban',
    icon: Monitor,
    title: '看板中心',
    permission: PERMISSION_CODES.KANBAN,
    children: [
      { index: '/kanban/line-status', title: '产线状态看板', permission: PERMISSION_CODES.KANBAN },
      { index: '/kanban/quality', title: '质量监控看板', permission: PERMISSION_CODES.KANBAN },
      { index: '/kanban/progress', title: '生产进度看板', permission: PERMISSION_CODES.KANBAN },
    ],
  },
  {
    index: '/production',
    icon: Document,
    title: '生产调度',
    children: [
      { index: '/production/work-order', title: '工单管理', permission: PERMISSION_CODES.WORK_ORDER },
      { index: '/production/batch', title: '批次管理', permission: PERMISSION_CODES.BATCH },
    ],
  },
  {
    index: '/execution',
    icon: Position,
    title: '生产执行',
    children: [
      { index: '/execution/check-in', title: '进站操作', permission: PERMISSION_CODES.CHECK_IN },
      { index: '/execution/loading', title: '上料管理', permission: PERMISSION_CODES.LOADING },
      { index: '/execution/check-out', title: '出站操作', permission: PERMISSION_CODES.CHECK_OUT },
      { index: '/execution/repair', title: '维修管理', permission: PERMISSION_CODES.REPAIR },
    ],
  },
  { index: '/execution/tracking', icon: Search, title: '批次跟踪', permission: PERMISSION_CODES.TRACKING },
  { index: '/device', icon: Monitor, title: '设备监控', permission: PERMISSION_CODES.DEVICE },
]

const menuItems = computed(() => allMenuItems
  .map((item) => {
    if (!item.children) return userStore.hasPermission(item.permission) ? item : null
    const children = item.children.filter((child) => userStore.hasPermission(child.permission))
    if (!children.length) return null
    return { ...item, children }
  })
  .filter(Boolean))

function handleCommand(command) {
  if (command === 'profile') router.push('/system/profile')
  if (command === 'message') router.push('/system/message')
  if (command === 'logout') {
    userStore.logout()
    router.push('/login')
  }
}
</script>

<template>
  <el-container class="app-layout">
    <el-aside :width="isCollapsed ? '64px' : '228px'" class="app-aside">
      <div class="logo-area">
        <div class="logo-mark">RT</div>
        <div v-if="!isCollapsed">
          <h1>MES-RTM</h1>
          <p>实时制造执行</p>
        </div>
      </div>

      <el-menu
        :default-active="activeMenu"
        :collapse="isCollapsed"
        :collapse-transition="false"
        background-color="#17202c"
        text-color="#c8d2df"
        active-text-color="#ffffff"
        router
      >
        <template v-for="item in menuItems" :key="item.index">
          <el-sub-menu v-if="item.children" :index="item.index">
            <template #title>
              <el-icon><component :is="item.icon" /></el-icon>
              <span>{{ item.title }}</span>
            </template>
            <el-menu-item v-for="child in item.children" :key="child.index" :index="child.index">
              {{ child.title }}
            </el-menu-item>
          </el-sub-menu>
          <el-menu-item v-else :index="item.index">
            <el-icon><component :is="item.icon" /></el-icon>
            <template #title>{{ item.title }}</template>
          </el-menu-item>
        </template>
      </el-menu>
    </el-aside>

    <el-container class="main-container">
      <el-header class="app-header">
        <div class="header-left">
          <el-button text :icon="isCollapsed ? Expand : Fold" @click="isCollapsed = !isCollapsed" />
          <el-breadcrumb separator="/">
            <el-breadcrumb-item>{{ route.meta?.module || '首页' }}</el-breadcrumb-item>
            <el-breadcrumb-item>{{ route.meta?.title || '生产驾驶舱' }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>

        <div class="header-right">
          <div class="system-status">
            <span class="status-light" />
            <span>实时连接正常</span>
            <strong>30s 自动刷新</strong>
          </div>
          <el-button class="kanban-entry" :icon="TrendCharts" @click="router.push('/kanban/line-status')">
            大屏
          </el-button>
          <el-badge :value="unreadCount" :hidden="unreadCount === 0">
            <el-button text :icon="Bell" @click="handleCommand('message')" />
          </el-badge>
          <el-dropdown trigger="click" @command="handleCommand">
            <button class="user-info">
              <el-avatar :size="30" :icon="User" />
              <span>{{ displayName }}</span>
              <small>{{ roleLabel }}</small>
            </button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile" :icon="Tickets">个人中心</el-dropdown-item>
                <el-dropdown-item command="message" :icon="Bell">消息通知</el-dropdown-item>
                <el-dropdown-item command="logout" divided :icon="SwitchButton">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="app-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<style lang="scss" scoped>
.app-layout {
  height: 100vh;
  overflow: hidden;
}

.app-aside {
  background: var(--rtm-steel-dark);
  transition: width 0.2s ease;
  overflow: hidden;

  .logo-area {
    height: 66px;
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 0 16px;
    border-bottom: 1px solid rgba(216, 222, 230, 0.14);
    color: #fff;
  }

  .logo-mark {
    width: 36px;
    height: 36px;
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    border: 1px solid rgba(255, 255, 255, 0.22);
    border-radius: 6px;
    background: #1f5f99;
    font-weight: 800;
  }

  h1 {
    font-size: 17px;
    line-height: 1.2;
  }

  p {
    margin-top: 3px;
    color: #9cadbf;
    font-size: 12px;
  }

  .el-menu {
    border-right: none;
  }

  :deep(.el-menu-item),
  :deep(.el-sub-menu__title) {
    height: 44px;
    margin: 2px 8px;
    border-radius: 5px;
  }

  :deep(.el-menu-item.is-active) {
    position: relative;
    background: rgba(31, 95, 153, 0.88);

    &::before {
      position: absolute;
      top: 8px;
      bottom: 8px;
      left: 0;
      width: 3px;
      background: #9cc8ee;
      content: '';
    }
  }

  :deep(.el-menu-item:hover),
  :deep(.el-sub-menu__title:hover) {
    background: rgba(255, 255, 255, 0.08);
  }
}

.main-container {
  overflow: hidden;
}

.app-header {
  height: 66px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  border-bottom: 1px solid var(--rtm-line);
  background: #ffffff;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.06);
}

.header-left,
.header-right {
  display: flex;
  align-items: center;
  gap: 14px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  border: 0;
  background: transparent;
  color: var(--rtm-text);
  cursor: pointer;

  small {
    color: var(--rtm-text-soft);
  }
}

.app-main {
  overflow-y: auto;
  padding: 16px;
  background:
    linear-gradient(90deg, rgba(23, 32, 44, 0.035) 1px, transparent 1px),
    linear-gradient(rgba(23, 32, 44, 0.03) 1px, transparent 1px),
    var(--rtm-bg);
  background-size: 32px 32px;
}

.system-status {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 34px;
  padding: 0 12px;
  border: 1px solid var(--rtm-line);
  border-radius: 18px;
  background: #f8fafc;
  color: var(--rtm-text-soft);
  font-size: 12px;

  strong {
    color: var(--rtm-primary-dark);
  }
}

.status-light {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--rtm-success);
  box-shadow: 0 0 0 3px rgba(25, 135, 84, 0.14);
}

.kanban-entry {
  border-color: #9bb9d2;
  background: #eef5fb;
  color: var(--rtm-primary-dark);
  font-weight: 800;
}

@media (max-width: 900px) {
  .app-aside {
    display: none;
  }

  .header-right .el-tag,
  .header-right > .el-button {
    display: none;
  }
}
</style>
