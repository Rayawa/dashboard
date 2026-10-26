import { formatDateTime } from '../../utils/format/format';
import type { VersionChange } from '../../models/types';

@Component
export struct VersionChangeRow {
    @Require @Prop change: VersionChange;
    @State private expanded: boolean = false;
    build() {
        Column({ space: 6 }) {
            Text(this.change.version).fontSize(15).fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            Text(formatDateTime(this.change.observedAt)).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary')).width('100%')
            Text(this.change.summary).fontSize(13).fontColor($r('app.color.diff_content')).width('100%')
            if (this.change.notes) {
                Text(this.change.notes).fontSize(13).fontColor($r('app.color.v3_text_secondary')).width('100%')
                    .maxLines(this.expanded ? 10000 : 6).textOverflow({ overflow: TextOverflow.Ellipsis })
                if (this.change.notes.length > 180) {
                    Button(this.expanded ? '收起说明' : '展开说明').fontSize(12)
                        .onClick((): void => { this.expanded = !this.expanded; })
                }
            }
            Divider().color($r('app.color.v3_chart_grid')).margin({ top: 6 })
        }.width('100%').accessibilityGroup(true)
    }
}
