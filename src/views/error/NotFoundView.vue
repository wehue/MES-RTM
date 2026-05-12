<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <div class="not-found">
    <h1>404</h1>
    <p>页面不存在</p>
    <el-button type="primary" @click="router.push('/dashboard')">返回首页</el-button>
  </div>
</template>

<style lang="scss" scoped>
.not-found {
  height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #f0f2f5;

  h1 {
    font-size: 72px;
    color: #409eff;
    margin-bottom: 16px;
  }

  p {
    font-size: 18px;
    color: #909399;
    margin-bottom: 24px;
  }
}
</style>
