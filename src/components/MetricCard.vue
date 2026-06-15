<script setup>
defineProps({
  title: { type: String, required: true },
  value: { type: [String, Number], required: true },
  unit: { type: String, default: '' },
  trend: { type: String, default: '' },
  tone: { type: String, default: 'primary' },
  icon: { type: [Object, String], default: null },
})
</script>

<template>
  <el-card class="metric-card" :class="`is-${tone}`" shadow="never">
    <div class="metric-content">
      <div class="metric-main">
        <p class="metric-title">{{ title }}</p>
        <div class="metric-value">
          <span>{{ value }}</span>
          <small v-if="unit">{{ unit }}</small>
        </div>
        <p v-if="trend" class="metric-trend">{{ trend }}</p>
      </div>
      <div v-if="icon" class="metric-icon" :class="`is-${tone}`">
        <el-icon><component :is="icon" /></el-icon>
      </div>
    </div>
  </el-card>
</template>

<style lang="scss" scoped>
.metric-card {
  position: relative;
  overflow: hidden;
  min-height: 118px;
  color: var(--rtm-primary);
  border: 1px solid #dfe7f1;
  border-radius: var(--rtm-radius);
  background:
    linear-gradient(135deg, rgba(31, 95, 153, 0.09) 0%, rgba(31, 95, 153, 0) 44%),
    linear-gradient(180deg, #ffffff 0%, #f7f9fc 100%);
  box-shadow: 0 8px 22px rgba(23, 32, 44, 0.07);

  &::before {
    position: absolute;
    right: -34px;
    bottom: -34px;
    width: 96px;
    height: 96px;
    border: 18px solid rgba(31, 95, 153, 0.08);
    border-radius: 50%;
    background: currentColor;
    content: '';
  }

  &::after {
    position: absolute;
    top: 16px;
    left: 0;
    width: 4px;
    height: 46px;
    border-radius: 0 3px 3px 0;
    background: currentColor;
    content: '';
  }

  :deep(.el-card__body) {
    position: relative;
    z-index: 1;
    height: 100%;
    padding: 18px 18px 16px 20px;
  }
}

.metric-card.is-success {
  color: var(--rtm-success);
  background:
    linear-gradient(135deg, rgba(25, 135, 84, 0.1) 0%, rgba(25, 135, 84, 0) 44%),
    linear-gradient(180deg, #ffffff 0%, #f7f9fc 100%);
}

.metric-card.is-warning {
  color: var(--rtm-warning);
  background:
    linear-gradient(135deg, rgba(183, 121, 31, 0.12) 0%, rgba(183, 121, 31, 0) 44%),
    linear-gradient(180deg, #ffffff 0%, #f7f9fc 100%);
}

.metric-card.is-danger {
  color: var(--rtm-danger);
  background:
    linear-gradient(135deg, rgba(180, 35, 24, 0.1) 0%, rgba(180, 35, 24, 0) 44%),
    linear-gradient(180deg, #ffffff 0%, #f7f9fc 100%);
}

.metric-card.is-info {
  color: var(--rtm-text-muted);
  background:
    linear-gradient(135deg, rgba(95, 107, 122, 0.1) 0%, rgba(95, 107, 122, 0) 44%),
    linear-gradient(180deg, #ffffff 0%, #f7f9fc 100%);
}

:global(.kanban-page) .metric-card {
  border-color: #2d5f99;
  background: #102038;
  box-shadow: none;

  &::before {
    opacity: 0.22;
  }

  .metric-title,
  .metric-trend,
  .metric-value small {
    color: #d7e5f5;
  }

  .metric-value span {
    color: #f8fafc;
  }
}

:global(.kanban-page) .metric-card.is-success {
  background: #102c2b;
}

:global(.kanban-page) .metric-card.is-warning {
  background: #2d2514;
}

:global(.kanban-page) .metric-card.is-danger {
  background: #321a1d;
}

.metric-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 82px;
}

.metric-main {
  min-width: 0;
}

.metric-title {
  color: var(--rtm-text-soft);
  font-size: 14px;
  font-weight: 700;
  line-height: 1.4;
}

.metric-value {
  display: flex;
  align-items: baseline;
  gap: 4px;
  margin-top: 10px;

  span {
    color: var(--rtm-text);
    font-size: 36px;
    font-weight: 800;
    line-height: 1;
  }

  small {
    color: var(--rtm-text-soft);
    font-size: 15px;
    font-weight: 700;
  }
}

.metric-trend {
  margin-top: 10px;
  color: var(--rtm-text-soft);
  font-size: 12px;
}

.metric-icon {
  flex: 0 0 auto;
  width: 48px;
  height: 48px;
  display: grid;
  place-items: center;
  border-radius: 8px;
  font-size: 23px;

  &.is-primary {
    color: var(--rtm-primary);
    background: #e6eef6;
  }

  &.is-success {
    color: var(--rtm-success);
    background: #e7f3ed;
  }

  &.is-warning {
    color: var(--rtm-warning);
    background: #f7eedb;
  }

  &.is-danger {
    color: var(--rtm-danger);
    background: #f7e7e4;
  }
}
</style>
