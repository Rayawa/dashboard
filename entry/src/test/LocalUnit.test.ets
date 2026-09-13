import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from "@ohos/hypium";
import { buildAppsPagePath } from '../main/ets/common/AppListQuery';
import { buildAdvancedAppsQueryPath, buildDeveloperRankingPath, buildDownloadGrowthPath } from '../main/ets/common/RankingQuery';
import {
    buildSearchExpression,
    defaultOperatorForField,
    normalizeSearchConditions,
    operatorNeedsValue,
    operatorsForField,
} from '../main/ets/common/SearchExpression';
import { formatDuration } from '../main/ets/common/format';

export default function localUnitTest() {
    describe("localUnitTest", () => {
        // Defines a test suite. Two parameters are supported: test suite name and test suite function.
        beforeAll(() => {
            // Presets an action, which is performed only once before all test cases of the test suite start.
            // This API supports only one parameter: preset action function.
        });
        beforeEach(() => {
            // Presets an action, which is performed before each unit test case starts.
            // The number of execution times is the same as the number of test cases defined by **it**.
            // This API supports only one parameter: preset action function.
        });
        afterEach(() => {
            // Presets a clear action, which is performed after each unit test case ends.
            // The number of execution times is the same as the number of test cases defined by **it**.
            // This API supports only one parameter: clear action function.
        });
        afterAll(() => {
            // Presets a clear action, which is performed after all test cases of the test suite end.
            // This API supports only one parameter: clear action function.
        });
        it("assertContain", 0, () => {
            // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
            let a = "abc";
            let b = "b";
            // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
            expect(a).assertContain(b);
            expect(a).assertEqual(a);
        });
        it('buildAppsPagePathIncludesHuaweiByDefault', 0, () => {
            const path = buildAppsPagePath({
                page: 1,
                pageSize: 20,
                sort: 'total_star_rating_count',
                desc: true,
                excludeHuawei: false,
            });
            expect(path.includes('exclude_huawei')).assertFalse();
            expect(path).assertContain('sort=total_star_rating_count');
            expect(path).assertContain('desc=true');
        });
        it('buildAppsPagePathEncodesFilters', 0, () => {
            const path = buildAppsPagePath({
                page: 0,
                pageSize: 50,
                sort: 'updated_at',
                desc: false,
                searchKey: 'developer_name',
                searchValue: '测试 开发者',
                exact: true,
                excludeHuawei: true,
                excludeAtomic: true,
            });
            expect(path).assertContain('apps/list/1?');
            expect(path).assertContain('search_value=%E6%B5%8B%E8%AF%95%20%E5%BC%80%E5%8F%91%E8%80%85');
            expect(path).assertContain('search_exact=true');
            expect(path).assertContain('exclude_huawei=true');
            expect(path).assertContain('exclude_atomic=true');
        });
        it('buildAdvancedSearchExpressionSupportsLogicAndSpecialOperators', 0, () => {
            const expression = buildSearchExpression('and', [
                { key: 'download_count', op: 'gte', value: '10000' },
                { key: 'developer_name', op: 'is_not_null', value: '' },
                { key: 'main_device_codes', op: 'array_contains', value: 'phone,tablet' },
            ]);
            expect(expression !== undefined).assertTrue();
            expect(expression?.and?.length).assertEqual(3);
            expect(expression?.and?.[1].value).assertNull();
            expect(operatorNeedsValue('is_null')).assertFalse();
            expect(operatorNeedsValue('array_overlaps')).assertTrue();
        });
        it('normalizeSearchConditionsDropsIncompleteValues', 0, () => {
            const normalized = normalizeSearchConditions([
                { key: 'name', op: 'i_like', value: '  地图  ' },
                { key: 'developer_name', op: 'eq', value: '   ' },
            ]);
            expect(normalized.length).assertEqual(1);
            expect(normalized[0].value).assertEqual('地图');
        });
        it('advancedSearchOperatorsFollowFieldTypes', 0, () => {
            expect(defaultOperatorForField('main_device_codes')).assertEqual('array_contains');
            expect(defaultOperatorForField('download_count')).assertEqual('gte');
            expect(operatorsForField('main_device_codes').some((item) => item.op === 'array_overlaps')).assertTrue();
            expect(operatorsForField('name').some((item) => item.op === 'array_overlaps')).assertFalse();
        });
        it('rankingPathsMatchApiContract', 0, () => {
            expect(buildAdvancedAppsQueryPath({ page: 2, pageSize: 50, sort: 'download_count', desc: true }))
                .assertContain('apps/query?page=2&page_size=50&detail=true&sort=download_count&desc=true');
            expect(buildDownloadGrowthPath({ days: 7, limit: 10, page: 1, excludeHuawei: false }))
                .assertContain('rankings/download_increase?days=7&limit=10&page=1');
            expect(buildDeveloperRankingPath(10, 2)).assertEqual('rankings/developers?limit=10&page=2');
        });
        it('formatDurationUsesReadableUnits', 0, () => {
            expect(formatDuration(65)).assertEqual('1分5秒');
            expect(formatDuration(7200)).assertEqual('2小时0分');
        });
    });
}
