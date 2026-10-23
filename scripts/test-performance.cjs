#!/usr/bin/env node
// Desktop algorithm/race checks against actual ArkTS sources, not a substitute for device profiling.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const vm = require('node:vm');
const studio = process.env.DEVECO_STUDIO_HOME || path.join(os.homedir(), 'Applications/DevEco-Studio.app');
const ts = require(path.join(studio, 'Contents/tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const root = path.resolve(__dirname, '..');
const common = path.join(root, 'entry/src/main/ets/common');
const tests = [];
const test = (name, run) => tests.push({ name, run });
const hypium = {
  describe: (_name, run) => run(), it: (name, _flags, run) => test(name, run),
  beforeAll() {}, beforeEach() {}, afterEach() {}, afterAll() {},
  expect: actual => ({
    assertEqual: expected => assert.equal(actual, expected), assertTrue: () => assert.equal(actual, true),
    assertFalse: () => assert.equal(actual, false), assertNull: () => assert.equal(actual, null),
    assertContain: expected => assert.ok(actual.includes(expected), `${actual} must contain ${expected}`),
  }),
};
function compile(source, globals = {}) {
  const exports = {};
  const code = ts.transpileModule(source, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021,
  } }).outputText;
  vm.runInNewContext(code, { exports, console, setTimeout, clearTimeout, setInterval, clearInterval, Observed: value => value,
    $r: () => ({ id: 1 }), ...globals });
  return exports;
}
const modules = new Map();
function load(file) {
  if (modules.has(file)) return modules.get(file);
  const result = compile(fs.readFileSync(file, 'utf8'), { require: name => {
    if (name === '@ohos/hypium') return hypium;
    if (name.startsWith('.')) return load(path.resolve(path.dirname(file), name + '.ets'));
    throw Error(`Unexpected native import: ${name}`);
  } });
  modules.set(file, result);
  return result;
}
load(path.join(root, 'entry/src/test/List.test.ets')).default();
function webActivity(resume, pause) {
  return compile(fs.readFileSync(path.join(common, 'WebActivity.ets'), 'utf8'), {
    require: name => {
      assert.equal(name, '@kit.ArkWeb');
      return { webview: { WebviewController: { resumeAllTimers: resume, pauseAllTimers: pause } } };
    },
  }).WebActivity;
}
test('hidden web owners cannot pause a different visible web page', () => {
  const calls = [];
  const activity = webActivity(() => calls.push('resume'), () => calls.push('pause'));
  const station = activity.createOwner(), remote = activity.createOwner(), local = activity.createOwner();
  activity.setActive(station, true);
  activity.setActive(remote, true);
  activity.setActive(station, false);
  activity.setActive(local, true);
  activity.setActive(remote, false);
  assert.deepEqual(calls, ['resume']);
  activity.setActive(local, false);
  assert.deepEqual(calls, ['resume', 'pause']);
  activity.setActive(remote, true);
  assert.deepEqual(calls, ['resume', 'pause', 'resume']);
});
test('web timer state retries after the engine was not yet attached', () => {
  let calls = 0;
  const activity = webActivity(() => { if (++calls === 1) throw Error('not attached'); }, () => {});
  const owner = activity.createOwner();
  activity.setActive(owner, true);
  activity.setActive(owner, true);
  activity.setActive(owner, true);
  assert.equal(calls, 2);
});
const { CachedRequest, RequestScope } = load(path.join(common, 'CachedRequest.ets'));
const response = value => ({ success: true, data: { value }, timestamp: 'test' });
const validate = value => value?.success === true;
test('network result is available while persistence is still blocked', async () => {
  const cache = { generation: () => 0, read: async () => undefined, write: () => new Promise(() => {}) };
  const client = new CachedRequest(cache, validate);
  const result = await client.request('a', 100, false, async () => response(2));
  assert.equal(result.data.data.value, 2);
});
test('a delayed older cache read cannot overwrite a completed newer force refresh', async () => {
  let finishRead, reads = 0;
  const writes = [];
  const cache = { generation: () => 0,
    read: () => ++reads === 1 ? new Promise(resolve => { finishRead = resolve; }) : Promise.resolve(undefined),
    write: async (_key, value) => { writes.push(value.data.value); } };
  const client = new CachedRequest(cache, validate);
  const old = client.request('ordered', 100, false, async () => response(1));
  await client.request('ordered', 100, true, async () => response(2));
  finishRead(undefined); await old;
  assert.deepEqual(writes, [2]);
});
test('a later fresh cache hit does not suppress an in-flight force refresh', async () => {
  let finish, started;
  const ready = new Promise(resolve => { started = resolve; }), writes = [];
  const cache = { generation: () => 0,
    read: async () => ({ data: response(1), savedAt: 1, fresh: true }),
    write: async (_key, value) => { writes.push(value.data.value); } };
  const client = new CachedRequest(cache, validate);
  const forced = client.request('ordered', 100, true, () => {
    started(); return new Promise(resolve => { finish = resolve; });
  });
  await ready;
  const cached = await client.request('ordered', 100, false, async () => response(3));
  assert.equal(cached.data.data.value, 1);
  finish(response(2)); await forced;
  assert.deepEqual(writes, [2]);
});
test('expired cache returns before the network and concurrent revalidation is shared', async () => {
  let resolveNetwork, calls = 0, generation = 0;
  const network = new Promise(resolve => { resolveNetwork = resolve; });
  const cache = { generation: () => generation, read: async () => ({ data: response(1), savedAt: 1, fresh: false }),
    write: async () => {} };
  const client = new CachedRequest(cache, validate);
  const fetch = () => { calls++; return network; };
  const old = await client.request('a', 100, false, fetch, true);
  const forced = client.request('a', 100, true, fetch, true);
  assert.equal(old.data.data.value, 1); assert.equal(old.stale, true);
  resolveNetwork(response(2));
  assert.equal((await old.revalidated).data.data.value, 2);
  await forced; assert.equal(calls, 1);
});
test('clearing during stale revalidation prevents fallback and cache resurrection', async () => {
  let rejectNetwork, generation = 0, writes = 0;
  const network = new Promise((_resolve, reject) => { rejectNetwork = reject; });
  const cache = { generation: () => generation, read: async () => ({ data: response(1), savedAt: 1, fresh: false }),
    write: async () => { writes++; } };
  const client = new CachedRequest(cache, validate);
  const old = await client.request('a', 100, false, () => network, true);
  await Promise.resolve(); generation++; rejectNetwork(Error('offline'));
  await assert.rejects(old.revalidated); assert.equal(writes, 0);
});
test('a cancelled subscriber cannot abort a request still needed by another page', async () => {
  let finish, aborts = 0;
  const cache = { generation: () => 0, read: async () => undefined, write: async () => {} };
  const client = new CachedRequest(cache, validate), a = new RequestScope(), b = new RequestScope();
  const fetch = scope => { scope.onCancel(() => aborts++); return new Promise(resolve => { finish = resolve; }); };
  const first = client.request('shared', 100, false, fetch, false, a);
  const second = client.request('shared', 100, false, fetch, false, b);
  await Promise.resolve(); a.cancel();
  await assert.rejects(first); assert.equal(aborts, 0);
  finish(response(2)); assert.equal((await second).data.data.value, 2);
});
test('the last subscriber cancels transport and a subsequent request starts independently', async () => {
  let aborts = 0, onStart;
  const started = new Promise(resolve => { onStart = resolve; });
  const cache = { generation: () => 0, read: async () => undefined, write: async () => {} };
  const client = new CachedRequest(cache, validate), scope = new RequestScope();
  const first = client.request('shared', 100, false, cancellation => {
    cancellation.onCancel(() => aborts++); onStart(); return new Promise(() => {});
  }, false, scope);
  await started; scope.cancel(); await assert.rejects(first); assert.equal(aborts, 1);
  const fresh = await client.request('shared', 100, false, async () => response(3));
  assert.equal(fresh.data.data.value, 3);
});
test('cancelled cache reads release client tracking even if the adapter never settles', async () => {
  const cache = { generation: () => 0, read: () => new Promise(() => {}), write: async () => {} };
  const client = new CachedRequest(cache, validate), scope = new RequestScope();
  const pending = client.request('cancelled-read', 100, false, async () => response(1), false, scope);
  scope.cancel(); await assert.rejects(pending);
  await new Promise(setImmediate);
  assert.equal(client.pending.size, 0); assert.equal(client.ordering.size, 0);
});
test('cancelled transports release client tracking without depending on a native rejection callback', async () => {
  let started;
  const ready = new Promise(resolve => { started = resolve; });
  const cache = { generation: () => 0, read: async () => undefined, write: async () => {} };
  const client = new CachedRequest(cache, validate), scope = new RequestScope();
  const pending = client.request('cancelled-network', 100, false, () => { started(); return new Promise(() => {}); }, false, scope);
  await ready; scope.cancel(); await assert.rejects(pending);
  await new Promise(setImmediate);
  assert.equal(client.pending.size, 0); assert.equal(client.ordering.size, 0);
});
test('cache-owned stale revalidation survives the original page leaving', async () => {
  let finish;
  const scope = new RequestScope(), cache = { generation: () => 0,
    read: async () => ({ data: response(1), savedAt: 1, fresh: false }), write: async () => {} };
  const client = new CachedRequest(cache, validate);
  const old = await client.request('a', 100, false, () => new Promise(resolve => { finish = resolve; }), true, scope);
  scope.cancel(); finish(response(2)); assert.equal((await old.revalidated).data.data.value, 2);
});

