import { runPageEnterAnimation, contentEnterTransition } from '../../common/motion';
import { STAGGER_ENTER_DELAY_MS, STAGGER_ENTER_INTERVAL_MS } from '../../common/constants';

@Builder
function emptyDiscoveryContent(): void {}

/** 每次挂载只播放一次；列表延迟封顶，长榜单不等待数秒。 */
@Component
export struct DiscoveryEnter {
    @BuilderParam content: () => void = emptyDiscoveryContent;
    @Prop order: number = 0;
    @State private entered: boolean = false;
    private timer: number = -1;
    private start(): void {
        this.entered = false;
        if (this.timer >= 0) clearTimeout(this.timer);
        this.timer = setTimeout((): void => {
            this.timer = -1;
            runPageEnterAnimation(this.getUIContext(), (): void => { this.entered = true; });
        }, STAGGER_ENTER_DELAY_MS + Math.min(6, Math.max(0, this.order)) * STAGGER_ENTER_INTERVAL_MS);
    }
    aboutToDisappear(): void {
        if (this.timer >= 0) clearTimeout(this.timer);
        this.timer = -1;
    }
    build() {
        Column() { this.content() }
            .width('100%')
            .opacity(this.entered ? 1 : 0)
            .translate({ y: this.entered ? 0 : 20 })
            .transition(contentEnterTransition(10))
            .onAppear((): void => this.start())
    }
}
