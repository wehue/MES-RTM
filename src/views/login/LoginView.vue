<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const loginForm = ref({
  username: '',
  password: '',
})
const loading = ref(false)

async function handleLogin() {
  loading.value = true
  try {
    userStore.setToken('mock-token')
    userStore.setUserInfo({
      id: '1',
      username: loginForm.value.username,
      name: '管理员',
      department: '生产部',
      role: 'admin',
      roles: ['admin'],
    })
    const redirect = route.query.redirect || '/dashboard'
    router.push(redirect)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-container">
    <div class="login-card">
      <h1 class="login-title">MES-RTM</h1>
      <p class="login-subtitle">SMT 实时制造执行系统</p>
      <el-form :model="loginForm" @submit.prevent="handleLogin">
        <el-form-item>
          <el-input
            v-model="loginForm.username"
            placeholder="请输入用户名"
            prefix-icon="User"
            size="large"
          />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入密码"
            prefix-icon="Lock"
            size="large"
            show-password
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            class="login-btn"
            native-type="submit"
          >
            登 录
          </el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.login-container {
  width: 100%;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
}

.login-card {
  width: 400px;
  padding: 40px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

.login-title {
  text-align: center;
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  margin-bottom: 8px;
}

.login-subtitle {
  text-align: center;
  color: #909399;
  margin-bottom: 32px;
}

.login-btn {
  width: 100%;
}
</style>
