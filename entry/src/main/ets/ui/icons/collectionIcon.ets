import { SymbolGlyphModifier } from '@kit.ArkUI';

/** 收藏标题按钮统一使用 24vp 系统星标。 */
export function collectionStarIcon(saved: boolean): SymbolGlyphModifier {
    return new SymbolGlyphModifier(saved ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
        .fontSize(24)
        .fontColor([saved ? $r('app.color.diff_content') : $r('sys.color.icon_primary')]);
}
