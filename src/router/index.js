import { createRouter, createWebHistory } from 'vue-router'
import NProgress from 'nprogress'
import 'nprogress/nprogress.css'
import { useUserStore } from '@/stores/user'
import { isRtmRole, PERMISSION_CODES } from '@/utils/constants'

NProgress.configure({ showSpinner: false })

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/LoginView.vue'),
    meta: { title: '登录', noAuth: true },
  },
  {
    path: '/',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/DashboardView.vue'),
        meta: { title: '生产驾驶舱', module: '首页', permission: PERMISSION_CODES.DASHBOARD },
      },
      {
        path: 'production',
        redirect: '/production/work-order',
        children: [
          {
            path: 'work-order',
            name: 'WorkOrder',
            component: () => import('@/views/production/WorkOrderView.vue'),
            meta: { title: '工单管理', module: '生产调度', permission: PERMISSION_CODES.WORK_ORDER },
          },
          {
            path: 'work-order/:id',
            name: 'WorkOrderDetail',
            component: () => import('@/views/production/WorkOrderDetailView.vue'),
            meta: {
              title: '工单详情',
              module: '生产调度',
              parent: { title: '工单管理', path: '/production/work-order' },
              activeMenu: '/production/work-order',
              permission: PERMISSION_CODES.WORK_ORDER,
            },
          },
          {
            path: 'batch',
            name: 'Batch',
            component: () => import('@/views/production/BatchView.vue'),
            meta: { title: '批次管理', module: '生产调度', permission: PERMISSION_CODES.BATCH },
          },
          {
            path: 'batch/:id',
            name: 'BatchDetail',
            component: () => import('@/views/production/BatchDetailView.vue'),
            meta: {
              title: '批次详情',
              module: '生产调度',
              parent: { title: '批次管理', path: '/production/batch' },
              activeMenu: '/production/batch',
              permission: PERMISSION_CODES.BATCH,
            },
          },
        ],
      },
      {
        path: 'execution',
        redirect: '/execution/check-in',
        children: [
          {
            path: 'check-in',
            name: 'CheckIn',
            component: () => import('@/views/execution/CheckInView.vue'),
            meta: { title: '进站操作', module: '生产执行', permission: PERMISSION_CODES.CHECK_IN },
          },
          {
            path: 'loading',
            name: 'Loading',
            component: () => import('@/views/execution/LoadingView.vue'),
            meta: { title: '上料管理', module: '生产执行', permission: PERMISSION_CODES.LOADING },
          },
          {
            path: 'check-out',
            name: 'CheckOut',
            component: () => import('@/views/execution/CheckOutView.vue'),
            meta: { title: '出站操作', module: '生产执行', permission: PERMISSION_CODES.CHECK_OUT },
          },
          {
            path: 'repair',
            name: 'Repair',
            component: () => import('@/views/execution/RepairView.vue'),
            meta: { title: '维修管理', module: '生产执行', permission: PERMISSION_CODES.REPAIR },
          },
          {
            path: 'tracking',
            name: 'Tracking',
            component: () => import('@/views/execution/TrackingView.vue'),
            meta: { title: '批次跟踪', module: '生产执行', permission: PERMISSION_CODES.TRACKING },
          },
        ],
      },
      {
        path: 'device',
        name: 'DeviceMonitor',
        component: () => import('@/views/execution/DeviceMonitorView.vue'),
        meta: { title: '设备监控', module: '设备监控', permission: PERMISSION_CODES.DEVICE },
      },
      {
        path: 'system',
        children: [
          {
            path: 'profile',
            name: 'Profile',
            component: () => import('@/views/system/ProfileView.vue'),
            meta: { title: '个人中心', module: '个人中心', permission: PERMISSION_CODES.SYSTEM },
          },
          {
            path: 'message',
            name: 'Message',
            component: () => import('@/views/system/MessageView.vue'),
            meta: { title: '消息通知', module: '消息中心', permission: PERMISSION_CODES.SYSTEM },
          },
        ],
      },
    ],
  },
  {
    path: '/kanban',
    component: () => import('@/layouts/KanbanLayout.vue'),
    children: [
      {
        path: 'line-status',
        name: 'KanbanLineStatus',
        component: () => import('@/views/kanban/LineStatusView.vue'),
        meta: { title: '产线状态看板', module: '看板中心', permission: PERMISSION_CODES.KANBAN },
      },
      {
        path: 'quality',
        name: 'KanbanQuality',
        component: () => import('@/views/kanban/QualityView.vue'),
        meta: { title: '质量监控看板', module: '看板中心', permission: PERMISSION_CODES.KANBAN },
      },
      {
        path: 'progress',
        name: 'KanbanProgress',
        component: () => import('@/views/kanban/ProgressView.vue'),
        meta: { title: '生产进度看板', module: '看板中心', permission: PERMISSION_CODES.KANBAN },
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/NotFoundView.vue'),
    meta: { title: '页面不存在', noAuth: true },
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

router.beforeEach(async (to) => {
  NProgress.start()
  if (to.meta.noAuth) {
    return true
  }
  const token = localStorage.getItem('token')
  if (!token) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }

  try {
    const userStore = useUserStore()
    const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
    const role = userInfo.role || 'RTM_ADMIN'
    if (!isRtmRole(role)) {
      localStorage.removeItem('token')
      localStorage.removeItem('userInfo')
      localStorage.removeItem('userFunctions')
      localStorage.removeItem('permissionCodes')
      return { path: '/login', query: { redirect: to.fullPath } }
    }
    // 权限接口失败时不要踢回登录页，否则会掩盖后端真实错误
    // 而是让用户进入页面（可能侧边栏不全），并在控制台暴露错误便于联调
    try {
      await userStore.ensurePermissionsLoaded()
    } catch (permErr) {
      console.error('[router] 加载用户功能权限失败，先放行进入页面：', permErr)
    }
    const permission = to.meta.permission
    if (permission && !userStore.hasPermission(permission)) {
      return { path: userStore.firstAccessiblePath() }
    }
  } catch (e) {
    console.error('Failed to parse userInfo:', e)
    localStorage.removeItem('token')
    localStorage.removeItem('userInfo')
    localStorage.removeItem('userFunctions')
    localStorage.removeItem('permissionCodes')
    return { path: '/login', query: { redirect: to.fullPath } }
  }
  return true
})

router.afterEach((to) => {
  document.title = `${to.meta.title || 'MES-RTM'}-MES-RTM-frontend-完整`
  NProgress.done()
})

export default router
