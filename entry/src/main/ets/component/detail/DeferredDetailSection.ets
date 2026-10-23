@Builder
function emptyDetailSection(): void {}

/** Keep a stable placeholder until the section reaches the viewport; preserve mounted state on return. */
@Component
export struct DeferredDetailSection {
    @BuilderParam content: () => void = emptyDetailSection;
    @Prop @Watch('notifyVisibility') active: boolean = true;
    placeholderHeight: number = 280;
    onVisibilityChanged: (visible: boolean) => void = (_visible: boolean): void => {};
    @State private mounted: boolean = false;
    private visible: boolean = false;
    private notifyVisibility(): void {
        if (this.active && this.visible) this.mounted = true;
        this.onVisibilityChanged(this.active && this.visible);
    }
    aboutToDisappear(): void { this.onVisibilityChanged(false); }
    build() {
        Column() {
            if (this.mounted) this.content()
            else Blank().height(this.placeholderHeight).width('100%')
        }
        .width('100%')
        .onVisibleAreaChange([0, 0.01], (visible: boolean, ratio: number): void => {
            this.visible = visible && ratio > 0;
            if (this.visible && this.active) this.mounted = true;
            this.notifyVisibility();
        })
    }
}
