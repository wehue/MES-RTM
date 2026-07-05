<script setup>
import { computed, reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Lock, OfficeBuilding, Phone, User, UserFilled } from '@element-plus/icons-vue'
import { loginUser, registerUser } from '@/api/user'
import { useUserStore } from '@/stores/user'
import { ROLES } from '@/utils/constants'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const activeMode = ref('login')
const loginForm = reactive({
  username: 'admin',
  password: '123456',
})
const registerForm = reactive({
  username: '',
  password: '',
  fullName: '',
  department: 'SMT车间',
  position: '操作工',
  contact: '',
})
const loading = ref(false)

const positionOptions = computed(() => ROLES.map((item) => item.label))
const panelTitle = computed(() => activeMode.value === 'login' ? '系统登录' : '用户注册')
const panelDesc = computed(() => activeMode.value === 'login'
  ? '使用系统账号与密码进入生产执行工作台。'
  : '创建新的 MES-RTM 系统用户账号。')

function switchMode(mode) {
  activeMode.value = mode
}

function compactPayload(payload) {
  return Object.fromEntries(
    Object.entries(payload).map(([key, value]) => [key, typeof value === 'string' ? value.trim() : value])
  )
}

async function handleLogin() {
  if (!loginForm.username.trim() || !loginForm.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  loading.value = true
  try {
    const result = await loginUser({
      username: loginForm.username.trim(),
      password: loginForm.password,
    })
    if (!result?.token) {
      ElMessage.error('登录响应缺少 token，请检查后端接口返回')
      return
    }
    userStore.setToken(result.token)
    userStore.setUserInfo(result)
    await userStore.fetchCurrentFunctions()
    ElMessage.success('登录成功')
    router.push(route.query.redirect || userStore.firstAccessiblePath())
  } finally {
    loading.value = false
  }
}

async function handleRegister() {
  if (!registerForm.username.trim() || !registerForm.password) {
    ElMessage.warning('注册账号和密码为必填项')
    return
  }
  loading.value = true
  try {
    const payload = compactPayload(registerForm)
    const result = await registerUser(payload)
    ElMessage.success(`用户 ${result?.username || payload.username} 注册成功`)
    loginForm.username = payload.username
    loginForm.password = payload.password
    switchMode('login')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-container">
    <section class="login-shell">
      <div class="login-info">
        <div class="brand dark">
          <div class="brand-mark">RT</div>
          <div>
            <h1>MES-RTM</h1>
            <p>SMT 实时制造执行子系统</p>
          </div>
        </div>

        <div class="factory-grid">
          <div>
            <strong>4</strong>
            <span>产线在线</span>
          </div>
          <div>
            <strong>30s</strong>
            <span>数据刷新</span>
          </div>
          <div>
            <strong>24h</strong>
            <span>现场看板</span>
          </div>
        </div>

        <div class="login-note">
          <span class="note-dot" />
          <p>面向车间工位、生产调度、质量拦截与大屏看板的统一入口。</p>
        </div>
      </div>

      <div class="login-panel">
        <div class="panel-title">
          <h2>{{ panelTitle }}</h2>
          <p>{{ panelDesc }}</p>
        </div>

        <div class="mode-switch" role="tablist" aria-label="登录注册切换">
          <button type="button" :class="{ active: activeMode === 'login' }" @click="switchMode('login')">
            登录
          </button>
          <button type="button" :class="{ active: activeMode === 'register' }" @click="switchMode('register')">
            注册
          </button>
        </div>

        <el-form v-if="activeMode === 'login'" :model="loginForm" class="login-form" @submit.prevent="handleLogin">
          <el-form-item>
            <el-input v-model="loginForm.username" :prefix-icon="User" size="large" placeholder="请输入用户名" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="loginForm.password" :prefix-icon="Lock" type="password" size="large" show-password placeholder="请输入密码" />
          </el-form-item>
          <el-button type="primary" size="large" :loading="loading" class="login-btn" native-type="submit">
            登录系统
          </el-button>
        </el-form>

        <el-form v-else :model="registerForm" class="login-form register-form" @submit.prevent="handleRegister">
          <el-form-item class="full">
            <el-input v-model="registerForm.username" :prefix-icon="User" size="large" placeholder="用户账号（必填）" />
          </el-form-item>
          <el-form-item class="full">
            <el-input v-model="registerForm.password" :prefix-icon="Lock" type="password" size="large" show-password placeholder="登录密码（必填）" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="registerForm.fullName" :prefix-icon="UserFilled" size="large" placeholder="真实姓名" />
          </el-form-item>
          <el-form-item>
            <el-select v-model="registerForm.position" size="large" class="role-select" placeholder="岗位">
              <el-option v-for="position in positionOptions" :key="position" :label="position" :value="position" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-input v-model="registerForm.department" :prefix-icon="OfficeBuilding" size="large" placeholder="所属部门" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="registerForm.contact" :prefix-icon="Phone" size="large" placeholder="联系方式" />
          </el-form-item>
          <el-button type="primary" size="large" :loading="loading" class="login-btn" native-type="submit">
            创建账号
          </el-button>
        </el-form>
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.login-container {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
  background:
    linear-gradient(90deg, rgba(255, 255, 255, 0.04) 1px, transparent 1px),
    linear-gradient(rgba(255, 255, 255, 0.035) 1px, transparent 1px),
    #17202c;
  background-size: 34px 34px;
}

.login-shell {
  width: min(920px, 100%);
  display: grid;
  grid-template-columns: 1.08fr 0.92fr;
  overflow: hidden;
  border: 1px solid rgba(216, 222, 230, 0.2);
  border-radius: 8px;
  background: #fff;
  box-shadow: 0 24px 70px rgba(0, 0, 0, 0.28);
}

.login-panel {
  padding: 42px;
  background: #fff;
}

.brand {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 28px;

  h1 {
    color: #111827;
    font-size: 28px;
    letter-spacing: 0;
  }

  p {
    margin-top: 4px;
    color: #667085;
  }
}

.brand.dark {
  margin-bottom: 44px;

  h1 {
    color: #f8fafc;
  }

  p {
    color: #9cadbf;
  }
}

.brand-mark {
  width: 54px;
  height: 54px;
  display: grid;
  place-items: center;
  border-radius: 6px;
  background: #1f5f99;
  color: #fff;
  font-size: 18px;
  font-weight: 800;
}

.login-info {
  padding: 42px;
  background:
    linear-gradient(135deg, rgba(31, 95, 153, 0.14), transparent 52%),
    #202b38;
  color: #f8fafc;
}

.factory-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}

.factory-grid div {
  min-height: 96px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 14px;
  border: 1px solid rgba(216, 222, 230, 0.22);
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.05);
}

.factory-grid strong {
  font-size: 28px;
  line-height: 1;
}

.factory-grid span {
  margin-top: 10px;
  color: #aab8c7;
  font-size: 13px;
}

.login-note {
  display: flex;
  gap: 10px;
  margin-top: 34px;
  padding: 14px;
  border: 1px solid rgba(216, 222, 230, 0.18);
  border-radius: 6px;
  color: #c8d2df;
  line-height: 1.7;
}

.note-dot {
  width: 9px;
  height: 9px;
  flex: 0 0 auto;
  margin-top: 8px;
  border-radius: 50%;
  background: #42b883;
  box-shadow: 0 0 0 4px rgba(66, 184, 131, 0.14);
}

.panel-title {
  margin-bottom: 24px;

  h2 {
    color: var(--rtm-text);
    font-size: 24px;
  }

  p {
    margin-top: 6px;
    color: var(--rtm-text-soft);
    font-size: 13px;
  }
}

.mode-switch {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 4px;
  margin-bottom: 22px;
  padding: 4px;
  border: 1px solid #d8dee6;
  border-radius: 6px;
  background: #f3f6f9;
}

.mode-switch button {
  min-height: 40px;
  border: 0;
  border-radius: 4px;
  background: transparent;
  color: #526170;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.2s ease, color 0.2s ease, box-shadow 0.2s ease;
}

.mode-switch button.active {
  background: #1f5f99;
  color: #fff;
  box-shadow: 0 8px 20px rgba(31, 95, 153, 0.22);
}

.login-form :deep(.el-form-item) {
  margin-bottom: 16px;
}

.register-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  column-gap: 12px;
}

.register-form .full,
.register-form .login-btn {
  grid-column: 1 / -1;
}

.role-select,
.login-btn {
  width: 100%;
}

@media (max-width: 820px) {
  .login-shell {
    grid-template-columns: 1fr;
  }

  .login-info {
    display: none;
  }

  .register-form {
    grid-template-columns: 1fr;
  }
}
</style>
