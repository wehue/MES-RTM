import { createRouter, createWebHistory } from 'vue-router'
import NProgress from 'nprogress'
import 'nprogress/nprogress.css'

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
        meta: { title: '生产驾驶舱', module: '首页' },
      },
      {
        path: 'production',
        redirect: '/production/work-order',
        children: [
          {
            path: 'work-order',
            name: 'WorkOrder',
            component: () => import('@/views/production/WorkOrderView.vue'),
            meta: { title: '工单管理', module: '生产调度' },
          },
          {
            path: 'work-order/:id',
            name: 'WorkOrderDetail',
            component: () => import('@/views/production/WorkOrderDetailView.vue'),
            meta: { title: '工单详情', module: '生产调度' },
          },
          {
            path: 'batch',
            name: 'Batch',
            component: () => import('@/views/production/BatchView.vue'),
            meta: { title: '批次管理', module: '生产调度' },
          },
          {
            path: 'batch/:id',
            name: 'BatchDetail',
            component: () => import('@/views/production/BatchDetailView.vue'),
            meta: { title: '批次详情', module: '生产调度' },
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
            meta: { title: '进站操作', module: '生产执行' },
          },
          {
            path: 'loading',
            name: 'Loading',
            component: () => import('@/views/execution/LoadingView.vue'),
            meta: { title: '上料校验', module: '生产执行' },
          },
          {
            path: 'check-out',
            name: 'CheckOut',
            component: () => import('@/views/execution/CheckOutView.vue'),
            meta: { title: '出站操作', module: '生产执行' },
          },
          {
            path: 'repair',
            name: 'Repair',
            component: () => import('@/views/execution/RepairView.vue'),
            meta: { title: '维修管理', module: '生产执行' },
          },
          {
            path: 'tracking',
            name: 'Tracking',
            component: () => import('@/views/execution/TrackingView.vue'),
            meta: { title: '批次跟踪', module: '生产执行' },
          },
          {
            path: 'device',
            name: 'DeviceMonitor',
            component: () => import('@/views/execution/DeviceMonitorView.vue'),
            meta: { title: '设备监控', module: '生产执行' },
          },
        ],
      },
      {
        path: 'quality',
        redirect: '/quality/threshold',
        children: [
          {
            path: 'threshold',
            name: 'Threshold',
            component: () => import('@/views/quality/ThresholdView.vue'),
            meta: { title: '阈值配置', module: '质量管理' },
          },
          {
            path: 'intercept',
            name: 'Intercept',
            component: () => import('@/views/quality/InterceptView.vue'),
            meta: { title: '拦截管理', module: '质量管理' },
          },
        ],
      },
      {
        path: 'system',
        children: [
          {
            path: 'profile',
            name: 'Profile',
            component: () => import('@/views/system/ProfileView.vue'),
            meta: { title: '个人中心', module: '个人中心' },
          },
          {
            path: 'message',
            name: 'Message',
            component: () => import('@/views/system/MessageView.vue'),
            meta: { title: '消息中心', module: '消息中心' },
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
        meta: { title: '产线状态看板', module: '看板中心', noAuth: true },
      },
      {
        path: 'quality',
        name: 'KanbanQuality',
        component: () => import('@/views/kanban/QualityView.vue'),
        meta: { title: '质量监控看板', module: '看板中心', noAuth: true },
      },
      {
        path: 'progress',
        name: 'KanbanProgress',
        component: () => import('@/views/kanban/ProgressView.vue'),
        meta: { title: '生产进度看板', module: '看板中心', noAuth: true },
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

router.beforeEach((to, from, next) => {
  NProgress.start()
  if (to.meta.noAuth) {
    next()
  } else {
    const token = localStorage.getItem('token')
    if (token) {
      next()
    } else {
      next({ path: '/login', query: { redirect: to.fullPath } })
    }
  }
})

router.afterEach(() => {
  NProgress.done()
})

export default router
