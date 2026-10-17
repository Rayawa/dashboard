/** 新发现组件统一使用应用主题资源，避免落回系统默认按钮蓝色。 */
export class DiscoveryButtonStyle implements AttributeModifier<ButtonAttribute> {
    applyNormalAttribute(button: ButtonAttribute): void {
        button.backgroundColor($r('app.color.v3_surface_alt'))
            .fontColor($r('app.color.diff_content'));
    }
}
export class DiscoverySelectStyle implements AttributeModifier<SelectAttribute> {
    applyNormalAttribute(select: SelectAttribute): void {
        select.backgroundColor($r('app.color.v3_surface_alt')).fontColor($r('app.color.v3_text_primary'))
            .optionBgColor($r('app.color.v3_surface')).optionFontColor($r('app.color.v3_text_primary'))
            .selectedOptionBgColor($r('app.color.v3_surface_alt')).selectedOptionFontColor($r('app.color.diff_content'));
    }
}
