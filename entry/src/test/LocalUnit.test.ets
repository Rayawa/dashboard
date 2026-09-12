import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from "@ohos/hypium";
import { buildAppsPagePath } from '../main/ets/common/AppListQuery';

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
    });
}