test('native stale detail revalidation bypasses server cache and preserves request headers', async () => {
  const urls = [];
  const native = compile(fs.readFileSync(path.join(common, 'MarketRequest.ets'), 'utf8'), { require: name => {
    if (name === './PerformanceTrace') return { PerformanceTrace: { begin: () => 1, finish() {}, measure: (_name, action) => action() } };
    if (name === './CachedRequest') return { CachedRequest, RequestScope, validApiResponse: validate };
    if (name === './CacheService') return { getCacheGeneration: () => 0, writeCache: async () => {},
      readCache: async () => ({ data: response(1), savedAt: 1, fresh: false }) };
    if (name === './constants') return { SAPIBaseURL: { toString: () => 'https://api.test/' },
      DEFAULT_NETWORK_TIMEOUT_MS: 10000, createApiRequestHeaders: () => ({ 'User-Agent': 'Dashboard/test' }) };
    if (name === '@kit.NetworkKit') return { http: { HttpDataType: { STRING: 1 }, RequestMethod: { GET: 'GET' },
      createHttp: () => ({ destroy() {}, request: async (url, options) => {
        urls.push(url); assert.equal(options.header['User-Agent'], 'Dashboard/test');
        return { responseCode: 200, result: JSON.stringify(response(2)) };
      } }) } };
    throw Error(`Unexpected transport import ${name}`);
  } });
  const cached = await native.requestJson('apps/app_id/a?use_cache=true', 100, false, 'GET', undefined, 'detail:a');
  assert.equal(cached.data.data.value, 1);
  assert.equal((await cached.revalidated).data.data.value, 2);
  assert.deepEqual(urls, ['https://api.test/apps/app_id/a?use_cache=false']);
});
test('native cancellation finishes tracing and releases HTTP when destroy does not settle the request', async () => {
  let started, destroyed = 0, finished = 0;
  const ready = new Promise(resolve => { started = resolve; });
  const native = compile(fs.readFileSync(path.join(common, 'MarketRequest.ets'), 'utf8'), { require: name => {
    if (name === './PerformanceTrace') return { PerformanceTrace: { begin: () => 1,
      finish: () => finished++, measure: (_name, action) => action() } };
    if (name === './CachedRequest') return { CachedRequest, RequestScope, validApiResponse: validate };
    if (name === './CacheService') return { getCacheGeneration: () => 0, writeCache: async () => {}, readCache: async () => undefined };
    if (name === './constants') return { SAPIBaseURL: { toString: () => 'https://api.test/' },
      DEFAULT_NETWORK_TIMEOUT_MS: 10000, createApiRequestHeaders: () => ({}) };
    if (name === '@kit.NetworkKit') return { http: { HttpDataType: { STRING: 1 }, RequestMethod: { GET: 'GET' },
      createHttp: () => ({ destroy: () => destroyed++, request: () => { started(); return new Promise(() => {}); } }) } };
    throw Error(`Unexpected transport import ${name}`);
  } });
  const scope = new RequestScope();
  const request = native.requestJson('market_info', 100, false, 'GET', undefined, undefined, scope);
  await ready; scope.cancel(); await assert.rejects(request);
  await new Promise(setImmediate);
  assert.equal(destroyed, 1); assert.equal(finished, 1);
});

