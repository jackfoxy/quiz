/* Quiz-only execution UI. Server records are the sole source of progress. */
(() => {
  'use strict';
  const idPattern = /^[1-9][0-9]*$/;
  const deskPattern = /^[a-z][a-z0-9-]*$/;
  const seedPattern = /^0v[0-9a-v]+(?:\.[0-9a-v]+)*$/;
  const modes = ['draft', 'file', 'suite'];
  const cleanFields = (saved = {}) => {
    const value = saved.runSettings || {};
    const bounded = (key, pattern, max) => typeof value[key] === 'string'
      && value[key].length <= max && pattern.test(value[key]) ? value[key] : '';
    return {
      runSettings: {
        mode: modes.includes(value.mode) ? value.mode : 'draft',
        desk: bounded('desk', deskPattern, 64),
        revision: bounded('revision', idPattern, 40),
        requested: bounded('requested', /^(0|[1-9][0-9]*)$/, 10),
        seed: bounded('seed', seedPattern, 256),
        arms: typeof value.arms === 'string' && value.arms.length <= 6400
          && /^[a-z0-9,\s-]*$/.test(value.arms) ? value.arms : ''
      },
      runIds: Array.isArray(saved.runIds)
        ? [...new Set(saved.runIds.filter((id) => typeof id === 'string'
          && id.length <= 40 && idPattern.test(id)))].slice(0, 100) : []
    };
  };
  window.quizRunFields = cleanFields;
  window.createQuizRuns = ({runtime, post, getContexts, getDefaults,
    selection, select, pollDelay = 1000}) => {
    const docs = runtime.documents;
    const el = (id) => document.getElementById(id);
    const node = (tag, id, text) => {
      const item = document.createElement(tag);
      if (id) item.id = id;
      if (text !== undefined) item.textContent = text;
      return item;
    };
    const button = (id, text, action) => {
      const item = node('button', id, text); item.type = 'button';
      item.addEventListener('click', () => { void action(); }); return item;
    };
    const controls = el('run-controls');
    const fields = {};
    const addField = (key, label, tag = 'input') => {
      const wrap = node('label', '', label);
      const input = node(tag, `run-${key}`);
      if (tag === 'input') input.type = 'text';
      wrap.append(input); controls.append(wrap); fields[key] = input;
      input.addEventListener('change', saveControls);
      if (tag === 'input') input.addEventListener('input', saveControls);
      return input;
    };
    const mode = addField('mode', 'Source to run', 'select');
    for (const [value, label] of [['draft', 'Draft property (editor buffer)'],
      ['file', 'Saved property (selected revision)'], ['suite', 'Saved suite (selected revision)']]) {
      const option = node('option', '', label); option.value = value; mode.append(option);
    }
    addField('desk', 'Dependency / source desk', 'select');
    addField('revision', 'Pinned revision').inputMode = 'numeric';
    addField('requested', 'Requested checks (blank = document conf)').inputMode = 'numeric';
    addField('seed', 'Seed (blank = document conf / new seed)').placeholder = '0v123';
    addField('arms', 'Suite arms (comma separated; blank = all)');
    const contextButton = button('run-latest', 'Use latest revision', latest);
    const inspectButton = button('run-inspect', 'Read document conf', inspect);
    const discoverButton = button('run-discover', 'Discover suite arms', discover);
    const runButton = button('run-start', 'Run draft property', run);
    const note = node('p', 'run-source-note');
    const settingsNote = node('p', 'run-settings-note');
    const message = node('p', 'run-message'); message.setAttribute('role', 'status');
    const toolbar = node('div', 'run-toolbar');
    toolbar.append(runButton, contextButton, inspectButton, discoverButton);
    controls.append(toolbar, note, settingsNote, message);
    const results = el('quiz-runs');
    const actions = node('div', 'result-actions');
    const refreshButton = button('runs-refresh', 'Refresh history', () => refresh());
    const cancelButton = button('run-cancel', 'Cancel selected run', cancel);
    const rerunButton = button('run-rerun', 'Rerun request', rerun);
    const replayButton = button('run-replay', 'Replay exact property', replay);
    actions.append(refreshButton, cancelButton, rerunButton, replayButton);
    const connection = node('p', 'runs-connection'); connection.setAttribute('role', 'status');
    const history = node('div', 'run-history'); history.setAttribute('aria-label', 'Run history');
    const detail = node('article', 'run-detail');
    results.append(actions, connection, history, detail);
    const records = new Map();
    let ids = [];
    let busy = false;
    let online = false;
    let refreshing = null;
    let timer;
    let stopped = false;
    let currentTab = null;
    let inspecting = 0;
    let detailKey = '';
    let historyKey = '';
    const active = () => docs.active('property');
    const tell = (text) => { message.textContent = text; };
    const linked = (id) => docs.list('property').find((tab) => tab.runIds?.includes(id));
    function clearInspection() {
      ++inspecting; settingsNote.textContent = '';
      fields.requested.placeholder = 'Document conf';
      fields.seed.placeholder = 'Document conf / new seed';
    }
    function pathFor(tab) {
      const path = tab?.path;
      if (!path || path.at(-1) !== 'hoon') return null;
      if (path[0] === 'work') return ['data', 'quiz', ...path.slice(1)];
      if (path[0] === 'examples') return ['tests', 'examples', ...path.slice(1)];
      if (path[0] === 'clay') return path.slice(3);
      return null;
    }
    function settings(tab) {
      if (!tab.runSettings) Object.assign(tab, cleanFields());
      const value = tab.runSettings;
      if (!value.desk) {
        const clay = tab.path?.[0] === 'clay';
        const context = getContexts().find((item) => item.desk === 'quiz');
        value.desk = clay ? tab.path[1] : context?.desk || '';
        value.revision = clay ? tab.path[2] : context?.revision || '';
        if (tab.path?.[0] === 'examples') value.mode = 'suite';
        else if (clay) value.mode = tab.path[3] === 'tests' ? 'suite' : 'file';
      }
      return value;
    }
    function saveControls() {
      const tab = active(); if (!tab) return;
      const value = settings(tab);
      for (const [key, input] of Object.entries(fields)) value[key] = input.value;
      clearInspection();
      runtime.session.queue(); updateButtons();
    }
    function activate(tab) {
      if (!tab) return;
      const value = settings(tab);
      fields.desk.replaceChildren();
      const choices = [...new Set([...getContexts().map((item) => item.desk), value.desk])].filter(Boolean);
      for (const name of choices) {
        const option = node('option', '', `%${name}`); option.value = name; fields.desk.append(option);
      }
      for (const [key, input] of Object.entries(fields)) input.value = value[key];
      if (currentTab !== tab.id) {
        const restoredSelection = currentTab === null && selection();
        currentTab = tab.id; clearInspection(); tell('');
        if (!restoredSelection && tab.runIds?.length) select(tab.runIds[0]);
      }
      updateButtons(); renderDetail();
    }
    function updateButtons() {
      const tab = active(); const value = tab ? settings(tab) : {};
      const suite = value.mode === 'suite';
      fields.requested.disabled = suite; fields.seed.disabled = suite;
      fields.arms.disabled = !suite;
      inspectButton.disabled = busy || suite || !online;
      discoverButton.disabled = busy || !suite || !pathFor(tab) || !online;
      runButton.disabled = busy || !online || !tab
        || (tab.path?.at(-1) === 'md') || (value.mode !== 'draft' && !pathFor(tab));
      contextButton.disabled = busy;
      runButton.textContent = {draft: 'Run draft property', file: 'Run saved property', suite: 'Run saved suite'}[value.mode] || 'Run';
      note.textContent = value.mode === 'draft'
        ? 'Runs the editor buffer; imports come from the pinned context.'
        : `Runs ${pathFor(tab)?.join('/') || 'a saved Hoon file'} at the selected desk and revision. Editor edits are not included.`;
      const rec = records.get(selection());
      const done = rec?.status === 'done';
      cancelButton.disabled = busy || !online || !rec || done || rec.status === 'cancelling';
      rerunButton.disabled = busy || !online || !rec || !done;
      replayButton.disabled = busy || !online || !done || rec?.kind === 'suite'
        || !rec?.snapshot || !rec?.config || !rec?.seed;
    }
    function requestFor(tab) {
      const value = {...settings(tab)};
      if (!deskPattern.test(value.desk) || value.desk.length > 64
        || !idPattern.test(value.revision) || value.revision.length > 40) {
        throw new Error('Choose a desk and a positive pinned revision.');
      }
      if (tab.path?.at(-1) === 'md') throw new Error('Open a Hoon document to run.');
      const path = pathFor(tab);
      if (value.mode !== 'draft' && !path) throw new Error('Save or open a Hoon file first.');
      const arms = value.arms.trim() ? value.arms.trim().split(/[\s,]+/).filter(Boolean) : [];
      if (arms.length > 100 || arms.some((arm) => !deskPattern.test(arm) || arm.length > 64)) {
        throw new Error('Use at most 100 exact suite arm names.');
      }
      if (value.mode !== 'suite' && value.seed && !seedPattern.test(value.seed)) {
        throw new Error('Use a Hoon @uv seed such as 0v123, or leave it blank.');
      }
      const source = value.mode === 'draft' ? {kind: 'draft', text: tab.text}
        : {kind: value.mode, path, ...(value.mode === 'suite' ? {arms: [...new Set(arms)]} : {})};
      return {op: 'run', source, desk: value.desk,
        revision: {kind: 'ud', value: value.revision},
        seed: value.mode === 'suite' ? null : value.seed || null};
    }
    async function latest() {
      const tab = active(); if (!tab) return;
      const desk = settings(tab).desk;
      const generation = ++inspecting;
      try {
        const result = await post('/apps/quiz/api', {op: 'contexts'});
        if (generation !== inspecting || active()?.id !== tab.id) return;
        const value = settings(tab);
        const ctx = result.contexts.find((item) => item.desk === desk);
        if (!ctx) throw new Error('That desk is unavailable.');
        value.revision = ctx.revision; activate(tab); runtime.session.queue();
        tell(`Selected %${ctx.desk} revision ${ctx.revision}.`);
      } catch (error) { if (generation === inspecting) tell(error.message); }
    }
    async function inspect() {
      const tab = active(); if (!tab) return;
      const generation = ++inspecting;
      try {
        const request = requestFor(tab);
        const result = await post('/apps/quiz/api', {...request, op: 'document-conf'});
        if (generation !== inspecting || active()?.id !== tab.id) return;
        fields.requested.placeholder = String(result.config.requested);
        fields.seed.placeholder = result.seed || 'New recorded seed';
        settingsNote.textContent = `Document conf: ${result.config.requested} checks; seed ${result.seed || 'chosen for each run'}. Other budgets are preserved when overriding requested checks.`;
      } catch (error) { if (generation === inspecting) tell(errorText(error)); }
    }
    async function discover() {
      const tab = active(); if (!tab) return;
      const generation = ++inspecting;
      try {
        const req = requestFor(tab);
        const result = await post('/apps/quiz/api', {op: 'suite-arms',
          desk: req.desk, revision: req.revision, path: req.source.path});
        if (generation !== inspecting || active()?.id !== tab.id) return;
        settingsNote.textContent = result.arms.length
          ? `Available arms: ${result.arms.join(', ')}` : 'No test arms found.';
      } catch (error) { if (generation === inspecting) tell(errorText(error)); }
    }
    function errorText(error) {
      const d = error.diagnostic;
      return d ? `${d.code} at ${d.path?.join('/') || 'document'}:${d.line}:${d.column}\n${(d.trace || []).join('\n')}`
        : String(error.message || error);
    }
    async function mutate(command, tabId) {
      const response = await post('/apps/quiz/api', command);
      if (typeof response.id !== 'string' || !idPattern.test(response.id)) {
        throw new Error('Admission was not correlated to a run. Refresh history before retrying.');
      }
      const tab = docs.get('property', tabId);
      if (tab) {
        tab.runIds = [response.id, ...(tab.runIds || []).filter((id) => id !== response.id)].slice(0, 100);
      }
      select(response.id); runtime.session.save();
      tell(`Run ${response.id} admitted.`);
      await refresh();
    }
    async function action(work) {
      if (busy) return;
      busy = true; updateButtons(); tell('Submitting…');
      try { await work(); }
      catch (error) {
        tell(`${errorText(error)}${error.uncertain ? '\nThe request may have been accepted. Refresh history before retrying; nothing was retried automatically.' : ''}`);
      } finally { busy = false; updateButtons(); }
    }
    async function run() {
      const tab = active(); if (!tab) return;
      // Capture source and controls before the first await, even if tabs change.
      let req, requested;
      try { req = requestFor(tab); requested = settings(tab).requested; }
      catch (error) { tell(error.message); return; }
      await action(async () => {
        if (req.source.kind !== 'suite' && requested !== '') {
          const maximum = getDefaults()?.bounds?.['requested-max'];
          if (!/^(0|[1-9][0-9]*)$/.test(requested) || !Number.isSafeInteger(Number(requested))
            || maximum === undefined || Number(requested) > maximum) {
            throw new Error(`Requested checks must be between 0 and ${maximum ?? 'the engine ceiling'}.`);
          }
          const conf = await post('/apps/quiz/api', {...req, op: 'document-conf'});
          req.config = {...conf.config, requested: Number(requested)};
        }
        await mutate(req, tab.id);
      });
    }
    async function cancel() {
      const id = selection(); const rec = records.get(id);
      if (!rec || rec.status === 'done') return;
      await action(async () => {
        await post('/apps/quiz/api', {op: 'cancel', id});
        tell(`Cancellation requested for ${id}; awaiting server confirmation.`);
        await refresh();
      });
    }
    async function rerun() {
      const rec = records.get(selection()); if (!rec) return;
      const owner = linked(rec.id);
      await action(() => mutate({op: 'run', source: rec.request.source,
        desk: rec.request.desk, revision: rec.request.revision,
        config: rec.request.config, seed: rec.request.seed}, owner?.id));
    }
    async function replay() {
      const rec = records.get(selection()); if (!rec || rec.kind === 'suite') return;
      const owner = linked(rec.id);
      await action(() => mutate({op: 'replay', id: rec.id}, owner?.id));
    }
    const line = (parent, label, value) => {
      const row = node('p'); const title = node('strong', '', `${label}: `);
      row.append(title, node('span', '', value == null ? 'Unavailable' : String(value))); parent.append(row);
    };
    const block = (parent, id, label, text) => {
      parent.append(node('h3', '', label), node('pre', id, String(text ?? 'Unavailable')));
    };
    function renderDetail() {
      const id = selection(); const rec = records.get(id);
      const tab = linked(id);
      const key = JSON.stringify([id, rec, tab?.id, tab?.label, tab?.text]);
      if (key === detailKey) { updateButtons(); return; }
      detailKey = key;
      detail.replaceChildren();
      if (!rec) {
        detail.append(node('p', 'run-empty', id
          ? 'Selected run is unavailable or no longer retained. Refresh history.'
          : 'No run selected. Run a property or a saved suite to see results.'));
        updateButtons(); return;
      }
      const title = node('h2', 'run-result-status', `Run ${rec.id}: ${rec.outcome?.kind === 'suite'
        ? rec.outcome.status : rec.outcome?.kind || rec.status}`);
      detail.append(title);
      const snapshot = rec.snapshot;
      const stale = Boolean(tab && snapshot && tab.text !== snapshot.source);
      detail.append(node('p', 'run-stale', stale
        ? 'Stale: the source tab differs from this run’s snapshot.'
        : !tab ? 'Source tab is closed or not linked in this browser.'
          : !snapshot ? (rec.status === 'done' ? 'No source snapshot is available for this run.'
            : 'Waiting for the server source snapshot.') : 'Source tab matches this snapshot.'));
      if (tab) detail.append(button('run-source-tab', `Source tab: ${tab.label}`,
        () => docs.select('property', tab.id)));
      line(detail, 'Server status', rec.status);
      line(detail, 'Workflow', rec.kind === 'draft' ? 'Draft property' : rec.kind === 'suite' ? 'Saved suite' : 'Saved property');
      if (snapshot) {
        line(detail, 'Context', `%${snapshot.context.desk} revision ${snapshot.context.revision}`);
        line(detail, 'Source hash', snapshot['source-hash']);
        line(detail, 'Source path', snapshot.path.join('/'));
      }
      line(detail, 'Engine version', rec['engine-version']);
      line(detail, 'Replay of', rec['replay-of'] || 'None');
      line(detail, 'Seed', rec.kind === 'suite' ? 'Unavailable for suites' : rec.seed);
      if (rec.config) block(detail, 'run-config', 'Effective configuration', JSON.stringify(rec.config, null, 2));
      if (rec['sample-metrics'] === 'unavailable') {
        detail.append(node('p', 'run-unavailable', 'Property sample counts, controlled seed and counterexamples are unavailable for suites.'));
      }
      block(detail, 'run-counts', 'Confirmed counters', JSON.stringify(rec.counts, null, 2));
      const outcome = rec.outcome;
      if (outcome?.kind === 'passed') line(detail, 'Meaning', 'Requested checks passed; this is not a proof.');
      if (outcome?.kind === 'cancelled') line(detail, 'Cancellation reason', outcome.reason);
      if (outcome?.kind === 'limited') line(detail, 'Limit', outcome.which);
      if (outcome?.kind === 'exhausted') {
        line(detail, 'Exhausted budget', outcome.budget);
        line(detail, 'All dropped', outcome['all-dropped']);
      }
      if (outcome?.diagnostic) block(detail, 'run-diagnostic', 'Diagnostic', JSON.stringify(outcome.diagnostic, null, 2));
      if (outcome?.stage) line(detail, 'Error stage', outcome.stage);
      const proof = outcome?.evidence;
      if (proof) {
        block(detail, 'run-original', 'Original counterexample', proof.original.text);
        block(detail, 'run-shrunk', 'Shrunk counterexample', proof.shrunk.text);
        block(detail, 'run-failure', 'Failure', JSON.stringify(proof.why, null, 2));
      } else if (outcome?.why) block(detail, 'run-failure', 'Failure', JSON.stringify(outcome.why, null, 2));
      if (outcome?.arms) {
        const list = node('ul', 'run-suite-arms');
        for (const arm of outcome.arms) {
          const item = node('li', '', `${arm.name}: ${arm.status}${arm.clipped ? ' (diagnostic clipped)' : ''}`);
          if (arm.trace?.length) item.append(node('pre', '', arm.trace.join('\n')));
          list.append(item);
        }
        detail.append(list);
      }
      if (snapshot) {
        const source = node('details', 'run-snapshot');
        source.append(node('summary', '', 'Exact source snapshot'), node('pre', '', snapshot.source));
        detail.append(source);
      }
      updateButtons();
    }
    function render() {
      const key = JSON.stringify([selection(), ids.map((id) => {
        const rec = records.get(id);
        return [id, rec?.kind, rec?.outcome?.status, rec?.outcome?.kind, rec?.status];
      })]);
      if (key === historyKey) { renderDetail(); return; }
      historyKey = key;
      history.replaceChildren();
      if (!ids.length) history.append(node('p', 'history-empty', 'History is empty.'));
      for (const id of ids) {
        const rec = records.get(id);
        const item = button('', `#${id} ${rec?.kind || ''} — ${rec?.outcome?.status || rec?.outcome?.kind || rec?.status || 'loading'}`,
          () => { select(id); runtime.session.queue(); render(); });
        item.dataset.runId = id; item.setAttribute('aria-pressed', String(selection() === id)); history.append(item);
      }
      renderDetail();
    }
    function schedule() {
      clearTimeout(timer);
      if (!stopped && !window.__URUI_DOUBLES_TEST__) timer = setTimeout(() => { void refresh(); }, online ? pollDelay : 5000);
    }
    async function refresh() {
      if (refreshing) return refreshing;
      refreshing = (async () => {
        try {
          const result = await post('/apps/quiz/api', {op: 'runs'});
          ids = result.ids;
          for (const id of [...records.keys()]) if (!ids.includes(id)) records.delete(id);
          // Completed records are immutable. Limit concurrency for active/new records.
          const needed = ids.filter((id) => !records.has(id) || records.get(id).status !== 'done');
          for (let i = 0; i < needed.length; i += 4) {
            await Promise.all(needed.slice(i, i + 4).map(async (id) => {
              try { records.set(id, await post('/apps/quiz/api', {op: 'status', id})); }
              catch (error) { if (error.status !== 404) throw error; records.delete(id); }
            }));
          }
          online = true; connection.textContent = 'Connected — showing confirmed server records.';
          render();
        } catch (error) {
          online = false;
          connection.textContent = `Connection unavailable. Last confirmed results are unchanged. ${error.message}`;
          updateButtons();
        } finally { refreshing = null; schedule(); }
      })();
      return refreshing;
    }
    window.addEventListener('pagehide', () => { stopped = true; clearTimeout(timer); });
    window.addEventListener('pageshow', () => { if (stopped) { stopped = false; void refresh(); } });
    function changed() {
      clearInspection();
      renderDetail();
    }
    return {activate, changed, refresh, run, cancel, rerun, replay,
      inspect, discover, pathFor, requestFor, records,
      start: async () => { activate(active()); await refresh(); },
      stop: () => { stopped = true; clearTimeout(timer); }};
  };
})();
