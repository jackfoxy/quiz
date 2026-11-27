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
  // urui's file wire, except that Open's bare /clay root browses the
  // context chosen in Clay source: urui's chooser lists one flat scope and
  // the server cannot know which desk and revision this browser picked.
  async function filesPost(body) {
    const response = await fetch('/apps/quiz/files', {
      method: 'POST', credentials: 'same-origin',
      headers: {'content-type': 'application/json'}, body: JSON.stringify(body)
    });
    let reply = null;
    try { reply = JSON.parse(await response.text()); } catch (_) { reply = null; }
    if (!response.ok || !reply || reply.ok === false) {
      const error = new Error(reply?.error?.message || `Request failed (${response.status})`);
      error.status = response.status;
      error.code = reply?.error?.code || null;
      error.retryable = Boolean(reply?.error?.retryable);
      error.details = Array.isArray(reply?.error?.details) ? reply.error.details : [];
      throw error;
    }
    return reply;
  }
  const transport = {
    browse: async (scope) => {
      const bare = scope.length === 1 && scope[0] === 'clay';
      if (bare && !context) {
        throw new Error('Choose a desk and revision in Clay source, then Browse revision.');
      }
      const target = bare ? ['clay', context.desk, context.revision] : scope;
      return (await filesPost({op: 'browse', scope: target})).entries || [];
    },
    load: async (path) => {
      const reply = await filesPost({op: 'load', path});
      return {text: String(reply.text ?? ''), hash: reply.hash ?? null,
        readonly: reply.readonly === true};
    },
    save: async (path, text, choices = {}) => {
      const reply = await filesPost({op: 'save', path, text,
        base: choices.base ?? null, overwrite: Boolean(choices.overwrite)});
      return {hash: reply.hash ?? null};
    },
    remove: async (path, choices = {}) => {
      await filesPost({op: 'delete', path, base: choices.base ?? null});
    }
  };
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
    transport,
    session: {
      read: (key) => key === 'clayContext' ? context
        : key === 'clayTree' ? clayTree
          : key === 'runSelection' ? runSelection : undefined,
      validate: (key, value) => key === 'clayContext'
        ? validContext(value) : key === 'clayTree' ? validClayTree(value)
        : key === 'runSelection'
          ? (typeof value === 'string' && /^[1-9][0-9]{0,39}$/.test(value) ? value : null)
          : undefined
    },
    documents: {
      property: {
        fields: {defaults: window.quizRunFields, validate: window.quizRunFields},
        afterActivate: (tab) => showDocument(tab),
        saved: (tab) => { showDocument(tab); runner?.saved(tab); void refreshHeads(); }
      }
    },
    // As heathcliff's: Clay source's rows and revision box offer Now and
    // Revision…; Open is for files, and Clay is never deleted from here.
    contextMenu: {
      items: [
        {id: 'open-run', label: 'Open and run',
          title: 'Open this property or suite and run it with its run settings'},
        {id: 'now', label: 'Now', title: 'List this desk at its current revision'},
        {id: 'revision', label: 'Revision…', title: 'List this desk at a revision you choose'}
      ],
      state: (target) => {
        const clay = target.path?.[0] === 'clay';
        const head = clay ? headOf(target.path[1]) : 0;
        //  Clay rows carry the index's role; the Examples roots hold
        //  only properties and suites
        const runnable = target.entry === 'file' ? Boolean(target.role)
          : !target.entry && ['props', 'failing', 'examples'].includes(target.path?.[0]);
        return {
          'open-run': {hidden: !runnable},
          open: {hidden: Boolean(target.entry) && target.entry !== 'file'},
          delete: {hidden: clay},
          now: {hidden: !clay,
            disabled: head <= 1 || Number(revisionOf(target.path[1])) >= head},
          revision: {hidden: !clay, disabled: head <= 1}
        };
      },
      select: (id, target) => {
        if (id === 'open-run') {
          void openAndRun(target.path);
          return;
        }
        if (target.path?.[0] !== 'clay' || target.path[1] !== desk.value) return;
        if (id === 'now') pick(headOf(desk.value));
        else if (id === 'revision') {
          revision.focus();
          revision.select();
        }
      }
    }
  });
  const docs = runtime.documents;
  //  Runs the opened tab only if it is the one the menu named: a cancelled
  //  reopen of an edited tab leaves another tab active.
  async function openAndRun(path) {
    try {
      await docs.open('property', path);
    } catch (_) {
      return;
    }
    const tab = docs.active('property');
    if (tab?.path?.join('/') === path.join('/')) await runner?.run();
  }
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

  async function post(url, body) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 35000);
    const mutation = ['run', 'replay', 'cancel', 'delete', 'clear'].includes(body.op);
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
  // ---- Clay source ----------------------------------------------------
  //  A desk, a revision and Browse revision choose the context; its
  //  property documents and suites are listed below as a tree after
  //  heathcliff's explorer, its folders starting below the desk and
  //  revision.  The context is what Open's /clay location browses.
  function make(tag, attrs = {}, ...children) {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs)) {
      if (key === 'text') node.textContent = value;
      else if (key === 'id') node.id = value;
      else if (key === 'hidden') node.hidden = Boolean(value);
      else node.setAttribute(key, value);
    }
    if (children.length) node.append(...children);
    return node;
  }
  const desk = make('select', {id: 'clay-desk'});
  //  The revision box, after heathcliff's: `now` sits left, green, while
  //  the box holds the desk's head; ▴ ▾ and the arrow keys step.
  const now = make('span', {class: 'clay-now', text: 'now', 'aria-hidden': 'true'});
  const revision = make('input', {id: 'clay-revision', type: 'text', inputmode: 'numeric'});
  const newer = make('button', {id: 'clay-newer', type: 'button', text: '▴',
    'aria-label': 'Newer revision', title: 'Newer revision'});
  const older = make('button', {id: 'clay-older', type: 'button', text: '▾',
    'aria-label': 'Older revision', title: 'Older revision'});
  const state = make('p', {id: 'clay-state', role: 'status', text: 'Loading desks…'});
  const field = make('span', {class: 'clay-case-field'}, now, revision);
  const selector = make('span', {class: 'clay-case'}, field, newer, older);
  const controls = make('div', {id: 'clay-controls'},
    make('label', {for: 'clay-desk', text: 'Desk'}), desk,
    make('label', {for: 'clay-revision', text: 'Revision'}), selector, state);
  //  its menu offers Now from any revision, as a heathcliff desk row's does
  const selectorMenu = (event) => {
    if (!headOf(desk.value)) return;
    runtime.explorer.context.open('property',
      ['clay', desk.value, revisionOf(desk.value)], revision, event,
      {entry: 'revision'});
  };
  selector.addEventListener('contextmenu', selectorMenu);
  revision.addEventListener('keydown', (event) => {
    if (!event.altKey || event.key !== 'Enter') return;
    event.preventDefault();
    selectorMenu(event);
  });
  const clayHost = byId('clay-source-tree');
  byId('clay-source-panel')?.replaceChildren(...[controls, clayHost].filter(Boolean));
  //  persisted: each desk's chosen revision, absent at its head, and the
  //  folders the user closed, by desk, revision and path
  let clayTree = {cases: {}, closed: {}};
  let clayRestored = false;
  function validClayTree(raw) {
    const clean = {cases: {}, closed: {}};
    for (const [name, value] of Object.entries(raw?.cases || {})) {
      if (validContext({desk: name, revision: value})) clean.cases[name] = value;
    }
    for (const [key, value] of Object.entries(raw?.closed || {})) {
      if (value === true && key.length <= 1024) clean.closed[key] = true;
    }
    return clean;
  }
  //  revisions never change, so a listing is good for the session
  const clayListings = new Map();
  function listing(name, number) {
    const key = `${name}:${number}`;
    if (!clayListings.has(key)) {
      const request = post('/apps/quiz/api', {op: 'properties', desk: name, revision: number})
        .then((result) => result.entries.filter((entry) => entry.kind === 'file'));
      clayListings.set(key, request);
      request.catch(() => clayListings.delete(key));
    }
    return clayListings.get(key);
  }
  const headOf = (name) => Number(contexts.find((item) => item.desk === name)?.revision || 0);
  const revisionOf = (name) => clayTree.cases[name] || String(headOf(name));
  //  A folder: a toggle row and its children, built on first open.
  //  The file context menu on a Clay row, as on urui's own rows: right
  //  click, Shift-F10 or Alt-Enter on `focus`, or the row's … button.
  function withMenu(row, focus, path, detail, label) {
    const menu = (source, event) => {
      runtime.explorer.context.open('property', path, source, event, detail);
    };
    const actions = make('button', {type: 'button', class: 'file-tree-actions',
      'aria-label': `Actions for ${label}`, 'aria-haspopup': 'menu',
      'aria-expanded': 'false', text: '…',
      title: detail.entry === 'file' ? 'File actions' : 'Folder actions'});
    actions.addEventListener('click', (event) => menu(actions, event));
    focus.addEventListener('keydown', (event) => {
      if (!event.altKey || event.key !== 'Enter') return;
      event.preventDefault();
      menu(focus, event);
    });
    row.addEventListener('contextmenu', (event) => menu(focus, event));
    row.append(actions);
    return row;
  }
  //  A folder: a toggle row and its children, built on first open.
  function folder(label, path, key, fill) {
    const toggle = make('button', {type: 'button', class: 'clay-toggle',
      text: label, title: '/' + path.slice(3).join('/'), 'aria-expanded': 'false'});
    const kids = make('div', {class: 'clay-kids', role: 'group', hidden: true});
    let built = false;
    const show = (open) => {
      toggle.setAttribute('aria-expanded', String(open));
      kids.hidden = !open;
      if (open) delete clayTree.closed[key];
      else clayTree.closed[key] = true;
      if (open && !built) {
        built = true;
        fill(kids);
      }
    };
    toggle.addEventListener('click', () => {
      runtime.explorer.context.close();
      show(kids.hidden);
      runtime.session.queue();
    });
    show(!clayTree.closed[key]);
    const row = withMenu(make('div', {class: 'clay-row'}, toggle), toggle, path,
      {entry: 'directory'}, label);
    return make('div', {class: 'clay-dir'}, row, kids);
  }
  function fileRow(entry) {
    const path = entry.path;
    const label = path.slice(-2).join('.');
    const file = make('button', {type: 'button', class: 'file-tree-file',
      text: label, title: '/' + path.slice(3).join('/')});
    file.dataset.path = path.join('/');
    file.dataset.role = entry.role || 'property';
    file.addEventListener('click', () => {
      runtime.explorer.context.close();
      docs.open('property', path);
    });
    return withMenu(make('div', {class: 'explorer-file-row'}, file), file, path,
      {entry: 'file', role: file.dataset.role}, label);
  }
  function showClay(entries) {
    if (!clayHost) return;
    const top = {dirs: new Map(), files: []};
    for (const entry of entries) {
      const relative = entry.path.slice(3);
      if (relative.length < 2) continue;
      let branch = top;
      relative.slice(0, -2).forEach((part, index) => {
        if (!branch.dirs.has(part)) {
          branch.dirs.set(part,
            {path: relative.slice(0, index + 1), dirs: new Map(), files: []});
        }
        branch = branch.dirs.get(part);
      });
      branch.files.push(entry);
    }
    const base = entries[0]?.path.slice(0, 3) || [];
    const prefix = base.slice(1).join(':');
    const label = (entry) => entry.path.slice(-2).join('.');
    const build = (branch) => [
      ...[...branch.dirs.keys()].sort().map((name) => {
        const dir = branch.dirs.get(name);
        const where = dir.path.join('/');
        return folder(name, [...base, ...dir.path], `${prefix}:${where}`,
          (kids) => kids.append(...build(dir)));
      }),
      ...branch.files.slice()
        .sort((left, right) => label(left).localeCompare(label(right)))
        .map(fileRow)
    ];
    clayHost.setAttribute('aria-busy', 'false');
    clayHost.replaceChildren(make('div', {class: 'clay-tree'}, ...build(top)));
  }
  function showCase() {
    const head = headOf(desk.value);
    const number = Number(revisionOf(desk.value));
    revision.value = head ? String(number) : '';
    revision.title = head ? `Revision of %${desk.value}: 1 to ${head}; ${head} is now` : '';
    revision.setAttribute('aria-label', `Revision of %${desk.value}`);
    now.style.visibility = head && number >= head ? 'visible' : 'hidden';
    field.style.width = `${String(head || 1).length + 5}ch`;
    newer.disabled = !head || number >= head;
    older.disabled = !head || number <= 1;
  }
  async function browseClay() {
    const name = desk.value;
    const generation = ++browseGeneration;
    clayHost?.replaceChildren();
    if (!headOf(name)) {
      state.textContent = name ? `%${name} is not available.` : 'No local desk is available.';
      return false;
    }
    const selected = {desk: name, revision: revisionOf(name)};
    context = selected;
    runtime.session.queue();
    state.textContent = `Loading %${name} at revision ${selected.revision}…`;
    try {
      // Property documents, suites and quiz suites, as +role-of in
      // quiz-files decides.  Open's /clay location, at this same
      // context, lists every Hoon file.
      const entries = await listing(name, selected.revision);
      if (generation !== browseGeneration) return false;
      showClay(entries);
      const count = (role) => entries.filter((entry) => (entry.role || 'property') === role).length;
      state.textContent = `${count('property')} property documents, ${count('suite')} suites `
        + `and ${count('quiz-suite')} quiz suites — revision ${selected.revision}. `
        + 'Open → clay lists every Hoon file here.';
      return true;
    } catch (cause) {
      if (generation !== browseGeneration) return false;
      state.textContent = String(cause.message || cause);
      return false;
    }
  }
  function pick(number, typed = number) {
    const head = headOf(desk.value);
    if (!Number.isInteger(number) || number < 1 || number > head) {
      runtime.notify(`%${desk.value} has no revision ${typed}; `
        + `its revisions run from 1 to ${head} (now).`, {kind: 'error'});
      showCase();
      return;
    }
    if (number >= head) delete clayTree.cases[desk.value];
    else clayTree.cases[desk.value] = String(number);
    showCase();
    browseClay();
  }
  function step(by) {
    const next = Number(revisionOf(desk.value)) + by;
    if (next >= 1 && next <= headOf(desk.value)) pick(next);
  }
  desk.addEventListener('change', () => {
    showCase();
    browseClay();
  });
  revision.addEventListener('change', () => {
    const text = revision.value.trim().replace(/^now */, '');
    if (text === '') pick(headOf(desk.value));
    else pick(/^[0-9]+$/.test(text) ? Number(text) : NaN, text);
  });
  revision.addEventListener('keydown', (event) => {
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    step(event.key === 'ArrowUp' ? 1 : -1);
  });
  newer.addEventListener('click', () => step(1));
  older.addEventListener('click', () => step(-1));
  async function fetchContexts() {
    const result = await post('/apps/quiz/api', {op: 'contexts'});
    contexts = result.contexts.map(validContext).filter(Boolean);
    defaults = result.defaults;
    //  a revision that is now a head is now
    for (const [name, value] of Object.entries(clayTree.cases)) {
      if (Number(value) >= headOf(name)) delete clayTree.cases[name];
    }
  }
  async function loadContexts() {
    try {
      await fetchContexts();
    } catch (cause) {
      state.textContent = String(cause.message || cause);
      problem('Could not load desks. Sign in and reload to try again.');
      return;
    }
    //  a context saved before per-desk revisions keeps its revision
    if (!clayRestored && context && Number(context.revision) < headOf(context.desk)) {
      clayTree.cases[context.desk] = context.revision;
    }
    clayRestored = true;
    const selected = context?.desk || (headOf('quiz') ? 'quiz' : contexts[0]?.desk);
    desk.replaceChildren();
    for (const item of contexts) {
      desk.append(make('option', {value: item.desk, text: `%${item.desk}`}));
    }
    if (selected && !headOf(selected)) {
      desk.append(make('option', {value: selected, text: `%${selected} (unavailable)`}));
    }
    desk.value = selected || '';
    showCase();
    await browseClay();
  }
  //  A save commits to %quiz: a desk shown at now follows its head.
  async function refreshHeads() {
    const name = desk.value;
    const head = headOf(name);
    const atNow = !clayTree.cases[name];
    try {
      await fetchContexts();
    } catch (_) {
      return;
    }
    showCase();
    if (atNow && headOf(name) !== head) browseClay();
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
  //  F5 runs: the Run control is built by quiz-runs.js inside
  //  #run-controls, so the chord goes through the button rather than
  //  reaching into the runner.  urui registers no `run`, so this does
  //  not race its own registrations in runtime.start.
  runtime.shortcuts.register('run', () => {
    const button = document.querySelector('#run-start');
    if (button && !button.disabled) button.click();
  });
  window.urui.boot({
    onReady() {
      runtime.start((saved) => {
        context = validContext(saved?.clayContext);
        clayRestored = Boolean(saved?.clayTree);
        clayTree = validClayTree(saved?.clayTree);
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
