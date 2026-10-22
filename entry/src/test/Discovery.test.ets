import { appIconPath } from '../main/ets/common/AppIconQuery';
import { appCollectionSubtitle } from '../main/ets/common/AppListPresentation';
import { parseLocalCollection } from '../main/ets/common/LocalCollection';
import { describe, it, expect } from '@ohos/hypium';
import { collectionExpression, collectionSort, versionChanges } from '../main/ets/common/DiscoveryQuery';
import { reputationSubtitle, reputationValue } from '../main/ets/common/ReputationPresentation';
import { buildReputationPath, buildCategoryGrowthPath, buildTopicsPath } from '../main/ets/common/RankingQuery';
import { latestDailyMaxRecords } from '../main/ets/common/DailyRanking';
import type { ReputationItem, AppMetric, DailyMaxDownloadApp, MarketApp } from '../main/ets/common/types';

function listApp(): MarketApp {
    return { app_id: 'a', icon_url: '', created_at: '', description: '', dev_en_name: '', developer_name: '开发者甲',
        download_count: 100, kind_name: '工具', kind_type_name: '应用', listed_at: '2026-10-15T00:00:00Z',
        main_device_codes: [], metrics_created_at: '', minsdk: 12, name: '应用甲', pkg_name: 'app.a',
        release_date: 1792022400, size_bytes: 100, updated_at: '', version: '2.0', version_code: 2,
        supplier: '', tag_name: '', target_sdk: 20, compile_sdk_version: 20, average_rating: '4.8', total_star_rating_count: 123 };
}
function metric(date: string, version: string = '1.0', size: number = 100, price: string = '0'): AppMetric {
    return { version, version_code: version === '1.0' ? 1 : 2, size_bytes: size, download_count: 100,
        price, release_date: 0, target_sdk: 20, minsdk: 12, compile_sdk_version: 20,
        min_hmos_api_level: 12, api_release_type: 'Release', created_at: date };
}
export default function discoveryTests() {
    describe('discovery', () => {
        it('reputationQuerySupportsEveryDocumentedCombination', 0, () => {
            const sorts: ('weighted' | 'raw')[] = ['weighted', 'raw'];
            for (const days of [1, 7, 30]) {
                for (const minSamples of [10, 50, 100]) {
                    for (const sort of sorts) {
                        expect(buildReputationPath({ days, minSamples, sort }))
                            .assertEqual(`rankings/reputation?days=${days}&min_samples=${minSamples}&sort=${sort}`);
                    }
                }
            }
        });
        it('reputationQueryEncodesCategoriesAndOmitsPagination', 0, () => {
            const path = buildReputationPath({ days: 30, minSamples: 100, sort: 'raw', kindName: ' 工具 & 效率 ', tagName: 'A/B+C' });
            expect(path).assertEqual('rankings/reputation?days=30&min_samples=100&sort=raw&kind_name=' +
                encodeURIComponent('工具 & 效率') + '&tag_name=A%2FB%2BC');
            expect(path.includes('page=')).assertFalse();
            expect(path.includes('limit=')).assertFalse();
            expect(buildReputationPath({ days: 2, minSamples: 20, kindName: ' ' }))
                .assertEqual('rankings/reputation?days=1&min_samples=10&sort=weighted');
        });
        it('reputationShowsUnclampedMetricsCorrectionsAndActualSpan', 0, () => {
            const item: ReputationItem = {
                app_id: 'a', name: '应用', pkg_name: 'a', developer_name: '开发者', icon_url: '',
                kind_name: '工具', tag_name: null, snapshot_date: '2026-10-19', baseline_date: '2026-10-11',
                actual_days: 8, sample_count: 10, positive_sample_count: 30,
                rating: 7.5, weighted_score: -0.25, confidence_weight: 0.6, has_correction: true,
            };
            expect(reputationValue(item)).assertEqual('加权得分 -0.25\n评分指标 7.5');
            const subtitle = reputationSubtitle(item);
            expect(subtitle).assertContain('开发者 · 工具');
            expect(subtitle).assertContain('2026-10-11 → 2026-10-19（实际 8 天）');
            expect(subtitle).assertContain('净样本 10 · 正样本 30');
            expect(subtitle).assertContain('含数据修正');
            item.has_correction = false;
            expect(reputationSubtitle(item).includes('含数据修正')).assertFalse();
            item.rating = -2.5;
            item.weighted_score = 0;
            expect(reputationValue(item)).assertEqual('加权得分 0\n评分指标 -2.5');
        });
        it('developerScopeUsesStableIdRatherThanName', 0, () => {
            const query = JSON.stringify(collectionExpression({ title: '同名开发者', developerId: 'a&b', developerName: '同名开发者' }));
            expect(query).assertContain('"key":"dev_id","op":"eq","value":"a&b"');
            expect(query.includes('developer_name')).assertFalse();
        });
        it('developerNameFallbackIsExact', 0, () => {
            expect(JSON.stringify(collectionExpression({ title: '开发者', developerName: '测试' })))
                .assertContain('"key":"developer_name","op":"eq"');
        });
        it('segmentFallbackIncludesNullEmptyAndMatchingTag', 0, () => {
            const query = JSON.stringify(collectionExpression({ title: '工具', category: '工具', segment: '工具' }));
            expect(query).assertContain('"key":"kind_name","op":"eq","value":"工具"');
            expect(query).assertContain('"or":[');
            expect(query).assertContain('"op":"is_null"');
            expect(query).assertContain('"value":""');
        });
        it('segmentWithOwnLabelDoesNotIncludeSiblingApps', 0, () => {
            const query = JSON.stringify(collectionExpression({ title: '地图', category: '出行', segment: '地图' }));
            expect(query).assertContain('"key":"tag_name","op":"eq","value":"地图"');
            expect(query.includes('"or"')).assertFalse();
        });
        it('earlyAppsUseExclusiveUpperDownloadBoundary', 0, () => {
            const query = JSON.stringify(collectionExpression({ title: '早期应用', early: true }));
            expect(query).assertContain('"op":"gte","value":"1000"');
            expect(query).assertContain('"op":"lt","value":"100000"');
        });
        it('ratingPresetRequiresEnoughVotes', 0, () => {
            const query = JSON.stringify(collectionExpression({ title: '高分', preset: 'rated' }));
            expect(query).assertContain('"key":"average_rating","op":"gte","value":"4.5"');
            expect(query).assertContain('"key":"total_star_rating_count","op":"gte","value":"100"');
        });
        it('devicePresetsUseMarketDeviceCodes', 0, () => {
            expect(JSON.stringify(collectionExpression({ title: '平板', preset: 'tablet' }))).assertContain('"value":"4"');
            expect(JSON.stringify(collectionExpression({ title: '电脑', preset: 'pc' }))).assertContain('"value":"15"');
        });
        it('datePresetsHaveNonEmptyValidExpressions', 0, () => {
            expect(JSON.stringify(collectionExpression({ title: '收录', preset: 'listed' }))).assertContain('"key":"listed_at"');
            expect(JSON.stringify(collectionExpression({ title: '发布', preset: 'release' }))).assertContain('"key":"release_date"');
            expect(collectionSort({ title: '', preset: 'release' })).assertEqual('release_date');
            expect(collectionSort({ title: '', preset: 'listed' })).assertEqual('listed_at');
        });
        it('growthAndTopicPathsMatchBackendContract', 0, () => {
            expect(buildCategoryGrowthPath({ kind: 'segment', days: 7, page: 2, limit: 20 }))
                .assertEqual('rankings/segment_download_growth?days=7&page=2&limit=20');
            expect(buildCategoryGrowthPath({ kind: 'early', days: 30, page: 1, limit: 20 }))
                .assertContain('level=segment&min_downloads=1000&max_downloads=100000');
            expect(buildTopicsPath(0, 20)).assertEqual('substance/list/1?page_size=20&sort=created_at&desc=true');
        });
        it('dailyRecordsKeepLatestUniqueAppBeforePagination', 0, () => {
            const records: DailyMaxDownloadApp[] = [
                { app_id: 'a', app_name: 'A', pkg_name: 'a', download_count: 100, report_date: '2026-10-01' },
                { app_id: 'a', app_name: 'A', pkg_name: 'a', download_count: 200, report_date: '2026-10-03' },
                { app_id: 'b', app_name: 'B', pkg_name: 'b', download_count: 150, report_date: '2026-10-02' },
            ];
            const result = latestDailyMaxRecords(records);
            expect(result.length).assertEqual(2);
            expect(result[0].report_date).assertEqual('2026-10-03');
            expect(result[0].app_id).assertEqual('a');
            expect(result[1].app_id).assertEqual('b');
            expect(latestDailyMaxRecords(records, 1)[0].download_count).assertEqual(200);
            expect(records[0].report_date).assertEqual('2026-10-01');
            expect(latestDailyMaxRecords(records, 0).length).assertEqual(0);
        });
        it('iconFallbackUsesEncodedIdentityWithoutFetchingDetails', 0, () => {
            expect(appIconPath(' a&b ', 'ignored')).assertEqual('apps/icon/content?app_id=a%26b');
            expect(appIconPath('', ' app.name+beta ')).assertEqual('apps/icon/content?pkg_name=app.name%2Bbeta');
            expect(appIconPath('', '')).assertEqual('');
        });
        it('developerAndCategorySubtitlesReflectTheirPageContext', 0, () => {
            const app = listApp();
            expect(appCollectionSubtitle(app, { title: '开发者甲', developerId: 'd' })).assertEqual('工具 · 版本 2.0');
            expect(appCollectionSubtitle(app, { title: '工具', category: '工具' })).assertEqual('开发者甲 · 版本 2.0');
        });
        it('discoverySubtitlesShowRelevantDatesAndRatingCounts', 0, () => {
            const app = listApp();
            expect(appCollectionSubtitle(app, { title: '', preset: 'listed' })).assertContain('收录于 2026-10-15');
            expect(appCollectionSubtitle(app, { title: '', preset: 'release' })).assertContain('版本 2.0 · 发布于');
            expect(appCollectionSubtitle(app, { title: '', preset: 'rated' })).assertEqual('评分 4.8 · 123 条评分');
            const seconds = appCollectionSubtitle(app, { title: '', preset: 'release' });
            app.release_date *= 1000;
            expect(appCollectionSubtitle(app, { title: '', preset: 'release' })).assertEqual(seconds);
        });
        it('timelineDropsRepeatedSnapshotsButKeepsSizeAndPriceChanges', 0, () => {
            const changes = versionChanges([
                metric('2026-10-04T00:00:00Z', '2.0', 200, '6'),
                metric('2026-10-02T00:00:00Z'),
                metric('2026-10-01T00:00:00Z'),
                metric('2026-10-03T00:00:00Z', '1.0', 200),
            ]);
            expect(changes.length).assertEqual(3);
            expect(changes[0].summary).assertContain('版本更新');
            expect(changes[0].summary).assertContain('价格 0 → 6');
            expect(changes[1].summary).assertContain('大小 100 B → 200 B');
            expect(changes[2].summary).assertContain('首次采集');
        });
        it('localCollectionsPreserveValidRowsAndDeduplicateIds', 0, () => {
            const saved = parseLocalCollection('{"apps":[null,{"appId":"a","name":"A"},{"appId":"a"},{}],"developers":[{"developerId":"d","developerName":"D"}]}');
            expect(saved.apps.length).assertEqual(1);
            expect(saved.apps[0].name).assertEqual('A');
            expect(saved.apps[0].packageName).assertEqual('');
            expect(saved.developers[0].developerId).assertEqual('d');
        });
        it('localCollectionsHandleInvalidDocuments', 0, () => {
            expect(parseLocalCollection('null').apps.length).assertEqual(0);
            expect(parseLocalCollection('bad json').developers.length).assertEqual(0);
        });
        it('timelineSortsAbsoluteTimesAndIgnoresInvalidDates', 0, () => {
            const changes = versionChanges([
                metric('2026-10-01T09:00:00+08:00', '2.0'),
                metric('2026-10-01T00:00:00Z', '1.0'),
                metric('invalid', '2.0'),
            ]);
            expect(changes.length).assertEqual(2);
            expect(changes[0].version).assertEqual('2.0 (2)');
        });
        it('timelineIgnoresEquivalentPriceFormatsAndKeepsSdkChanges', 0, () => {
            const first = metric('2026-10-01', '1.0', 100, '0');
            const second = metric('2026-10-02', '1.0', 100, '0.00');
            expect(versionChanges([first, second]).length).assertEqual(1);
            second.compile_sdk_version = 26;
            expect(versionChanges([first, second])[0].summary).assertContain('编译 SDK 20 → 26');
        });
        it('timelineKeepsVersionRollbacks', 0, () => {
            const changes = versionChanges([metric('2026-10-01', '1.0'), metric('2026-10-02', '2.0'), metric('2026-10-03', '1.0')]);
            expect(changes.length).assertEqual(3);
            expect(changes[0].version).assertEqual('1.0 (1)');
        });
    });
}
