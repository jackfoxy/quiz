/-  urui
/+  shell=urui-shell, ucfg=urui-config, ujs=urui-js, ufiles=urui-files
|%
  ::  Minimal compiled shell. The workbench is introduced in Unit 9.
  ::
++  config
  ^-  app-config:urui
  :*  [%quiz 'Quiz' '/apps/quiz' 'quiz.session' 1]
      [350 150 180 10 25 70 262.144]
      ~  ~  ~[[%ready 'Ready']]
      `'/docs/d/quiz/'
      :*  '/apps/quiz/ace'  'quizAceAssets'  '1.44.0'
          'ace/mode/text'  'ace/theme/github'  'ace/theme/monokai'  ~  |
      ==
      %columns  |  ~  ~
  ==
::
++  file-policy
  ::  Text-backed Hoon documents under /data/quiz only.
  ^-  policy:ufiles
  =/  files=files:urui
    :*  '/apps/quiz/files'
        :~  :*  %property  'Property'  'Untitled'  ''
                ~[[~ ~[%hoon] ~ &]]
                ~  ~[%open %save %save-as]  |  ~
            ==
        ==
        ~
    ==
  =/  policy  (make-policy:ufiles files /data/quiz |)
  policy(codecs ~[[%hoon %cord]], max-bytes 524.288)
::
++  pane
  |=  [role=pane-role:urui id=@t title=@t]
  ^-  pane:urui
  :*  role  id  title  %read-only  ~
      :~  [%tabs [~ & ''] [%tabs ~[[%main title %fixed ~ ~ ~ | |]]]]
          :*  %body  [~ & '']  %panel  (cat 3 id '-body')  ~
              ~[;p:"{(trip title)}"]
          ==
      ==
  ==
::
++  spec
  ^-  shell-spec:urui
  :*  config
      ~[;h1:"Quiz"]
      ~[;span#quiz-status:"Ready"]
      :*  (pane %reference 'reference' 'Property testing')
          (pane %editor 'editor' 'Quiz HTTP API is ready.')
          (pane %result 'result' 'Run controls arrive with the workbench.')
      ==
      ~[;p:"Install %docs to read the Quiz documentation."]
      ~
      ~['body { font: 16px system-ui; margin: 2rem; }']
      ~['/apps/quiz/app.js']
      ~
  ==
::
++  page
  ^-  @t
  (crip (en-xml:html (build:shell spec)))
::
++  javascript
  ^-  @t
  %+  rap  3
  :~  (emit:ucfg spec)
      core:ujs
      '''
      window.urui.boot({
        onReady() {
          document.getElementById('quiz-status').textContent = 'Ready';
        }
      });
      '''
  ==
--
