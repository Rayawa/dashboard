#!/usr/bin/env node
// ArkTS can compile component calls inside ordinary callbacks without lowering them.
// Check emitted code so that deferred UI cannot call a component class as a function.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const studio = process.env.DEVECO_STUDIO_HOME || path.join(os.homedir(), 'Applications/DevEco-Studio.app');
const ts = require(path.join(studio, 'Contents/tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const root = path.resolve(__dirname, '..');
const sourceRoot = path.join(root, 'entry/src/main/ets');
const mode = process.argv[2] || 'debug';
if (!['debug', 'release'].includes(mode)) throw Error('Usage: node scripts/check-arkui-builders.cjs [debug|release]');
const buildRoot = path.join(root, mode === 'release' ? 'entry/build/release' : 'entry/build/default',
  'cache/default/default@CompileArkTS/esmodule', mode, 'entry/src/main/ets');
function files(directory, extension) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(directory, entry.name);
    return entry.isDirectory() ? files(file, extension) : file.endsWith(extension) ? [file] : [];
  });
}
const sourceFiles = files(sourceRoot, '.ets');
const componentNames = new Set(sourceFiles.flatMap(file =>
  [...fs.readFileSync(file, 'utf8').matchAll(/\bstruct\s+(\w+)/g)].map(match => match[1])));
for (const required of ['pages/detail/AppDetailPage.ts', 'components/detail/VersionTimeline.ts']) {
  if (!fs.existsSync(path.join(buildRoot, required))) throw Error(`Build ${mode} before checking builder output.`);
}
const errors = [];
let checked = 0;
for (const emitted of files(buildRoot, '.ts')) {
  const relative = path.relative(buildRoot, emitted);
  const ast = ts.createSourceFile(relative, fs.readFileSync(emitted, 'utf8'), ts.ScriptTarget.Latest, true);
  const names = new Set(componentNames);
  for (const statement of ast.statements) {
    if (!ts.isImportDeclaration(statement)) continue;
    const bindings = statement.importClause?.namedBindings;
    if (bindings && ts.isNamedImports(bindings)) {
      for (const binding of bindings.elements) {
        if (componentNames.has(binding.propertyName?.text || binding.name.text)) names.add(binding.name.text);
      }
    }
  }
  function visit(node) {
    if (ts.isCallExpression(node) && ts.isIdentifier(node.expression) && names.has(node.expression.text)) {
      const { line } = ast.getLineAndCharacterOfPosition(node.getStart(ast));
      errors.push(`${relative}:${line + 1}: untransformed component call ${node.expression.text}`);
    }
    ts.forEachChild(node, visit);
  }
  visit(ast);
  checked++;
}
if (errors.length) throw Error(errors.join('\n'));
console.log(`ArkUI builder output verified: ${checked} emitted files (${mode}).`);
