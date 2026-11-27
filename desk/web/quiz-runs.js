/* Quiz-only execution UI. Server records are the sole source of progress. */
(() => {
  'use strict';
  const idPattern = /^[1-9][0-9]*$/;
  const deskPattern = /^[a-z][a-z0-9-]*$/;
  const seedPattern = /^0v[0-9a-v]+(?:\.[0-9a-v]+)*$/;
  const modes = ['draft', 'file', 'suite'];
  const policies = ['mug', 'exact', 'allow'];
  const previewShows = ['all', 'alts', 'verdicts', 'samples'];
  const timeoutPolicies = ['interrupt', 'fail', 'discard'];
  // Every limit of a conf's bounds; a bounds override sends all twelve.
  const boundKeys = ['source-bytes', 'requested-max', 'shrink-candidates',
    'shrink-depth', 'sample-bytes', 'rendered-bytes', 'diagnostics-bytes',
    'alts-bytes', 'seen-bytes', 'retained-runs', 'samples-per-slice', 'trace-steps'];
  // Optional whole-number overrides of the document's conf, by run field.
  const budgetKeys = {attemptsMax: 'attempts-max', dropsMax: 'drops-max',
    duplicatesMax: 'duplicates-max'};
  const wholeText = /^(0|[1-9][0-9]*)$/;
  // A revision is a number, a date (~2026.11.25 or with ..hh.mm.ss) or a label.
  const datePattern = /^~[1-9][0-9]*\.[1-9][0-9]?\.[1-9][0-9]?(\.\.[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2})?$/;
  const caseOf = (text) => idPattern.test(text) ? {kind: 'ud', value: text}
    : datePattern.test(text) ? {kind: 'da', value: text}
      : deskPattern.test(text) ? {kind: 'tas', value: text} : null;
  const cleanFields = (saved = {}) => {
    const value = saved.runSettings || {};
    const bounded = (key, pattern, max) => typeof value[key] === 'string'
      && value[key].length <= max && pattern.test(value[key]) ? value[key] : '';
    return {
      runSettings: {
        mode: modes.includes(value.mode) ? value.mode : 'draft',
        desk: bounded('desk', deskPattern, 64),
        revision: typeof value.revision === 'string' && value.revision.length <= 40
          && caseOf(value.revision) ? value.revision : '',
        requested: bounded('requested', /^(0|[1-9][0-9]*)$/, 10),
        sizeStart: bounded('sizeStart', /^[1-9][0-9]*$/, 10),
        sizeMax: bounded('sizeMax', /^(0|[1-9][0-9]*)$/, 10),
        duplicates: policies.includes(value.duplicates) ? value.duplicates : '',
        ...Object.fromEntries(Object.keys(budgetKeys).map((key) =>
          [key, bounded(key, wholeText, 10)])),
        onTimeout: timeoutPolicies.includes(value.onTimeout) ? value.onTimeout : '',
        ...Object.fromEntries(boundKeys.map((key) =>
          [`bound-${key}`, bounded(`bound-${key}`, wholeText, 12)])),
        seed: bounded('seed', seedPattern, 256),
        arms: typeof value.arms === 'string' && value.arms.length <= 6400
          && /^[a-z0-9,\s-]*$/.test(value.arms) ? value.arms : '',
        previewCount: bounded('previewCount', /^[1-9][0-9]*$/, 4),
        previewShow: previewShows.includes(value.previewShow) ? value.previewShow : 'all',
        examplesCount: bounded('examplesCount', /^[1-9][0-9]*$/, 5)
      },
      runIds: Array.isArray(saved.runIds)
        ? [...new Set(saved.runIds.filter((id) => typeof id === 'string'
          && id.length <= 40 && idPattern.test(id)))].slice(0, 100) : []
    };
  };
  window.quizRunFields = cleanFields;
  window.createQuizRuns = ({runtime, post, getContexts, getDefaults,
    selection, select, pollDelay = 1000, idleDelay = 30000}) => {
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
    const addField = (key, label, tag = 'input', parent = controls) => {
      const wrap = node('label', '', label);
      const input = node(tag, `run-${key}`);
      if (tag === 'input') input.type = 'text';
      wrap.append(input); parent.append(wrap); fields[key] = input;
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
    addField('revision', 'Pinned revision (number, ~date or label)');
    addField('requested', 'Requested checks (blank = document conf)').inputMode = 'numeric';
    addField('seed', 'Seed (blank = document conf / new seed)').placeholder = '0v123';
    addField('sizeStart', 'First sample size (blank = document conf)').inputMode = 'numeric';
    addField('sizeMax', 'Largest sample size (blank = document conf; 0 = no cap)').inputMode = 'numeric';
    const dups = addField('duplicates', 'Repeated samples', 'select');
    for (const [value, label] of [['', 'Document conf'], ['mug', 'Skip a repeated mug'],
      ['exact', 'Skip only an equal sample'], ['allow', 'Evaluate every sample']]) {
      const option = node('option', '', label); option.value = value; dups.append(option);
    }
    // Budgets, timeout policy and bounds, folded away; blank keeps the
    // document's value. Setting any bound sends the document's other bounds.
    const more = node('details', 'run-more');
    more.append(node('summary', '', 'More limits (blank = document conf)'));
    controls.append(more);
    addField('attemptsMax', 'Attempts budget', 'input', more).inputMode = 'numeric';
    addField('dropsMax', 'Drops budget', 'input', more).inputMode = 'numeric';
    addField('duplicatesMax', 'Duplicates budget', 'input', more).inputMode = 'numeric';
    const onTimeout = addField('onTimeout', 'On timeout', 'select', more);
    const timeoutDefault = node('option', '', 'Document conf'); timeoutDefault.value = '';
    onTimeout.append(timeoutDefault);
    for (const [value, label] of [['interrupt', 'Interrupt the run'],
      ['fail', 'Fail with the sample'], ['discard', 'Discard the sample']]) {
      const option = node('option', '', label); option.value = value; onTimeout.append(option);
    }
    for (const key of boundKeys) {
      addField(`bound-${key}`, `Bound: ${key}`, 'input', more).inputMode = 'numeric';
    }
    addField('arms', 'Suite arms (comma separated; blank = all)');
    addField('previewCount', 'Preview samples (1-1000, blank = 20; first 100 listed)').inputMode = 'numeric';
    const shows = addField('previewShow', 'Preview shows', 'select');
    for (const [value, label] of [['all', 'Samples, verdicts and shrink candidates'],
      ['alts', 'Samples and shrink candidates'],
      ['verdicts', 'Samples and verdicts'], ['samples', 'Samples only']]) {
      const option = node('option', '', label); option.value = value; shows.append(option);
    }
    addField('examplesCount', 'Find examples over passing samples (blank = 100)').inputMode = 'numeric';
    const contextButton = button('run-latest', 'Use latest revision', latest);
    const inspectButton = button('run-inspect', 'Read document conf', inspect);
    const discoverButton = button('run-discover', 'Discover suite arms', discover);
    const runButton = button('run-start', 'Run draft property', run);
    const previewButton = button('run-preview', 'Preview samples', preview);
    const examplesButton = button('run-find-examples', 'Find examples for each label', findExamples);
    const note = node('p', 'run-source-note');
    const settingsNote = node('p', 'run-settings-note');
    const message = node('p', 'run-message'); message.setAttribute('role', 'status');
    const toolbar = node('div', 'run-toolbar');
    toolbar.append(runButton, previewButton, examplesButton, contextButton, inspectButton, discoverButton);
    controls.append(toolbar, note, settingsNote, message);
    const results = el('quiz-runs');
    const actions = node('div', 'result-actions');
    const refreshButton = button('runs-refresh', 'Refresh history', () => refresh());
    const cancelButton = button('run-cancel', 'Cancel selected run', cancel);
    const rerunButton = button('run-rerun', 'Rerun request', rerun);
    const replayButton = button('run-replay', 'Replay exact property', replay);
    const regressionButton = button('run-save-regression', 'Save as regression', saveRegression);
    const deleteButton = button('run-delete', 'Delete record', () => confirmThen(
      `Delete run ${selection()}? Its record cannot be recovered.`, remove));
    const clearButton = button('runs-clear', 'Clear completed history', () => confirmThen(
      'Delete every completed run? Queued and active runs are kept.', clear));
    actions.append(refreshButton, cancelButton, rerunButton, replayButton,
      regressionButton, deleteButton, clearButton);
    // Deletion is confirmed in the page; browser dialogs are not used.
    const confirmBar = node('div', 'run-confirm'); confirmBar.hidden = true;
    confirmBar.setAttribute('role', 'alertdialog');
    const confirmText = node('p', 'run-confirm-text');
    const confirmYes = button('run-confirm-yes', 'Delete', () => {
      const work = confirmed; closeConfirm(); return work ? work() : undefined;
    });
    const confirmNo = button('run-confirm-no', 'Keep', () => closeConfirm());
    confirmBar.append(confirmText, confirmYes, confirmNo);
    actions.append(confirmBar);
    let confirmed = null;
    function confirmThen(text, work) {
      confirmed = work; confirmText.textContent = text; confirmBar.hidden = false;
      confirmNo.focus?.();
    }
    function closeConfirm() { confirmed = null; confirmBar.hidden = true; }
    const connection = node('p', 'runs-connection'); connection.setAttribute('role', 'status');
    const history = node('div', 'run-history'); history.setAttribute('aria-label', 'Run history');
    const detail = node('article', 'run-detail');
    results.append(actions, connection, history, detail);
    const records = new Map();
    // History rows from `runs`; whole records are fetched only when selected.
    let summaries = new Map();
    let ids = [];
    let busy = false;
    let online = false;
    let refreshing = null;
    let timer;
    let stopped = false;
    let currentTab = null;
    // Latest, inspect and discover each keep their own sequence: a reply
    // applies only while it is the newest of its kind, its tab is active and
    // its inputs still match. Explorer and editor changes do not void it.
    const asked = {latest: 0, inspect: 0, discover: 0};
    let inspected = null;
    let shown = {};
    let staleNote = null;
    let historyKey = '';
    const active = () => docs.active('property');
    const tell = (text) => { message.textContent = text; };
    const linked = (id) => docs.list('property').find((tab) => tab.runIds?.includes(id));
    function clearInspection() {
      inspected = null; settingsNote.textContent = '';
      fields.requested.placeholder = 'Document conf';
      fields.sizeStart.placeholder = 'Document conf';
      fields.sizeMax.placeholder = 'Document conf';
      fields.seed.placeholder = 'Document conf / new seed';
      timeoutDefault.textContent = 'Document conf';
      for (const key of [...Object.keys(budgetKeys), ...boundKeys.map((k) => `bound-${k}`)]) {
        fields[key].placeholder = 'Document conf';
      }
    }
    function pathFor(tab) {
      const path = tab?.path;
      if (!path || path.at(-1) !== 'hoon') return null;
      if (path[0] === 'clay') return path.slice(3);
      return null;
    }
    function settings(tab) {
      if (!tab.runSettings) Object.assign(tab, cleanFields());
      const value = tab.runSettings;
      if (!value.desk) {
        const clay = tab.path?.[0] === 'clay';
        value.desk = clay ? tab.path[1] : 'quiz';
        // A path at now runs at the desk's head: a run is always pinned.
        const head = getContexts().find((item) => item.desk === value.desk)?.revision || '';
        value.revision = clay && tab.path[2] !== 'now' ? tab.path[2] : head;
        // ++fate makes a property, else a ++test- arm a suite, as the
        // index's roles fall out for the files it lets open.
        if (clay) {
          const text = tab.text || '';
          value.mode = !/^\+\+  fate(\s|$)/m.test(text)
            && (/^\+\+  test-/m.test(text) || tab.path[3] === 'tests') ? 'suite' : 'file';
        }
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
        if (!restoredSelection && tab.runIds?.length) {
          select(tab.runIds[0]);
          if (!records.has(tab.runIds[0])) void refresh();
        }
      }
      updateButtons(); renderDetail();
    }
    function updateButtons() {
      const tab = active(); const value = tab ? settings(tab) : {};
      const suite = value.mode === 'suite';
      for (const key of ['requested', 'seed', 'sizeStart', 'sizeMax', 'duplicates', 'onTimeout',
        ...Object.keys(budgetKeys), ...boundKeys.map((k) => `bound-${k}`)]) fields[key].disabled = suite;
      fields.arms.disabled = !suite;
      for (const key of ['previewCount', 'previewShow', 'examplesCount']) fields[key].disabled = suite;
      inspectButton.disabled = busy || suite || !online;
      discoverButton.disabled = busy || !suite || !pathFor(tab) || !online;
      runButton.disabled = busy || !online || !tab
        || (tab.path?.at(-1) === 'md') || (value.mode !== 'draft' && !pathFor(tab));
      previewButton.disabled = runButton.disabled || suite;
      examplesButton.disabled = runButton.disabled || suite;
      contextButton.disabled = busy;
      runButton.textContent = {draft: 'Run draft property', file: 'Run saved property', suite: 'Run saved suite'}[value.mode] || 'Run';
      note.textContent = value.mode === 'draft'
        ? 'Runs the editor buffer; imports come from the pinned context.'
        : `Runs ${pathFor(tab)?.join('/') || 'a saved Hoon file'} at the selected desk and revision. Editor edits are not included.`;
      const rec = records.get(selection());
      const done = rec?.status === 'done';
      cancelButton.disabled = busy || !online || !rec || done || rec.status === 'cancelling';
      rerunButton.disabled = busy || !online || !rec || !done;
      deleteButton.disabled = busy || !online || !done;
      clearButton.disabled = busy || !online
        || !ids.some((id) => summaries.get(id)?.status === 'done');
      replayButton.disabled = busy || !online || !done || rec?.kind === 'suite'
        || ['preview', 'examples'].includes(rec?.request?.mode?.kind)
        || !rec?.snapshot || !rec?.config || !rec?.seed;
      regressionButton.disabled = busy || !online || !regressionReady(rec);
    }
    // A property run's counterexample, unless the document expects the failure.
    function regressionReady(rec) {
      return rec?.status === 'done' && rec.kind !== 'suite'
        && Boolean(rec.outcome?.evidence) && rec.outcome.kind !== 'failed-as-expected';
    }
    function requestFor(tab) {
      const value = {...settings(tab)};
      const revision = value.revision.length <= 40 ? caseOf(value.revision) : null;
      if (!deskPattern.test(value.desk) || value.desk.length > 64 || !revision) {
        throw new Error('Choose a desk and a pinned revision: a positive number, a date such as ~2026.11.25, or a label.');
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
        revision,
        seed: value.mode === 'suite' ? null : value.seed || null};
    }
    async function latest() {
      const tab = active(); if (!tab) return;
      const desk = settings(tab).desk;
      const n = ++asked.latest;
      const current = () => n === asked.latest && active()?.id === tab.id
        && settings(tab).desk === desk;
      try {
        const result = await post('/apps/quiz/api', {op: 'contexts'});
        if (!current()) return;
        const value = settings(tab);
        const ctx = result.contexts.find((item) => item.desk === desk);
        if (!ctx) throw new Error('That desk is unavailable.');
        value.revision = ctx.revision; activate(tab); runtime.session.queue();
        tell(`Selected %${ctx.desk} revision ${ctx.revision}.`);
      } catch (error) { if (current()) tell(error.message); }
    }
    async function inspect() {
      const tab = active(); if (!tab) return;
      const n = ++asked.inspect;
      let key = null;
      const current = () => n === asked.inspect && active()?.id === tab.id
        && requestKey(tab) === key;
      try {
        const request = requestFor(tab); key = JSON.stringify(request);
        const result = await post('/apps/quiz/api', {...request, op: 'document-conf'});
        if (!current()) return;
        inspected = key;
        const conf = result.config;
        fields.requested.placeholder = String(conf.requested);
        fields.seed.placeholder = result.seed || 'New recorded seed';
        fields.sizeStart.placeholder = String(conf['size-start']);
        fields.sizeMax.placeholder = String(conf['size-max']);
        for (const [key, name] of Object.entries(budgetKeys)) fields[key].placeholder = String(conf[name]);
        for (const key of boundKeys) fields[`bound-${key}`].placeholder = String(conf.bounds[key]);
        timeoutDefault.textContent = `Document conf (${conf['on-timeout']})`;
        settingsNote.textContent = `Document conf: ${conf.requested} checks; sizes from ${conf['size-start']}${conf['size-max'] ? ` up to ${conf['size-max']}` : ', uncapped'}; repeats ${conf.duplicates}; seed ${result.seed || 'chosen for each run'}. Other budgets are preserved when overriding these fields.`;
      } catch (error) { if (key === null || current()) tell(errorText(error)); }
    }
    async function discover() {
      const tab = active(); if (!tab) return;
      const n = ++asked.discover;
      let key = null;
      const current = () => n === asked.discover && active()?.id === tab.id
        && requestKey(tab) === key;
      try {
        const req = requestFor(tab); key = JSON.stringify(req);
        const result = await post('/apps/quiz/api', {op: 'suite-arms',
          desk: req.desk, revision: req.revision, path: req.source.path});
        if (!current()) return;
        inspected = key;
        settingsNote.textContent = result.arms.length
          ? `Available arms: ${result.arms.join(', ')}` : 'No test arms found.';
      } catch (error) { if (key === null || current()) tell(errorText(error)); }
    }
    function requestKey(tab) {
      try { return JSON.stringify(requestFor(tab)); } catch { return null; }
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
    function run() { return submit('run'); }
    // A preview makes samples with the run's streams and sizes, but no budgets.
    function preview() { return submit('preview'); }
    // A search runs like a run to `count` passes, then shrinks each label's
    // first sample to its smallest that still carries the label.
    function findExamples() { return submit('examples'); }
    async function submit(kind) {
      const previewing = kind === 'preview';
      const tab = active(); if (!tab) return;
      // Capture source and controls before the first await, even if tabs change.
      let req, value;
      try { req = requestFor(tab); value = {...settings(tab)}; }
      catch (error) { tell(error.message); return; }
      if (previewing) {
        const count = value.previewCount === '' ? 20 : Number(value.previewCount);
        if (!Number.isSafeInteger(count) || count < 1 || count > 1000) {
          tell('Preview between 1 and 1000 samples.'); return;
        }
        req.mode = {kind: 'preview', count,
          verdicts: ['all', 'verdicts'].includes(value.previewShow),
          alts: ['all', 'alts'].includes(value.previewShow)};
      }
      if (kind === 'examples') {
        const count = value.examplesCount === '' ? 100 : Number(value.examplesCount);
        const maximum = getDefaults()?.bounds?.['requested-max'] ?? 10000;
        if (!Number.isSafeInteger(count) || count < 1 || count > maximum) {
          tell(`Find examples over 1 to ${maximum} passing samples.`); return;
        }
        req.mode = {kind: 'examples', count};
      }
      await action(async () => {
        const {sizeStart, sizeMax, duplicates, onTimeout} = value;
        // A preview's or search's count replaces requested checks.
        const requested = kind === 'run' ? value.requested : '';
        const budgets = Object.keys(budgetKeys).filter((key) => value[key] !== '');
        const bounds = boundKeys.filter((key) => value[`bound-${key}`] !== '');
        if (req.source.kind !== 'suite' && ([requested, sizeStart, sizeMax, duplicates, onTimeout]
          .some((item) => item) || budgets.length || bounds.length)) {
          const whole = (text) => /^(0|[1-9][0-9]*)$/.test(text) && Number.isSafeInteger(Number(text));
          const maximum = getDefaults()?.bounds?.['requested-max'];
          if (requested !== '' && (!whole(requested) || maximum === undefined || Number(requested) > maximum)) {
            throw new Error(`Requested checks must be between 0 and ${maximum ?? 'the engine ceiling'}.`);
          }
          if (sizeStart !== '' && (!whole(sizeStart) || Number(sizeStart) < 1)) {
            throw new Error('The first sample size must be a whole number of at least 1.');
          }
          if (sizeMax !== '' && !whole(sizeMax)) throw new Error('The largest sample size must be a whole number; 0 means no cap.');
          // Only the changed fields: %quiz merges them into the document's conf
          // after its one build, and reports an out-of-range result as conf-range.
          const next = {};
          if (requested !== '') next.requested = Number(requested);
          if (sizeStart !== '') next['size-start'] = Number(sizeStart);
          if (sizeMax !== '') next['size-max'] = Number(sizeMax);
          if (duplicates) next.duplicates = duplicates;
          if (onTimeout) next['on-timeout'] = onTimeout;
          for (const key of budgets) {
            if (!whole(value[key])) throw new Error(`The ${budgetKeys[key]} budget must be a whole number.`);
            next[budgetKeys[key]] = Number(value[key]);
          }
          if (bounds.length) {
            for (const key of bounds) {
              if (!whole(value[`bound-${key}`])) throw new Error(`Bound ${key} must be a whole number.`);
            }
            // A bounds patch is complete: fill the rest from the document.
            const {config} = await post('/apps/quiz/api', {...req, op: 'document-conf'});
            next.bounds = {...config.bounds,
              ...Object.fromEntries(bounds.map((key) => [key, Number(value[`bound-${key}`])]))};
          }
          if (next['size-max'] && next['size-start'] && next['size-max'] < next['size-start']) {
            throw new Error(`The largest sample size (${next['size-max']}) is below the first (${next['size-start']}).`);
          }
          req.config = next;
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
        config: rec.request.config, seed: rec.request.seed,
        ...(rec.request.mode ? {mode: rec.request.mode} : {})}, owner?.id));
    }
    async function replay() {
      const rec = records.get(selection()); if (!rec || rec.kind === 'suite') return;
      const owner = linked(rec.id);
      await action(() => mutate({op: 'replay', id: rec.id}, owner?.id));
    }
    // The suite opens as an unsaved tab in Saved suite mode. Saving it
    // commits a new revision, which the tab then selects (see saved).
    async function saveRegression() {
      const rec = records.get(selection()); if (!regressionReady(rec)) return;
      await action(async () => {
        const result = await post('/apps/quiz/api', {op: 'regression', id: rec.id});
        const desk = rec.snapshot?.context?.desk || rec.request?.desk || '';
        docs.create('property', {text: result.text, clean: '', label: result.name, focus: true,
          fields: {...cleanFields({runSettings: {mode: 'suite', desk}}), regression: rec.id}});
        tell(`Regression for run ${rec.id} opened as ${result.name}. Save it, then choose Run saved suite: it fails until the bug is fixed.`);
      });
    }
    // A save lands at now, in a new revision of its desk: the tab runs
    // there next.
    function saved(tab) {
      if (tab?.path?.[0] !== 'clay' || tab.path[2] !== 'now') return;
      settings(tab).desk = tab.path[1];
      if (active()?.id === tab.id) void latest();
    }
    async function remove() {
      const id = selection(); const rec = records.get(id);
      if (!rec || rec.status !== 'done') return;
      await action(async () => {
        await post('/apps/quiz/api', {op: 'delete', id});
        await forget(); tell(`Run ${id} deleted.`);
      });
    }
    async function clear() {
      await action(async () => {
        await post('/apps/quiz/api', {op: 'clear'});
        await forget(); tell('Completed history cleared; queued and active runs are kept.');
      });
    }
    // After a deletion, tabs drop ids the server no longer holds and the
    // selection moves to the active tab's newest remaining run.
    async function forget() {
      await refresh();
      for (const tab of docs.list('property')) {
        if (tab.runIds) tab.runIds = tab.runIds.filter((id) => ids.includes(id));
      }
      if (!ids.includes(selection())) select(active()?.runIds?.[0] ?? null);
      runtime.session.save(); render();
    }
    const line = (parent, label, value) => {
      const row = node('p'); const title = node('strong', '', `${label}: `);
      row.append(title, node('span', '', value == null ? 'Unavailable' : String(value))); parent.append(row);
    };
    const block = (parent, id, label, text) => {
      parent.append(node('h3', '', label), node('pre', id, String(text ?? 'Unavailable')));
    };
    // Rows of [label, count] with their share of accepted samples.
    const shares = (parent, id, title, counts, accepted) => {
      const rows = Object.entries(counts || {}).sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1));
      if (!rows.length) return;
      parent.append(node('h3', '', title));
      const table = node('table', id);
      for (const [label, count] of rows) {
        const row = node('tr');
        const share = accepted ? `${Math.floor(count * 100 / accepted)}%` : '—';
        row.append(node('td', '', label), node('td', '', String(count)), node('td', '', share));
        table.append(row);
      }
      parent.append(table);
    };
    const coverage = (parent, id, title, rows) => {
      if (!rows?.length) return;
      const list = node('ul', id);
      for (const row of rows) list.append(node('li', '', row.table == null
        ? `${row.label}: ${row.got}% of accepted samples, required ${row.want}%`
        : `${row.table} = ${row.label}: ${row.got}% of the table's entries, required ${row.want}%`));
      parent.append(node('h3', '', title), list);
    };
    // What a generator makes, over every previewed sample: sizes, jammed
    // bytes, repeats, verdicts and labels, with a note where it looks weak.
    function previewSummary(sum, listed) {
      const box = node('section', 'run-preview-summary');
      box.append(node('h3', '', `Generator summary: ${sum.samples} samples`));
      const spread = (values) => {
        const sorted = [...values].sort((a, b) => a - b);
        return sorted.length ? `${sorted[0]} / ${sorted[Math.floor((sorted.length - 1) / 2)]} / ${sorted.at(-1)}` : '—';
      };
      const share = (n) => sum.samples ? `${Math.round(n * 100 / sum.samples)}%` : '—';
      line(box, 'Size min / median / max', spread(sum.sizes));
      line(box, 'Sample bytes min / median / max', spread(sum.bytes));
      // Jammed size in power-of-two buckets: how big the samples really are.
      const buckets = new Map();
      for (const bytes of sum.bytes) {
        let top = 1; while (top < bytes) top *= 2;
        buckets.set(top, (buckets.get(top) || 0) + 1);
      }
      const table = node('table', 'run-preview-bytes');
      for (const [top, count] of [...buckets].sort((a, b) => a[0] - b[0])) {
        const row = node('tr', '');
        row.append(node('td', '', `≤ ${top} bytes`), node('td', '', String(count)),
          node('td', '', share(count)), node('td', '', '█'.repeat(Math.ceil(count * 20 / sum.samples))));
        table.append(row);
      }
      box.append(table);
      line(box, 'Repeats a run would skip', `${sum.repeats} (${share(sum.repeats)})`);
      shares(box, 'run-preview-verdicts', 'Verdicts', sum.verdicts, sum.samples);
      shares(box, 'run-preview-labels', 'Labels (share of samples)', sum.labels, sum.samples);
      const notes = [];
      const drops = sum.verdicts?.drop || 0;
      if (drops * 2 >= sum.samples && drops) notes.push(`${share(drops)} of samples were discarded (%drop): a run tests only the rest, and may exhaust its drops budget. Generate valid inputs directly.`);
      if (sum.repeats * 2 >= sum.samples && sum.repeats) notes.push(`${share(sum.repeats)} of samples repeat an earlier one: the generator's range may be too small for the requested checks.`);
      if (!Object.keys(sum.verdicts || {}).length) notes.push('Preview with verdicts to see drops and labels.');
      if (notes.length) {
        const list = node('ul', 'run-preview-notes');
        for (const text of notes) list.append(node('li', '', text));
        box.append(list);
      }
      if (sum.samples > listed) box.append(node('p', '', `The first ${listed} samples are listed below.`));
      return box;
    }
    // What became of a shrink candidate, as a short outcome and in words.
    const fates = {
      accepted: ['still fails', () => 'Accepted: lighter, and fails the same way. It becomes the best sample.'],
      timeout: ['still fails (timeout)', () => 'Accepted: it hung under on-timeout %fail, as the best sample did.'],
      passed: ['passed', () => 'Rejected: the fate passed, so it is not a counterexample.'],
      dropped: ['dropped', () => 'Rejected: the fate dropped it (%drop, or a hang under on-timeout %discard).'],
      'other-failure': ['other failure', () => 'Rejected: it failed in a different category from the best sample.'],
      heavier: ['not lighter', (row, best) => `Skipped: weight ${row.weight} is not below the best weight${best == null ? '' : ` ${best}`} (strict-weight rule).`],
      visited: ['seen', () => 'Skipped: a candidate with the same mug was tried before.']
    };
    const isAccepted = (row) => row.why === 'accepted' || row.why === 'timeout';
    const tally = (tried) => {
      const counts = new Map();
      for (const row of tried) {
        const what = fates[row.why]?.[0] ?? row.why;
        counts.set(what, (counts.get(what) || 0) + 1);
      }
      return [...counts].map(([what, n]) => `${n} ${what}`).join(', ');
    };
    // The shrink trace as steps: one alts call on the best sample and the
    // candidates tried against it, oldest first, with why each was or was
    // not accepted. Opens on the last step: why shrinking stopped there.
    function shrinkTrace(rows) {
      const steps = [];
      for (const row of rows) {
        if (row.kind === 'alts') steps.push({best: row.best, count: row.count, tried: []});
        else {
          // The trace's oldest rows can belong to an alts call it no longer holds.
          if (!steps.length) steps.push({best: null, count: null, tried: []});
          steps.at(-1).tried.push(row);
        }
      }
      const box = node('details', 'run-shrink-trace');
      const taken = steps.filter((step) => step.tried.some(isAccepted)).length;
      box.append(node('summary', '', `Shrink trace: ${steps.length} steps, ${taken} accepted (last ${rows.length} trace rows)`),
        node('p', 'run-trace-rule', 'A candidate replaces the best sample only when it was not seen before, its weight is strictly below the best weight, and it fails in the same category. Candidates are tried in the order alts gives them; the first accepted one becomes the best sample, and alts is asked again for it.'));
      const controls = node('div', 'run-trace-controls');
      const buttons = {};
      for (const [key, label] of [['first', 'First'], ['prev', 'Previous'], ['next', 'Next'], ['last', 'Last']]) {
        buttons[key] = node('button', `run-trace-${key}`, label);
        buttons[key].type = 'button';
        controls.append(buttons[key]);
      }
      const position = node('span', 'run-trace-position');
      const filter = node('input', 'run-trace-accepted');
      filter.type = 'checkbox';
      const filterLabel = node('label', '', 'Accepted path only');
      filterLabel.htmlFor = 'run-trace-accepted';
      controls.append(position, filter, filterLabel);
      const view = node('div', 'run-trace-view');
      box.append(controls, view);
      let at = steps.length - 1;
      const heading = (step, i) => {
        const opened = step.best == null
          ? 'its alts call is older than the retained trace'
          : `alts on the best sample (weight ${step.best}) offered ${step.count} candidates`;
        const won = step.tried.findIndex(isAccepted);
        const end = won >= 0
          ? `candidate ${won + 1} was accepted (weight ${step.tried[won].weight})${step.count != null && step.count > won + 1 ? `; the other ${step.count - won - 1} were not tried` : ''}`
          : i < steps.length - 1 ? 'none was accepted'
            : step.count == null || step.tried.length >= step.count
              ? `none was accepted (${tally(step.tried) || 'no candidates'}), so shrinking stopped here`
              : `the run stopped after ${step.tried.length} of ${step.count} candidates`;
        return `Step ${i + 1}: ${opened}; ${end}.`;
      };
      const show = () => {
        view.replaceChildren();
        const path = filter.checked;
        for (const key of ['first', 'prev']) buttons[key].disabled = path || at <= 0;
        for (const key of ['next', 'last']) buttons[key].disabled = path || at >= steps.length - 1;
        if (path) {
          position.textContent = `${taken} of ${steps.length} steps accepted a candidate`;
          const table = node('table', 'run-trace-path');
          const head = node('tr', '');
          for (const title of ['Step', 'Weight', 'From weight', 'Sample']) head.append(node('th', '', title));
          table.append(head);
          steps.forEach((step, i) => {
            const won = step.tried.find(isAccepted);
            if (!won) return;
            const tr = node('tr', '');
            for (const text of [String(i + 1), won.weight ?? '—', step.best ?? '—', won.text ?? '']) tr.append(node('td', '', text));
            table.append(tr);
          });
          view.append(table, node('p', 'run-trace-end', heading(steps.at(-1), steps.length - 1)));
          return;
        }
        const step = steps[at];
        position.textContent = `Step ${at + 1} of ${steps.length}`;
        view.append(node('p', 'run-trace-heading', heading(step, at)));
        const table = node('table', 'run-trace-step');
        const head = node('tr', '');
        for (const title of ['#', 'Weight', 'Outcome', 'Reason', 'Sample']) head.append(node('th', '', title));
        table.append(head);
        step.tried.forEach((row, i) => {
          const [outcome, words] = fates[row.why] ?? [row.why, () => ''];
          const tr = node('tr', '');
          for (const text of [String(i + 1), row.weight ?? '—', outcome, words(row, step.best),
            row.text ?? (row.why === 'heavier' || row.why === 'visited' ? '(not rendered)' : '')]) tr.append(node('td', '', text));
          table.append(tr);
        });
        view.append(table);
      };
      const go = (to) => { at = Math.max(0, Math.min(steps.length - 1, to)); show(); };
      buttons.first.addEventListener('click', () => go(0));
      buttons.prev.addEventListener('click', () => go(at - 1));
      buttons.next.addEventListener('click', () => go(at + 1));
      buttons.last.addEventListener('click', () => go(steps.length - 1));
      filter.addEventListener('change', show);
      show();
      return box;
    }
    // Every coverage requirement as the run ended: what was observed, what
    // was required, and under %confident the Wilson bounds and decision.
    const modeMeanings = {
      warn: '%warn: a share below its requirement is reported; the run still passes.',
      check: '%check: a share below its requirement at the requested count makes the run uncovered.',
      confident: '%confident: testing goes on until Wilson bounds establish or refute each share, as QuickCheck\'s checkCoverage does.'
    };
    const whyWords = {'requested-max': 'requested-max reached', 'no-samples': 'no samples',
      attempts: 'the attempts budget ran out', drops: 'the drops budget ran out',
      duplicates: 'the duplicates budget ran out'};
    const ruling = (decision) => !decision ? '—'
      : decision.kind === 'established' ? 'established: lower bound reached the tolerance of the share'
        : decision.kind === 'refuted' ? 'refuted: upper bound below the share'
          : decision.kind === 'undecided' ? 'undecided'
            : `plain threshold: ${whyWords[decision.why] ?? decision.why}`;
    function coverageTable(rows) {
      const box = node('section', 'run-coverage');
      box.append(node('h3', '', 'Coverage requirements'));
      const table = node('table', 'run-coverage-rows');
      const head = node('tr', '');
      for (const title of ['Requirement', 'Mode', 'Hits / total', 'Observed', 'Required', 'Met', 'Wilson bounds', 'Decision']) head.append(node('th', '', title));
      table.append(head);
      for (const row of rows) {
        const tr = node('tr', '');
        for (const text of [row.table == null ? row.label : `${row.table} = ${row.label}`, row.mode,
          `${row.hits} / ${row.total}`, `${row.got}%`, `${row.want}%`, row.met ? 'yes' : 'no',
          row.low == null ? '—' : `${row.low}% – ${row.high}%`, ruling(row.decision)]) tr.append(node('td', '', text));
        table.append(tr);
      }
      box.append(table);
      const modes = node('ul', 'run-coverage-modes');
      for (const mode of [...new Set(rows.map((row) => row.mode))]) modes.append(node('li', '', modeMeanings[mode] ?? mode));
      box.append(modes);
      return box;
    }
    // Each label's smallest example from a labelled-example search, the
    // ++cover labels never seen, and why the search ended early, if it did.
    function foundExamples(outcome) {
      const box = node('section', 'run-found');
      const ends = {done: 'smallest found', limited: 'shrink limit reached',
        stopped: 'not shrunk: a failure ended the search'};
      box.append(node('h3', '', outcome.found.length
        ? `Smallest example for each of ${outcome.found.length} labels` : 'No sample carried a label'));
      if (outcome.found.length) {
        const table = node('table', 'run-found-examples');
        const head = node('tr', '');
        for (const title of ['Label', 'Smallest example', 'Weight', 'Shrink steps', 'Tried', 'Shrink']) head.append(node('th', '', title));
        table.append(head);
        for (const row of outcome.found) {
          const tr = node('tr', '');
          for (const text of [row.label, row.sample.text, row.weight, String(row.steps), String(row.tried), ends[row.end] ?? row.end]) tr.append(node('td', '', text));
          table.append(tr);
        }
        box.append(table);
      }
      if (outcome.unseen?.length) {
        const list = node('ul', 'run-found-unseen');
        for (const label of outcome.unseen) list.append(node('li', '', label));
        box.append(node('h3', '', '++cover labels no passing sample carried'), list);
      }
      if (outcome.budget) line(box, 'Generation ended early', `the ${outcome.budget} budget ran out`);
      if (outcome.evidence) line(box, 'Search ended', 'A generated sample failed; it is shown below as a counterexample.');
      return box;
    }
    // A false verdict may carry the fate's notes and an expected/actual pair.
    const failure = (parent, why) => {
      if (why?.kind === 'timeout') {
        line(parent, 'Failure', 'timeout');
        line(parent, 'Meaning', 'The fate did not return within the call limit for this sample.');
        return;
      }
      const detail = why?.kind === 'false' ? why.detail : null;
      if (!detail?.notes?.length && !detail?.compared) {
        block(parent, 'run-failure', 'Failure', JSON.stringify(why, null, 2));
        return;
      }
      line(parent, 'Failure', 'false');
      if (detail.notes?.length) block(parent, 'run-notes', 'Notes', detail.notes.join('\n'));
      if (detail.compared) {
        block(parent, 'run-want', 'Expected', detail.compared.want);
        block(parent, 'run-got', 'Actual', detail.compared.got);
      }
    };
    const sourceNote = (rec, tab) => {
      const snapshot = rec.snapshot;
      if (tab && snapshot && tab.text !== snapshot.source) return 'Stale: the source tab differs from this run’s snapshot.';
      return !tab ? 'Source tab is closed or not linked in this browser.'
        : !snapshot ? (rec.status === 'done' ? 'No source snapshot is available for this run.'
          : 'Waiting for the server source snapshot.') : 'Source tab matches this snapshot.';
    };
    // Fetched records are replaced, never mutated, so identity detects change.
    // An edit only touches the stale note, not the whole detail.
    function renderDetail() {
      const id = selection(); const rec = records.get(id);
      const tab = linked(id);
      if (shown.id === id && shown.rec === rec && shown.tab === tab?.id && shown.label === tab?.label) {
        if (rec && staleNote) staleNote.textContent = sourceNote(rec, tab);
        updateButtons(); return;
      }
      shown = {id, rec, tab: tab?.id, label: tab?.label};
      staleNote = null;
      detail.replaceChildren();
      if (!rec) {
        detail.append(node('p', 'run-empty', !id
          ? 'No run selected. Run a property or a saved suite to see results.'
          : summaries.has(id) ? 'Loading run…'
            : 'Selected run is unavailable or no longer retained. Refresh history.'));
        updateButtons(); return;
      }
      const title = node('h2', 'run-result-status', `Run ${rec.id}: ${rec.outcome?.kind === 'suite'
        ? rec.outcome.status : rec.outcome?.kind || rec.status}`);
      detail.append(title);
      const snapshot = rec.snapshot;
      staleNote = node('p', 'run-stale', sourceNote(rec, tab));
      detail.append(staleNote);
      if (tab) detail.append(button('run-source-tab', `Source tab: ${tab.label}`,
        () => docs.select('property', tab.id)));
      line(detail, 'Server status', rec.status);
      line(detail, 'Workflow', rec.kind === 'draft' ? 'Draft property' : rec.kind === 'suite' ? 'Saved suite'
        : rec.kind === 'preview' ? 'Generator preview' : rec.kind === 'examples' ? 'Labelled-example search' : 'Saved property');
      if (snapshot) {
        line(detail, 'Context', `%${snapshot.context.desk} revision ${snapshot.context.revision}`);
        const wanted = rec.request?.revision;
        if (wanted && wanted.kind !== 'ud') line(detail, 'Requested revision', `${wanted.kind} ${wanted.value}`);
        line(detail, 'Source hash', snapshot['source-hash']);
        line(detail, 'Source path', snapshot.path.join('/'));
      }
      line(detail, 'Engine version', rec['engine-version']);
      const origin = rec['replay-of'];
      line(detail, 'Replay of', !origin ? 'None' : ids.includes(origin) ? origin
        : `${origin} (record deleted or no longer retained)`);
      line(detail, 'Seed', rec.kind === 'suite' ? 'Unavailable for suites' : rec.seed);
      if (rec['call-ms'] != null) line(detail, 'Call limit', `${rec['call-ms']} ms per call`);
      if (rec.config) block(detail, 'run-config', 'Effective configuration', JSON.stringify(rec.config, null, 2));
      if (rec['sample-metrics'] === 'unavailable') {
        detail.append(node('p', 'run-unavailable', 'Property sample counts, controlled seed and counterexamples are unavailable for suites.'));
      }
      block(detail, 'run-counts', 'Confirmed counters', JSON.stringify(rec.counts, null, 2));
      const spread = rec.distribution;
      shares(detail, 'run-labels', 'Distribution', spread?.labels, rec.counts?.accepted);
      for (const [name, counts] of Object.entries(spread?.tables || {})) {
        shares(detail, '', `Table: ${name}`, counts, Object.values(counts).reduce((a, b) => a + b, 0));
      }
      const outcome = rec.outcome;
      if (outcome?.kind === 'passed') line(detail, 'Meaning', 'Requested checks passed; this is not a proof.');
      if (outcome?.kind === 'uncovered') line(detail, 'Meaning', 'Every check passed, but required labels were too rare.');
      if (outcome?.kind === 'passed-unexpectedly') line(detail, 'Meaning', 'The document expects a failure, but every requested check passed.');
      if (outcome?.kind === 'failed-as-expected') line(detail, 'Meaning', 'The document expects a failure, and one was found.');
      if (outcome?.coverage?.length) detail.append(coverageTable(outcome.coverage));
      coverage(detail, 'run-coverage-warnings', 'Coverage warnings', outcome?.warnings);
      coverage(detail, 'run-coverage-shortfalls', 'Coverage shortfalls', outcome?.shortfalls);
      if (outcome?.examples?.length) {
        const list = node('ul', 'run-examples');
        for (const item of outcome.examples) list.append(node('li', '', `${item.label}: ${item.sample.text}`));
        detail.append(node('h3', '', 'First example per label'), list);
      }
      if (outcome?.kind === 'examples') detail.append(foundExamples(outcome));
      if (outcome?.kind === 'preview') {
        if (outcome.summary) detail.append(previewSummary(outcome.summary, outcome.rows.length));
        const table = node('table', 'run-preview-rows');
        const head = node('tr', '');
        for (const title of ['Size', 'Sample', 'Verdict', 'Labels', 'Repeat']) head.append(node('th', '', title));
        table.append(head);
        for (const row of outcome.rows) {
          const tr = node('tr', '');
          for (const text of [String(row.size), row.sample.text, row.verdict ?? '—',
            row.labels.join(', '), row.repeat ? 'skipped by a run' : '']) tr.append(node('td', '', text));
          table.append(tr);
        }
        detail.append(node('h3', '', outcome.summary?.samples > outcome.rows.length
          ? `Preview: first ${outcome.rows.length} of ${outcome.summary.samples} samples`
          : `Preview: ${outcome.rows.length} samples`), table);
        if (outcome.candidates?.length) {
          const list = node('ol', 'run-preview-candidates');
          for (const item of outcome.candidates) list.append(node('li', '', item.weight == null
            ? `${item.sample.text || '(not shown)'}`
            : `${item.sample.text} — weight ${item.weight}, ${item.lighter ? 'lighter' : 'not lighter: the engine would skip it'}`));
          detail.append(node('h3', '', "First sample's shrink candidates"), list);
        }
      }
      if (outcome?.kind === 'cancelled') line(detail, 'Cancellation reason', outcome.reason);
      if (outcome?.kind === 'interrupted') {
        line(detail, 'Meaning', 'The runtime aborted this run: a call exceeded its CPU time limit, the operator pressed Ctrl-C, or memory ran out.');
        line(detail, 'Interrupted during', outcome.during);
        if (outcome.arm) line(detail, 'Interrupted arm', outcome.arm);
        if (outcome.evidence) line(detail, 'Evidence', 'Best counterexample found before the interruption.');
      }
      if (outcome?.kind === 'limited') line(detail, 'Limit', outcome.which);
      if (outcome?.kind === 'exhausted') {
        line(detail, 'Exhausted budget', outcome.budget);
        line(detail, 'All dropped', outcome['all-dropped']);
      }
      if (outcome?.diagnostic) block(detail, 'run-diagnostic', 'Diagnostic', JSON.stringify(outcome.diagnostic, null, 2));
      if (outcome?.stage) line(detail, 'Error stage', outcome.stage);
      const proof = outcome?.evidence;
      // An error after a counterexample (a crashing shrinker, say) has its own
      // cause, shown before the retained evidence and its failure.
      if (proof && outcome.why) {
        block(detail, 'run-error-cause', 'Error cause', JSON.stringify(outcome.why, null, 2));
      }
      if (proof) {
        block(detail, 'run-original', 'Original counterexample', proof.original.text);
        block(detail, 'run-shrunk', 'Shrunk counterexample', proof.shrunk.text);
        failure(detail, proof.why);
        if (proof.trace?.length) detail.append(shrinkTrace(proof.trace));
      } else if (outcome?.why) failure(detail, outcome.why);
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
      detail.append(recordView(rec, proof));
      updateButtons();
    }
    // The whole server record: request, times and jammed sample nouns, with
    // a JSON download and a copy of the shrunk sample's jam.
    function recordView(rec, proof) {
      const view = node('details', 'run-record');
      view.append(node('summary', '', 'Record'));
      line(view, 'Created', rec.created);
      line(view, 'Updated', rec.updated);
      line(view, 'Finished', rec.finished);
      block(view, 'run-request', 'Submitted request', JSON.stringify(rec.request, null, 2));
      if (proof) {
        line(view, 'Original sample noun (jam, @uv)', proof.original['noun-jam']);
        line(view, 'Shrunk sample noun (jam, @uv)', proof.shrunk['noun-jam']);
      }
      const save = button('run-download', 'Download record', async () => {
        const blob = new Blob([JSON.stringify(rec, null, 2)], {type: 'application/json'});
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob); link.download = `quiz-run-${rec.id}.json`;
        document.body.append(link); link.click(); link.remove();
        setTimeout(() => URL.revokeObjectURL(link.href), 0);
      });
      const copy = button('run-copy-noun', 'Copy sample noun', async () => {
        try {
          await navigator.clipboard.writeText(proof.shrunk['noun-jam']);
          tell(`Copied the shrunk sample noun of run ${rec.id}.`);
        } catch (error) { tell(`Copy failed: ${error.message || error}`); }
      });
      copy.disabled = !proof?.shrunk?.['noun-jam'];
      view.append(save, copy);
      return view;
    }
    function render() {
      const key = JSON.stringify([selection(), ids.map((id) => {
        const row = summaries.get(id);
        return [id, row?.kind, row?.outcome, row?.status];
      })]);
      if (key === historyKey) { renderDetail(); return; }
      historyKey = key;
      history.replaceChildren();
      if (!ids.length) history.append(node('p', 'history-empty', 'History is empty.'));
      for (const id of ids) {
        const row = summaries.get(id);
        const item = button('', `#${id} ${row?.kind || ''} — ${row?.outcome || row?.status || 'loading'}`,
          () => { select(id); runtime.session.queue(); render(); if (!records.has(id)) void refresh(); });
        item.dataset.runId = id; item.setAttribute('aria-pressed', String(selection() === id)); history.append(item);
      }
      renderDetail();
    }
    // Poll quickly only while a known run can still change. When every run is
    // done, a slow poll still notices runs started elsewhere; a hidden page
    // does not poll and refreshes when shown again.
    function schedule() {
      clearTimeout(timer);
      if (stopped || document.hidden || window.__URUI_DOUBLES_TEST__) return;
      const working = ids.some((id) => summaries.get(id)?.status !== 'done');
      timer = setTimeout(() => { void refresh(); }, !online ? 5000 : working ? pollDelay : idleDelay);
    }
    async function refresh() {
      if (refreshing) return refreshing;
      refreshing = (async () => {
        try {
          const result = await post('/apps/quiz/api', {op: 'runs'});
          ids = result.ids;
          summaries = new Map((result.runs || []).map((row) => [row.id, row]));
          for (const id of [...records.keys()]) if (!ids.includes(id)) records.delete(id);
          // Only the selected run needs its whole record; a finished one never changes.
          const id = selection();
          if (ids.includes(id) && records.get(id)?.status !== 'done') {
            try { records.set(id, await post('/apps/quiz/api', {op: 'status', id})); }
            catch (error) { if (error.status !== 404) throw error; records.delete(id); }
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
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) clearTimeout(timer); else if (!stopped) void refresh();
    });
    function changed() {
      // Keep an inspection while the request it describes is unchanged.
      if (inspected !== null && requestKey(active()) !== inspected) clearInspection();
      renderDetail();
    }
    return {activate, changed, refresh, run, cancel, rerun, replay, remove, clear,
      saveRegression, saved, latest, inspect, discover, preview, findExamples, pathFor, requestFor, records,
      start: async () => { activate(active()); await refresh(); },
      stop: () => { stopped = true; clearTimeout(timer); }};
  };
})();
