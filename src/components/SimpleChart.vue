<script setup>
import { computed } from 'vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart, PieChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components'

use([CanvasRenderer, LineChart, BarChart, PieChart, GridComponent, TooltipComponent, LegendComponent])

const props = defineProps({
  type: { type: String, default: 'line' },
  x: { type: Array, default: () => [] },
  series: { type: Array, default: () => [] },
  data: { type: Array, default: () => [] },
  height: { type: String, default: '280px' },
  theme: { type: String, default: 'light' },
})

const option = computed(() => {
  const isDark = props.theme === 'dark'
  const textColor = isDark ? '#ffffff' : '#334155'
  const splitColor = isDark ? '#2d5f99' : '#eef2f7'

  if (props.type === 'pie') {
    return {
      color: ['#38bdf8', '#22c55e', '#f59e0b', '#ef4444', '#a78bfa'],
      tooltip: { trigger: 'item' },
      legend: { bottom: 0, left: 'center', textStyle: { color: textColor, fontSize: 16, fontWeight: 600 } },
      series: [
        {
          type: 'pie',
          radius: ['42%', '68%'],
          center: ['50%', '42%'],
          data: props.data,
          label: { formatter: '{b} {d}%', color: textColor, fontSize: 16, fontWeight: 700 },
        },
      ],
    }
  }

  return {
    color: isDark ? ['#60a5fa', '#22c55e', '#fbbf24', '#f87171'] : ['#2563eb', '#16a34a', '#d97706', '#dc2626'],
    tooltip: { trigger: 'axis' },
    legend: { top: 0, textStyle: { color: textColor, fontSize: 16, fontWeight: 600 } },
    grid: { left: 38, right: 20, top: 42, bottom: 28 },
    xAxis: { type: 'category', data: props.x, axisTick: { show: false }, axisLabel: { color: textColor, fontSize: 15, fontWeight: 600 }, axisLine: { lineStyle: { color: splitColor } } },
    yAxis: { type: 'value', axisLabel: { color: textColor, fontSize: 15, fontWeight: 600 }, splitLine: { lineStyle: { color: splitColor } } },
    series: props.series.map((item) => ({
      ...item,
      type: props.type,
      smooth: props.type === 'line',
      barWidth: props.type === 'bar' ? 16 : undefined,
    })),
  }
})
</script>

<template>
  <v-chart class="chart" :style="{ height }" :option="option" autoresize />
</template>

<style scoped>
.chart {
  width: 100%;
}
</style>
