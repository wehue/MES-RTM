<script setup>
import { computed, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Lock, User } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import { firstAccessiblePath, ROLES } from '@/utils/constants'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const loginForm = ref({
  username: 'admin',
  password: '123456',
  role: 'admin',
})
const loading = ref(false)

const roleName = computed(() => ROLES.find((item) => item.value === loginForm.value.role)?.label || '工厂管理层')

async function handleLogin() {
  loading.value = true
  try {
    userStore.setToken('mock-token')
    userStore.setUserInfo({
      id: 'U001',
      username: loginForm.value.username,
      name: roleName.value,
      department: loginForm.value.role === 'quality_engineer' ? '质量部' : '生产部',
      post: roleName.value,
      role: loginForm.value.role,
      roles: [loginForm.value.role],
      lines: loginForm.value.role === 'team_leader' || loginForm.value.role === 'operator' ? ['SMT-A1', 'SMT-A2'] : ['SMT-A1', 'SMT-A2', 'SMT-B1', 'SMT-B2'],
    })
    router.push(route.query.redirect || firstAccessiblePath(loginForm.value.role))
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
          <h2>系统登录</h2>
          <p>选择角色后进入对应权限范围的业务页面。</p>
        </div>
        <el-form :model="loginForm" class="login-form" @submit.prevent="handleLogin">
          <el-form-item>
            <el-input v-model="loginForm.username" :prefix-icon="User" size="large" placeholder="请输入用户名" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="loginForm.password" :prefix-icon="Lock" type="password" size="large" show-password placeholder="请输入密码" />
          </el-form-item>
          <el-form-item>
            <el-select v-model="loginForm.role" size="large" class="role-select" placeholder="选择演示角色">
              <el-option v-for="role in ROLES" :key="role.value" :label="role.label" :value="role.value" />
            </el-select>
          </el-form-item>
          <el-button type="primary" size="large" :loading="loading" class="login-btn" native-type="submit">
            登录系统
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
}
</style>