test('atomic cache reads remain independent of writes and clearing invalidates old work', async () => {
  const fsp = fs.promises, directory = await fsp.mkdtemp(path.join(os.tmpdir(), 'dashboard-cache-'));
  const handles = new Map(); let blockWrite, startedWrite, holdWrites = false;
  let holdRead = false, releaseRead, startedRead;
  let readGate = Promise.resolve();
  let gate = Promise.resolve(), started = Promise.resolve();
  const fileIo = {
    OpenMode: { CREATE: 1, WRITE_ONLY: 2, TRUNC: 4 },
    access: async file => { try { await fsp.access(file); return true; } catch { return false; } },
    mkdir: file => fsp.mkdir(file), readText: async file => {
      const text = await fsp.readFile(file, 'utf8');
      if (holdRead) { holdRead = false; startedRead(); await readGate; }
      return text;
    },
    listFile: file => fsp.readdir(file), unlink: file => fsp.unlink(file), rmdir: file => fsp.rmdir(file),
    stat: async file => { const stat = await fsp.stat(file); return { size: stat.size, mtime: stat.mtimeMs / 1000,
      isFile: () => stat.isFile(), isDirectory: () => stat.isDirectory() }; },
    open: async file => { const handle = await fsp.open(file, 'w'); handles.set(handle.fd, handle); return { fd: handle.fd }; },
    write: async (fd, data) => {
      if (holdWrites) { startedWrite(); await gate; }
      return (await handles.get(fd).write(Buffer.from(data))).bytesWritten;
    },
    close: async file => { const handle = handles.get(file.fd); handles.delete(file.fd); await handle.close(); },
    rename: (a, b) => fsp.rename(a, b),
  };
  const constants = { CACHE_DIRECTORY_NAME: 'api', CACHE_MAX_STALE_MS: 30 * 86400000,
    CACHE_MAX_BYTES: 32 * 1024 * 1024, CACHE_MAINTENANCE_INTERVAL_MS: 300000, CACHE_MAINTENANCE_DELAY_MS: 60000 };
  const makeCache = () => {
    const api = compile(fs.readFileSync(path.join(common, 'CacheService.ets'), 'utf8'), { require: name => {
      if (name === '@kit.CoreFileKit') return { fileIo };
      if (name === '@kit.ArkTS') return { util: { TextEncoder: class { encodeInto(text) { return new TextEncoder().encode(text); } } } };
      if (name === '@kit.ArkWeb') return { webview: { WebStorage: { deleteAllData() {} }, WebCookieManager: { clearAllCookiesSync() {} } } };
      if (name === './constants') return constants;
      if (name === './CachePolicy') return load(path.join(common, 'CachePolicy.ets'));
      throw Error(`Unexpected cache import: ${name}`);
    } });
    api.initializeCache({ cacheDir: directory }); return api;
  };
  const original = makeCache(), current = makeCache();
  try {
    await original.writeCache('b', response('中文应用缓存'));
    readGate = new Promise(resolve => { releaseRead = resolve; });
    const reading = new Promise(resolve => { startedRead = resolve; });
    holdRead = true; const oldRead = current.readCache('b', 10000); await reading;
    await current.writeCache('b', response('新版本应用缓存'));
    releaseRead();
    assert.equal((await oldRead).data.data.value, '新版本应用缓存');
    await original.writeCache('large', response('old'));
    readGate = new Promise(resolve => { releaseRead = resolve; });
    const readingLarge = new Promise(resolve => { startedRead = resolve; });
    holdRead = true; const oldLarge = current.readCache('large', 10000); await readingLarge;
    const largeValue = 'x'.repeat(4 * 1024 * 1024 + 256);
    await current.writeCache('large', response(largeValue)); releaseRead();
    assert.equal((await oldLarge).data.data.value.length, largeValue.length);
    gate = new Promise(resolve => { blockWrite = resolve; });
    started = new Promise(resolve => { startedWrite = resolve; }); holdWrites = true;
    const writing = current.writeCache('a', response(1)); await started;
    const queued = current.writeCache('queued', response(3));
    assert.equal((await current.readCache('queued', 10000)).data.data.value, 3);
    const cached = await current.readCache('b', 10000);
    assert.equal(cached.data.data.value, '新版本应用缓存');
    const warm = await current.readCache('b', 10000); assert.equal(warm.data, cached.data);
    const clearing = current.clearCompleteCache(); blockWrite(); await writing; await queued; await clearing;
    assert.equal(await current.readCache('a', 10000), undefined);
    assert.equal(await current.readCache('b', 10000), undefined);
    assert.equal(await current.readCache('queued', 10000), undefined);
    assert.equal(handles.size, 0); holdWrites = false;
    await current.writeCache('new', response(2)); assert.equal((await current.readCache('new', 10000)).data.data.value, 2);
  } finally {
    releaseRead?.(); blockWrite?.(); holdWrites = false;
    await current.clearCompleteCache(); await original.clearCompleteCache();
    await fsp.rm(directory, { recursive: true, force: true });
  }
});

