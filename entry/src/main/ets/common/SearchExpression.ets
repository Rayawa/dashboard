import type { SearchCondition, SearchExpression, SearchOperator } from './types';

export interface SearchFieldOption {
    label: string;
    key: string;
    kind: 'text' | 'number' | 'array';
}

export interface SearchOperatorOption {
    label: string;
    op: SearchOperator;
}

export const ADVANCED_SEARCH_FIELDS: SearchFieldOption[] = [
    { label: '应用名称', key: 'name', kind: 'text' },
    { label: '包名', key: 'pkg_name', kind: 'text' },
    { label: '开发者', key: 'developer_name', kind: 'text' },
    { label: '分类', key: 'kind_name', kind: 'text' },
    { label: '分类类型', key: 'kind_type_name', kind: 'text' },
    { label: '下载量', key: 'download_count', kind: 'number' },
    { label: '平均评分', key: 'average_rating', kind: 'number' },
    { label: '评分数量', key: 'total_star_rating_count', kind: 'number' },
    { label: '最低 SDK', key: 'minsdk', kind: 'number' },
    { label: '目标 SDK', key: 'target_sdk', kind: 'number' },
    { label: '支持设备', key: 'main_device_codes', kind: 'array' },
];

export const ADVANCED_SEARCH_OPERATORS: SearchOperatorOption[] = [
    { label: '等于', op: 'eq' },
    { label: '不等于', op: 'ne' },
    { label: '包含（区分大小写）', op: 'like' },
    { label: '不包含（区分大小写）', op: 'not_like' },
    { label: '包含（忽略大小写）', op: 'i_like' },
    { label: '不包含（忽略大小写）', op: 'not_i_like' },
    { label: '大于', op: 'gt' },
    { label: '大于或等于', op: 'gte' },
    { label: '小于', op: 'lt' },
    { label: '小于或等于', op: 'lte' },
    { label: '为空', op: 'is_null' },
    { label: '不为空', op: 'is_not_null' },
    { label: '数组包含全部', op: 'array_contains' },
    { label: '数组存在交集', op: 'array_overlaps' },
    { label: '数组被包含', op: 'array_contained_by' },
];

export function operatorNeedsValue(operator: SearchOperator): boolean {
    return operator !== 'is_null' && operator !== 'is_not_null';
}

export function operatorsForField(key: string): SearchOperatorOption[] {
    const field = ADVANCED_SEARCH_FIELDS.find((item: SearchFieldOption): boolean => item.key === key);
    const allowed: SearchOperator[] = field?.kind === 'array' ?
        ['array_contains', 'array_overlaps', 'array_contained_by', 'is_null', 'is_not_null'] :
        field?.kind === 'number' ?
            ['eq', 'ne', 'gt', 'gte', 'lt', 'lte', 'is_null', 'is_not_null'] :
            ['eq', 'ne', 'like', 'not_like', 'i_like', 'not_i_like', 'is_null', 'is_not_null'];
    return ADVANCED_SEARCH_OPERATORS.filter((item: SearchOperatorOption): boolean =>
        allowed.indexOf(item.op) >= 0);
}

export function defaultOperatorForField(key: string): SearchOperator {
    const field = ADVANCED_SEARCH_FIELDS.find((item: SearchFieldOption): boolean => item.key === key);
    if (field?.kind === 'array') return 'array_contains';
    if (field?.kind === 'number') return 'gte';
    return 'i_like';
}

export function normalizeSearchConditions(conditions: SearchCondition[]): SearchCondition[] {
    const normalized: SearchCondition[] = [];
    for (const condition of conditions) {
        const key = condition.key.trim();
        const value = condition.value?.trim() ?? '';
        if (!key) continue;
        if (operatorNeedsValue(condition.op) && !value) continue;
        normalized.push({
            key,
            op: condition.op,
            value: operatorNeedsValue(condition.op) ? value : null,
        });
    }
    return normalized;
}

export function buildSearchExpression(
    logic: 'and' | 'or',
    conditions: SearchCondition[],
): SearchExpression | undefined {
    const normalized = normalizeSearchConditions(conditions);
    if (normalized.length === 0) return undefined;
    return logic === 'and' ? { and: normalized } : { or: normalized };
}
