'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {createEnvironment, bootApplication} = require('./doubles');
const {createAce} = require('./doubles/ace');
const scenario = process.argv[2];
const runTests = require('./run-scenarios');
const mock = runTests.mockApi();
setTimeout(() => {console.error('Scenario timeout'); process.exit(1);}, 10000);
const env = createEnvironment({session: null});
const addListener = env.window.addEventListener;
env.window.addEventListener = (name, callback) => {
  const previous = env.windowListeners[name];
  addListener(name, previous ? (event) => { previous(event); callback(event); } : callback);
};
const {ace, aceAssets} = createAce('ace/mode/hoon');
// Consumer-only shell nodes; the upstream doubles stay unchanged.
for (const id of ['quiz-editor', 'editable-copy', 'document-location',
  'quiz-error', 'run-controls', 'quiz-runs', 'clay-source-panel', 'work-files-tree', 'example-files-tree',
  'doc-files-tree', 'property-save', 'property-save-as', 'property-open',
  'property-ref', 'source-status']) {
  const node = new env.Element(); node.id = id;
  env.elements[`#${id}`] = node;
  env.document.body.append(node);
}
env.window.ace = ace;
env.window.quizAceAssets = aceAssets;
env.window.location.href = 'http://localhost/apps/quiz/';
const savedTab = {id: 'property-7', path: ['work', 'restored', 'hoon'],
  text: '|=  a=@ud\n+(a)', clean: '|=  a=@ud\na', hash: '0v1',
  selection: {start: 2, end: 5}, display: 'source'};
if (['restore', 'invalid-session'].includes(scenario)) {
  env.saved.set('quiz.session', JSON.stringify({version: 2,
    propertyTabs: [savedTab], activePropertyTabId: 'property-7', nextPropertyTab: 8,
    clayContext: scenario === 'restore'
      ? {desk: 'base', revision: '9', extra: 'discard'}
      : {desk: '../base', revision: 9}}));
}
const files = new Map([['examples/example/hoon', '|=  a=@ud\n=(a a)']]);
const requests = [];
global.fetch = async (url, options = {}) => {
  const req = options.body ? JSON.parse(options.body) : {};
  requests.push({url, ...req});
  let body = {ok: true}; let status = 200;
  if (url.endsWith('/api') && req.op !== 'contexts') {
    body = await mock.api(req); status = body?._status || 200;
  }
  else if (url === '/docs' || url.endsWith('/doc.toc')) status = 404;
  else if (url.endsWith('/api') && req.op === 'runs') body.ids = [];
  else if (url.endsWith('/api')) body.contexts = [
    {desk: 'quiz', revision: '20'}, {desk: 'base', revision: '10'}];
  else if (req.op === 'browse') body.entries = [...files.keys()]
    .filter((key) => key.startsWith(req.scope.join('/') + '/'))
    .map((key) => ({path: key.split('/'), kind: 'file'}));
  else if (req.op === 'load') body = {ok: true,
    text: files.get(req.path.join('/')), hash: '0v1',
    readonly: req.path[0] !== 'work'};
  else if (req.op === 'save') {
    files.set(req.path.join('/'), req.text); body.hash = '0v2';
  }
  if (req.op === 'contexts') body.defaults = mock.config;
  return {ok: status < 400, status, headers: {get: () => 'application/json'},
    text: async () => JSON.stringify(body), json: async () => body};
};
const settle = async () => { for (let i = 0; i < 6; i++) await env.tick(); };
const el = (id) => env.document.getElementById(id);
(async () => {
  bootApplication(env, fs.readFileSync(process.argv[3], 'utf8'), 'quiz-app.js');
  await env.window.quiz.ready;
  if (scenario.startsWith('run')) {
    await runTests.scenario(env, mock, scenario); console.log(`PASS ${scenario}`); return;
  }
  const {documents: docs, runtime, validContext} = env.window.quiz;
  assert.equal(validContext({desk: 'quiz', revision: '0'}), null);
  assert.equal(validContext({desk: 'quiz', revision: '01'}), null);
  assert.equal(validContext([]), null);
  if (scenario === 'documents') {
    assert.equal(docs.list('property').length, 1);
    const editor = docs.editor('property');
    editor.setSource('|=  n=@ud\n=(n n)', {history: 'reset'});
    assert(docs.dirty('property', docs.active('property').id));
    const saving = docs.save('property'); await settle();
    el('urui-file-dialog-path').value = 'doubles';
    el('urui-file-dialog-mark').value = 'hoon';
    el('urui-file-dialog-confirm').onclick(); await saving;
    assert.equal(files.get('work/doubles/hoon'), '|=  n=@ud\n=(n n)');
    assert(!docs.dirty('property', docs.active('property').id));
    await docs.open('property', ['work', 'doubles', 'hoon']);
    editor.setSource('local edit', {history: 'reset'});
    const opening = docs.open('property', ['work', 'doubles', 'hoon']);
    await settle(); el('urui-confirm-cancel').listeners.click(); await opening;
    assert.equal(docs.active('property').text, 'local edit');
    let prevented = false;
    env.windowListeners.beforeunload({preventDefault() { prevented = true; }});
    assert(prevented);
    await docs.open('property', ['examples', 'example', 'hoon']);
    assert.equal(el('property-save').disabled, true);
    assert.equal(await docs.save('property', {as: true}), undefined);
    env.window.quiz.editableCopy();
    assert.equal(docs.active('property').path, null);
    assert(docs.dirty('property', docs.active('property').id));
    assert.equal(el('property-save').disabled, false);
  } else {
    assert.equal(docs.active('property').text, savedTab.text);
    assert(docs.dirty('property', 'property-7'));
    assert.deepEqual(docs.editor('property').getSelection(), savedTab.selection);
  }
  runtime.session.save();
  const saved = JSON.parse(env.saved.get('quiz.session'));
  assert.deepEqual(saved.clayContext, scenario === 'restore'
    ? {desk: 'base', revision: '9'} : {desk: 'quiz', revision: '20'});
  assert(requests.some((req) => req.op === 'browse'
    && req.scope.join('/') === `clay/${saved.clayContext.desk}/${saved.clayContext.revision}`));
  console.log(`PASS ${scenario}`);
})().then(() => process.exit(0), (error) => {console.error(error); process.exit(1);});
