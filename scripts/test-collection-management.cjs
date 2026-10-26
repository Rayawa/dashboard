#!/usr/bin/env node
// Exercise actual storage and page methods; no device, preferences or user collections are changed.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const studio = process.env.DEVECO_STUDIO_HOME || path.join(os.homedir(), 'Applications/DevEco-Studio.app');
const ts = require(path.join(studio, 'Contents/tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const source = path.resolve(__dirname, '../entry/src/main/ets');
function compile(text, globals = {}) {
  const exports = {};
  const code = ts.transpileModule(text, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021,
  } }).outputText;
  vm.runInNewContext(code, { exports, console, Set, $r: name => name, ...globals });
  return exports;
}
const parser = compile(fs.readFileSync(path.join(source, 'domain/collection/LocalCollection.ets'), 'utf8'));
const app = id => ({ appId: id, packageName: `pkg.${id}`, name: id, iconUrl: '' });
const developer = id => ({ developerId: id, developerName: id });
function storage() {
  let raw = JSON.stringify({ apps: [app('a'), app('b')], developers: [developer('a'), developer('d')] });
  let writes = 0, fail = false;
  const store = { has: async () => true, get: async () => raw, set: async (_key, value) => {
    if (fail) throw Error('disk full'); raw = value; writes++;
  } };
  const api = compile(fs.readFileSync(path.join(source, 'services/storage/storage.ets'), 'utf8'), {
    require: name => {
      if (name.endsWith('/DiskStorage')) return { default: () => store };
      if (name.endsWith('/LocalCollection')) return parser;
      if (name.endsWith('/constants')) return new Proxy({}, { get: (_target, key) => key });
      if (name === '@kit.BasicServicesKit') return { deviceInfo: {} };
      throw Error(`Unexpected storage dependency: ${name}`);
    },
  });
  return { api, writes: () => writes, snapshot: () => JSON.parse(raw), fail: value => { fail = value; } };
}
const pageSource = fs.readFileSync(path.join(source, 'pages/collection/CollectionManagementPage.ets'), 'utf8');
function page(dialogIndex = 1, failing = false) {
  const methods = ['busy', 'count', 'currentIds', 'selectedIds', 'select', 'selectAll', 'load', 'removeSelected'].map(name => {
    const match = new RegExp(`private (?:async )?${name}\\(`).exec(pageSource);
    assert.ok(match, `Missing method ${name}`);
    const start = pageSource.indexOf('{', match.index); let depth = 1, end = start + 1;
    while (depth) { if (pageSource[end] === '{') depth++; if (pageSource[end] === '}') depth--; end++; }
    return pageSource.slice(match.index, end);
  }).join('\n');
  const calls = [], toasts = [];
  const Page = compile(`export class Page { ${methods} }`, {
    getLocalCollection: async () => ({ apps: [app('b')], developers: [developer('d')] }),
    removeCollectedItems: async (apps, developers) => {
      calls.push({ apps: [...apps], developers: [...developers] });
      if (failing) throw Error('disk full');
    },
    showToastSafely: (_prompt, message) => toasts.push(message),
  }).Page;
  const value = new Page();
  Object.assign(value, { selectedIndexes: [0], apps: [app('a'), app('b')], developers: [developer('a'), developer('d')],
    selectedApps: [], selectedDevelopers: [], loading: false, saving: false, confirming: false, alive: true,
    token: 0, error: '', interaction: { activate() {} }, getUIContext: () => ({ getPromptAction: () => ({
      showDialog: async () => ({ index: dialogIndex }),
    }) }) });
  return { value, calls, toasts };
}
const tests = [];
const test = (name, action) => tests.push({ name, action });
test('batch removal writes once and scopes identical IDs by entity type', async () => {
  const state = storage(); await state.api.removeCollectedItems(['a', 'a', 'missing'], ['d']);
  assert.equal(state.writes(), 1);
  assert.deepEqual(state.snapshot(), { apps: [app('b')], developers: [developer('a')] });
});
test('batch removal preserves concurrent saves through the shared queue', async () => {
  const state = storage();
  await Promise.all([state.api.saveCollectedApp(app('new'), true), state.api.removeCollectedItems(['a'], []),
    state.api.saveFollowedDeveloper(developer('new'), true)]);
  assert.deepEqual(state.snapshot().apps.map(item => item.appId), ['new', 'b']);
  assert.deepEqual(state.snapshot().developers.map(item => item.developerId), ['new', 'a', 'd']);
});
test('failed batch leaves persisted records intact and later writes recover', async () => {
  const state = storage(); state.fail(true);
  await assert.rejects(state.api.removeCollectedItems(['a'], ['d']));
  assert.equal(state.snapshot().apps.length, 2); assert.equal(state.snapshot().developers.length, 2);
  state.fail(false); await state.api.saveCollectedApp(app('new'), true);
  assert.equal(state.snapshot().apps.length, 3);
});
test('selection remains independent across categories and select-all only affects the current category', () => {
  const { value } = page(); value.select('a'); value.selectedIndexes = [1]; value.selectAll();
  assert.equal(value.count(), 3); value.selectedIndexes = [0]; value.selectAll(); assert.equal(value.count(), 4);
  value.selectAll(); assert.equal(value.count(), 2);
});
test('saving and confirmation block further selection and duplicate actions', async () => {
  const { value, calls } = page(); value.selectedApps = ['a']; value.confirming = true;
  value.select('b'); value.selectAll(); await value.removeSelected();
  assert.deepEqual(value.selectedApps, ['a']); assert.equal(calls.length, 0);
});
test('cancelled confirmation preserves both categories and does not write', async () => {
  const { value, calls, toasts } = page(0); value.selectedApps = ['a']; value.selectedDevelopers = ['a'];
  await value.removeSelected(); assert.equal(calls.length, 0); assert.equal(value.count(), 2);
  assert.equal(value.confirming, false); assert.equal(toasts.length, 0);
});
test('confirmed removal commits both categories and reloads current records', async () => {
  const { value, calls, toasts } = page(); value.selectedApps = ['a']; value.selectedDevelopers = ['a'];
  await value.removeSelected(); assert.deepEqual(calls, [{ apps: ['a'], developers: ['a'] }]);
  assert.equal(value.count(), 0); assert.equal(value.apps[0].appId, 'b'); assert.equal(value.saving, false);
  assert.deepEqual(toasts, ['取消收藏']);
});
test('failed removal retains selections for retry and releases busy state', async () => {
  const { value, toasts } = page(1, true); value.selectedApps = ['a'];
  await value.removeSelected(); assert.equal(value.count(), 1); assert.equal(value.saving, false);
  assert.equal(value.confirming, false); assert.deepEqual(toasts, ['取消收藏失败，请重试']);
});
(async () => {
  for (const { name, action } of tests) { await action(); console.log(`PASS ${name}`); }
  console.log(`${tests.length} collection management checks passed`);
})().catch(error => { console.error(error); process.exitCode = 1; });