const { FrameScheduler } = compile(fs.readFileSync(path.join(common, 'FrameScheduler.ets'), 'utf8'), {
  require: () => ({ FrameCallback: class {} }),
});
test('frame work coalesces input and cancels stale native callbacks', () => {
  const callbacks = [], context = { postFrameCallback: callback => callbacks.push(callback) };
  const scheduler = new FrameScheduler(); let draws = 0;
  for (let i = 0; i < 100; i++) scheduler.request(context, () => draws++);
  assert.equal(callbacks.length, 1); callbacks.shift().onFrame(0); assert.equal(draws, 1);
  scheduler.request(context, () => draws++); scheduler.cancel();
  scheduler.request(context, () => draws++);
  callbacks.shift().onFrame(0); assert.equal(draws, 1);
  callbacks.shift().onFrame(0); assert.equal(draws, 2);
});

function methodsFrom(file, names, globals = {}) {
  const source = fs.readFileSync(file, 'utf8');
  const methods = names.map(name => {
    const declaration = source.indexOf(`private ${name}(`);
    assert.ok(declaration >= 0, `Missing method ${name}`);
    const start = source.indexOf('{', declaration);
    let level = 1, end = start + 1;
    while (level && end < source.length) {
      if (source[end] === '{') level++; if (source[end] === '}') level--; end++;
    }
    return source.slice(declaration, end);
  }).join('\n');
  return compile(`export class Chart { ${methods} }`, globals).Chart;
}
test('station preload suspends timers after loading and while the application is backgrounded', () => {
  const calls = [];
  const Station = methodsFrom(path.join(root, 'entry/src/main/ets/pages/main/SStationPage.ets'), ['syncWebActivity'], {
    WebActivity: { setActive: (owner, active) => calls.push([owner, active]) },
  });
  const station = Object.assign(new Station(), { webOwnerId: 1, applicationActive: true, active: false, loading: true });
  station.syncWebActivity();
  station.loading = false; station.syncWebActivity();
  station.active = true; station.syncWebActivity();
  station.applicationActive = false; station.loading = true; station.syncWebActivity();
  assert.deepEqual(calls, [[1, true], [1, false], [1, true], [1, false]]);
});
const chartLayout = load(path.join(root, 'entry/src/main/ets/component/charts/chartLayout.ets'));
test('chart axes abbreviate large counts while exact application values remain intact', () => {
  const { chartAxisLabel, chartAxisScale } = chartLayout;
  assert.equal(chartAxisLabel(90453922, '次'), '9045.4万');
  assert.equal(chartAxisLabel(100000000, '次'), '1亿');
  assert.equal(chartAxisLabel(1000000000000, '次'), '1万亿');
  assert.equal(chartAxisLabel(12.3456789, '%'), '12.35%');
  assert.equal(chartAxisLabel(Infinity, '次'), '-');
  assert.equal(chartLayout.chartPercentLabel(0.00001), '<0.01%');
  assert.equal(chartLayout.chartPercentLabel(0), '0%');
  assert.equal(chartLayout.chartPercentLabel(18.98333333333), '18.98%');
  for (const value of [1, 3, 86408, 90453922, 1e12, Number.MAX_VALUE]) {
    const scale = chartAxisScale(value, '次');
    assert.ok(Number.isFinite(scale.maximum) && scale.maximum >= value);
    assert.equal(new Set(scale.labels).size, scale.labels.length);
    assert.ok(scale.labels.every(label => label.length <= 9));
  }
  assert.deepEqual(Array.from(chartAxisScale(3.9, '分').labels), ['5', '4', '3', '2', '1', '0']);
  assert.equal(load(path.join(common, 'format.ets')).formatCount(90453922), '90453922');
});
test('chart dates use bounded horizontal lines and zoomed viewports retain both visible endpoints', () => {
  assert.deepEqual(Array.from(chartLayout.chartDateLines('2026-10-23')), ['10-23', '2026']);
  assert.deepEqual(Array.from(chartLayout.chartDateLines('2025-01-02T10:20:30Z')), ['01-02', '2025']);
  for (const width of [160, 240, 318, 600, 840]) {
    for (const zoom of [1, 2, 4]) {
      const pan = width * (zoom - 1) * 0.6;
      const indices = chartLayout.chartDateIndices(360, width, zoom, pan);
      assert.ok(indices.length >= 2 && indices.length <= Math.floor(width / 64) + 1);
      assert.equal(indices[0], Math.ceil(pan / (width * zoom / 359)));
      assert.equal(indices.at(-1), Math.min(359, Math.floor((pan + width) / (width * zoom / 359))));
      assert.equal(new Set(indices).size, indices.length);
    }
  }
});
test('legend columns follow the width of each chart instead of the page breakpoint', () => {
  for (const width of [130, 240, 300, 318, 600, 840, 1200]) {
    const columns = chartLayout.chartLegendColumns(width);
    assert.ok(columns >= 1 && columns <= 6);
    if (columns > 1) assert.ok((width - 6 * (columns - 1)) / columns >= 150);
  }
});
const Chart = methodsFrom(path.join(root, 'entry/src/main/ets/component/charts/InteractiveLineChart.ets'), [
  'rebuildModel', 'sourceSeries', 'pointCount', 'labels', 'maximum', 'dimensions', 'axisFontSize', 'pointX', 'pointY',
  'traceSmoothLine', 'rgba', 'resolveColor', 'bottomAxisSpace', 'dateFontSize', 'draw',
], chartLayout);
function chartScenario(seriesCount, pointCount) {
  let reads = 0;
  const series = Array.from({ length: seriesCount }, (_, s) => ({ label: `${s}`, color: { id: 1 },
    points: Array.from({ length: pointCount }, (_, i) => ({ label: `${i}`, get value() { reads++; return i + s; } })) }));
  const context = new Proxy({}, { get: (_target, key) => key === 'createLinearGradient' ?
    () => ({ addColorStop() {} }) : key === 'measureText' ? text => ({ width: text.length * 7 }) : () => {}, set: () => true });
  const chart = Object.assign(new Chart(), { series, points: [], colors: new Map(), title: 'test', unit: '次',
    canvasWidth: 380, chartHeight: 250, responsiveAxisFont: false, zoom: 1, panOffset: 0, selected: pointCount - 1,
    drawProgress: 1, canvasReady: true, inViewport: true, active: true, context,
    getUIContext: () => ({ getHostContext: () => ({ resourceManager: { getColorSync: () => 1 } }) }) });
  chart.rebuildModel(); assert.equal(reads, seriesCount * pointCount);
  reads = 0; chart.draw(); return { chart, reads };
}
test('360-point and multi-series drawings have linear data access', () => {
  const small = chartScenario(1, 180), large = chartScenario(1, 360), multi = chartScenario(10, 360);
  assert.ok(large.reads <= small.reads * 2.1, `${small.reads} -> ${large.reads}`);
  assert.ok(multi.reads < 20 * 10 * 360, `Unexpected full-data rescans: ${multi.reads}`);
  console.log(`  value reads per draw: 180=${small.reads}, 360=${large.reads}, 10×360=${multi.reads}`);
  assert.equal(large.chart.pointX(0), large.chart.dimensions()[0]);
  assert.equal(large.chart.pointX(359), 368);
});
test('drawn axis and date text stays within the canvas and dates are outside the curve clip', () => {
  for (const width of [180, 240, 318, 600, 840]) {
    for (const unit of ['次', '分', '%']) {
      const { chart } = chartScenario(1, 360);
      chart.points = [];
      chart.series[0].points = chart.series[0].points.map((point, i) => ({
        label: `2026-10-${String(i % 28 + 1).padStart(2, '0')}`, value: i / 359 * (unit === '次' ? 90453922 : 4.9), detail: '',
      }));
      const state = { font: '', textAlign: '', textBaseline: '', clipDepth: 0 }, stack = [], draws = [];
      const measure = text => ({ width: Array.from(text).reduce((sum, char) => sum + (char.charCodeAt(0) > 127 ? 12 : 7), 0) });
      const actions = {
        measureText: measure, createLinearGradient: () => ({ addColorStop() {} }),
        save: () => stack.push({ ...state }), restore: () => Object.assign(state, stack.pop()),
        clip: () => state.clipDepth++,
        rotate: () => { throw Error('Dates must not rotate out of their measured bounds'); },
        fillText: (text, x, y, maxWidth) => draws.push({ text, x, y, width: Math.min(measure(text).width, maxWidth), ...state }),
      };
      chart.context = new Proxy(state, { get: (target, key) => actions[key] || target[key] || (() => {}),
        set: (target, key, value) => { target[key] = value; return true; } });
      chart.canvasWidth = width; chart.unit = unit; chart.rebuildModel(); chart.draw();
      const dates = draws.filter(item => item.textBaseline === 'top');
      assert.ok(dates.length >= 4);
      for (const item of draws) {
        const left = item.textAlign === 'right' ? item.x - item.width : item.x - item.width / 2;
        assert.ok(left >= 0 && item.x + (item.textAlign === 'right' ? 0 : item.width / 2) <= width);
        assert.ok(item.y >= 0 && item.y + 12 < chart.chartHeight);
      }
      assert.ok(dates.every(item => item.clipDepth === 0));
      assert.ok(chart.dimensions()[2] >= width * 0.6);
    }
  }
});
test('offscreen charts do not draw or scan point values', () => {
  const { chart } = chartScenario(1, 360); chart.active = false;
  chart.context = new Proxy({}, { get() { throw Error('Offscreen draw'); } });
  chart.draw();
});

