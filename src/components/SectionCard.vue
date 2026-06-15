<script setup>
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
})
</script>

<template>
  <el-card class="section-card" shadow="never">
    <template #header>
      <div class="section-header">
        <div>
          <h2>{{ title }}</h2>
          <p v-if="subtitle">{{ subtitle }}</p>
        </div>
        <slot name="actions" />
      </div>
    </template>
    <slot />
  </el-card>
</template>

<style lang="scss" scoped>
.section-card {
  border: 1px solid #dfe7f1;
  border-radius: var(--rtm-radius);
  background: var(--rtm-panel);
  box-shadow: 0 8px 22px rgba(23, 32, 44, 0.06);

  :deep(.el-card__header) {
    padding: 16px 20px;
    border-bottom: 1px solid var(--rtm-line);
    background: linear-gradient(180deg, #fbfdff 0%, #f6f9fc 100%);
  }

  :deep(.el-card__body) {
    padding: 20px;
  }
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;

  h2 {
    position: relative;
    padding-left: 14px;
    color: var(--rtm-text);
    font-size: 17px;
    font-weight: 800;

    &::before {
      position: absolute;
      top: 2px;
      bottom: 2px;
      left: 0;
      width: 4px;
      border-radius: 2px;
      background: var(--rtm-primary);
      content: '';
    }
  }

  p {
    margin-top: 5px;
    color: var(--rtm-text-soft);
    font-size: 14px;
  }
}
</style>
