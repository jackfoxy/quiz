'use strict';
const assert = require('node:assert/strict');
const config = {requested: 3, 'attempts-max': 17, 'drops-max': 9,
  'duplicates-max': 8, bounds: {'requested-max': 10000, 'samples-per-slice': 2}};
function mockApi() {
  const records = new Map();
  let next = 9007199254740993n;
  let offline = false, reject = false, uncertain = false;
  let holdConf = false, releaseConf;
  const calls = [];
  const api = async (req) => {
    calls.push(req);
    if (offline) throw new Error('offline');
    if (req.op === 'runs') return {ids: [...records.keys()].reverse()};
    if (req.op === 'status') return structuredClone(records.get(req.id));
    if (req.op === 'document-conf') {
      if (holdConf) await new Promise(resolve => { releaseConf = resolve; });
      return {config, seed: '0v123'};
    }
    if (req.op === 'suite-arms') return {arms: ['test-one', 'test-two']};
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
        config: suite ? null : request.config || config,
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
  return {api, records, calls, config, setOffline: value => {offline=value;},
    holdConf: () => {holdConf=true;},
    releaseConf: () => {holdConf=false; releaseConf();},
    setReject: value => {reject=value;}, setUncertain: value => {uncertain=value;}};
}
async function scenario(env, mock, name) {
  const {runs, documents: docs, runtime} = env.window.quiz;
  const el = id => env.document.getElementById(id);
  const field = (key, value) => { el(`run-${key}`).value=value; el(`run-${key}`).listeners.input?.(); el(`run-${key}`).listeners.change?.(); };
  assert.equal(el('history-empty').textContent, 'History is empty.');
  const tab = docs.active('property');
  mock.holdConf();
  const inspection = runs.inspect();
  docs.editor('property').setSource(':: edited during inspection\n' + tab.text,
    {history:'reset'});
  mock.releaseConf(); await inspection;
  assert.equal(el('run-settings-note').textContent, '', 'discard obsolete inspection');
  field('requested', '5'); field('seed', '0v123');
  await runs.run();
  const id = tab.runIds[0];
  assert.equal(id, '9007199254740993');
  assert.equal(mock.records.get(id).config.requested, 5);
  assert.equal(mock.records.get(id).config['attempts-max'], 17, 'preserve document budgets');
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
    field('arms','test-one'); await runs.discover();
    assert.match(el('run-settings-note').textContent,/test-one, test-two/);
    await runs.run();
    const suite = mock.records.get(docs.active('property').runIds[0]);
    assert.deepEqual(suite.request.source.arms,['test-one']);
    assert.equal(suite.request.config,undefined);
    assert.match(el('run-unavailable').textContent,/unavailable for suites/);
    assert.equal(el('run-replay').disabled,true);
  }
  runtime.session.save();
  const saved = JSON.parse(env.saved.get('quiz.session'));
  assert(saved.propertyTabs.some(t=>t.runIds?.includes(id)));
  const cleaned = env.window.quizRunFields({runSettings:{desk:'../bad',revision:'0',seed:'<script>',requested:'NaN',arms:'<script>'},runIds:['1',1,'../2','1']});
  assert.deepEqual(cleaned.runIds,['1']);
  assert.equal(cleaned.runSettings.desk,'');
  assert.equal(cleaned.runSettings.requested,'');
  runs.stop();
}
module.exports={mockApi,scenario};
