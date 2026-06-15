import dayjs from 'dayjs'

export function formatDate(value, format = 'YYYY-MM-DD') {
  if (!value) return ''
  return dayjs(value).format(format)
}

export function formatDateTime(value) {
  return formatDate(value, 'YYYY-MM-DD HH:mm:ss')
}

export function formatPercent(value, decimals = 1) {
  if (value == null) return '--'
  return `${(value * 100).toFixed(decimals)}%`
}

export function generateWorkOrderNo() {
  const date = dayjs().format('YYYYMMDD')
  const seq = String(Math.floor(Math.random() * 9999) + 1).padStart(4, '0')
  return `WO${date}${seq}`
}

export function generateBatchNo() {
  const date = dayjs().format('YYYYMMDD')
  const seq = String(Math.floor(Math.random() * 999) + 1).padStart(3, '0')
  return `LOT${date}${seq}`
}
