<script setup>
import { reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Lock, User } from '@element-plus/icons-vue'
import { loginUser } from '@/api/user'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const loginForm = reactive({
  username: 'admin',
  password: '123456',
})
const loading = ref(false)

// 兼容后端两种返回结构：扁平 token/userInfo 或嵌套 { token, userInfo }
function extractLoginResult(result = {}) {
  const userInfo = result.userInfo || result
  const token = result.token
  return { token, userInfo }
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
    const { token, userInfo } = extractLoginResult(result)
    userStore.setToken(token)
    userStore.setUserInfo(userInfo)
    try {
      await userStore.fetchCurrentFunctions()
    } catch (e) {
      // 权限接口失败时不应阻断登录流程，但仍提示用户
      console.error('加载用户功能权限失败：', e)
      ElMessage.warning('登录已成功，但功能权限加载失败，部分菜单可能不可见')
    }
    ElMessage.success('登录成功')
    router.push(route.query.redirect || userStore.firstAccessiblePath())
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
        <div class="panel-decoration" />

        <div class="panel-title">
          <div class="title-icon">
            <el-icon :size="28"><User /></el-icon>
          </div>
          <h2>欢迎登录</h2>
          <p>使用系统账号与密码进入生产执行工作台</p>
        </div>

        <el-form :model="loginForm" class="login-form" @submit.prevent="handleLogin">
          <el-form-item>
            <el-input v-model="loginForm.username" :prefix-icon="User" size="large" placeholder="请输入用户名" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="loginForm.password" :prefix-icon="Lock" type="password" size="large" show-password placeholder="请输入密码" />
          </el-form-item>
          <el-button type="primary" size="large" :loading="loading" class="login-btn" native-type="submit">
            <span class="btn-text">登录系统</span>
            <span class="btn-arrow">→</span>
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
  position: relative;
  padding: 48px 42px 36px;
  background: #fff;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.panel-decoration {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 5px;
  background: linear-gradient(90deg, #1f5f99 0%, #42b883 100%);
}

.panel-decoration::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 200px;
  height: 200px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(31, 95, 153, 0.06) 0%, transparent 70%);
  pointer-events: none;
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
  grid-template-columns: repeat(2, 1fr);
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
  margin-bottom: 28px;

  .title-icon {
    width: 56px;
    height: 56px;
    display: grid;
    place-items: center;
    border-radius: 12px;
    background: linear-gradient(135deg, rgba(31, 95, 153, 0.1), rgba(66, 184, 131, 0.1));
    color: #1f5f99;
    margin-bottom: 18px;
  }

  h2 {
    color: var(--rtm-text);
    font-size: 26px;
    font-weight: 700;
    letter-spacing: 0.5px;
  }

  p {
    margin-top: 8px;
    color: var(--rtm-text-soft);
    font-size: 13px;
  }
}

.login-form {
  flex: 1;
}

.login-form :deep(.el-form-item) {
  margin-bottom: 18px;
}

.login-form :deep(.el-input__wrapper) {
  border-radius: 8px;
  transition: box-shadow 0.2s ease;
}

.login-form :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px #1f5f99 inset, 0 0 0 3px rgba(31, 95, 153, 0.1);
}

.login-btn {
  width: 100%;
  height: 46px;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 1px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: transform 0.15s ease, box-shadow 0.2s ease;
}

.login-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 22px rgba(31, 95, 153, 0.28);
}

.login-btn:active {
  transform: translateY(0);
}

.btn-arrow {
  font-size: 18px;
  transition: transform 0.15s ease;
}

.login-btn:hover .btn-arrow {
  transform: translateX(4px);
}

.panel-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 32px;
  padding-top: 20px;
  border-top: 1px solid #f0f2f5;
  color: #9ca3af;
  font-size: 12px;
}

.footer-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #42b883;
  box-shadow: 0 0 0 3px rgba(66, 184, 131, 0.15);
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
