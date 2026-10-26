// Focused regression cases for ownership, late completion and native resource cleanup.
module.exports = ({ test, assert, load, compile, methodsFrom, etsRoot, fs, path }) => {
  const sourcePath = relative => path.join(etsRoot, relative);
  const source = relative => fs.readFileSync(sourcePath(relative), 'utf8');
  const { RequestScope } = load(sourcePath('services/cache/CachedRequest.ets'));
  const tick = () => new Promise(resolve => setImmediate(resolve));
  const deferred = () => {
    let resolve, reject;
    const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
    return { promise, resolve, reject };
  };

  test('cancelled native frame callbacks release captured actions before the next frame', () => {
    const { FrameScheduler } = compile(source('utils/runtime/FrameScheduler.ets'), {
      require: () => ({ FrameCallback: class {} }),
    });
    const callbacks = [], context = { postFrameCallback: callback => callbacks.push(callback) };
    const scheduler = new FrameScheduler(); let runs = 0;
    scheduler.request(context, () => runs++); scheduler.cancel();
    assert.equal(callbacks[0].action, undefined);
    callbacks[0].onFrame(0); assert.equal(runs, 0);
    scheduler.request(context, () => runs++);
    callbacks[1].onFrame(0); callbacks[1].onFrame(0);
    assert.equal(runs, 1); assert.equal(callbacks[1].action, undefined);
  });

  test('failed native frame registration releases its action and allows retry', () => {
    const { FrameScheduler } = compile(source('utils/runtime/FrameScheduler.ets'), {
      require: () => ({ FrameCallback: class {} }),
    });
    const scheduler = new FrameScheduler(); let callback, runs = 0;
    assert.throws(() => scheduler.request({ postFrameCallback: frame => { callback = frame; throw Error('detached'); } },
      () => runs++), /detached/);
    assert.equal(callback.action, undefined);
    scheduler.request({ postFrameCallback: frame => { callback = frame; } }, () => runs++);
    callback.onFrame(0); assert.equal(runs, 1);
  });

  test('replaced and cancelled deferred callbacks cannot run even if already queued', () => {
    const callbacks = new Map(), cleared = [];
    let next = 0, runs = 0;
    const { DeferredTask } = compile(source('utils/runtime/DeferredTask.ets'), {
      setTimeout: action => { callbacks.set(++next, action); return next; },
      clearTimeout: id => cleared.push(id),
    });
    const task = new DeferredTask();
    task.schedule(() => runs++); task.schedule(() => runs += 10);
    callbacks.get(1)(); assert.equal(runs, 0);
    callbacks.get(2)(); assert.equal(runs, 10);
    task.schedule(() => runs += 100); task.cancel(); callbacks.get(3)();
    assert.equal(runs, 10); assert.deepEqual(cleared, [1, 3]);
  });

  test('search input preserves routing precedence and normalizes lowercase app IDs', () => {
    const { searchTargetFromInput } = load(sourcePath('domain/search/SearchInput.ets'));
    const target = input => JSON.parse(JSON.stringify(searchTargetFromInput(input)));
    assert.deepEqual(target('c123456'), { appId: 'C123456' });
    assert.deepEqual(target('com.example.app'), { packageName: 'com.example.app' });
    assert.deepEqual(target('https://example.org/?app_id=C12&pkg=com.other'), { appId: 'C12' });
    assert.deepEqual(target('https://example.org/#/detail?pkg=com.example%2Eapp'), { packageName: 'com.example.app' });
    assert.deepEqual(target('https://example.org/?app_id=%broken'), { appId: '%broken' });
    assert.deepEqual(target('备忘录'), {});
  });

  test('query values retain literal equals signs and plus decoding', () => {
    const { URLSearchParams } = load(sourcePath('utils/url/URLSearchParams.ets'));
    const params = new URLSearchParams('token=a=b=c&label=a+b&encoded=%3D');
    assert.equal(params.get('token'), 'a=b=c');
    assert.equal(params.get('label'), 'a b'); assert.equal(params.get('encoded'), '=');
    assert.equal(new URLSearchParams(params.toString()).get('token'), 'a=b=c');
    const { URL } = load(sourcePath('utils/url/url.ets'));
    assert.equal(new URL('/api/v0/', 'https://example.org:10003/').toString(), 'https://example.org:10003/api/v0/');
    assert.equal(new URL('dashboard', new URL('https://example.org/')).toString(), 'https://example.org/dashboard');
  });

  test('search relevance is stable and leaves the API result array unchanged', () => {
    const { sortSearchResults } = load(sourcePath('domain/search/SearchInput.ets'));
    const apps = [{ name: 'My Notes', pkg_name: 'com.a' }, { name: 'Notes Plus' },
      { name: 'Other', pkg_name: 'notes.widget' }, { name: 'NOTES' }, { name: 'Notes Two' }];
    const sorted = sortSearchResults(apps, ' notes ');
    assert.deepEqual(Array.from(sorted, app => app.name), ['NOTES', 'Notes Plus', 'Notes Two', 'Other', 'My Notes']);
    assert.equal(apps[0].name, 'My Notes');
  });

  test('leaving search cancels all delayed work and both request scopes', () => {
    const Search = methodsFrom(sourcePath('pages/search/SearchPage.ets'), ['aboutToDisappear'], {
      cancelStaggerEnterAnimation() {},
    });
    let cancelledTasks = 0;
    const task = () => ({ cancel: () => cancelledTasks++ });
    const search = Object.assign(new Search(), { requestScope: new RequestScope(), recommendationScope: new RequestScope(),
      pendingSearch: task(), backgroundRefresh: task(), pendingDetail: task(), pendingFocus: task(), visible: true,
      lifecycleToken: 1, searchRequestToken: 2, backgroundUpdateToken: 3, loading: true, openDetailAfterSearch: true });
    search.aboutToDisappear();
    assert.equal(search.requestScope.cancelled, true); assert.equal(search.recommendationScope.cancelled, true);
    assert.equal(cancelledTasks, 4); assert.equal(search.visible, false); assert.equal(search.loading, false);
    assert.equal(search.searchRequestToken, 3); assert.equal(search.openDetailAfterSearch, false);
  });

  test('incoming search replaces an in-flight command before scheduling its successor', () => {
    let command = { rawText: 'com.first', autoRun: true }, scheduled;
    const Search = methodsFrom(sourcePath('pages/search/SearchPage.ets'), ['consumePendingTarget'], {
      RequestScope, consumeSearchTarget: () => command,
    });
    const search = Object.assign(new Search(), { visible: true, requestScope: new RequestScope(), loading: true,
      searchRequestToken: 1, backgroundUpdateToken: 1, backgroundRefresh: { cancel() {} }, pendingDetail: { cancel() {} },
      pendingSearch: { cancel: () => { scheduled = undefined; }, schedule: action => { scheduled = action; } },
      search: history => { search.ran = [search.input, history]; } });
    const oldScope = search.requestScope;
    search.consumePendingTarget(); assert.equal(oldScope.cancelled, true); assert.equal(search.loading, false);
    command = { appId: 'C222', autoRun: true, recordHistory: true };
    search.consumePendingTarget(); scheduled(); assert.deepEqual(search.ran, ['C222', true]);
    command = { rawText: 'draft', autoRun: false };
    search.consumePendingTarget(); assert.equal(scheduled, undefined);
  });

  test('search orchestrates name and identifier lookups without navigating after a late completion', async () => {
    const { searchTargetFromInput } = load(sourcePath('domain/search/SearchInput.ets'));
    const Search = methodsFrom(sourcePath('pages/search/SearchPage.ets'), ['search', 'isSearchCurrent', 'isVisible'], {
      RequestScope, searchTargetFromInput, showToastSafely() { throw Error('unexpected toast'); },
    });
    for (const input of ['备忘录', 'c123']) {
      const pending = deferred(), calls = [];
      const search = Object.assign(new Search(), { input, visible: true, lifecycleToken: 1, searchRequestToken: 1,
        backgroundUpdateToken: 1, requestScope: new RequestScope(), backgroundRefresh: { cancel() {} },
        pendingDetail: { cancel() {} }, setResults() {}, remember: async () => calls.push('history'),
        searchByName: () => { calls.push('name'); return pending.promise; },
        searchByTarget: target => { calls.push(target.appId); return pending.promise; },
        openDetailIfRequested: () => calls.push('navigate') });
      const operation = search.search(); await tick();
      assert.deepEqual(calls, ['history', input === '备忘录' ? 'name' : 'C123']);
      search.searchRequestToken++; search.loading = true;
      pending.resolve(); await operation;
      assert.equal(calls.includes('navigate'), false); assert.equal(search.loading, true);
    }
  });

  test('detail history keeps valid ratings ordered and bounds long series while preserving endpoints', () => {
    const { detailRatingPoints, detailDownloadPoints } = load(sourcePath('domain/detail/DetailHistory.ets'));
    const history = [
      { report_date: '2026-10-22', cumulative_avg_rating_high_prec: 4.2, cumulative_total_count: 10 },
      { report_date: 'bad', cumulative_avg_rating_high_prec: 4 },
      { report_date: '2026-10-21', cumulative_avg_rating_high_prec: 6 },
      { report_date: '2026-10-20', cumulative_avg_rating_origin: 3.9, cumulative_total_count: 5 },
    ];
    const ratings = detailRatingPoints(history);
    assert.deepEqual(Array.from(ratings, point => point.value), [3.9, 4.2]);
    assert.match(ratings[1].detail, /累计 10 条评分/);
    assert.equal(history[0].report_date, '2026-10-22');
    const metrics = Array.from({ length: 1000 }, (_, i) => ({
      download_count: i * 100, created_at: new Date(Date.UTC(2024, 0, i + 1)).toISOString(), version: '1.0',
    }));
    const points = detailDownloadPoints(metrics);
    assert.ok(points.length <= 360); assert.equal(points[0].value, 0); assert.equal(points.at(-1).value, 99900);
  });

  test('every discovery API forwards the caller scope without changing query or body contracts', async () => {
    const calls = [];
    const api = compile(source('services/api/MarketApi.ets'), { require: name => {
      if (name === '@kit.NetworkKit') return { http: { RequestMethod: { GET: 'GET', POST: 'POST' } } };
      if (name.endsWith('/constants')) return {};
      if (name.endsWith('/MarketRequest')) return { requestJson: (...args) => { calls.push(args); return Promise.resolve({}); } };
      if (name.endsWith('/AppListQuery')) return load(sourcePath('domain/apps/AppListQuery.ets'));
      if (name.endsWith('/RankingQuery')) return load(sourcePath('domain/rankings/RankingQuery.ets'));
      throw Error(`Unexpected API import ${name}`);
    } });
    const scope = new RequestScope(), expression = { and: [] };
    await api.fetchAppsQuery({ page: 2, pageSize: 20, sort: 'download_count', desc: true }, expression, scope);
    await api.fetchDownloadGrowth({}, undefined, scope);
    await api.fetchCategoryGrowth({ kind: 'category' }, scope);
    await api.fetchTopics(2, 20, false, scope);
    await api.fetchTopic('topic/1', false, scope);
    for (const call of calls) assert.equal(call[6], scope);
    assert.equal(calls[0][3], 'POST'); assert.equal(calls[0][4], expression);
    assert.equal(calls.at(-1)[0], 'substance/topic%2F1');
  });

  test('discovery pages release requests when leaving and ignore their late responses', async () => {
    for (const name of ['TopicsPage', 'AppCollectionPage', 'RankingPage']) {
      const pending = deferred(); let scope;
      const fetch = (...args) => { scope = args.at(-1); return scope.waitFor(pending.promise); };
      const Page = methodsFrom(sourcePath(`pages/discovery/${name}.ets`), ['load', 'aboutToDisappear'], {
        RequestScope, fetchTopics: fetch, fetchAppsQuery: fetch, fetchAppsPage: fetch,
        collectionExpression: () => ({}), DISCOVERY_PAGE_SIZE: 20,
      });
      const page = Object.assign(new Page(), { alive: true, token: 0, requestScope: new RequestScope(),
        target: {}, page: 1, sortIndex: 0, sorts: ['download_count'], interaction: { dispose() {} }, kind: () => 'downloads' });
      const operation = page.load(false); page.aboutToDisappear(); await operation;
      assert.equal(scope.cancelled, true); assert.equal(page.error, ''); assert.equal(page.alive, false);
      pending.resolve({ data: { success: true, data: { data: [{ app_id: 'late' }], total_count: 1 } } });
      await tick(); assert.equal(page.apps.length, 0);
    }
  });

  test('latest list request cancels the old subscriber without clearing the new loading state', async () => {
    const requests = [];
    const fetch = (_query, scope) => {
      const pending = deferred(); requests.push({ ...pending, scope });
      return scope.waitFor(pending.promise);
    };
    const Apps = methodsFrom(sourcePath('pages/main/AppsPage.ets'), ['load', 'aboutToDisappear'], {
      RequestScope, fetchAppsPage: fetch, fetchAppsQuery: () => { throw Error('unexpected advanced search'); },
      showToastSafely() { throw Error('obsolete errors must not reach UI'); }, flushContinuationScroll() {},
      cancelStaggerEnterAnimation() {},
    });
    const page = Object.assign(new Apps(), { alive: true, requestScope: new RequestScope(), listLoadToken: 0,
      page: 1, sortIndex: 0, descending: true, typeIndex: 0, appliedFilterText: '', loading: false,
      sortChoices: () => [{ field: 'download_count' }], pageSize: () => 20, restoreScrollTimer: -1 });
    const first = page.load(false); const second = page.load(true);
    await first; assert.equal(requests[0].scope.cancelled, true); assert.equal(page.loading, true);
    requests[1].resolve({ data: { success: true, data: { data: [{ app_id: 'new' }], total_count: 1 } }, stale: false });
    await second; assert.equal(page.apps[0].app_id, 'new'); assert.equal(page.loading, false);
    const third = page.load(false); page.aboutToDisappear(); await third;
    assert.equal(requests[2].scope.cancelled, true); assert.equal(page.apps[0].app_id, 'new');
  });

  test('raw image decoding waits for cleanup and attempts both releases after failures', async () => {
    for (const failure of ['none', 'decode', 'source', 'close', 'create', 'open']) {
      const calls = [], pixel = {};
      const resources = {
        getRawFd: async () => { calls.push('open'); if (failure === 'open') throw Error('open'); return {}; },
        closeRawFd: async () => { calls.push('close'); if (failure === 'close') throw Error('close'); },
      };
      const { loadRawPixelMap } = compile(source('services/media/RawImageLoader.ets'), {
        console: { warn() {} }, require: () => ({ image: { createImageSource: () => {
          calls.push('create'); if (failure === 'create') throw Error('create');
          return { createPixelMap: async () => { calls.push('decode'); if (failure === 'decode') throw Error('decode'); return pixel; },
            release: async () => { calls.push('release'); if (failure === 'source') throw Error('source'); } };
        } } }),
      });
      const operation = loadRawPixelMap(resources, 'guide.webp', 150, 100);
      if (['decode', 'create', 'open'].includes(failure)) await assert.rejects(operation, new RegExp(failure));
      else assert.equal(await operation, pixel);
      assert.equal(calls.includes('close'), failure !== 'open');
      assert.equal(calls.includes('release'), !['create', 'open'].includes(failure));
    }
  });

  test('abandoned or failed animation batches release every frame not handed to the component', async () => {
    const Guide = methodsFrom(sourcePath('components/sharing/KnockShareGuideCard.ets'), ['loadPixels']);
    for (const failure of ['decode', 'leave']) {
      const released = [], pending = deferred(), first = { src: {} }, second = { src: {} };
      let loads = 0;
      const guide = Object.assign(new Guide(), { alive: true, res: { framesCount: 4 }, loadToken: 1,
        loadByRawfile: async () => ++loads === 1 ? first : pending.promise,
        releaseFrames: frames => released.push(...frames), releaseAnimationFrames() {} });
      const operation = guide.loadPixels(1); await tick();
      if (failure === 'decode') { pending.reject(Error('decode')); await assert.rejects(operation, /decode/); }
      else { guide.alive = false; guide.loadToken++; pending.resolve(second); await operation; }
      assert.equal(released[0], first); assert.equal(guide.animReady, undefined);
      assert.equal(released.length, failure === 'decode' ? 1 : 2);
    }
  });

  test('destroyed or replaced window stages never attach late listeners or load content', async () => {
    const Entry = methodsFrom(sourcePath('abilities/EntryAbility.ets'), [
      'initializeWindowStage', 'bindWindowStorage', 'onWindowStageDestroy',
    ], { LOCAL_STORAGE_KEY_WINDOW_WIDTH: 'width', LOCAL_STORAGE_KEY_WINDOW_HEIGHT: 'height',
      DEFAULT_WINDOW_WIDTH: 1, DEFAULT_WINDOW_HEIGHT: 1 });
    const calls = [], pending = deferred();
    const entry = Object.assign(new Entry(), { windowStageVersion: 0, startupTask: Promise.resolve(),
      storage: { setOrCreate() {} }, detachWindowSizeListener: () => calls.push('detach'),
      loadCurrentPage: stage => calls.push(stage.name) });
    const nativeWindow = { getWindowProperties: () => ({ windowRect: { width: 100, height: 200 } }),
      on: () => calls.push('on') };
    entry.initializeWindowStage({ name: 'old', getMainWindow: () => pending.promise });
    entry.onWindowStageDestroy(); pending.resolve(nativeWindow); await tick();
    assert.deepEqual(calls, ['detach']);
    entry.initializeWindowStage({ name: 'current', getMainWindow: async () => nativeWindow }); await tick();
    assert.deepEqual(calls, ['detach', 'detach', 'on', 'current']);
  });
};
