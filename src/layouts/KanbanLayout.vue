<script setup>
</script>

<template>
  <div class="kanban-layout">
    <router-view />
  </div>
</template>

<style lang="scss" scoped>
.kanban-layout {
  width: 100%;
  height: calc(100vh - 56px);
  overflow: hidden;
  background: #0d1b2a;
}
</style>
