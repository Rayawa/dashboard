import { hdsEffect } from '@kit.UIDesignKit';
import {
    ADVANCED_SEARCH_FIELDS,
    buildSearchExpression,
    defaultOperatorForField,
    operatorNeedsValue,
    operatorsForField,
} from '../../common/SearchExpression';
import type { SearchOperatorOption } from '../../common/SearchExpression';
import type { SearchCondition, SearchExpression, SearchOperator } from '../../common/types';
import { cancelStaggerEnterAnimation, contentEnterTransition, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { vibration } from '../../common/vibration';

/**
 * API 高级查询的可视化编辑器。这里只负责表达式编辑，分页、排序和网络请求由 AppsPage 统一管理。
 */
@Component
export struct AdvancedSearchPanel {
    @Prop active: boolean = false;
    onApply: (expression: SearchExpression) => void = (): void => {};
    onClear: () => void = (): void => {};
    @State private logicIndex: number = 0;
    @State private conditions: SearchCondition[] = [{ key: 'name', op: 'i_like', value: '' }];
    @State private validationMessage: string = '';
    @State private pressedControl: string = '';
    @State private animStep: number = 0;
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private enterAnimationTimers: number[] = [];
    private readonly logicOptions: SelectOption[] = [{ value: '所有条件（AND）' }, { value: '任一条件（OR）' }];
    private readonly fieldOptions: SelectOption[] = ADVANCED_SEARCH_FIELDS
        .map((item) => ({ value: item.label } as SelectOption));

    private fieldIndex(condition: SearchCondition): number {
        const index = ADVANCED_SEARCH_FIELDS.findIndex((item) => item.key === condition.key);
        return Math.max(0, index);
    }

    private operatorIndex(condition: SearchCondition): number {
        const index = operatorsForField(condition.key).findIndex((item: SearchOperatorOption): boolean =>
            item.op === condition.op);
        return Math.max(0, index);
    }

    private operatorOptions(condition: SearchCondition): SelectOption[] {
        return operatorsForField(condition.key).map((item: SearchOperatorOption) =>
            ({ value: item.label } as SelectOption));
    }

    private vibrate(): void {
        if (this.vibrationLevel > 0) vibration.dotVibration();
    }

    private updatePressed(key: string, event: TouchEvent): void {
        if (event.type === TouchType.Down) this.pressedControl = key;
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedControl = '';
    }

    private startEnterAnimation(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 1, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
    }

    private updateCondition(index: number, key: string, op: SearchOperator, value: string | null): void {
        const updated = this.conditions.slice();
        updated[index] = { key, op, value };
        this.conditions = updated;
        this.validationMessage = '';
    }

    private addCondition(): void {
        this.vibrate();
        this.conditions = this.conditions.concat([{ key: 'name', op: 'i_like', value: '' }]);
        this.validationMessage = '';
    }

    private removeCondition(index: number): void {
        if (this.conditions.length <= 1) return;
        this.vibrate();
        this.conditions = this.conditions.filter((_item: SearchCondition, itemIndex: number): boolean =>
            itemIndex !== index);
        this.validationMessage = '';
    }

    private apply(): void {
        this.vibrate();
        const expression = buildSearchExpression(this.logicIndex === 0 ? 'and' : 'or', this.conditions);
        if (!expression) {
            this.validationMessage = '请至少完整填写一个查询条件';
            return;
        }
        this.validationMessage = '';
        this.onApply(expression);
    }

    private clear(): void {
        this.vibrate();
        this.logicIndex = 0;
        this.conditions = [{ key: 'name', op: 'i_like', value: '' }];
        this.validationMessage = '';
        this.onClear();
    }

    build() {
        Column({ space: 10 }) {
            Row({ space: 10 }) {
                Column({ space: 3 }) {
                    Text('高级组合搜索').fontSize(16).fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                    Text('支持逻辑组合、比较、空值判断与数组条件')
                        .fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                if (this.active) {
                    Text('已生效').fontSize(12).fontColor(Color.White).padding({ left: 10, right: 10, top: 5, bottom: 5 })
                        .borderRadius(12).backgroundColor($r('app.color.diff_content'))
                }
            }.width('100%')

            Select(this.logicOptions).selected(this.logicIndex).value(this.logicOptions[this.logicIndex].value)
                .height(40).backgroundColor($r('app.color.v3_surface'))
                .scale({ x: this.pressedControl === 'logic' ? 0.97 : 1,
                    y: this.pressedControl === 'logic' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedControl === 'logic',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.pressedControl === 'logic'))
                .onTouch((event: TouchEvent): void => this.updatePressed('logic', event))
                .onSelect((index: number): void => {
                    this.vibrate();
                    this.logicIndex = index;
                    this.validationMessage = '';
                })
                .accessibilityText('选择高级搜索条件之间的逻辑关系')

            ForEach(this.conditions, (condition: SearchCondition, index: number) => {
                Column({ space: 8 }) {
                    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                        Select(this.fieldOptions).selected(this.fieldIndex(condition))
                            .value(ADVANCED_SEARCH_FIELDS[this.fieldIndex(condition)].label)
                            .height(40).margin(3).constraintSize({ minWidth: 132 })
                            .backgroundColor($r('app.color.v3_surface'))
                            .scale({ x: this.pressedControl === `field-${index}` ? 0.97 : 1,
                                y: this.pressedControl === `field-${index}` ? 0.97 : 1 })
                            .animation({ duration: 120, curve: Curve.EaseOut })
                            .visualEffect(pressVisualEffect(this.pressedControl === `field-${index}`,
                                hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                            .compositingFilter(pressLightFieldFilter(this.pressedControl === `field-${index}`))
                            .onTouch((event: TouchEvent): void => this.updatePressed(`field-${index}`, event))
                            .onSelect((fieldIndex: number): void => {
                                this.vibrate();
                                this.updateCondition(
                                    index,
                                    ADVANCED_SEARCH_FIELDS[fieldIndex].key,
                                    defaultOperatorForField(ADVANCED_SEARCH_FIELDS[fieldIndex].key),
                                    '',
                                );
                            })
                        Select(this.operatorOptions(condition)).selected(this.operatorIndex(condition))
                            .value(operatorsForField(condition.key)[this.operatorIndex(condition)].label)
                            .height(40).margin(3).constraintSize({ minWidth: 160 })
                            .backgroundColor($r('app.color.v3_surface'))
                            .scale({ x: this.pressedControl === `operator-${index}` ? 0.97 : 1,
                                y: this.pressedControl === `operator-${index}` ? 0.97 : 1 })
                            .animation({ duration: 120, curve: Curve.EaseOut })
                            .visualEffect(pressVisualEffect(this.pressedControl === `operator-${index}`,
                                hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                            .compositingFilter(pressLightFieldFilter(this.pressedControl === `operator-${index}`))
                            .onTouch((event: TouchEvent): void => this.updatePressed(`operator-${index}`, event))
                            .onSelect((operatorIndex: number): void => {
                                this.vibrate();
                                const operator = operatorsForField(condition.key)[operatorIndex].op;
                                this.updateCondition(index, condition.key, operator,
                                    operatorNeedsValue(operator) ? (condition.value ?? '') : null);
                            })
                        if (operatorNeedsValue(condition.op)) {
                            TextInput({ text: condition.value ?? '', placeholder: '输入条件值' })
                                .height(40).margin(3).constraintSize({ minWidth: 180, maxWidth: 300 })
                                .backgroundColor($r('app.color.v3_surface'))
                                .border({ width: 1, color: $r('app.color.nd_card_border') })
                                .scale({ x: this.pressedControl === `value-${index}` ? 0.985 : 1,
                                    y: this.pressedControl === `value-${index}` ? 0.985 : 1 })
                                .animation({ duration: 120, curve: Curve.EaseOut })
                                .visualEffect(pressVisualEffect(this.pressedControl === `value-${index}`,
                                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 4, 72))
                                .compositingFilter(pressLightFieldFilter(this.pressedControl === `value-${index}`))
                                .onTouch((event: TouchEvent): void => this.updatePressed(`value-${index}`, event))
                                .onChange((value: string): void =>
                                    this.updateCondition(index, condition.key, condition.op, value))
                                .accessibilityText(`输入第${index + 1}个高级搜索条件值`)
                        }
                        if (this.conditions.length > 1) {
                            Button('删除', { stateEffect: false }).height(40).margin(3)
                                .fontColor($r('app.color.v3_accent_red'))
                                .backgroundColor($r('app.color.v3_surface'))
                                .scale({ x: this.pressedControl === `remove-${index}` ? 0.97 : 1,
                                    y: this.pressedControl === `remove-${index}` ? 0.97 : 1 })
                                .animation({ duration: 120, curve: Curve.EaseOut })
                                .visualEffect(pressVisualEffect(this.pressedControl === `remove-${index}`,
                                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                                .compositingFilter(pressLightFieldFilter(this.pressedControl === `remove-${index}`))
                                .onTouch((event: TouchEvent): void => this.updatePressed(`remove-${index}`, event))
                                .onClick((): void => this.removeCondition(index))
                                .accessibilityText(`删除第${index + 1}个高级搜索条件`)
                        }
                    }.width('100%')
                    if (condition.op === 'array_contains' || condition.op === 'array_overlaps' ||
                        condition.op === 'array_contained_by') {
                        Text('数组值可用英文逗号分隔，例如 phone,tablet')
                            .fontSize(11).fontColor($r('app.color.v3_text_secondary')).width('100%')
                    }
                }
                .width('100%').padding(8).borderRadius(12)
                .backgroundColor($r('app.color.v3_surface_alt'))
                .transition(contentEnterTransition(6))
            }, (_condition: SearchCondition, index: number) => `advanced-condition-${index}`)

            if (this.validationMessage.length > 0) {
                Text(this.validationMessage).fontSize(12).fontColor($r('app.color.v3_accent_red')).width('100%')
            }
            Flex({ wrap: FlexWrap.Wrap }) {
                Button('添加条件', { stateEffect: false }).height(40).margin(3)
                    .fontColor($r('app.color.diff_content')).backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'add' ? 0.97 : 1,
                        y: this.pressedControl === 'add' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'add',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'add'))
                    .onTouch((event: TouchEvent): void => this.updatePressed('add', event))
                    .onClick((): void => this.addCondition())
                Button('应用高级搜索', { stateEffect: false }).height(40).margin(3)
                    .backgroundColor($r('app.color.diff_content'))
                    .scale({ x: this.pressedControl === 'apply' ? 0.97 : 1,
                        y: this.pressedControl === 'apply' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'apply',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'apply'))
                    .onTouch((event: TouchEvent): void => this.updatePressed('apply', event))
                    .onClick((): void => this.apply())
                Button('清除高级搜索', { stateEffect: false }).height(40).margin(3)
                    .fontColor($r('app.color.v3_text_secondary')).backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'clear' ? 0.97 : 1,
                        y: this.pressedControl === 'clear' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'clear',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'clear'))
                    .onTouch((event: TouchEvent): void => this.updatePressed('clear', event))
                    .onClick((): void => this.clear())
            }.width('100%')
        }
        .width('100%').padding(14).borderRadius(16)
        .backgroundColor($r('app.color.v3_surface_alt'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= 1 ? 1 : 0)
        .translate({ y: this.animStep >= 1 ? 0 : 18 })
        .onAppear((): void => this.startEnterAnimation())
        .accessibilityGroup(true)
        .accessibilityText('高级组合搜索编辑器')
    }
}
