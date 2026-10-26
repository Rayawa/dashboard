import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from './visualEffects';

function applyFeedback(attribute: CommonAttribute, pressed: boolean): void {
    attribute.scale({ x: pressed ? 0.97 : 1, y: pressed ? 0.97 : 1 })
        .visualEffect(pressVisualEffect(pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
        .compositingFilter(pressLightFieldFilter(pressed));
}
export class DiscoveryButtonStyle implements AttributeModifier<ButtonAttribute> {
    private pressed: boolean;
    constructor(pressed: boolean = false) { this.pressed = pressed; }
    applyNormalAttribute(button: ButtonAttribute): void {
        button.backgroundColor($r('app.color.v3_surface_alt')).fontColor($r('app.color.diff_content'));
        applyFeedback(button, this.pressed);
    }
}
export class DiscoverySelectStyle implements AttributeModifier<SelectAttribute> {
    private pressed: boolean;
    constructor(pressed: boolean = false) { this.pressed = pressed; }
    applyNormalAttribute(select: SelectAttribute): void {
        select.backgroundColor($r('app.color.v3_surface_alt')).fontColor($r('app.color.v3_text_primary'))
            .optionBgColor($r('app.color.v3_surface')).optionFontColor($r('app.color.diff_content'))
            .selectedOptionBgColor($r('app.color.v3_surface_alt')).selectedOptionFontColor($r('app.color.diff_content'));
        applyFeedback(select, this.pressed);
    }
}
export class DiscoveryToggleStyle implements AttributeModifier<ToggleAttribute> {
    private pressed: boolean;
    constructor(pressed: boolean = false) { this.pressed = pressed; }
    applyNormalAttribute(toggle: ToggleAttribute): void { applyFeedback(toggle, this.pressed); }
}
export class DiscoveryRowStyle implements AttributeModifier<RowAttribute> {
    private pressed: boolean;
    constructor(pressed: boolean = false) { this.pressed = pressed; }
    applyNormalAttribute(row: RowAttribute): void { applyFeedback(row, this.pressed); }
}
