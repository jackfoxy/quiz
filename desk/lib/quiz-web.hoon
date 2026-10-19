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
  ^-  app-config:urui
  :*  [%quiz 'Quiz' '/apps/quiz' 'quiz.session' 2]
      [350 150 180 10 25 70 262.144]
      slots
      :~  ['Ctrl-S' 'save:property' %always]
          ['Ctrl-Shift-S' 'save-as:property' %always]
          ['Ctrl-O' 'open:property' %always]
      ==
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
++  slots
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
  ^-  files:urui
  :*  '/apps/quiz/files'
      :~  :*  %property  'Document'  'Untitled'  starter
              :~  [/work ~[%hoon %md] ~ &]
                  [/examples ~[%hoon] ~ |]
                  [/props ~[%hoon] ~ |]
                  [/failing ~[%hoon] ~ |]
                  [/docs ~[%md] ~ |]
                  [/clay ~[%hoon] ~ |]
              ==
              ~  ~[%open %save %save-as %ref]  &  ~
          ==
      ==
      :~  [%work-files %property ~[/work]]
          [%example-files %property ~[/props /failing /examples]]
          [%doc-files %property ~[/docs]]
      ==
  ==
::
++  starter
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
  |=  [name=@tas item=band-item:urui]
  ^-  band:urui
  [name [~ & ''] item]
::
++  reference-pane
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
        ;p: Select a desk and an immutable revision, then browse Hoon files.
        ;p: Read-only files can be opened as editable copies.
        ;h2: Runs
        ;p: Draft runs use the editor; saved runs use the pinned revision.
        ;p: After saving, choose Use latest revision for the saved version.
        ;p: Blank overrides use document conf. Read document conf previews it.
        ;p: Replay keeps seed and context. Rerun repeats the request.
        ;p: Counters come from the ship; stale results retain their source.
        ;h2: Shortcuts
        ;p: Ctrl-S saves; Ctrl-Shift-S saves as; Ctrl-O opens a document.
        ;p: On macOS use Command. Run, replay and cancel have no shortcuts.
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
  ^-  shell-spec:urui
  =/  favicon-url=tape
    "/apps/quiz/favicon.png?v={(trip (scot %uv (mug favicon)))}"
  :*  config
      ~[;h1.app-title:"Quiz"]
      ~[;button#help(type "button", aria-expanded "false"):"Help"]
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
  ==
::
++  page
  ^-  @t
  (crip (en-xml:html (build:shell spec)))
::
++  ace-config
  ^-  @t
  =/  cfg  config
  (config-js:uace ace-spec.cfg)
::
++  css
  ^-  @t
  %+  rap  3
  :~  (compose:ucss ~[%tokens %controls %shell %explorer %tabs %dialogs])
      '''
      #result-pane { flex-direction: column; }
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
  ^-  @t
  (rap 3 ~[(emit:ucfg spec) core:ujs runs client])
--
