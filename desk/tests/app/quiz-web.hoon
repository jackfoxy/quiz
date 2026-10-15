/-  app=quiz-app
/+  *test, codec=quiz-json, web=quiz-web, engine=quiz-engine
/=  agent  /lib/quiz-web-agent
/=  packaged  /app/quiz-web
|%
::
++  bol
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    src  ~zod
    dap  %quiz-web
    byk  [~zod %quiz %da ~2026.10.15]
    now  ~2026.10.15
  ==
::
++  request
  |=  [method=method:http url=@t body=(unit octs)]
  ^-  inbound-request:eyre
  %*  .  *inbound-request:eyre
    authenticated  &
    request
      %*  .  *request:http
        method  method
        url  url
        body  body
        header-list  ~[['content-type' 'application/json']]
      ==
  ==
::
++  poke
  |=  req=inbound-request:eyre
  (on-poke:~(. agent bol) %handle-http-request !>(['request' req]))
::
++  api
  |=  body=@t
  (poke (request %'POST' '/apps/quiz/api' `(as-octs:mimes:html body)))
::
++  status
  |=  cards=(list card:agent:gall)
  ^-  @ud
  =/  found  (skim cards |=(c=card:agent:gall ?=([%give %fact * *] c)))
  ?>  ?=(^ found)
  =/  card  i.found
  ?>  ?=([%give %fact * %http-response-header *] card)
  status-code:!<(response-header:http q.cage.p.card)
::
++  response-body
  |=  cards=(list card:agent:gall)
  ^-  @t
  =/  found
    %+  skim  cards
    |=(c=card:agent:gall ?=([%give %fact * %http-response-data *] c))
  ?>  ?=(^ found)
  =/  card  i.found
  ?>  ?=([%give %fact * %http-response-data *] card)
  q:(need !<((unit octs) q.cage.p.card))
::
++  test-bind-and-reload
  ^-  tang
  =/  a  ~(. agent bol)
  =/  initial  on-init.a
  =/  loaded  (on-load.a !>([%0 ~]))
  =/  pending  a(api.state `['request' ~2026.10.15 [%poke ~]])
  ;:  weld
    (expect !>(=(-.initial -.loaded)))
    (expect-eq !>([%0 ~]) on-save.pending)
    (expect-eq !>(~) !>(api.state:+.loaded))
  ==
::
++  test-remote-poke-denied
  ^-  tang
  =/  bowl  bol
  %-  expect-fail
  |.  (on-poke:~(. agent bowl(src ~nec)) %handle-http-request !>(~))
::
++  test-guest-watch-and-forged-auth
  ^-  tang
  =/  bowl  bol
  =/  a  ~(. agent bowl(src ~nec))
  =/  watched  (on-watch.a /http-response/request)
  =/  req  (request %'POST' '/apps/quiz/api' `[2 '{}'])
  =/  got  (on-poke.a %handle-http-request !>(['request' req]))
  ;:  weld
    (expect-eq !>(~) !>(-.watched))
    (expect-eq !>(401) !>((status -.got)))
  ==
::
++  test-assets-public
  ^-  tang
  =/  urls=(list @t)
    :~  '/apps/quiz'  '/apps/quiz/'  '/apps/quiz/app.js?x=1'
        '/apps/quiz/doc.toc'  '/apps/quiz/favicon.png'
        '/apps/quiz/ace/ace.js'  '/apps/quiz/ace/theme-github.js'
        '/apps/quiz/ace/theme-monokai.js'
        '/apps/quiz/ace/ext-beautify.js'  '/apps/quiz/ace/ext-prompt.js'
        '/apps/quiz/ace/ext-searchbox.js'
        '/apps/quiz/ace/ext-settings_menu.js'
        '/apps/quiz/ace/keybinding-vim.js'  '/apps/quiz/ace/license.txt'
    ==
  %-  zing
  %+  turn  urls
  |=  url=@t
  ^-  tang
  =/  req  (request %'GET' url ~)
  =/  got  (poke req(authenticated |))
  (expect-eq !>(200) !>((status -.got)))
::
++  test-auth-before-method-body-and-path
  ^-  tang
  =/  urls  ~['/apps/quiz/api' '/apps/quiz/files' '/apps/quiz/nope']
  %-  zing
  %+  turn  urls
  |=  url=@t
  ^-  tang
  =/  req  (request %'GET' url ~)
  =/  got  (poke req(authenticated |))
  (expect-eq !>(401) !>((status -.got)))
::
++  test-method-and-exact-routes
  ^-  tang
  =/  cases=(list [method=method:http url=@t code=@ud])
    :~  [%'GET' '/apps/quiz/api' 405]
        [%'GET' '/apps/quiz/files' 405]
        [%'POST' '/apps/quiz/app.js' 405]
        [%'GET' '/apps/quiz/app.js/nope' 404]
        [%'POST' '/apps/quiz/api/' 404]
        [%'POST' '/apps/quiz/files/nope' 404]
    ==
  %-  zing
  %+  turn  cases
  |=  [method=method:http url=@t code=@ud]
  ^-  tang
  =/  got  (poke (request method url ~))
  (expect-eq !>(code) !>((status -.got)))
::
++  test-body-bound-and-length
  ^-  tang
  =/  a  (poke (request %'POST' '/apps/quiz/api' `[524.289 0]))
  =/  b  (poke (request %'POST' '/apps/quiz/api' `[1 0]))
  =/  c  (poke (request %'POST' '/apps/quiz/files' `[0 (bex 4.194.304)]))
  ;:  weld
    (expect-eq !>(413) !>((status -.a)))
    (expect-eq !>(400) !>((status -.b)))
    (expect-eq !>(413) !>((status -.c)))
  ==
