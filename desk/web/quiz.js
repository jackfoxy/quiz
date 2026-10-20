(() => {
  'use strict';
  const byId = (id) => document.getElementById(id);
  // Keep repository-relative Markdown links usable in rendered Help tabs.
  // Shared urui owns the frames; Quiz owns its documentation/source routes.
  document.addEventListener('load', (event) => {
    const frame = event.target;
    if (frame.tagName !== 'IFRAME'
        || !frame.classList.contains('docs-explorer-frame')) return;
    let doc;
    try { doc = frame.contentDocument; } catch (_) { return; }
    if (!doc) return;
    const location = new URL(doc.URL);
    const prefix = '/docs/d/quiz/';
    if (location.origin !== window.location.origin
        || !location.pathname.startsWith(prefix)) return;
    const repository = 'https://github.com/jackfoxy/quiz/blob/dev/desk/';
    const source = repository + 'doc/' + location.pathname.slice(prefix.length) + '.md';
    for (const link of doc.querySelectorAll('a[href]')) {
      const href = link.getAttribute('href');
      if (!href.startsWith('#') && !href.startsWith('/')
          && !/^[a-z][a-z0-9+.-]*:/i.test(href)) {
        const target = new URL(href, source);
        const docRoot = new URL(repository + 'doc/');
        if (target.origin === docRoot.origin
            && target.pathname.startsWith(docRoot.pathname)
            && target.pathname.endsWith('.md')) {
          link.href = prefix + target.pathname.slice(docRoot.pathname.length, -3)
            + target.hash;
        } else link.href = target.href;
      }
      const target = new URL(link.href, location);
      if (target.origin !== location.origin) {
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
      }
    }
  }, true);
  const validContext = (value) => {
    if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
    const {desk, revision} = value;
    if (typeof desk !== 'string' || desk.length > 64
        || !/^[a-z][a-z0-9-]*$/.test(desk)) return null;
    if (typeof revision !== 'string' || revision.length > 40
        || !/^[1-9][0-9]*$/.test(revision)) return null;
    return {desk, revision};
  };
  let context = null;
  let defaults = null;
  let runSelection = null;
  let runner = null;
  let contexts = [];
  let browseGeneration = 0;
  const problem = (message = '') => {
    const node = byId('quiz-error');
    node.textContent = message;
    node.hidden = !message;
  };
  const runtime = window.urui.runtime({
    elements: {
      explorerPane: byId('explorer-pane'),
      editorPane: byId('editor-pane'),
      resultPane: byId('result-pane'),
      editorStatus: byId('source-status')
    },
    onChange: () => { runtime.session.queue(); runner?.changed(); },
    session: {
      read: (key) => key === 'clayContext' ? context
        : key === 'runSelection' ? runSelection : undefined,
      validate: (key, value) => key === 'clayContext'
        ? validContext(value) : key === 'runSelection'
          ? (typeof value === 'string' && /^[1-9][0-9]{0,39}$/.test(value) ? value : null)
          : undefined
    },
    documents: {
      property: {
        fields: {defaults: window.quizRunFields, validate: window.quizRunFields},
        afterActivate: (tab) => showDocument(tab),
        saved: (tab) => showDocument(tab)
      }
    }
  });
  const docs = runtime.documents;
  function showDocument(tab) {
    if (!tab) return;
    const readOnly = Boolean(tab.readonly
      || (tab.path && tab.path[0] !== 'work'));
    byId('editable-copy').hidden = !readOnly;
    byId('document-location').textContent = tab.path
      ? `${readOnly ? 'Read-only: ' : ''}${tab.path.join('/')}`
      : 'Unsaved document';
    // Ace's module API owns syntax modes; urui continues to own editing.
    const raw = window.ace?.edit(byId('quiz-editor'));
    raw?.session?.setMode((tab.path?.at(-1) === 'md'
      || (!tab.path && tab.label?.endsWith('.md')))
      ? 'ace/mode/text' : 'ace/mode/hoon');
    runner?.activate(tab);
  }
  function editableCopy() {
    const tab = docs.active('property');
    if (!tab) return undefined;
    const label = tab.label || 'Document';
    return docs.create('property', {
      text: tab.text, clean: '', label: `Copy of ${label}`, focus: true
    });
  }
  byId('editable-copy').addEventListener('click', editableCopy);
  window.addEventListener('beforeunload', (event) => {
    runtime.session.save();
    if (!docs.list('property').some((tab) => docs.dirty('property', tab.id))) {
      return;
    }
    event.preventDefault();
    event.returnValue = '';
  });

  // The shared explorer owns its panels; this view supplies Clay context.
  const panel = byId('clay-source-panel');
  function control(tag, id, text) {
    const node = document.createElement(tag);
    node.id = id;
    if (text) node.textContent = text;
    return node;
  }
  const deskLabel = control('label', 'clay-desk-label', 'Desk');
  deskLabel.setAttribute('for', 'clay-desk');
  const desk = control('select', 'clay-desk');
  const revLabel = control('label', 'clay-revision-label', 'Revision');
  revLabel.setAttribute('for', 'clay-revision');
  const revision = control('input', 'clay-revision');
  revision.type = 'text';
  revision.inputMode = 'numeric';
  const browse = control('button', 'clay-browse', 'Browse revision');
  browse.type = 'button';
  const state = control('p', 'clay-state', 'Loading desks…');
  state.setAttribute('role', 'status');
  const files = control('div', 'clay-files');
  panel.append(deskLabel, desk, revLabel, revision, browse, state, files);
  async function post(url, body) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 35000);
    const mutation = ['run', 'replay', 'cancel'].includes(body.op);
    try {
      const response = await fetch(url, {
        method: 'POST', credentials: 'same-origin', signal: controller.signal,
        headers: {'content-type': 'application/json'}, body: JSON.stringify(body)
      });
      let result;
      try { result = await response.json(); }
      catch {
        throw new Error(response.status === 500
          ? 'The ship aborted this request (500). A build may have exceeded its CPU time or memory.'
          : `Unexpected server response (${response.status}).`);
      }
      if (!response.ok || result.ok === false) {
        const reason = typeof result.error === 'string' ? result.error : result.error?.message;
        const error = new Error(reason || result.code || `Request failed (${response.status})`);
        error.status = response.status;
        error.diagnostic = result.code && result.path ? result : undefined;
        error.uncertain = mutation && response.status >= 500;
        throw error;
      }
      return result;
    } catch (error) {
      if (!error.status) error.uncertain = mutation;
      throw error;
    } finally { clearTimeout(timeout); }
  }
  async function browseClay() {
    const selected = validContext({desk: desk.value, revision: revision.value});
    const generation = ++browseGeneration;
    files.replaceChildren();
    if (!selected) {
      state.textContent = 'Choose a desk and a positive revision number.';
      return false;
    }
    context = selected;
    runtime.session.queue();
    state.textContent = `Loading %${context.desk} at revision ${context.revision}…`;
    const scope = ['clay', context.desk, context.revision];
    try {
      const result = await post('/apps/quiz/files', {op: 'browse', scope});
      if (generation !== browseGeneration) return false;
      const entries = result.entries.filter((entry) => entry.kind === 'file');
      for (const entry of entries) {
        const button = control('button', '', entry.path.slice(3).join('/'));
        button.type = 'button';
        button.dataset.path = entry.path.join('/');
        button.addEventListener('click', () => docs.open('property', entry.path));
        files.append(button);
      }
      state.textContent = `${entries.length} Hoon files — revision ${selected.revision}`;
      return true;
    } catch (cause) {
      if (generation !== browseGeneration) return false;
      state.textContent = String(cause.message || cause);
      return false;
    }
  }
  desk.addEventListener('change', () => {
    ++browseGeneration;
    files.replaceChildren();
    revision.value = contexts.find((item) => item.desk === desk.value)?.revision || '';
    state.textContent = 'Choose Browse revision to load this context.';
  });
  revision.addEventListener('input', () => {
    ++browseGeneration;
    files.replaceChildren();
    state.textContent = 'Choose Browse revision to load this context.';
  });
  browse.addEventListener('click', browseClay);
  async function loadContexts() {
    try {
      const result = await post('/apps/quiz/api', {op: 'contexts'});
      contexts = result.contexts.map(validContext).filter(Boolean);
      defaults = result.defaults;
      const selected = context || contexts.find((item) => item.desk === 'quiz');
      desk.replaceChildren();
      for (const item of contexts) {
        const option = control('option', '', `%${item.desk}`);
        option.value = item.desk;
        desk.append(option);
      }
      if (selected && !contexts.some((item) => item.desk === selected.desk)) {
        const option = control('option', '', `%${selected.desk} (unavailable)`);
        option.value = selected.desk;
        desk.append(option);
      }
      desk.value = selected?.desk || '';
      revision.value = selected?.revision || '';
      if (selected) await browseClay();
      else state.textContent = 'No local desk is available.';
    } catch (cause) {
      state.textContent = String(cause.message || cause);
      problem('Could not load desks. Sign in and reload to try again.');
    }
  }
  // Ship-wide CPU time limits live in %quiz; urui's Settings dialog hosts them.
  const limitFields = [['call-time', 'quiz-limit-call'],
    ['build-time', 'quiz-limit-build'], ['arm-time', 'quiz-limit-arm']];
  let limitsLoaded = false;
  let limitsSnapshot = '';
  const currentLimits = () => limitFields.map(([, id]) => byId(id)?.value.trim() || '');
  const limitState = (text) => {
    const status = byId('quiz-limits-state');
    if (status) status.textContent = text;
  };
  async function loadLimits() {
    if (!byId('quiz-limits-state')) return null;
    try {
      const result = await post('/apps/quiz/api', {op: 'timeouts'});
      for (const [key, id] of limitFields) byId(id).value = String(result[key]);
      limitsLoaded = true;
      limitsSnapshot = currentLimits().join('\n');
      limitState('Ship-wide. Changes save when Settings closes and apply to the next slice or build.');
      return result;
    } catch (cause) {
      limitsLoaded = false;
      limitState(String(cause.message || cause));
      return null;
    }
  }
  async function saveLimits() {
    const body = {op: 'set-timeouts'};
    for (const [key, id] of limitFields) {
      const value = byId(id)?.value.trim() || '';
      if (!/^[1-9][0-9]*$/.test(value) || Number(value) > 3600) {
        limitState('Each limit must be a whole number of seconds from 1 to 3600.');
        return false;
      }
      body[key] = value;
    }
    limitState('Saving…');
    try {
      await post('/apps/quiz/api', body);
    } catch (cause) {
      limitState(String(cause.message || cause));
      return false;
    }
    const saved = await loadLimits();
    if (saved) limitState('Saved. Changes apply to the next slice or build.');
    return Boolean(saved);
  }
  const settingsModal = byId('settings-modal');
  if (settingsModal && typeof MutationObserver === 'function') {
    let wasOpen = !settingsModal.hidden;
    new MutationObserver(() => {
      const open = !settingsModal.hidden;
      if (wasOpen && !open && limitsLoaded
          && currentLimits().join('\n') !== limitsSnapshot) void saveLimits();
      wasOpen = open;
    }).observe(settingsModal, {attributes: true, attributeFilter: ['hidden']});
  }
  runner = window.createQuizRuns({runtime, post,
    getContexts: () => contexts, getDefaults: () => defaults,
    selection: () => runSelection, select: (id) => { runSelection = id; }
  });
  window.quiz = {runtime, documents: docs, editableCopy, browseClay, validContext, runs: runner,
    loadLimits, saveLimits};
  window.urui.boot({
    onReady() {
      runtime.start((saved) => {
        context = validContext(saved?.clayContext);
        runSelection = saved?.runSelection || null;
      });
      showDocument(docs.active('property'));
      window.quiz.ready = loadContexts().then(() => runner.start());
      window.quiz.limitsReady = loadLimits();
    },
    editor: {primary: () => docs.editor('property')},
    dialog: {help: runtime.dialogs.setHelpOpen},
    session: {save: runtime.session.save, queue: runtime.session.queue},
    shortcuts: runtime.shortcuts,
    explorer: {
      show: runtime.explorer.setView,
      openDocs: runtime.explorer.docs.open
    },
    layout: {
      paneWidth: runtime.layout.paneWidth,
      explorerWidth: runtime.layout.explorerWidth
    }
  });
})();
