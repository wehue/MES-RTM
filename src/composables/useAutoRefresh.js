import { ref, onMounted, onUnmounted } from 'vue'
import { useAppStore } from '@/stores/app'

export function useAutoRefresh(fetchFn, immediate = true) {
  const appStore = useAppStore()
  const data = ref(null)
  const loading = ref(false)
  let timer = null

  async function refresh() {
    loading.value = true
    try {
      data.value = await fetchFn()
    } finally {
      loading.value = false
    }
  }

  function startAutoRefresh() {
    stopAutoRefresh()
    if (immediate) refresh()
    timer = setInterval(refresh, appStore.refreshInterval)
  }

  function stopAutoRefresh() {
    if (timer) {
      clearInterval(timer)
      timer = null
    }
  }

  onMounted(() => {
    startAutoRefresh()
  })

  onUnmounted(() => {
    stopAutoRefresh()
  })

  return { data, loading, refresh, startAutoRefresh, stopAutoRefresh }
}