::
++  test-content-type
  ^-  tang
  =/  req  (request %'POST' '/apps/quiz/api' `[2 '{}'])
  =/  got  (poke req(header-list.request ~))
  (expect-eq !>(415) !>((status -.got)))
::
++  test-invalid-api-input
  ^-  tang
  =/  bodies=(list @t)
    :~  ''  '{'  'null'  '[]'  '{}'  '{"op":"unknown"}'
        '{"op":"status","id":-1}'
        '{"op":"status","id":1.5}'
        '{"op":"status","id":"1e3"}'
        '{"op":"run","source":{"kind":"other"}}'
    ==
  %-  zing
  %+  turn  bodies
  |=  body=@t
  ^-  tang
  =/  got  (api body)
  (expect-eq !>(400) !>((status -.got)))
::
++  test-files-path-validation
  ^-  tang
  =/  text  '{"op":"load","path":["..","escape","hoon"]}'
  =/  got
    (poke (request %'POST' '/apps/quiz/files' `(as-octs:mimes:html text)))
  (expect-eq !>(400) !>((status -.got)))
::
++  test-submit-ack-and-error
  ^-  tang
  =/  started  (api '{"op":"cancel","id":"3"}')
  =/  a  +.started
  =/  success  (on-agent.a /quiz-http/request [%poke-ack ~])
  =/  failure
    (on-agent.a /quiz-http/request [%poke-ack `~[[%leaf "no"]]])
  ;:  weld
    (expect-eq !>(2) !>((lent -.started)))
    (expect-eq !>(202) !>((status -.success)))
    (expect-eq !>(422) !>((status -.failure)))
    (expect-eq !>(~) !>(api.state:+.success))
    (expect-eq !>('{"accepted":true}') !>((response-body -.success)))
  ==
::
++  test-busy-timeout-and-stale-reply
  ^-  tang
  =/  started  (api '{"op":"cancel","id":"3"}')
  =/  a  +.started
  =/  req
    %:  request  %'POST'  '/apps/quiz/api'
      `(as-octs:mimes:html '{"op":"cancel","id":"4"}')
    ==
  =/  busy  (on-poke.a %handle-http-request !>(['other' req]))
  =/  late  (on-agent.a /quiz-http/other [%poke-ack ~])
  =/  timeout  (on-arvo.a /quiz-http/request [%behn %wake ~])
  =/  finished  +.timeout
  =/  stale  (on-agent.finished /quiz-http/request [%poke-ack ~])
  ;:  weld
    (expect-eq !>(503) !>((status -.busy)))
    (expect-eq !>(~) !>(-.late))
    (expect-eq !>(504) !>((status -.timeout)))
    (expect-eq !>(~) !>(api.state:+.timeout))
    (expect-eq !>(~) !>(-.stale))
  ==
::
++  test-config-round-trip
  ^-  tang
  =/  got  (config-in:codec (config-out:codec defaults:engine))
  (expect-eq !>(defaults:engine) !>(got))
::
++  test-decimal-precision
  ^-  tang
  =/  n  9.007.199.254.740.993
  =/  encoded  (decimal:codec n)
  ;:  weld
    (expect-eq !>(s+'9007199254740993') !>(encoded))
    (expect-eq !>(n) !>((natural:codec encoded)))
  ==
::
++  test-json-escape-round-trip
  ^-  tang
  =/  raw=@t  (crip "<script>\"&\0a</script>")
  =/  encoded  (sample-out:codec [42 raw])
  =/  decoded  (need (de:json:html (en:json:html encoded)))
  (expect-eq !>(encoded) !>(decoded))
::
++  test-page-text-escaped
  ^-  tang
  =/  spec  spec:web
  =/  tag  ;p:"<script>alert(1)</script>"
  =.  brand.spec  ~[tag]
  =/  html  (crip (en-xml:html (build:shell:web spec)))
  (expect !>(?=(^ (find "&lt;script&gt;" (trip html)))))
::
++  test-private-response-excludes-foreign-watchers
  ^-  tang
  =/  bowl  bol
  =.  sup.bowl
    %-  malt
    :~  [~[/foreign] [~nec /http-response/request]]
        [~[/local] [~zod /http-response/request]]
        [~[/unrelated] [~bud /http-response/other]]
    ==
  =/  a  ~(. agent bowl)
  =/  req  (request %'POST' '/apps/quiz/api' `[2 '{}'])
  =/  got  (on-poke.a %handle-http-request !>(['request' req]))
  ?>  ?=(^ -.got)
  =/  first  i.-.got
  =/  expected=card:agent:gall
    [%give %kick ~[/http-response/request] `~nec]
  (expect-eq !>(expected) !>(first))
::
++  test-suite-reply-timeout-and-stale-wire
  ^-  tang
  =/  a  ~(. agent bol)
  =/  doc=document:suite:codec
    [[~zod %quiz 1] /tests/example/hoon '' ~]
  =.  a  a(api.state `['request' ~2026.10.15 [%suite doc]])
  =/  bad  (on-arvo.a /quiz-http/request [%clay %writ ~])
  =/  late  (on-arvo.a /quiz-http/other [%clay %writ ~])
  =/  timeout  (on-arvo.a /quiz-http/request [%behn %wake ~])
  ;:  weld
    (expect-eq !>(422) !>((status -.bad)))
    (expect-eq !>(~) !>(api.state:+.bad))
    (expect-eq !>(~) !>(-.late))
    (expect-eq !>(504) !>((status -.timeout)))
    (expect-eq !>(4) !>((lent -.timeout)))
  ==
::
++  test-file-wire-timeout-and-reload
  ^-  tang
  =/  a  ~(. agent bol)
  =/  held=pending:ufiles:web
    ['request' 'change' %save /example/hoon `'text' ~2026.10.15]
  =.  a  a(files.state `held)
  =/  got  (on-arvo.a /urui-files/change/timeout [%behn %wake ~])
  =/  loaded  (on-load.a on-save.a)
  ;:  weld
    (expect-eq !>(504) !>((status -.got)))
    (expect-eq !>(~) !>(files.state:+.got))
    (expect-eq !>(~) !>(files.state:+.loaded))
  ==
--
