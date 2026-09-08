/**
 * PC/二合一设备的滚轮与触控板会发送轴事件。部分 HDS 容器不会把该事件继续交给
 * 内层 Scroll，因此在页面根容器上显式转发给页面 Scroller。
 */
export function scrollByAxis(scroller: Scroller, event: AxisEvent): void {
    if (event.action !== AxisAction.UPDATE) {
        return;
    }
    try {
        if (event.getModifierKeyState?.(['Ctrl'])) {
            return;
        }
    } catch (_error) {
        // 个别输入设备不支持读取修饰键，仍按普通滚轮事件处理。
    }
    const vertical = event.getVerticalAxisValue();
    const horizontal = event.getHorizontalAxisValue();
    if (!Number.isFinite(vertical) || Math.abs(vertical) < 0.01 ||
        Math.abs(vertical) < Math.abs(horizontal)) {
        return;
    }
    try {
        scroller.scrollBy(0, vertical);
    } catch (error) {
        console.warn('[Dashboard][common/scroll][WARN]', `转发滚轮事件失败: ${JSON.stringify(error)}`);
    }
}
