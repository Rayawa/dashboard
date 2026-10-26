#!/usr/bin/env node
// Validate moves at source level so incremental compiler caches cannot conceal stale paths.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'entry/src/main/ets');
function files(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(item => {
    const file = path.join(directory, item.name);
    return item.isDirectory() ? files(file) : [file];
  });
}
let imports = 0, links = 0;
const dependencyBoundaries = {
  domain: new Set(['domain', 'models', 'utils']),
  models: new Set(['models']),
  services: new Set(['services', 'domain', 'models', 'config', 'state', 'utils']),
};
for (const file of files(path.join(root, 'entry/src')).filter(file => file.endsWith('.ets'))) {
  const layer = path.relative(source, file).split(path.sep)[0];
  for (const match of fs.readFileSync(file, 'utf8').matchAll(/\bfrom\s*['"]([^'"]+)['"]/g)) {
    if (!match[1].startsWith('.')) {
      assert.ok(layer !== 'domain', `${path.relative(root, file)}: pure domain cannot import ${match[1]}`);
      continue;
    }
    const target = path.resolve(path.dirname(file), match[1]);
    assert.ok(fs.existsSync(target + '.ets'), `${path.relative(root, file)}: missing import ${match[1]}`);
    const targetLayer = path.relative(source, target).split(path.sep)[0];
    if (dependencyBoundaries[layer]) {
      assert.ok(dependencyBoundaries[layer].has(targetLayer),
        `${path.relative(root, file)}: ${layer} cannot depend on ${targetLayer} (${match[1]})`);
    }
    imports++;
  }
}
for (const legacy of ['common', 'component', 'ability', 'pages/more']) {
  assert.ok(!fs.existsSync(path.join(source, legacy)), `Uncategorized legacy directory: ${legacy}`);
}
assert.deepEqual(fs.readdirSync(path.join(source, 'pages/main')).sort(),
  ['AppsPage.ets', 'CollectionPage.ets', 'HomePage.ets', 'MyPage.ets', 'SStationPage.ets']);
for (const file of files(path.join(source, 'components'))) {
  assert.match(fs.readFileSync(file, 'utf8'), /@Component\b/, `Non-component utility: ${file}`);
}
const profile = path.join(root, 'entry/src/main/resources/base/profile');
for (const page of JSON.parse(fs.readFileSync(path.join(profile, 'main_pages.json'))).src) {
  assert.ok(fs.existsSync(path.join(source, page + '.ets')), `Missing entry page ${page}`);
}
const routes = JSON.parse(fs.readFileSync(path.join(profile, 'route_map.json'))).routerMap;
const names = new Set();
for (const route of routes) {
  assert.ok(!names.has(route.name), `Duplicate route ${route.name}`); names.add(route.name);
  const file = path.join(root, 'entry', route.pageSourceFile);
  assert.ok(fs.existsSync(file), `Missing route source ${file}`);
  assert.match(fs.readFileSync(file, 'utf8'), new RegExp(`export function ${route.buildFunction}\\(`));
}
const moduleText = fs.readFileSync(path.join(root, 'entry/src/main/module.json5'), 'utf8');
for (const match of moduleText.matchAll(/"srcEntry":\s*"([^"\n]+)"/g)) {
  assert.ok(fs.existsSync(path.resolve(root, 'entry/src/main', match[1])), `Missing Ability ${match[1]}`);
}
for (const file of fs.readdirSync(root).filter(file => file.endsWith('.md'))) {
  assert.ok(['README.md', 'AGENTS.md'].includes(file), `Classify root document: ${file}`);
}
assert.ok(!fs.existsSync(path.join(root, '.deveco/plans')), 'Do not retain generated agent plans under .deveco/plans');
for (const file of [path.join(root, 'README.md'), path.join(root, 'AGENTS.md'), ...files(path.join(root, 'docs'))].filter(file => file.endsWith('.md'))) {
  for (const match of fs.readFileSync(file, 'utf8').matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
    const target = match[1].split('#')[0];
    if (!target || /^[a-z]+:/i.test(target)) continue;
    assert.ok(fs.existsSync(path.resolve(path.dirname(file), decodeURIComponent(target))),
      `${path.relative(root, file)}: broken link ${match[1]}`);
    links++;
  }
}
const base = JSON.parse(fs.readFileSync(path.join(root, 'entry/src/main/resources/base/element/color.json'))).color;
const dark = JSON.parse(fs.readFileSync(path.join(root, 'entry/src/main/resources/dark/element/color.json'))).color;
const colors = new Set(base.map(item => item.name));
assert.deepEqual([...colors].sort(), dark.map(item => item.name).sort());
for (const file of files(source).filter(file => file.endsWith('.ets'))) {
  for (const match of fs.readFileSync(file, 'utf8').matchAll(/\$r\(['"]app\.color\.([^'"]+)['"]\)/g)) {
    assert.ok(colors.has(match[1]), `${path.relative(root, file)}: missing color ${match[1]}`);
  }
}
console.log(`Structure verified: ${imports} imports, ${routes.length} routes, ${links} local Markdown links and ${colors.size} light/dark colors.`);
