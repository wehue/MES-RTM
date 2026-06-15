import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  const sidebarCollapsed = ref(false)
  const refreshInterval = ref(30000)
  const pageSize = ref(20)

  function toggleSidebar() {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }

  function setRefreshInterval(val) {
    refreshInterval.value = val
  }

  function setPageSize(val) {
    pageSize.value = val
  }

  return { sidebarCollapsed, refreshInterval, pageSize, toggleSidebar, setRefreshInterval, setPageSize }
})