test('scroll events preserve the latest position with one storage write per batch', () => {
  const storage = new Map(), writes = [];
  const constants = { MAIN_TAB_DEFAULT: 1, DEFAULT_SCROLL_DISTANCE: 0, CONTINUATION_ROUTE_MAIN: 'main' };
  const source = fs.readFileSync(path.join(common, 'constants.ets'), 'utf8');
  for (const match of source.matchAll(/export const (\w+)\s*=\s*'([^']*)'/g)) constants[match[1]] = match[2];
  const state = compile(fs.readFileSync(path.join(common, 'appState.ets'), 'utf8'), {
    require: () => constants, AppStorage: { get: key => storage.get(key),
      setOrCreate: (key, value) => { storage.set(key, value); writes.push(key); } },
  });
  state.setContinuationView(1, 0); state.flushContinuationScroll(); writes.length = 0;
  for (let i = 0; i < 1000; i++) state.setContinuationView(1, i);
  assert.equal(writes.length, 0); assert.equal(state.getContinuationState().scrollDistance, 999);
  state.flushContinuationScroll(); assert.equal(writes.length, 1);
  state.setContinuationView(2, 12); state.flushContinuationScroll();
  assert.equal(state.getContinuationState().scrollDistance, 12);
});

test('stable app row identities receive fresh content and positions after a reload', () => {
  const { AppDataSource } = load(path.join(common, 'AppDataSource.ets'));
  const data = new AppDataSource(); let reloads = 0;
  data.registerDataChangeListener({ onDataReloaded: () => reloads++ });
  data.replace([{ app_id: 'a', name: 'Old' }, { app_id: 'b', name: 'Second' }]);
  const original = data.getData(0);
  data.replace([{ app_id: 'b', name: 'Second' }, { app_id: 'a', name: 'New' }], 40);
  assert.equal(data.getData(1), original); assert.equal(original.app.name, 'New');
  assert.equal(original.index, 42); assert.equal(reloads, 2);
  data.replace([]); assert.equal(data.totalCount(), 0);
});
const Carousel = methodsFrom(path.join(root, 'entry/src/main/ets/component/detail/ScreenshotCarousel.ets'), [
  'updateWindow', 'onScreenshotsChanged', 'screenshotKey', 'allScreenshotsSettled', 'stopAutoPlay',
  'restartAutoPlay', 'completeSwitch',
], { curves: { springMotion: () => null }, setInterval: () => 1, clearInterval() {} });
function carouselModel(count) {
  const finishes = [];
  const model = Object.assign(new Carousel(), {
    screenshots: Array.from({ length: count }, (_, i) => ({ url: `shot-${i}`, resolution: '1080*2400', rotated: 0 })),
    currentIndex: 0, screenshotSignature: '', generation: 0, switching: false, alive: true, active: true,
    inViewport: false, settledScreenshotKeys: [], autoPlayTimer: -1, dragOffset: 0, frameWidth: 300,
    getUIContext: () => ({ animateTo: (options, update) => { update(); finishes.push(options.onFinish); } }),
  });
  return { model, finishes };
}
test('screenshot windows remain bounded with unique keys for one, two and many images', () => {
  for (const count of [0, 1, 2, 3, 50]) {
    const { model } = carouselModel(count);
    model.updateWindow();
    assert.equal(model.cards.length, count < 2 ? count : 3);
    assert.equal(new Set(model.cards.map(card => card.key)).size, model.cards.length);
  }
});
test('metadata-only screenshot updates preserve readiness of existing image nodes', () => {
  const { model } = carouselModel(3);
  model.settledScreenshotKeys = [model.screenshotKey(model.screenshots[0], 0)];
  model.onScreenshotsChanged(); assert.equal(model.allScreenshotsSettled(), true);
  model.screenshots = model.screenshots.map(shot => ({ ...shot, resolution: '720*1600' }));
  model.onScreenshotsChanged(); assert.equal(model.allScreenshotsSettled(), true);
  model.screenshots[0] = { ...model.screenshots[0], url: 'replacement' };
  model.onScreenshotsChanged(); assert.equal(model.allScreenshotsSettled(), false);
});
test('leaving a carousel during an animation invalidates its late completion', () => {
  const { model, finishes } = carouselModel(3);
  model.inViewport = true; model.completeSwitch(1);
  assert.equal(model.switching, true);
  model.active = false; model.restartAutoPlay(); finishes.shift()();
  assert.equal(model.currentIndex, 0); assert.equal(model.switching, false);
  assert.equal(model.dragOffset, 0); assert.equal(model.autoPlayTimer, -1);
  model.completeSwitch(1); assert.equal(finishes.length, 0);
});
const DetailHistory = methodsFrom(path.join(root, 'entry/src/main/ets/pages/detail/AppDetailPage.ets'), ['requestHistory']);
test('detail revalidation reuses history for the same page generation and package', () => {
  const calls = [];
  const model = Object.assign(new DetailHistory(), { active: true, app: { pkg_name: 'a' }, historyRequested: false,
    historyRequestVersion: -1, historyPackage: '', loadMetrics: (...args) => calls.push(['metrics', ...args]),
    loadRatings: (...args) => calls.push(['rating', ...args]) });
  model.requestHistory(false, 1); model.requestHistory(false, 1); assert.equal(calls.length, 2);
  model.requestHistory(true, 1); assert.equal(calls.length, 4);
  model.requestHistory(false, 2); assert.equal(calls.length, 6);
  model.app = { pkg_name: 'b' }; model.requestHistory(false, 2); assert.equal(calls.length, 8);
  model.active = false; model.requestHistory(true, 3); assert.equal(calls.length, 8);
});
const DetailShare = methodsFrom(path.join(root, 'entry/src/main/ets/pages/detail/AppDetailPage.ets'), [
  'suspendShare', 'onApplicationActiveChanged',
]);
test('background details release their own share listener and only the visible owner resumes', () => {
  const calls = [];
  const model = Object.assign(new DetailShare(), { applicationActive: false, active: true, pageVisible: true,
    shareOwnerId: 7, shareManager: { clearShareDataProvider: id => calls.push(['clear', id]),
      disablePassiveShare: id => calls.push(['disable', id]) }, syncShareData: () => calls.push(['resume']) });
  model.onApplicationActiveChanged(); assert.deepEqual(calls, [['clear', 7], ['disable', 7]]);
  model.applicationActive = true; model.pageVisible = false; model.onApplicationActiveChanged();
  assert.equal(calls.length, 2);
  model.pageVisible = true; model.onApplicationActiveChanged(); assert.deepEqual(calls[2], ['resume']);
});

