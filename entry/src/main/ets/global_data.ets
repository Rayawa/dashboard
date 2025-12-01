
export const APP_VERSION: string = "1.1.0-alpha.2";

/**
 * 生成程序 UA
 * 其实应该用个 lazy 的, 懒了
 * @returns
 */
export function APP_UA(): string {
  
  return `${APP_VERSION}`
}
