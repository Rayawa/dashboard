@Component
export struct RollingNumber {
    @Prop @Watch('animateValue') value: number = 0;
    @Prop fontSize: number = 24;
    @Prop color: ResourceColor = $r('app.color.diff_content');
    @Prop accessibilityLabel: string = '';
    @State private displayedValue: number = 0;
    private animationToken: number = 0;
    private animationTimer: number = -1;

    private animateValue(): void {
        const target = Math.max(0, Math.round(this.value));
        const token = ++this.animationToken;
        this.displayedValue = 0;
        if (this.animationTimer >= 0) clearTimeout(this.animationTimer);
        this.animationTimer = setTimeout((): void => {
            this.animationTimer = -1;
            if (token !== this.animationToken) return;
            this.getUIContext().animateTo({ duration: 1000, curve: Curve.EaseOut }, (): void => {
                this.displayedValue = target;
            });
        }, 60);
    }

    aboutToAppear(): void {
        this.animateValue();
    }

    aboutToDisappear(): void {
        this.animationToken++;
        if (this.animationTimer >= 0) {
            clearTimeout(this.animationTimer);
            this.animationTimer = -1;
        }
    }

    build() {
        Text(String(this.displayedValue))
            .fontSize(this.fontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.color)
            .maxLines(1)
            .contentTransition(new NumericTextTransition({
                flipDirection: FlipDirection.DOWN,
                enableBlur: true,
            }))
            .accessibilityText(`${this.accessibilityLabel}${this.value}`)
    }
}
