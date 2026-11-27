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
  // Set by the save dialog for its one listing; see transport.browse.
  let saveListing = false;
  // urui's file wire, except that the chooser's bare /clay root lists the
  // desk and revision of the visible view, through the same
  // index: urui's chooser lists one flat scope, and only property
  // documents and suites may be opened or saved.
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
      if (scope.length === 1 && scope[0] === 'clay') {
        const name = chosen().name();
        if (!headOf(name)) throw new Error('Choose a desk in Apps.');
        // The Save As list is the desk's files at now, without the case:
        // the chooser's paths are <desk>/<path>, and saves land at now.
        if (saveListing) {
          saveListing = false;
          const entries = await listing(name, String(headOf(name)));
          return entries.map((entry) => ({...entry,
            path: [...entry.path.slice(0, 2), ...entry.path.slice(3)]}));
        }
        return shown(name, await listing(name, revisionOf(name)));
      }
      return (await filesPost({op: 'browse', scope})).entries || [];
    },
    // Never read-only to urui: Save and Save As of a numbered revision go
    // to the same path at now (beforeSave), which the server permits.
    load: async (path) => {
      const reply = await filesPost({op: 'load', path});
      return {text: String(reply.text ?? ''), hash: reply.hash ?? null, readonly: false};
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
    // A save or delete commits to its desk: a desk shown at now relists.
    onFile: ({op, phase}) => {
      if (phase === 'done' && ['save', 'delete'].includes(op)) void refreshHeads();
    },
    session: {
      read: (key) => key === 'clayContext' ? context
        : key === 'clayTree' ? clayTree
          : key === 'runSelection' ? runSelection : undefined,
      validate: (key, value) => key === 'clayContext'
        ? validContext(value)
        //  undefined when absent, so a record from before the slot is told
        //  apart from an empty tree
        : key === 'clayTree' ? (value && typeof value === 'object'
          ? validClayTree(value) : undefined)
        : key === 'runSelection'
          ? (typeof value === 'string' && /^[1-9][0-9]{0,39}$/.test(value) ? value : null)
          : undefined
    },
    documents: {
      property: {
        fields: {defaults: window.quizRunFields, validate: window.quizRunFields},
        afterActivate: (tab) => showDocument(tab),
        saved: (tab) => { showDocument(tab); runner?.saved(tab); },
        // The chooser starts from the tab's <desk>/<path>, with no case;
        // a new document starts in data/ of the visible view's desk.
        saveDialog: (tab) => {
          saveListing = true;
          const path = tab.path;
          if (path?.[0] === 'clay' && path.length > 4) {
            return {value: [path[1], ...path.slice(3, -1)].join('/')};
          }
          const name = chosen().name();
          return headOf(name) ? {value: `${name}/data/`} : {};
        },
        // Every save lands at now, marked hoon: a numbered revision's path
        // moves to the same path at now; a chooser path is <desk>/<path>,
        // or, when it names no desk or only a desk, a path in data/ of the
        // visible view's desk (`mine` is data/mine.hoon, `quiz` alone is
        // data/quiz.hoon), unless it already starts with data/.
        beforeSave: (tab, {path}) => {
          saveListing = false;
          if (path[0] !== 'clay') return undefined;
          const [, first, ...named] = path;
          const rest = headOf(first) && named.length > 2
            && /^(now|[1-9][0-9]*)$/.test(named[0]) ? named.slice(1) : named;
          const typed = [first, ...rest];
          const target = headOf(first) && rest.length > 1
            ? ['clay', first, 'now', ...rest]
            : ['clay', chosen().name(), 'now',
              ...(first === 'data' && rest.length > 1 ? [] : ['data']), ...typed];
          // the untouched default, <desk>/data/, would write data.hoon
          if (target.length === 5 && target[3] === 'data') {
            throw new Error(`Enter a name under ${target[1]}/data/.`);
          }
          return {path: target};
        }
      }
    },
    // As heathcliff's: the rows and revision box offer Now and Revision…;
    // Open is for files, and only a file at now can be deleted.
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
        const file = target.entry === 'file';
        return {
          'open-run': {hidden: !file},
          open: {hidden: !file},
          delete: {hidden: !file || target.path[2] !== 'now'},
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
        const view = target.path?.[0] === 'clay' ? viewOf(target.path[1]) : undefined;
        if (!view) return;
        if (id === 'now') view.pick(headOf(target.path[1]));
        else if (id === 'revision') view.focus();
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
    // a numbered revision saves to now
    const pinned = Boolean(tab.path) && tab.path[2] !== 'now';
    byId('document-location').textContent = tab.path
      ? `${tab.path.join('/')}${pinned ? ' (saves to now)' : ''}`
      : 'Unsaved document';
    // Ace's module API owns syntax modes; urui continues to own editing.
    const raw = window.ace?.edit(byId('quiz-editor'));
    raw?.session?.setMode('ace/mode/hoon');
    runner?.activate(tab);
  }
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
  // ---- Properties and suites, Apps ---------------------------------------
  //  Two explorer views of one kind: Properties and suites shows %quiz;
  //  Apps shows any other desk, chosen from its list.  A revision chooses
  //  the context; its property documents, suites and quiz suites are
  //  listed below as a tree after heathcliff's explorer, its folders
  //  starting below the desk and revision.  At the head the paths say
  //  `now` and are writable; at a revision number they are pinned, and
  //  save to the same path at now.  The chooser's /clay root lists the
  //  visible view's context.
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
  //  a listing of `name` at its chosen revision, its paths at now when
  //  that is the head
  function shown(name, entries) {
    if (clayTree.cases[name]) return entries;
    return entries.map((entry) => ({...entry,
      path: [entry.path[0], entry.path[1], 'now', ...entry.path.slice(3)]}));
  }
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
  //  Every desk shows data/, the place for saved documents, even when empty.
  function showClay(host, name, entries) {
    if (!host) return;
    const top = {dirs: new Map([['data', {path: ['data'], dirs: new Map(), files: []}]]),
      files: []};
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
    const base = ['clay', name, clayTree.cases[name] || 'now'];
    const prefix = base.slice(1).join(':');
    const label = (entry) => entry.path.slice(-2).join('.');
    const build = (branch) => branch.dirs.size || branch.files.length ? [
      ...[...branch.dirs.keys()].sort().map((dir) => {
        const node = branch.dirs.get(dir);
        const where = node.path.join('/');
        return folder(dir, [...base, ...node.path], `${prefix}:${where}`,
          (kids) => kids.append(...build(node)));
      }),
      ...branch.files.slice()
        .sort((left, right) => label(left).localeCompare(label(right)))
        .map(fileRow)
    ] : [make('p', {class: 'clay-empty', text: 'No files yet.'})];
    host.setAttribute('aria-busy', 'false');
    host.replaceChildren(make('div', {class: 'clay-tree'}, ...build(top)));
  }
  //  One view: `fixed` names its desk, else a list offers every desk
  //  but %quiz.  Its ids are `prefix`-desk, -revision, -newer, -older and
  //  -state; urui made `panel` and `tree`.
  function clayView({prefix, panel, tree, fixed}) {
    const desk = fixed ? null : make('select', {id: `${prefix}-desk`});
    //  The revision box, after heathcliff's: `now` sits left, green, while
    //  the box holds the desk's head; ▴ ▾ and the arrow keys step.
    const now = make('span', {class: 'clay-now', text: 'now', 'aria-hidden': 'true'});
    const revision = make('input', {id: `${prefix}-revision`, type: 'text',
      inputmode: 'numeric'});
    const newer = make('button', {id: `${prefix}-newer`, type: 'button', text: '▴',
      'aria-label': 'Newer revision', title: 'Newer revision'});
    const older = make('button', {id: `${prefix}-older`, type: 'button', text: '▾',
      'aria-label': 'Older revision', title: 'Older revision'});
    const state = make('p', {id: `${prefix}-state`, class: 'clay-state', role: 'status',
      text: 'Loading desks…'});
    const field = make('span', {class: 'clay-case-field'}, now, revision);
    const selector = make('span', {class: 'clay-case'}, field, newer, older);
    const named = fixed
      ? [make('p', {class: 'clay-desk-name', text: `%${fixed}`})]
      : [make('label', {for: `${prefix}-desk`, text: 'Desk'}), desk];
    const controls = make('div', {class: 'clay-controls'}, ...named,
      make('label', {for: `${prefix}-revision`, text: 'Revision'}), selector, state);
    const host = byId(tree);
    const panelNode = byId(panel);
    panelNode?.replaceChildren(...[controls, host].filter(Boolean));
    let generation = 0;
    const view = {
      name: () => fixed || desk.value,
      visible: () => Boolean(panelNode) && !panelNode.hidden,
      focus() {
        revision.focus();
        revision.select();
      },
      state: (text) => { state.textContent = text; },
      //  fills an Apps list from the desks, keeping `selected` if it can
      fill(selected) {
        if (fixed) return;
        desk.replaceChildren();
        for (const item of contexts) {
          if (item.desk !== 'quiz') desk.append(make('option', {value: item.desk, text: `%${item.desk}`}));
        }
        if (selected && selected !== 'quiz' && !headOf(selected)) {
          desk.append(make('option', {value: selected, text: `%${selected} (unavailable)`}));
        }
        desk.value = selected && selected !== 'quiz' ? selected
          : contexts.find((item) => item.desk !== 'quiz')?.desk || '';
      },
      showCase() {
        const name = view.name();
        const head = headOf(name);
        const number = Number(revisionOf(name));
        revision.value = head ? String(number) : '';
        revision.title = head ? `Revision of %${name}: 1 to ${head}; ${head} is now` : '';
        revision.setAttribute('aria-label', `Revision of %${name}`);
        now.style.visibility = head && number >= head ? 'visible' : 'hidden';
        field.style.width = `${String(head || 1).length + 5}ch`;
        newer.disabled = !head || number >= head;
        older.disabled = !head || number <= 1;
      },
      async browse() {
        const name = view.name();
        const mine = ++generation;
        host?.replaceChildren();
        if (!headOf(name)) {
          state.textContent = name ? `%${name} is not available.`
            : 'No other local desk is available.';
          return false;
        }
        const selected = {desk: name, revision: revisionOf(name)};
        if (!fixed) {
          context = selected;
          runtime.session.queue();
        }
        state.textContent = `Loading %${name} at revision ${selected.revision}…`;
        try {
          // Property documents, suites and quiz suites, as +role-of in
          // quiz-files decides.
          const entries = await listing(name, selected.revision);
          if (mine !== generation) return false;
          showClay(host, name, shown(name, entries));
          const count = (role) => entries.filter((entry) =>
            (entry.role || 'property') === role).length;
          const at = clayTree.cases[name] ? `revision ${selected.revision}, pinned`
            : `now, revision ${selected.revision}`;
          state.textContent = `${count('property')} property documents, `
            + `${count('suite')} suites and ${count('quiz-suite')} quiz suites`
            + ` — %${name} at ${at}.`;
          return true;
        } catch (cause) {
          if (mine !== generation) return false;
          state.textContent = String(cause.message || cause);
          return false;
        }
      },
      pick(number, typed = number) {
        const name = view.name();
        const head = headOf(name);
        if (!Number.isInteger(number) || number < 1 || number > head) {
          runtime.notify(`%${name} has no revision ${typed}; `
            + `its revisions run from 1 to ${head} (now).`, {kind: 'error'});
          view.showCase();
          return;
        }
        if (number >= head) delete clayTree.cases[name];
        else clayTree.cases[name] = String(number);
        view.showCase();
        view.browse();
      }
    };
    const step = (by) => {
      const next = Number(revisionOf(view.name())) + by;
      if (next >= 1 && next <= headOf(view.name())) view.pick(next);
    };
    //  its menu offers Now from any revision, as a heathcliff desk row's does
    const selectorMenu = (event) => {
      const name = view.name();
      if (!headOf(name)) return;
      runtime.explorer.context.open('property',
        ['clay', name, clayTree.cases[name] || 'now'], revision, event,
        {entry: 'revision'});
    };
    selector.addEventListener('contextmenu', selectorMenu);
    desk?.addEventListener('change', () => {
      view.showCase();
      view.browse();
    });
    revision.addEventListener('change', () => {
      const text = revision.value.trim().replace(/^now */, '');
      if (text === '') view.pick(headOf(view.name()));
      else view.pick(/^[0-9]+$/.test(text) ? Number(text) : NaN, text);
    });
    revision.addEventListener('keydown', (event) => {
      if (event.altKey && event.key === 'Enter') {
        event.preventDefault();
        selectorMenu(event);
      } else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
        event.preventDefault();
        step(event.key === 'ArrowUp' ? 1 : -1);
      }
    });
    newer.addEventListener('click', () => step(1));
    older.addEventListener('click', () => step(-1));
    return view;
  }
  const properties = clayView({prefix: 'clay', panel: 'properties-panel',
    tree: 'properties-tree', fixed: 'quiz'});
  const apps = clayView({prefix: 'apps', panel: 'apps-panel', tree: 'apps-tree'});
  const views = [properties, apps];
  //  the view a desk is shown in, and the visible view
  const viewOf = (name) => views.find((view) => view.name() === name);
  const chosen = () => (apps.visible() ? apps : properties);
  async function browseClay() {
    const results = await Promise.all(views.map((view) => view.browse()));
    return results.every(Boolean);
  }
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
      for (const view of views) view.state(String(cause.message || cause));
      problem('Could not load desks. Sign in and reload to try again.');
      return;
    }
    //  a context saved before per-desk revisions keeps its revision
    if (!clayRestored && context && Number(context.revision) < headOf(context.desk)) {
      clayTree.cases[context.desk] = context.revision;
    }
    clayRestored = true;
    apps.fill(context?.desk);
    for (const view of views) view.showCase();
    await browseClay();
  }
  //  A save or delete commits to its desk: a view shown at now follows
  //  its head.
  async function refreshHeads() {
    const before = views.map((view) => [view, view.name(), headOf(view.name())]);
    try {
      await fetchContexts();
    } catch (_) {
      return;
    }
    for (const [view, name, head] of before) {
      view.showCase();
      if (!clayTree.cases[name] && headOf(name) !== head) view.browse();
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
  window.quiz = {runtime, documents: docs, browseClay, validContext, runs: runner,
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
