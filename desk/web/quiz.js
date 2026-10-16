(() => {
  'use strict';
  const byId = (id) => document.getElementById(id);
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
    onChange: () => runtime.session.queue(),
    session: {
      read: (key) => key === 'clayContext' ? context : undefined,
      validate: (key, value) => key === 'clayContext'
        ? validContext(value) : undefined
    },
    documents: {
      property: {
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
    const response = await fetch(url, {
      method: 'POST', credentials: 'same-origin',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify(body)
    });
    const result = await response.json();
    if (!response.ok || result.ok === false) {
      const reason = typeof result.error === 'string'
        ? result.error : result.error?.message;
      throw new Error(reason || result.code || `Request failed (${response.status})`);
    }
    return result;
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
  window.quiz = {runtime, documents: docs, editableCopy, browseClay, validContext};
  window.urui.boot({
    onReady() {
      runtime.start((saved) => { context = validContext(saved?.clayContext); });
      showDocument(docs.active('property'));
      window.quiz.ready = loadContexts();
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
