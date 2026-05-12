<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  Menu as IconMenu,
  Document,
  Box,
  Position,
  Upload,
  Download,
  Setting,
  Monitor,
  Warning,
  DataBoard,
  TrendCharts,
  Timer,
  User,
  Bell,
  ArrowLeft,
  ArrowRight,
  SwitchButton,
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const isCollapsed = ref(false)

const activeMenu = computed(() => route.path)

const menuItems = [
  { index: '/dashboard', icon: DataBoard, title: '首页' },
  {
    index: '/production',
    icon: Document,
    title: '生产调度',
    children: [
      { index: '/production/work-order', title: '工单管理' },
      { index: '/production/batch', title: '批次管理' },
    ],
  },
  {
    index: '/execution',
    icon: Position,
    title: '生产执行',
    children: [
      { index: '/execution/check-in', title: '进站操作' },
      { index: '/execution/loading', title: '上料校验' },
      { index: '/execution/check-out', title: '出站操作' },
      { index: '/execution/repair', title: '维修管理' },
      { index: '/execution/tracking', title: '批次跟踪' },
      { index: '/execution/device', title: '设备监控' },
    ],
  },
  {
    index: '/quality',
    icon: Warning,
    title: '质量管理',
    children: [
      { index: '/quality/threshold', title: '阈值配置' },
      { index: '/quality/intercept', title: '拦截管理' },
    ],
  },
  {
    index: '/kanban',
    icon: Monitor,
    title: '看板中心',
    children: [
      { index: '/kanban/line-status', title: '产线状态看板' },
      { index: '/kanban/quality', title: '质量监控看板' },
      { index: '/kanban/progress', title: '生产进度看板' },
    ],
  },
]

const unreadCount = ref(3)

function handleMenuSelect(index) {
  router.push(index)
}

function handleCommand(command) {
  if (command === 'profile') {
    router.push('/system/profile')
  } else if (command === 'message') {
    router.push('/system/message')
  } else if (command === 'logout') {
    localStorage.removeItem('token')
    router.push('/login')
  }
}

function toggleCollapse() {
  isCollapsed.value = !isCollapsed.value
}
</script>

<template>
  <el-container class="app-layout">
    <el-aside :width="isCollapsed ? '64px' : '220px'" class="app-aside">
      <div class="logo-area">
        <h1 v-if="!isCollapsed" class="logo-title">MES-RTM</h1>
        <h1 v-else class="logo-title-mini">M</h1>
      </div>
      <el-menu
        :default-active="activeMenu"
        :collapse="isCollapsed"
        :collapse-transition="false"
        background-color="#001529"
        text-color="#ffffffa6"
        active-text-color="#409eff"
        router
        @select="handleMenuSelect"
      >
        <template v-for="item in menuItems" :key="item.index">
          <el-sub-menu v-if="item.children" :index="item.index">
            <template #title>
              <el-icon><component :is="item.icon" /></el-icon>
              <span>{{ item.title }}</span>
            </template>
            <el-menu-item
              v-for="child in item.children"
              :key="child.index"
              :index="child.index"
            >
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
          <el-icon class="collapse-btn" @click="toggleCollapse">
            <component :is="isCollapsed ? ArrowRight : ArrowLeft" />
          </el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item>{{ route.meta?.module || '首页' }}</el-breadcrumb-item>
            <el-breadcrumb-item v-if="route.meta?.title">
              {{ route.meta.title }}
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-badge :value="unreadCount" :hidden="unreadCount === 0" class="notify-badge">
            <el-icon class="header-icon" @click="handleCommand('message')"><Bell /></el-icon>
          </el-badge>
          <el-dropdown trigger="click" @command="handleCommand">
            <span class="user-info">
              <el-icon><User /></el-icon>
              <span class="username">管理员</span>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人中心</el-dropdown-item>
                <el-dropdown-item command="logout" divided>
                  <el-icon><SwitchButton /></el-icon>退出登录
                </el-dropdown-item>
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
  background-color: #001529;
  transition: width 0.3s;
  overflow: hidden;

  .logo-area {
    height: 56px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-bottom: 1px solid #ffffff1a;

    .logo-title {
      color: #fff;
      font-size: 18px;
      font-weight: 700;
      white-space: nowrap;
    }

    .logo-title-mini {
      color: #fff;
      font-size: 22px;
      font-weight: 700;
    }
  }

  .el-menu {
    border-right: none;
  }
}

.main-container {
  overflow: hidden;
}

.app-header {
  height: 56px;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
  z-index: 10;

  .header-left {
    display: flex;
    align-items: center;
    gap: 16px;

    .collapse-btn {
      font-size: 20px;
      cursor: pointer;
      color: #606266;

      &:hover {
        color: #409eff;
      }
    }
  }

  .header-right {
    display: flex;
    align-items: center;
    gap: 20px;

    .header-icon {
      font-size: 20px;
      cursor: pointer;
      color: #606266;

      &:hover {
        color: #409eff;
      }
    }

    .notify-badge {
      line-height: 1;
    }

    .user-info {
      display: flex;
      align-items: center;
      gap: 6px;
      cursor: pointer;
      color: #606266;

      &:hover {
        color: #409eff;
      }

      .username {
        font-size: 14px;
      }
    }
  }
}

.app-main {
  background: #f0f2f5;
  overflow-y: auto;
  padding: 20px;
}
</style>
