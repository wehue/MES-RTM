<script setup>
import { computed } from 'vue'

const props = defineProps({
  meta: { type: Object, required: true },
  effect: { type: String, default: 'light' },
})

const tagType = computed(() => props.meta.type || 'info')
</script>

<template>
  <el-tag :type="tagType" :effect="effect" round>
    <span class="status-dot" :style="{ backgroundColor: meta.color }" />
    {{ meta.label }}
  </el-tag>
</template>

<style scoped>
.status-dot {
  width: 7px;
  height: 7px;
  display: inline-block;
  margin-right: 6px;
  border-radius: 50%;
}
</style>