test('preference batches flush once and interleaved remove operations stay ordered', async () => {
  const values = new Map(); let flushes = 0, fail = false;
  const preference = { get: async (key, fallback) => values.has(key) ? values.get(key) : fallback,
    put: async (key, value) => values.set(key, value), delete: async key => values.delete(key),
    flush: async () => { if (fail) throw Error('disk full'); flushes++; } };
  const storage = compile(fs.readFileSync(path.join(common, 'DiskStorage.ets'), 'utf8'), {
    console: { info() {}, warn() {}, error() {} },
    require: () => ({ default: { getPreferences: async () => preference } }),
  }).default('test', {});
  await storage.setMany([{ key: 'a', value: 1 }, { key: 'b', value: 2 }]);
  assert.equal(flushes, 1); assert.equal(await storage.get('b', 0), 2);
  await Promise.all([storage.set('a', 3), storage.remove('a')]);
  assert.equal(await storage.get('a', 'missing'), 'missing'); assert.equal(flushes, 3);
  fail = true; await assert.rejects(storage.set('a', 4));
  fail = false; await storage.set('a', 5); assert.equal(await storage.get('a', 0), 5);
});

(async () => {
  for (const { name, run } of tests) {
    let timer;
    try {
      await Promise.race([Promise.resolve().then(run), new Promise((_resolve, reject) => {
        timer = setTimeout(() => reject(Error(`Timed out: ${name}`)), 3000);
      })]);
      console.log(`PASS ${name}`);
    } finally { clearTimeout(timer); }
  }
  console.log(`${tests.length} unit/performance regression checks passed`);
})().catch(error => { console.error(error); process.exitCode = 1; });
