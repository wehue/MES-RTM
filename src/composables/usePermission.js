import { useUserStore } from '@/stores/user'

export function usePermission() {
  const userStore = useUserStore()

  function hasRole(role) {
    return userStore.hasRole(role)
  }

  function hasAnyRole(roles) {
    return roles.some((role) => userStore.hasRole(role))
  }

  function canOperate(roles) {
    return hasAnyRole(roles)
  }

  return { hasRole, hasAnyRole, canOperate }
}
