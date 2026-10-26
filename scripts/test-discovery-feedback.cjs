#!/usr/bin/env node
// Run with DevEco's Node.js. Native visuals still require device verification.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const studio = process.env.DEVECO_STUDIO_HOME || path.join(os.homedir(), 'Applications/DevEco-Studio.app');
const ts = require(path.join(studio, 'Contents/tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const root = path.resolve(__dirname, '../entry/src/main/ets');
let count = 0;
function test(name, run) { run(); count++; console.log(`PASS ${name}`); }
function load(file, globals) {
  const source = fs.readFileSync(path.join(root, file), 'utf8').replace('@Observed', '');
  const code = ts.transpileModule(source, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021,
  } }).outputText;
  const exports = {};
  vm.runInNewContext(code, { exports, ...globals });
  return exports;
}
let now = 0, nextTimer = 0, vibrations = 0, level = 1;
const timers = new Map();
const advance = ms => {
  now += ms;
  for (const [id, timer] of [...timers]) if (timer.at <= now) {
    timers.delete(id); timer.callback();
  }
};
const globals = {
  Curve: { EaseOut: 'ease-out' }, Date: { now: () => now },
  TouchType: { Down: 0, Up: 1, Cancel: 2 }, AppStorage: { get: () => level },
  setTimeout: (callback, ms) => { const id = ++nextTimer; timers.set(id, { callback, at: now + ms }); return id; },
  clearTimeout: id => timers.delete(id),
  require: name => {
    if (name.endsWith('/constants')) return { MIN_PRESS_FEEDBACK_MS: 140, STORAGE_KEY_VIBRATION_LEVEL: 'vibrationLevel', DEFAULT_VIBRATION_LEVEL: 1 };
    if (name.endsWith('/vibration')) return { vibration: { dotVibration: () => vibrations++ } };
    throw new Error(`Unexpected import: ${name}`);
  },
};
const { DiscoveryInteraction } = load('ui/interaction/DiscoveryInteraction.ets', globals);
test('UIContext drives press and release animation', () => {
  let animations = 0;
  const state = new DiscoveryInteraction({ animateTo: (options, update) => {
    assert.equal(options.duration, 120); animations++; update();
  } });
  state.touch('button', { type: 0 }); state.touch('button', { type: 1 });
  advance(139); assert.equal(state.pressedKey, 'button');
  advance(1); assert.equal(state.pressedKey, ''); assert.equal(animations, 2);
});
test('unavailable UIContext still updates and clears state', () => {
  const state = new DiscoveryInteraction({ animateTo: () => { throw new Error('destroyed context'); } });
  state.touch('button', { type: 0 }); assert.equal(state.pressedKey, 'button');
  state.touch('button', { type: 1 }); advance(140); assert.equal(state.pressedKey, '');
});
test('cancel and disappear clear pending feedback', () => {
  const state = new DiscoveryInteraction();
  state.touch('row', { type: 0 }); state.touch('row', { type: 2 });
  assert.equal(state.pressedKey, ''); assert.equal(timers.size, 0);
  state.activate('row'); state.dispose(); advance(1000);
  assert.equal(state.pressedKey, ''); assert.equal(timers.size, 0);
});
test('interleaved controls ignore old releases and timeout safely', () => {
  const state = new DiscoveryInteraction();
  state.touch('old', { type: 0 }); state.touch('new', { type: 0 }); state.touch('old', { type: 1 });
  assert.equal(state.pressedKey, 'new'); advance(800); assert.equal(state.pressedKey, '');
});
test('keyboard activation respects vibration setting', () => {
  const state = new DiscoveryInteraction();
  const before = vibrations; level = 0; state.activate('key'); assert.equal(vibrations, before);
  level = 1; state.activate('key'); assert.equal(vibrations, before + 1); state.dispose();
});
const styles = load('ui/theme/DiscoveryTheme.ets', {
  $r: name => name,
  require: name => {
    if (name === '@kit.UIDesignKit') return { hdsEffect: { PointLightIlluminatedType: { BORDER_CONTENT: 1 } } };
    if (name.endsWith('/visualEffects')) return { pressVisualEffect: pressed => ({ pressed }), pressLightFieldFilter: pressed => ({ pressed }) };
    throw new Error(`Unexpected import: ${name}`);
  },
});
for (const name of ['DiscoveryButtonStyle', 'DiscoverySelectStyle', 'DiscoveryToggleStyle', 'DiscoveryRowStyle']) {
  test(`${name} uses supported modifier operations without animation()`, () => {
    const values = {};
    // The native AttributeModifier proxy throws for animation(); deliberately omit it here.
    const attribute = {};
    for (const method of ['scale', 'visualEffect', 'compositingFilter', 'backgroundColor', 'fontColor',
      'optionBgColor', 'optionFontColor', 'selectedOptionBgColor', 'selectedOptionFontColor']) {
      attribute[method] = value => { values[method] = value; return attribute; };
    }
    new styles[name](true).applyNormalAttribute(attribute);
    assert.equal(values.scale.x, .97); assert.equal(values.visualEffect.pressed, true);
    new styles[name](false).applyNormalAttribute(attribute);
    assert.equal(values.scale.x, 1); assert.equal(values.compositingFilter.pressed, false);
  });
}
console.log(`${count} feedback regression checks passed`);
