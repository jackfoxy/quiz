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
for (const id of ['quiz-editor', 'document-location',
  'quiz-error', 'run-controls', 'quiz-runs', 'properties-panel', 'properties-tree',
  'apps-panel', 'apps-tree',
  'property-save', 'property-save-as', 'property-open',
  'property-ref', 'source-status', 'quiz-limit-call', 'quiz-limit-build',
  'quiz-limit-arm', 'quiz-limits-state']) {
  const node = new env.Element(); node.id = id;
  env.elements[`#${id}`] = node;
  env.document.body.append(node);
}
// As urui's shell: the first view is shown, Apps hidden.
env.elements['#apps-panel'].hidden = true;
env.window.ace = ace;
env.window.quizAceAssets = aceAssets;
env.window.location.href = 'http://localhost/apps/quiz/';
const savedTab = {id: 'property-7', path: ['clay', 'quiz', 'now', 'restored', 'hoon'],
  text: '|=  a=@ud\n+(a)', clean: '|=  a=@ud\na', hash: '0v1',
  selection: {start: 2, end: 5}, display: 'source'};
if (['restore', 'invalid-session'].includes(scenario)) {
  env.saved.set('quiz.session', JSON.stringify({version: 2,
    propertyTabs: [savedTab], activePropertyTabId: 'property-7', nextPropertyTab: 8,
    clayContext: scenario === 'restore'
      ? {desk: 'base', revision: '9', extra: 'discard'}
      : {desk: '../base', revision: 9}}));
}
// Keyed by pinned path; the mock reads `now` as each desk's head.
const heads = {quiz: '20', base: '10'};
const pinned = (path) => (path[2] === 'now' ? [...path.slice(0, 2), heads[path[1]],
  ...path.slice(3)] : path).join('/');
const files = new Map([
  ['clay/quiz/20/examples/example/hoon', '/+  e=quiz-engine\n|%\n++  fate  |=(a=@ud =(a a))\n--'],
  ['clay/quiz/20/tests/example/hoon', '/+  *test\n|%\n++  test-one  ~\n--']]);
