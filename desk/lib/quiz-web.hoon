/-  urui
/+  shell=urui-shell, ucfg=urui-config, ujs=urui-js, ufiles=urui-files
/+  ucss=urui-css, uace=urui-ace, locations=quiz-files
/*  client  %js  /web/quiz/js
/*  runs  %js  /web/quiz-runs/js
/*  favicon  %png  /favicon/png
|%
  ::  Document workbench. urui owns editors, files, dialogs and persistence.
  ::
++  config
  ::  urui app config: identity, layout, slots, shortcuts, help URL, Ace
  ::  assets and the file store.
  ^-  app-config:urui
  :*  [%quiz 'Quiz' '/apps/quiz' 'quiz.session' 2]
      [350 150 180 10 25 70 262.144]
      slots
      shortcuts
      ~[[%ready 'Ready'] [%loading 'Loading'] [%failed 'Failed']]
      `'/docs/d/quiz/'
      :*  '/apps/quiz/ace'  'quizAceAssets'  '1.44.0'
          'ace/mode/hoon'  'ace/theme/github'  'ace/theme/monokai'
          :~  'ace/ext/beautify'  'ace/ext/prompt'
              'ace/ext/searchbox'  'ace/ext/settings_menu'
          ==
          |
      ==
      %columns  &  `files  ~
  ==
::
++  shortcuts
  ::  F1 and F2 displace Ace's command palette and fold widget; the
  ::  palette stays reachable at Ctrl-, and folds at Alt-F2.  F5 runs,
  ::  as it does in obelisk.
  ::
  ::  The file chords are urui's, registered from the store's name.
  ::  Alt-O rather than Ctrl-O for Open: Ctrl-O is free in Ace's
  ::  Windows/Linux table but taken by Vim in both insert and normal
  ::  mode, and the editor can be switched to Vim in Settings.  Alt-C
  ::  rather than Ctrl-Shift-C for Copy, which Chromium keeps for its
  ::  element inspector.  Both are %no-editor, so Ctrl-C and its
  ::  neighbours keep their ordinary meaning while editing.
  ^-  (list shortcut:urui)
  :~  ['F1' 'help' %always %override `'Help']
      ['F2' 'settings' %always %override `'Settings']
      ['F5' 'run' %no-editor %free `'Run the selected property']
      ['Ctrl-S' 'save:property' %always %free `'Save the document']
      ['Ctrl-Shift-S' 'save-as:property' %always %free `'Save as a new file']
      ['Alt-O' 'open:property' %no-editor %free `'Open a saved document']
      ['Alt-C' 'copy:property' %no-editor %free `'Copy the document']
  ==
::
++  slots
  ::  Session state the browser keeps: urui's layout, plus the Clay
  ::  context and selected run.
  ^-  (list slot:urui)
  :~  ['paneWidth' %urui %scalar ~]
      ['paneHeight' %urui %scalar ~]
      ['explorerWidth' %urui %scalar ~]
      ['explorerOpen' %urui %scalar ~]
      ['explorerView' %urui %scalar ~]
      ['explorerOrder' %urui %record ~]
      ['paneBands' %urui %record ~]
      ['panePaths' %urui %record ~]
      ['docsTabs' %urui %tabs ~]
      ['nextDocs' %urui %next ~]
      ['refTabs' %urui %tabs ~]
      ['nextRef' %urui %next ~]
      ['propertyTabs' %urui %tabs `%property]
      ['activePropertyTabId' %urui %active `%property]
      ['nextPropertyTab' %urui %next `%property]
      ['preferences.theme' %urui %scalar ~]
      ['preferences.layout' %urui %scalar ~]
      ['preferences.keybindings' %urui %scalar ~]
      ['resultOpen' %urui %scalar ~]
      ['fileTrees' %urui %record ~]
      ['clayContext' %app %record ~]
      ['runSelection' %app %scalar ~]
  ==
::
++  files
  ::  One document kind. Only /work is writable; examples, help and Clay
  ::  sources are read-only.
  ^-  files:urui
  :*  '/apps/quiz/files'
      :~  :*  name=%property
              noun='Document'
              untitled='Untitled'
              starter=starter
              :~  [/work ~[%hoon %md] ~ &]
                  [/examples ~[%hoon] ~ |]
                  [/props ~[%hoon] ~ |]
                  [/failing ~[%hoon] ~ |]
                  [/docs ~[%md] ~ |]
                  [/clay ~[%hoon] ~ |]
              ==
              preview=~
              actions=~[%open %save %save-as %copy %ref]
              refs=&
              share=~
          ==
      ==
      :~  [%work-files %property ~[/work]]
          [%example-files %property ~[/props /failing /examples]]
          [%doc-files %property ~[/docs]]
      ==
  ==
::
++  starter
  ::  A new document: the smallest passing property.
  ^-  @t
  %-  of-wain:format
  :~  '|%'
      '++  fate'
      '  |=  n=@ud'
      '  =(n (add 0 n))'
      '--'
  ==
::
++  file-policy
  ::  urui's policy plus the bare-path alias, Hoon stored as cord and
  ::  Markdown as mime, 512 KiB files, and quiz's virtual roots.
  ^-  policy:ufiles
  =/  policy  (make-policy:ufiles files /data/quiz |)
  %=  policy
    roots  (snoc roots.policy [~ ~[%hoon] ~ &])
    codecs  ~[[%hoon %cord] [%md %mime]]
    max-bytes  524.288
    locate  `locate:locations
  ==
::
++  pinned
  ::  A band pinned open, with no hide toggle.
  |=  [name=@tas item=band-item:urui]
  ^-  band:urui
  [name [~ & ''] item]
::
++  reference-pane
  ::  Explorer views: My documents, Examples, Documentation, Clay source.
  ^-  pane:urui
  :*  %reference  'explorer-pane'  'Quiz explorer'  %read-only  ~
      :~  %+  pinned  %tabs
          :-  %tabs
          :~  :*  %views  'Explorer'  %views  ~
                  :~  [%work-files 'My documents']
                      [%example-files 'Examples']
                      [%doc-files 'Documentation']
                      [%clay-source 'Clay source']
                  ==
                  ~  |  &
              ==
          ==
          (pinned %body [%panel 'explorer-body' ~ ~])
      ==
  ==
::
++  editor-pane
  ::  Document tabs, editor, source location and run controls.
  ^-  pane:urui
  :*  %editor  'editor-pane'  'Document editor'  %read-write  `%property
      :~  %+  pinned  %tabs
          :-  %tabs
          ~[[%document 'Documents' %documents `%property ~ `'New document' & &]]
          (pinned %head [%heading `'Document' `'source-status' ~])
          %+  pinned  %controls
          :-  %controls
          :~  ;button#editable-copy(type "button"): Open editable copy
              ;span#document-location
                =aria-live  "polite"
                ; New document
              ==
          ==
          %+  pinned  %run-controls
          [%controls ~[;div#run-controls;]]
          %+  pinned  %body
          :*  %panel  'editor-body'
              `['quiz-editor' 'Hoon source' 'ace/mode/hoon']  ~
          ==
      ==
  ==
::
++  result-pane
  ::  Run history and details; quiz-runs.js fills it.
  ^-  pane:urui
  :*  %result  'result-pane'  'Run results'  %read-only  ~
      :~  (pinned %head [%heading `'Run results' ~ ~])
          %+  pinned  %body
          :-  %panel
          :*  'result-body'  ~
              :~  ;div#quiz-runs;
                  ;p#quiz-error(role "alert", hidden "");
              ==
          ==
      ==
  ==
::
++  help
  ::  Fallback help when %docs is absent; the live docs load in place.
  ^-  marl
  :~  ;div#fallback-help-content
        ;p: Install %docs for the full Quiz help and reference.
        ;p: Documentation opens the shipped guide and reference as text.
        ;h2: Start here
        ;p: Examples has passing props, intentional failing cases and suites.
        ;p: Run 01-success with blank overrides; inspect 03-crash at zero.
        ;h2: Documents
        ;p: Use + for a new property. Open files from My documents or Examples.
        ;p: Save writes to this desk. Save As keeps another copy.
        ;p: Unsaved tabs and editor selections are restored in this browser.
        ;h2: Clay source
        ;p: Pick a desk and immutable revision to list its property documents.
        ;p: Read-only files can be opened as editable copies.
        ;h2: Runs
        ;p: Draft runs use the editor; saved runs use the pinned revision.
        ;p: After saving, choose Use latest revision for the saved version.
        ;p: Blank overrides use document conf. Read document conf previews it.
        ;p: Replay keeps seed and context. Rerun repeats the request.
        ;p: Counters come from the ship; stale results retain their source.
        ;h2: Shortcuts
        ::  from the same table the dispatcher reads, so the two cannot
        ::  disagree
        ;+  (shortcut-list:shell shortcuts)
        ;p: On macOS use Command for Ctrl.
        ;p
          ; Replay and cancel have no chord: they act on a selected run,
          ; not on the document.
        ==
        ;p: Ace supports search, undo, redo and optional Vim keys in Settings.
      ==
      ;div#docs-help-content.docs-help-content(hidden "")
        ;nav#docs-help-nav.docs-help-nav(aria-label "Quiz documentation")
          ;p: Loading documentation…
        ==
      ==
  ==
::
++  spec
  ::  The whole shell: header, panes, help, styles, scripts and Settings.
  ^-  shell-spec:urui
  =/  favicon-url=tape
    "/apps/quiz/favicon.png?v={(trip (scot %uv (mug favicon)))}"
  :*  config
      ~[;h1.app-title:"Quiz"]
      :~  ;nav.toolbar(aria-label "Quiz controls")
            ;+  settings-button:shell
            ;+  help-button:shell
          ==
      ==
      [reference-pane editor-pane result-pane]
      help  ~  ~[css]
      :~  '/apps/quiz/ace/ace.js'
          '/apps/quiz/ace/config.js'
          '/apps/quiz/ace/mode-hoon.js'
          '/apps/quiz/ace/theme-github.js'
          '/apps/quiz/ace/theme-monokai.js'
          '/apps/quiz/ace/ext-beautify.js'
          '/apps/quiz/ace/ext-prompt.js'
          '/apps/quiz/ace/ext-searchbox.js'
          '/apps/quiz/ace/ext-settings_menu.js'
          '/apps/quiz/app.js'
      ==
      ~[;link(rel "icon", type "image/png", href "{favicon-url}");]
      settings
  ==
::
++  settings
  ::  Ship-wide CPU time limits, appended to urui's Settings dialog.
  ::  quiz.js loads them from and saves them to %quiz when Settings closes.
  ^-  marl
  :~  ;fieldset#quiz-limits.settings-field
        ;legend.settings-label: Quiz CPU time limits (seconds)
        ;label.preference
          ;span: Property call
          ;input#quiz-limit-call(type "number", min "1", max "3600");
        ==
        ;label.preference
          ;span: Draft build
          ;input#quiz-limit-build(type "number", min "1", max "3600");
        ==
        ;label.preference
          ;span: Suite arm
          ;input#quiz-limit-arm(type "number", min "1", max "3600");
        ==
        ;p#quiz-limits-state(role "status"): Loading limits…
      ==
  ==
::
++  page
  ::  The workbench HTML.
  ^-  @t
  (crip (en-xml:html (build:shell spec)))
::
++  ace-config
  ::  Ace's loader configuration, from config's Ace spec.
  ^-  @t
  =/  cfg  config
  (config-js:uace ace-spec.cfg)
::
++  css
  ::  urui's shared styles, then quiz's own.
  ^-  @t
  %+  rap  3
  :~  (compose:ucss ~[%tokens %controls %shell %explorer %tabs %dialogs])
      '''
      #result-pane { flex-direction: column; }
      #result-pane > .pane-header {
        flex: 0 0 2.55rem;
        flex-wrap: nowrap;
        height: 2.55rem;
        min-height: 2.55rem;
        padding: 0 .75rem;
      }
      #result-collapse { height: 2.25rem; width: 2.25rem; }
      #settings-modal .settings-card > .settings-field {
        margin-top: 1rem;
      }
      #run-controls { display: grid; grid-template-columns: 1fr 1fr;
        gap: .5rem; padding: .75rem; flex: 0 0 auto; }
      #run-controls { width: 100%; }
      #run-controls label { font-size: .8rem; min-width: 0; }
      #run-controls input, #run-controls select { width: 100%; }
      #run-controls p, #run-toolbar { grid-column: 1 / -1; margin: 0; }
      #run-toolbar, #result-actions { display: flex; gap: .4rem;
        flex-wrap: wrap; }
      #run-source-note, #run-settings-note, #run-message {
        font-size: .8rem; white-space: pre-wrap; }
      #run-history { display: flex; gap: .3rem; flex-wrap: wrap;
        max-height: 9rem; overflow: auto; margin: .75rem 0; }
      #run-detail pre { white-space: pre-wrap; overflow-wrap: anywhere;
        max-height: 18rem; overflow: auto; font-size: .8rem; }
      #run-detail h2 { font-size: 1rem; }
      #run-detail h3 { font-size: .9rem; }
      #run-detail p, #runs-connection { font-size: .85rem; }
      #run-stale { font-weight: bold; }
      #run-controls [disabled] { opacity: .6; }
      #quiz-editor { height: 100%; min-height: 12rem; }
      #document-location { overflow-wrap: anywhere; color: var(--muted); }
      #clay-source-panel { padding: .75rem; overflow: auto; }
      #clay-source-panel label { display: block; margin: .5rem 0; }
      #clay-source-panel input, #clay-source-panel select { width: 100%; }
      #clay-files button { display: block; text-align: left; width: 100%; }
      #result-body { padding: 1rem; overflow: auto; }
      #quiz-error { color: var(--danger); white-space: pre-wrap; }
      '''
      (compose:ucss ~[%responsive])
  ==
::
++  javascript
  ::  The served app.js: config, urui runtime, runs view, client.
  ^-  @t
  (rap 3 ~[(emit:ucfg spec) core:ujs runs client])
--
