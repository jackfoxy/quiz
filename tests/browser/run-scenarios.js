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
    if (req.op === 'delete') {
      const rec = records.get(req.id);
      if (!rec) return {error: 'run-not-found', _status: 404};
      if (rec.status !== 'done') return {error: 'run-unfinished', _status: 409};
      records.delete(req.id); return {accepted: true};
    }
    if (req.op === 'clear') {
      for (const [id, rec] of [...records]) if (rec.status === 'done') records.delete(id);
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
    // A shrinker error after a counterexample shows its own cause too.
    await runs.run();
    const broken = tab.runIds[0];
    mock.records.get(broken).status='done';
    mock.records.get(broken).outcome={kind:'error',stage:'alts',
      why:{kind:'crash',trace:['alts-broken']},
      evidence:{why:{kind:'false'},original:{text:'9','noun-jam':'0v9'},
        shrunk:{text:'7','noun-jam':'0v7'},trace:[]}};
    await runs.refresh();
    const errored = env.descendants(el('run-detail')).map(n=>n.textContent).join(' ');
    assert.match(el('run-error-cause').textContent, /alts-broken/);
    assert.equal(el('run-shrunk').textContent,'7');
    assert.match(el('run-failure').textContent, /false/);
    assert.match(errored, /Shrunk sample noun \(jam, @uv\):\s+0v7/);
    assert.match(el('run-request').textContent, /"draft"/);
    assert.equal(el('run-copy-noun').disabled, false);
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
    // Example 11's whole shrink, as recorded: 21 alts calls in 89 rows.
    // A finished record is fetched once, so each trace gets its own run.
    const traced = async (trace) => {
      await runs.run();
      const rec = mock.records.get(docs.active('property').runIds[0]);
      rec.status = 'done';
      rec.outcome = {kind:'failed', evidence:{why:{kind:'false'},
        original:{text:'cmds=…'}, shrunk:{text:'cmds=…'}, trace}};
      await runs.refresh();
    };
    await traced(require('./fixtures/queue-model-bug-trace.json'));
    const text = (id) => env.descendants(el(id)).map(n=>n.textContent).join(' ');
    assert.match(text('run-shrink-trace'), /21 steps, 20 accepted \(last 89 trace rows\)/);
    assert.match(el('run-trace-rule').textContent, /strictly below the best weight/);
    // It opens on the last step: why shrinking stopped.
    assert.equal(el('run-trace-position').textContent, 'Step 21 of 21');
    assert.match(el('run-trace-heading').textContent,
      /offered 4 candidates; none was accepted \(2 seen, 2 passed\), so shrinking stopped here/);
    assert.match(text('run-trace-step'), /Skipped: a candidate with the same mug/);
    assert.equal(el('run-trace-next').disabled, true);
    el('run-trace-first').listeners.click();
    assert.equal(el('run-trace-position').textContent, 'Step 1 of 21');
    assert.match(el('run-trace-heading').textContent,
      /weight 17239453263\) offered 20 candidates; candidate 1 was accepted \(weight 15536932056\); the other 19 were not tried/);
    el('run-trace-next').listeners.click(); el('run-trace-next').listeners.click();
    el('run-trace-next').listeners.click(); el('run-trace-prev').listeners.click();
    el('run-trace-next').listeners.click();
    assert.equal(el('run-trace-position').textContent, 'Step 4 of 21');
    assert.match(text('run-trace-step'), /Rejected: the fate passed/);
    assert.match(text('run-trace-step'), /still fails/);
    el('run-trace-accepted').checked = true; el('run-trace-accepted').listeners.change();
    assert.equal(el('run-trace-path').children.length, 21, 'heading and 20 accepted rows');
    assert.equal(el('run-trace-first').disabled, true);
    assert.match(el('run-trace-end').textContent, /Step 21: .*so shrinking stopped here/);
    // A heavier candidate names the strict-weight rule; a trace cut by
    // trace-steps starts inside an alts call it no longer holds.
    await traced([
      {kind:'candidate', why:'passed', weight:'5', text:'n=4'},
      {kind:'alts', best:'9', count:2},
      {kind:'candidate', why:'heavier', weight:'9', text:null}]);
    assert.match(el('run-trace-heading').textContent, /Step 2: .*the run stopped after 1 of 2 candidates/);
    assert.match(text('run-trace-step'), /weight 9 is not below the best weight 9 \(strict-weight rule\)/);
    assert.match(text('run-trace-step'), /\(not rendered\)/);
    el('run-trace-prev').listeners.click();
    assert.match(el('run-trace-heading').textContent, /its alts call is older than the retained trace/);
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
        {size:2,sample:{text:'n=1'},repeat:true,verdict:'false',labels:[]}],
      summary:{samples:4,repeats:1,sizes:[1,2,3,4],bytes:[1,1,3,9],
        verdicts:{pass:1,false:1,drop:2},labels:{odd:1}}};
    await runs.refresh();
    // The summary covers all four samples though only two are listed.
    const summary = env.descendants(el('run-preview-summary')).map(n=>n.textContent).join(' ');
    assert.match(summary, /Generator summary: 4 samples/);
    assert.match(summary, /Sample bytes min \/ median \/ max:\s+1 \/ 1 \/ 9/);
    assert.match(summary, /≤ 16 bytes/);
    assert.match(summary, /50% of samples were discarded/);
    assert.match(env.descendants(el('run-preview-verdicts')).map(n=>n.textContent).join(' '), /drop/);
    assert.match(env.descendants(el('run-detail')).map(n=>n.textContent).join(' '),
      /Preview: first 2 of 4 samples/);
    const shown = env.descendants(el('run-preview-rows')).map(n=>n.textContent).join(' ');
    assert.match(shown, /skipped by a run/);
    assert.match(shown, /odd/);
    assert.match(env.descendants(el('run-preview-candidates')).map(n=>n.textContent).join(' '), /lighter/);
    assert.equal(el('run-replay').disabled,true,'a preview is not replayed');
    field('previewCount','1001'); await runs.preview();
    assert.match(el('run-message').textContent,/between 1 and 1000/);
    field('previewCount','2'); field('previewShow','alts'); await runs.preview();
    assert.deepEqual(mock.records.get(docs.active('property').runIds[0]).request.mode,
      {kind:'preview',count:2,verdicts:false,alts:true}, 'alternates without verdicts');
    // Find examples for each label: a count of passes, never `requested`.
    field('examplesCount','0'); await runs.findExamples();
    assert.match(el('run-message').textContent,/between|1 to/);
    field('requested','7'); field('examplesCount','50'); await runs.findExamples();
    const searchId = docs.active('property').runIds[0];
    const search = mock.records.get(searchId);
    assert.deepEqual(search.request.mode, {kind:'examples',count:50});
    assert.equal(search.request.config?.requested, undefined, 'a search ignores requested');
    field('requested','');
    search.status='done'; search.kind='examples';
    search.outcome={kind:'examples',
      found:[{label:'empty-pop',sample:{text:'cmds=[[7.368.560 0] 0]','noun-jam':'0v1'},weight:'7368563',steps:0,tried:3,end:'done'},
        {label:'refill',sample:{text:'cmds=[[1.752.397.168 0] [7.368.560 0] 0]','noun-jam':'0v2'},weight:'1759765737',steps:2,tried:40,end:'limited'}],
      unseen:['huge'], budget:'attempts', evidence:null};
    await runs.refresh();
    const found = env.descendants(el('run-found')).map(n=>n.textContent).join(' ');
    assert.match(found, /Smallest example for each of 2 labels/);
    assert.match(env.descendants(el('run-found-examples')).map(n=>n.textContent).join(' '),
      /empty-pop cmds=\[\[7\.368\.560 0\] 0\] 7368563 0 3 smallest found/);
    assert.match(found, /shrink limit reached/);
    assert.match(el('run-found-unseen').textContent + env.descendants(el('run-found-unseen')).map(n=>n.textContent).join(' '), /huge/);
    assert.match(found, /attempts budget ran out/);
    assert.match(env.descendants(el('run-detail')).map(n=>n.textContent).join(' '), /Labelled-example search/);
    assert.equal(el('run-replay').disabled,true,'a search is not replayed');
    // Every coverage requirement, met or not, with bounds under %confident.
    await runs.run();
    const covered = mock.records.get(docs.active('property').runIds[0]);
    covered.status='done';
    covered.outcome={kind:'uncovered', shortfalls:[{label:'none',want:90,got:0,table:null}], examples:[],
      coverage:[
        {mode:'confident',label:'any',table:null,hits:100,total:100,got:100,want:50,met:true,low:'73.04',high:'100.00',decision:{kind:'established'}},
        {mode:'confident',label:'none',table:null,hits:0,total:100,got:0,want:90,met:false,low:'0.00',high:'26.96',decision:{kind:'refuted'}},
        {mode:'confident',label:'h',table:'side',hits:3,total:10,got:30,want:40,met:false,low:null,high:null,decision:{kind:'threshold',why:'attempts'}}]};
    await runs.refresh();
    const rows = env.descendants(el('run-coverage-rows')).map(n=>n.textContent).join(' ');
    assert.match(rows, /any confident 100 \/ 100 100% 50% yes 73\.04% – 100\.00% established/);
    assert.match(rows, /refuted: upper bound below the share/);
    assert.match(rows, /side = h .* plain threshold: the attempts budget ran out/);
    assert.match(env.descendants(el('run-coverage-modes')).map(n=>n.textContent).join(' '), /checkCoverage/);
    // More limits: budgets and on-timeout go as single fields; a bound
    // sends the document's other bounds too, read with one conf build.
    field('requested','');
    field('attemptsMax','40'); field('onTimeout','fail'); field('bound-trace-steps','7');
    const builds = mock.calls.filter(c => c.op === 'document-conf').length;
    await runs.run();
    assert.match(el('run-message').textContent, /admitted/);
    const limited = mock.records.get(docs.active('property').runIds[0]);
    assert.equal(limited.request.config['attempts-max'], 40);
    assert.equal(limited.request.config['on-timeout'], 'fail');
    assert.deepEqual(limited.request.config.bounds, {...mock.config.bounds, 'trace-steps': 7});
    assert.equal(limited.request.config['drops-max'], undefined, 'blank keeps the document');
    assert.equal(mock.calls.filter(c => c.op === 'document-conf').length, builds + 1);
    field('attemptsMax',''); field('onTimeout',''); field('bound-trace-steps','');
    // A revision is a number, a date or a label.
    field('revision','~2026.11.25'); await runs.run();
    assert.deepEqual(mock.records.get(docs.active('property').runIds[0]).request.revision,
      {kind:'da',value:'~2026.11.25'});
    field('revision','release-1'); await runs.run();
    assert.deepEqual(mock.records.get(docs.active('property').runIds[0]).request.revision,
      {kind:'tas',value:'release-1'});
    field('revision','~2026.13'); await runs.run();
    assert.match(el('run-message').textContent, /a date such as/);
    field('revision','20');
    // Delete asks in the page first; Keep leaves the record.
    const settle = async () => { for (let i = 0; i < 20; i++) await env.tick(); };
    const pick = async (runId) => {
      const row = env.descendants(el('run-history')).find(n => n.dataset?.runId === runId);
      row.listeners.click(); await settle();
    };
    docs.select('property', tab.id); await pick(id);
    assert.equal(el('run-delete').disabled, false);
    el('run-delete').listeners.click();
    assert.equal(el('run-confirm').hidden, false);
    assert.match(el('run-confirm-text').textContent, new RegExp(`Delete run ${id}`));
    el('run-confirm-no').listeners.click();
    assert.equal(el('run-confirm').hidden, true);
    assert(mock.records.has(id));
    el('run-delete').listeners.click(); el('run-confirm-yes').listeners.click();
    await settle();
    assert(!mock.records.has(id));
    assert.match(el('run-message').textContent, new RegExp(`Run ${id} deleted`));
    assert(!tab.runIds.includes(id), 'tabs forget a deleted run');
    await pick(replayId);
    assert.match(env.descendants(el('run-detail')).map(n=>n.textContent).join(' '),
      /record deleted or no longer retained/);
    // Clear keeps unfinished runs.
    mock.records.get(original).status = 'running';
    await runs.refresh();
    el('runs-clear').listeners.click(); el('run-confirm-yes').listeners.click();
    await settle();
    assert(mock.records.has(original));
    assert([...mock.records.values()].every(rec => rec.status !== 'done'));
    assert.match(el('run-message').textContent, /Completed history cleared/);
  }
  runtime.session.save();
  const saved = JSON.parse(env.saved.get('quiz.session'));
  // The runs scenario deleted `id`; a deleted run is not restored.
  assert.equal(saved.propertyTabs.some(t=>t.runIds?.includes(id)), name === 'run-errors');
  const cleaned = env.window.quizRunFields({runSettings:{desk:'../bad',revision:'0',seed:'<script>',requested:'NaN',sizeStart:'0',sizeMax:'-1',duplicates:'never',arms:'<script>'},runIds:['1',1,'../2','1']});
  assert.deepEqual(cleaned.runIds,['1']);
  assert.equal(cleaned.runSettings.desk,'');
  assert.equal(cleaned.runSettings.requested,'');
  assert.equal(cleaned.runSettings.sizeStart,'');
  assert.equal(cleaned.runSettings.sizeMax,'');
  assert.equal(cleaned.runSettings.duplicates,'');
  const more = env.window.quizRunFields({runSettings:{revision:'~2026.11.25..12.00.00',
    attemptsMax:'5',onTimeout:'discard','bound-trace-steps':'0',dropsMax:'-1',
    'bound-sample-bytes':'x'}});
  assert.equal(more.runSettings.revision,'~2026.11.25..12.00.00');
  assert.equal(more.runSettings.attemptsMax,'5');
  assert.equal(more.runSettings.onTimeout,'discard');
  assert.equal(more.runSettings['bound-trace-steps'],'0');
  assert.equal(more.runSettings.dropsMax,'');
  assert.equal(more.runSettings['bound-sample-bytes'],'');
  runs.stop();
}
module.exports={mockApi,scenario};
