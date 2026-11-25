'use strict';
const assert = require('node:assert/strict');
const config = {requested: 3, 'attempts-max': 17, 'drops-max': 9,
  'duplicates-max': 8, 'size-start': 1, 'size-max': 0, duplicates: 'mug', bounds: {'requested-max': 10000, 'samples-per-slice': 2}};
function mockApi() {
  const records = new Map();
  let next = 9007199254740993n;
  let offline = false, reject = false, uncertain = false;
  // Held ops wait for release, to deliver a reply after other events.
  const gates = new Map();
  const gate = async (op) => { await gates.get(op)?.promise; };
  let limits = {'call-time': 10, 'build-time': 30, 'arm-time': 60};
  const calls = [];
  const api = async (req) => {
    calls.push(req);
    await gate(req.op);
    if (offline) throw new Error('offline');
    if (req.op === 'runs') {
      const ids = [...records.keys()].reverse();
      return {ids, runs: ids.map((id) => {
        const rec = records.get(id);
        return {id, kind: rec.kind, status: rec.status,
          outcome: rec.outcome?.status || rec.outcome?.kind || null};
      })};
    }
    if (req.op === 'status') return structuredClone(records.get(req.id));
    if (req.op === 'document-conf') return {config, seed: '0v123'};
    if (req.op === 'suite-arms') return {arms: ['test-one', 'test-two']};
    if (req.op === 'timeouts') return {...limits};
    if (req.op === 'set-timeouts') {
      limits = {'call-time': Number(req['call-time']),
        'build-time': Number(req['build-time']), 'arm-time': Number(req['arm-time'])};
      return {accepted: true};
    }
    if (req.op === 'cancel') {
      const rec = records.get(req.id); rec.status = 'done';
      rec.outcome = {kind: 'cancelled', reason: 'request'};
      return {accepted: true};
    }
    if (req.op === 'run' || req.op === 'replay') {
      if (reject) return {error: 'action-rejected', _status: 422};
      if (uncertain) throw new Error('connection closed after submit');
      const id = String(next++);
      const old = req.op === 'replay' ? records.get(req.id) : null;
      const request = old ? old.request : req;
      const suite = request.source.kind === 'suite';
      const rec = {id, kind: request.source.kind, request,
        status: 'running', 'engine-version': 'test',
        seed: suite ? null : request.seed || '0v123',
        // %quiz merges a request's changed fields into the document conf.
        config: suite ? null : {...config, ...(request.config || {})},
        'sample-metrics': suite ? 'unavailable' : 'available',
        'replay-of': old?.id || null,
        snapshot: {source: request.source.text || '|=  a=@ud\n=(a a)',
          path: request.source.path || ['draft', 'hoon'], 'source-hash': '0v123',
          context: {desk: request.desk, revision: request.revision.value}},
        counts: suite ? {total: 2, completed: 0} : {accepted: 1, attempted: 1}, outcome: null};
      records.set(id, rec);
      // Concurrent unrelated producer: newest ID must never identify our request.
      records.set('9999999999999999', {...structuredClone(rec), id: '9999999999999999', status: 'done', outcome: {kind:'passed'}});
      return {accepted: true, id};
    }
    return null;
  };
  return {api, records, calls, config, gate, setOffline: value => {offline=value;},
    hold: (op) => {
      let release; const promise = new Promise((resolve) => { release = resolve; });
      gates.set(op, {promise, release});
    },
    release: (op) => { gates.get(op).release(); gates.delete(op); },
    setReject: value => {reject=value;}, setUncertain: value => {uncertain=value;}};
}
async function scenario(env, mock, name) {
  const {runs, documents: docs, runtime} = env.window.quiz;
  const el = id => env.document.getElementById(id);
  const field = (key, value) => { el(`run-${key}`).value=value; el(`run-${key}`).listeners.input?.(); el(`run-${key}`).listeners.change?.(); };
  assert.equal(el('history-empty').textContent, 'History is empty.');
  const tab = docs.active('property');
  mock.hold('document-conf');
  const inspection = runs.inspect();
  docs.editor('property').setSource(':: edited during inspection\n' + tab.text,
    {history:'reset'});
  mock.release('document-conf'); await inspection;
  assert.equal(el('run-settings-note').textContent, '', 'discard obsolete inspection');
  // An explorer change (Save, Save As, refresh) between a request and its
  // reply keeps the reply while its request is unchanged.
  field('revision', '3');
  mock.hold('contexts');
  const latest = runs.latest();
  runs.changed(); mock.release('contexts'); await latest;
  assert.match(el('run-message').textContent, /Selected %quiz revision 20/);
  assert.equal(el('run-revision').value, '20');
  mock.hold('document-conf');
  const kept = runs.inspect();
  runs.changed(); mock.release('document-conf'); await kept;
  assert.match(el('run-settings-note').textContent, /Document conf/);
  runs.changed();
  assert.match(el('run-settings-note').textContent, /Document conf/,
    'an unrelated change keeps the inspection');
  field('revision', '19');
  assert.equal(el('run-settings-note').textContent, '', 'a new revision clears it');
  field('revision', '20');
  field('requested', '5'); field('seed', '0v123');
  field('sizeMax', '8'); field('duplicates', 'allow');
  const confCalls = () => mock.calls.filter(c => c.op === 'document-conf').length;
  const before = confCalls();
  await runs.run();
  assert.equal(confCalls(), before, 'overrides need no conf build');
  const id = tab.runIds[0];
  assert.equal(id, '9007199254740993');
  assert.equal(mock.records.get(id).config.requested, 5);
  assert.equal(mock.records.get(id).config['attempts-max'], 17, 'preserve document budgets');
  assert.equal(mock.records.get(id).config['size-start'], 1, 'preserve document size start');
  assert.equal(mock.records.get(id).config['size-max'], 8);
  assert.equal(mock.records.get(id).config.duplicates, 'allow');
  assert.match(el('run-result-status').textContent, new RegExp(id));
  assert.equal(el('run-cancel').disabled, false);
  if (name === 'run-errors') {
    const previous = el('run-counts').textContent;
    mock.setOffline(true); await runs.refresh();
    assert.equal(el('run-counts').textContent, previous);
    assert.match(el('runs-connection').textContent, /Last confirmed/);
    assert.equal(el('run-start').disabled, true);
    mock.setOffline(false); await runs.refresh();
    mock.setReject(true); await runs.run();
    assert.deepEqual(tab.runIds, [id]);
    assert.match(el('run-message').textContent, /action-rejected/);
    mock.setReject(false); mock.setUncertain(true); await runs.run();
    assert.deepEqual(tab.runIds, [id]);
    assert.match(el('run-message').textContent, /may have been accepted/);
    const count = mock.calls.filter(req => req.op === 'run').length;
    await runs.refresh();
    assert.equal(mock.calls.filter(req => req.op === 'run').length, count, 'no mutation retry');
    mock.setUncertain(false);
    mock.records.get(id).status='done';
    mock.records.get(id).outcome={kind:'cancelled',reason:'reload'};
    await runs.refresh();
    assert.match(env.descendants(el('run-detail')).map(n=>n.textContent).join(' '), /reload/);
    await runs.run();
    const aborted = tab.runIds[0];
    assert.notEqual(aborted, id);
    mock.records.get(aborted).status='done';
    mock.records.get(aborted).outcome={kind:'interrupted',during:'shrinking',arm:null,
      evidence:{why:{kind:'false'},original:{text:'n=9'},shrunk:{text:'n=5'}}};
    await runs.refresh();
    const interrupted = env.descendants(el('run-detail')).map(n=>n.textContent).join(' ');
    assert.match(interrupted, /Interrupted during/);
    assert.match(interrupted, /shrinking/);
    assert.match(interrupted, /CPU time limit/);
    assert.equal(el('run-shrunk').textContent,'n=5');
  } else {
    docs.editor('property').setSource('changed', {history:'reset'});
    assert.match(el('run-stale').textContent, /Stale:/);
    assert.equal(mock.records.get(id).snapshot.source === 'changed', false);
    await runs.cancel();
    assert.equal(el('run-cancel').disabled,true);
    await runs.replay();
    assert.equal(mock.records.get(tab.runIds[0])['replay-of'], id);
    const replayId = tab.runIds[0];
    mock.records.get(replayId).status='done';
    mock.records.get(replayId).outcome={kind:'failed',evidence:{why:{kind:'false'},original:{text:'541'},shrunk:{text:'501'}}};
    await runs.refresh();
    assert.equal(el('run-original').textContent,'541');
    assert.equal(el('run-shrunk').textContent,'501');
    await runs.rerun(); assert.notEqual(tab.runIds[0], replayId);
    const original = tab.runIds[0];
    const other = docs.create('property', {text:'another'});
    assert(!other.runIds?.includes(original));
    assert.match(el('run-source-tab').textContent, /Source tab/);
    docs.select('property',tab.id);
    await docs.open('property',['examples','example','hoon']);
    field('mode','suite'); field('requested','invalid ignored for suites');
    field('arms','test-one');
    mock.hold('suite-arms');
    const discovery = runs.discover();
    runs.changed(); mock.release('suite-arms'); await discovery;
    assert.match(el('run-settings-note').textContent,/test-one, test-two/);
    await runs.run();
    const suite = mock.records.get(docs.active('property').runIds[0]);
    assert.deepEqual(suite.request.source.arms,['test-one']);
    assert.equal(suite.request.config,undefined);
    assert.match(el('run-unavailable').textContent,/unavailable for suites/);
    assert.equal(el('run-replay').disabled,true);
    assert.equal(el('run-preview').disabled,true,'no preview for suites');
    field('mode','draft'); field('previewCount','3'); field('previewShow','verdicts');
    await runs.preview();
    const previewId = docs.active('property').runIds[0];
    assert.deepEqual(mock.records.get(previewId).request.mode,
      {kind:'preview',count:3,verdicts:true,alts:false});
    mock.records.get(previewId).status='done';
    mock.records.get(previewId).outcome={kind:'preview',candidates:[{sample:{text:'n=0'},weight:'1',lighter:true}],
      rows:[{size:1,sample:{text:'n=1'},repeat:false,verdict:'pass',labels:['odd']},
        {size:2,sample:{text:'n=1'},repeat:true,verdict:'false',labels:[]}]};
    await runs.refresh();
    const shown = env.descendants(el('run-preview-rows')).map(n=>n.textContent).join(' ');
    assert.match(shown, /skipped by a run/);
    assert.match(shown, /odd/);
    assert.match(env.descendants(el('run-preview-candidates')).map(n=>n.textContent).join(' '), /lighter/);
    assert.equal(el('run-replay').disabled,true,'a preview is not replayed');
    field('previewCount','101'); await runs.preview();
    assert.match(el('run-message').textContent,/between 1 and 100/);
  }
  runtime.session.save();
  const saved = JSON.parse(env.saved.get('quiz.session'));
  assert(saved.propertyTabs.some(t=>t.runIds?.includes(id)));
  const cleaned = env.window.quizRunFields({runSettings:{desk:'../bad',revision:'0',seed:'<script>',requested:'NaN',sizeStart:'0',sizeMax:'-1',duplicates:'never',arms:'<script>'},runIds:['1',1,'../2','1']});
  assert.deepEqual(cleaned.runIds,['1']);
  assert.equal(cleaned.runSettings.desk,'');
  assert.equal(cleaned.runSettings.requested,'');
  assert.equal(cleaned.runSettings.sizeStart,'');
  assert.equal(cleaned.runSettings.sizeMax,'');
  assert.equal(cleaned.runSettings.duplicates,'');
  runs.stop();
}
module.exports={mockApi,scenario};