const requests = [];
global.fetch = async (url, options = {}) => {
  const req = options.body ? JSON.parse(options.body) : {};
  requests.push({url, ...req});
  let body = {ok: true}; let status = 200;
  if (req.op === 'contexts') await mock.gate('contexts');
  if (url.endsWith('/api') && !['contexts', 'properties'].includes(req.op)) {
    body = await mock.api(req); status = body?._status || 200;
  }
  else if (url === '/docs' || url.endsWith('/doc.toc')) status = 404;
  else if (url.endsWith('/api') && req.op === 'runs') body.ids = [];
  else if (req.op === 'properties') body.entries = [...files.keys()]
    .filter((key) => key.startsWith(`clay/${req.desk}/${req.revision}/`))
    .map((key) => ({path: key.split('/'), kind: 'file'}));
  else if (url.endsWith('/api')) body.contexts = [
    {desk: 'quiz', revision: '20'}, {desk: 'base', revision: '10'}];
  else if (req.op === 'browse') body.entries = [...files.keys()]
    .filter((key) => key.startsWith(req.scope.join('/') + '/'))
    .map((key) => ({path: key.split('/'), kind: 'file'}));
  else if (req.op === 'load') body = {ok: true,
    text: files.get(pinned(req.path)), hash: '0v1',
    readonly: req.path[2] !== 'now'};
  else if (req.op === 'save') {
    assert.equal(req.path[2], 'now', 'saves land at now');
    files.set(pinned(req.path), req.text); body.hash = '0v2';
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
  if (scenario === 'open-run') {
    // A suite row's Open and run opens the file and submits it at the head.
    const path = ['clay', 'quiz', 'now', 'tests', 'example', 'hoon'];
    runtime.explorer.context.open('property', path, el('quiz-editor'), undefined,
      {entry: 'file', role: 'suite'});
    const item = env.document.getElementById('file-context-open-run');
    assert(item && !item.hidden, 'Open and run is offered');
    item.listeners.click(); await settle();
    assert.deepEqual(docs.active('property').path, path);
    const run = mock.calls.find((req) => req.op === 'run');
    assert(run, 'a run was submitted');
    assert.deepEqual(run.source, {kind: 'suite', path: ['tests', 'example', 'hoon'], arms: []});
    assert.deepEqual(run.revision, {kind: 'ud', value: '20'});
    console.log(`PASS ${scenario}`); return;
  }
  assert.equal(validContext({desk: 'quiz', revision: '0'}), null);
  assert.equal(validContext({desk: 'quiz', revision: '01'}), null);
  assert.equal(validContext([]), null);
  if (scenario === 'documents') {
    await env.window.quiz.limitsReady;
    assert.equal(el('quiz-limit-call').value, '10');
    assert.equal(el('quiz-limit-arm').value, '60');
    el('quiz-limit-call').value = '0';
    assert.equal(await env.window.quiz.saveLimits(), false);
    assert.match(el('quiz-limits-state').textContent, /whole number/);
    assert(!requests.some((req) => req.op === 'set-timeouts'), 'refuse before posting');
    el('quiz-limit-call').value = '5';
    assert.equal(await env.window.quiz.saveLimits(), true);
    assert.deepEqual(requests.filter((req) => req.op === 'set-timeouts').map((req) =>
      [req['call-time'], req['build-time'], req['arm-time']]), [['5', '30', '60']]);
    assert.equal(el('quiz-limit-call').value, '5');
    assert.match(el('quiz-limits-state').textContent, /^Saved/);
    assert.equal(docs.list('property').length, 1);
    const editor = docs.editor('property');
    editor.setSource('|=  n=@ud\n=(n n)', {history: 'reset'});
    assert(docs.dirty('property', docs.active('property').id));
    // %quiz always shows data/, empty or not; a new document starts there.
    const texts = (node) => [node.textContent, ...(node.children || []).flatMap(texts)];
    assert(texts(el('properties-tree')).includes('data'), 'data/ is shown');
    const saving = docs.save('property'); await settle();
    assert.equal(el('urui-file-dialog-path').value, 'quiz/data/');
    el('urui-file-dialog-confirm').onclick(); await saving;
    assert(docs.dirty('property', docs.active('property').id), 'quiz/data/ alone is refused');
    const retry = docs.save('property'); await settle();
    el('urui-file-dialog-path').value = 'doubles';
    el('urui-file-dialog-mark').value = 'hoon';
    el('urui-file-dialog-confirm').onclick(); await retry;
    // A path naming no desk lands in data/ of the visible desk at now.
    assert.equal(files.get('clay/quiz/20/data/doubles/hoon'), '|=  n=@ud\n=(n n)');
    assert.deepEqual(docs.active('property').path, ['clay', 'quiz', 'now', 'data', 'doubles', 'hoon']);
    assert(!docs.dirty('property', docs.active('property').id));
    await docs.open('property', ['clay', 'quiz', 'now', 'data', 'doubles', 'hoon']);
    editor.setSource('local edit', {history: 'reset'});
    const opening = docs.open('property', ['clay', 'quiz', 'now', 'data', 'doubles', 'hoon']);
    await settle(); el('urui-confirm-cancel').listeners.click(); await opening;
    assert.equal(docs.active('property').text, 'local edit');
    let prevented = false;
    env.windowListeners.beforeunload({preventDefault() { prevented = true; }});
    assert(prevented);
    // A numbered revision saves to the same path at now.
    await docs.open('property', ['clay', 'quiz', '20', 'examples', 'example', 'hoon']);
    assert.equal(el('property-save').disabled, false);
    editor.setSource('/+  e=quiz-engine\n|%\n++  fate  |=(a=@ud &)\n--', {history: 'reset'});
    await docs.save('property');
    assert.deepEqual(docs.active('property').path,
      ['clay', 'quiz', 'now', 'examples', 'example', 'hoon']);
    assert.match(files.get('clay/quiz/20/examples/example/hoon'), /\|=\(a=@ud &\)/);
    // Save As from a numbered revision offers <desk>/<path>, no case, and
    // lists the desk's files the same way; the save lands at now.
    await docs.open('property', ['clay', 'quiz', '20', 'tests', 'example', 'hoon']);
    const savingAs = docs.save('property', {as: true}); await settle();
    assert.equal(el('urui-file-dialog-path').value, 'quiz/tests/example');
    const listed = el('urui-file-dialog-list').children.map((entry) => entry.textContent);
    assert(listed.includes('clay/quiz/tests/example/hoon'), listed.join());
    assert(!listed.some((text) => text.includes('/now/')), listed.join());
    el('urui-file-dialog-path').value = 'quiz/tests/copy';
    el('urui-file-dialog-confirm').onclick(); await savingAs;
    assert.deepEqual(docs.active('property').path,
      ['clay', 'quiz', 'now', 'tests', 'copy', 'hoon']);
    assert.equal(files.get('clay/quiz/20/tests/copy/hoon'), files.get('clay/quiz/20/tests/example/hoon'));
    // A new document's Save As starts in data/ of the visible view's desk.
    docs.create('property', {text: '/+  e=quiz-engine\n|%\n++  fate  |=(a=@ud &)\n--', focus: true});
    el('apps-panel').hidden = false;
    const fresh = docs.save('property'); await settle();
    assert.equal(el('urui-file-dialog-path').value, 'base/data/');
    el('urui-file-dialog-confirm').onclick(); await fresh;
    assert(!docs.active('property').path, 'base/data/ alone is refused');
    el('apps-panel').hidden = true;
    // The mark is always hoon: `x.hoon`, `x/hoon` and `x` name one file.
    for (const [typed, saved] of [['quiz/tests/a.hoon', ['tests', 'a']],
      ['quiz/tests/b/hoon', ['tests', 'b']], ['quiz/tests/c', ['tests', 'c']],
      ['d.hoon', ['data', 'd']], ['e/hoon', ['data', 'e']], ['f', ['data', 'f']],
      ['g/h', ['data', 'g', 'h']], ['data/i', ['data', 'i']], ['data', ['data', 'data']],
      ['quiz', ['data', 'quiz']], ['quiz/hoon', ['data', 'quiz']],
      ['quiz.hoon', ['data', 'quiz']]]) {
      const saving = docs.save('property', {as: true}); await settle();
      el('urui-file-dialog-path').value = typed;
      el('urui-file-dialog-confirm').onclick(); await saving;
      assert.deepEqual(docs.active('property').path,
        ['clay', 'quiz', 'now', ...saved, 'hoon'], typed);
    }
  } else {
    assert.equal(docs.active('property').text, savedTab.text);
    assert(docs.dirty('property', 'property-7'));
    assert.deepEqual(docs.editor('property').getSelection(), savedTab.selection);
  }
  runtime.session.save();
  const saved = JSON.parse(env.saved.get('quiz.session'));
  // clayContext is the Apps view's: any desk but %quiz.
  assert.deepEqual(saved.clayContext, scenario === 'restore'
    ? {desk: 'base', revision: '9'} : {desk: 'base', revision: '10'});
  const options = el('apps-desk').children.map((option) => option.value);
  assert.deepEqual(options, ['base']);
  assert(!el('clay-desk'), 'Properties and suites has no desk list');
  // Apps shows data/ too, though %base has no indexed files here.
  const shownTexts = (node) => [node.textContent, ...(node.children || []).flatMap(shownTexts)];
  assert(shownTexts(el('apps-tree')).includes('data'), 'Apps shows data/');
  assert(requests.some((req) => req.op === 'properties' && req.desk === 'quiz'));
  assert(requests.some((req) => req.op === 'properties'
    && req.desk === saved.clayContext.desk
    && req.revision === saved.clayContext.revision));
  console.log(`PASS ${scenario}`);
})().then(() => process.exit(0), (error) => {console.error(error); process.exit(1);});
