/-  app=quiz-app
/+  default-agent, web=quiz-web, codec=quiz-json, build=quiz-build
/+  suite=quiz-suite, engine=quiz-engine
/+  uhttp=urui-http, ufiles=urui-files, qfiles=quiz-files
/*  docs-toc  %toc  /doc/toc
/*  favicon  %png  /favicon/png
/*  quiz-tile  %png  /quiz/png
/*  ace-hoon  %js  /web/ace/mode-hoon/js
/*  ace-core  %js  /web/ace/ace/js
/*  ace-light  %js  /web/ace/theme-github/js
/*  ace-dark  %js  /web/ace/theme-monokai/js
/*  ace-beaut  %js  /web/ace/ext-beautify/js
/*  ace-prompt  %js  /web/ace/ext-prompt/js
/*  ace-search  %js  /web/ace/ext-searchbox/js
/*  ace-sets  %js  /web/ace/ext-settings-menu/js
/*  ace-vim  %js  /web/ace/keybinding-vim/js
/*  ace-lic  %txt  /web/ace/license/txt
|%
+$  card  card:agent:gall
+$  task
  $%  [%poke ~]
      [%run ~]
      [%suite doc=document:suite]
      $:  %conf  doc=prepared:build  saved=?
          todo=(list [ship desk (unit rave:clay)])
          replies=(list riot:clay)
      ==
  ==
+$  pending  [id=@ta until=@da task=task]
+$  state
  [files=(unit pending:ufiles) api=(unit pending)]
::
++  assets
  ^-  (list [suffix=@t asset=asset:uhttp])
  =/  js  'text/javascript; charset=utf-8'
  =/  plain  'text/plain; charset=utf-8'
  =/  texts=(list [@t @t @t])
    :~  ['' 'text/html; charset=utf-8' page:web]
        ['/' 'text/html; charset=utf-8' page:web]
        ['/app.js' js javascript:web]
        ['/doc.toc' plain docs-toc]
        ['/ace/ace.js' js ace-core]
        ['/ace/config.js' js ace-config:web]
        ['/ace/mode-hoon.js' js ace-hoon]
        ['/ace/theme-github.js' js ace-light]
        ['/ace/theme-monokai.js' js ace-dark]
        ['/ace/ext-beautify.js' js ace-beaut]
        ['/ace/ext-prompt.js' js ace-prompt]
        ['/ace/ext-searchbox.js' js ace-search]
        ['/ace/ext-settings_menu.js' js ace-sets]
        ['/ace/keybinding-vim.js' js ace-vim]
        ['/ace/license.txt' plain (of-wain:format ace-lic)]
    ==
  :-  ['/favicon.png' 'image/png' (as-octs:mimes:html favicon)]
  :-  ['/quiz.png' 'image/png' (as-octs:mimes:html quiz-tile)]
  %+  turn  texts
  |=  [suffix=@t kind=@t body=@t]
  [suffix kind (as-octs:mimes:html body)]
::
++  reply
  |=  [id=@ta status=@ud body=json]
  ^-  (list card)
  =/  payload
    %:  respond:uhttp
      status
      'application/json; charset=utf-8'
      (as-octs:mimes:html (en:json:html body))
    ==
  =.  headers.response-header.payload
    :~  ['content-type' 'application/json; charset=utf-8']
        ['cache-control' 'no-store']
        ['x-content-type-options' 'nosniff']
    ==
  (give:uhttp id payload)
::
++  refuse
  |=  [id=@ta status=@ud code=@t]
  ^-  (list card)
  (reply id status (pairs:enjs:format ~[['error' s+code]]))
::
++  private-cards
  ::  Eyre guests need response watches for public assets and 401s.
  ::  Remove foreign watchers of private responses before emitting facts.
  |=  [bol=bowl:gall cards=(list card)]
  ^-  (list card)
  =/  kicks=(list card)
    %+  murn  ~(val by sup.bol)
    |=  [who=ship watched=path]
    ^-  (unit card)
    ?:  =(who our.bol)  ~
    ?.  %+  lien  cards
        |=  c=card
        ?.  ?=([%give %fact * *] c)  |
        (lien paths.p.c |=(p=path =(p watched)))
      ~
    `[%give %kick ~[watched] `who]
  (weld kicks cards)

::
++  conf-response
  |=  [id=@ta got=result:build]
  ^-  (list card)
  ?:  ?=(%invalid -.got)
    (reply id 422 (diagnostic-out:codec +.got))
  %+  reply  id
  :-  200
  %-  pairs:enjs:format
  :~  ['context' (context-out:codec where.got)]
      ['config' (config-out:codec config.settings.got)]
      ['seed' ?~(seed.settings.got ~ s+(scot %uv u.seed.settings.got))]
  ==

--
=|  state
=*  state  -
|_  bowl=bowl:gall
+*  this  .
    def   ~(. (default-agent this %n) bowl)
::
++  on-init
  ^-  (quip card _this)
  [~[[%pass /eyre/connect %arvo %e %connect `/apps/quiz dap.bowl]] this]
::
++  on-save
  ::  Neither Clay requests nor HTTP response ducts survive reload.
  ^-  vase
  !>([%0 ~])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  saved  !<([%0 ~] old)
  on-init:this(state [~ ~])
::
++  on-poke
  |=  [mark=mark vase=vase]
  ^-  (quip card _this)
  ?:  =(%quiz-admitted mark)
    ?>  =(src.bowl our.bowl)
    =/  [ticket=@ta admitted=@ud]  !<([@ta @ud] vase)
    =/  current  api.state
    ?~  current  `this
    ?.  &(=(ticket id.u.current) ?=(%run -.task.u.current))  `this
    =/  body
      %-  pairs:enjs:format
      ~[['accepted' b+&] ['id' (decimal:codec admitted)]]
    :_  this(api.state ~)
    :-  [%pass /quiz-http/[ticket] %arvo %b %rest until.u.current]
    (private-cards bowl (reply ticket 202 body))
  ?.  =(%handle-http-request mark)
    ?>  =(src.bowl our.bowl)
    (on-poke:def mark vase)
  |^
  =/  [id=@ta req=inbound-request:eyre]
    !<([@ta inbound-request:eyre] vase)
  =/  raw  (trip url.request.req)
  =/  query  (find "?" raw)
  =/  url  ?~(query url.request.req (crip (scag u.query raw)))
  =/  asset  (asset-route:uhttp '/apps/quiz' url assets)
  ?^  asset
    ?.  =(%'GET' method.request.req)
      [(refuse id 405 'method-not-allowed') this]
    [(give:uhttp id (respond:uhttp 200 u.asset)) this]
  ?.  &(authenticated.req =(src.bowl our.bowl))
    [(refuse id 401 'authentication-required') this]
  =/  handled  (private-http id req url)
  [(private-cards bowl -.handled) +.handled]
::
++  private-http
  |=  [id=@ta req=inbound-request:eyre url=@t]
  ^-  (quip card _this)
  ?.  |(=('/apps/quiz/api' url) =('/apps/quiz/files' url))
    [(refuse id 404 'not-found') this]
  ?.  =(%'POST' method.request.req)
    [(refuse id 405 'method-not-allowed') this]
  ?~  body.request.req  [(refuse id 400 'missing-body') this]
  =/  body  u.body.request.req
  ?:  |((gth p.body max-body:codec) (gth (met 3 q.body) max-body:codec))
    [(refuse id 413 'payload-too-large') this]
  ?.  =(p.body (met 3 q.body))
    [(refuse id 400 'body-length') this]
  ?.  (json-type:ufiles header-list.request.req)
    [(refuse id 415 'content-type') this]
  ?:  =('/apps/quiz/files' url)
    =^  cards  files.state
      (handle:qfiles file-policy:web bowl id req files.state)
    [cards this]
  =/  parsed  (de:json:html q.body)
  ?~  parsed  [(refuse id 400 'malformed-json') this]
  =/  cmd  (decode:codec u.parsed)
  ?~  cmd  [(refuse id 400 'invalid-command') this]
  (dispatch id u.cmd)
::
++  ids
  ^-  (list @ud)
  .^((list @ud) %gx /(scot %p our.bowl)/quiz/(scot %da now.bowl)/runs/noun)
::
++  dispatch
  |=  [id=@ta cmd=command:codec]
  ^-  (quip card _this)
  ?-  -.cmd
    %runs
      :_  this
      %:  reply  id  200
        (pairs:enjs:format ~[['ids' a+(turn ids decimal:codec)]])
      ==
    %status
      ?.  (lien ids |=(n=@ud =(n id.cmd)))
        [(refuse id 404 'run-not-found') this]
      =/  path=path
        /(scot %p our.bowl)/quiz/(scot %da now.bowl)/run/(scot %ud id.cmd)/noun
      [(reply id 200 (record-out:codec .^(record:app %gx path))) this]
    %cancel  (submit id [%cancel id.cmd])
    %replay
      =/  req=request:app
        [[%draft ''] %quiz [%ud 1] ~ ~ `id.cmd]
      (submit id [%run req])
    %run  (submit id [%run +.cmd])
    %document-conf
      ?:  !=(~ api.state)  [(refuse id 503 'api-busy') this]
      ?:  ?=(%suite -.source.cmd)
        [(refuse id 400 'property-required') this]
      =/  ctx  (pin:build our.bowl desk.cmd revision.cmd now.bowl)
      ?:  ?=(%.n -.ctx)
        [(reply id 422 (diagnostic-out:codec p.ctx)) this]
      =/  doc
        ?:  ?=(%draft -.source.cmd)
          (prepare:build p.ctx /draft/hoon text.source.cmd)
        (prepare-file:build p.ctx path.source.cmd)
      ?:  ?=(%.n -.doc)
        [(reply id 422 (diagnostic-out:codec p.doc)) this]
      =/  saved  ?=(%file -.source.cmd)
      =/  todo=(list [ship desk (unit rave:clay)])
        ?:(saved ~[(saved-request:build p.doc)] (draft-requests:build p.doc))
      ?~  todo
        [(conf-response id (draft:build p.doc ~)) this]
      =/  until  (add now.bowl ~s30)
      :_  this(api.state `[id until [%conf p.doc saved t.todo ~]])
      :~  [%pass /quiz-http/[id] %arvo %c %warp i.todo]
          [%pass /quiz-http/[id] %arvo %b %wait until]
      ==
    %contexts
      =/  desks
        .^((set @tas) %cd [(scot %p our.bowl) %$ (scot %da now.bowl) ~])
      =/  found=(list json)
        %+  murn  ~(tap in desks)
        |=  desk=@tas
        ^-  (unit json)
        =/  got  (pin:build our.bowl desk [%da now.bowl] now.bowl)
        ?:(?=(%.y -.got) `(context-out:codec p.got) ~)
      :_  this
      %+  reply  id
      :-  200
      %-  pairs:enjs:format
      :~  ['contexts' a+found]
          ['defaults' (config-out:codec defaults:engine)]
          ['engine-version' s+version:engine]
      ==
    %suite-arms
      ?:  !=(~ api.state)  [(refuse id 503 'api-busy') this]
      =/  ctx  (pin:build our.bowl desk.cmd revision.cmd now.bowl)
      ?:  ?=(%.n -.ctx)
        [(reply id 422 (diagnostic-out:codec p.ctx)) this]
      =/  doc  (prepare-file:suite p.ctx path.cmd ~)
      ?:  ?=(%.n -.doc)
        [(reply id 422 (diagnostic-out:codec p.doc)) this]
      =/  until  (add now.bowl ~s30)
      :_  this(api.state `[id until [%suite p.doc]])
      :~  [%pass /quiz-http/[id] %arvo %c %warp (request:suite p.doc)]
          [%pass /quiz-http/[id] %arvo %b %wait until]
      ==
  ==
::
++  submit
  |=  [id=@ta act=action:app]
  ^-  (quip card _this)
  ?:  !=(~ api.state)  [(refuse id 503 'api-busy') this]
  =/  until  (add now.bowl ~s30)
  ?:  ?=(%run -.act)
    :_  this(api.state `[id until [%run ~]])
    :~  :*  %pass  /quiz-http/[id]  %agent  [our.bowl %quiz]
            %poke  %quiz-submit  !>([id +.act])
        ==
        [%pass /quiz-http/[id] %arvo %b %wait until]
    ==
  :_  this(api.state `[id until [%poke ~]])
  :~  :*  %pass  /quiz-http/[id]  %agent  [our.bowl %quiz]
          %poke  %quiz-action  !>(act)
      ==
      [%pass /quiz-http/[id] %arvo %b %wait until]
  ==
--
::
++  on-agent
  |=  [wire=wire sign=sign:agent:gall]
  ^-  (quip card _this)
  =/  current  api.state
  ?~  current  `this
  =/  pending  u.current
  ?.  &(?=([%quiz-http @ ~] wire) =(i.t.wire id.pending))  `this
  ?.  &(?=(?(%poke %run) -.task.pending) ?=(%poke-ack -.sign))  `this
  ?:  &(?=(%run -.task.pending) =(~ p.sign))  `this
  =/  response=(list card)
    ?~  p.sign
      (reply id.pending 202 (pairs:enjs:format ~[['accepted' b+&]]))
    (refuse id.pending 422 'action-rejected')
  :_  this(api.state ~)
  :-  [%pass wire %arvo %b %rest until.pending]
  (private-cards bowl response)
::
++  on-arvo
  |=  [wire=wire sign=sign-arvo]
  ^-  (quip card _this)
  =/  taken
    (take:ufiles file-policy:web bowl wire sign files.state)
  ?^  taken
    =.  files.state  next.u.taken
    [(private-cards bowl cards.u.taken) this]
  ?.  ?=([%quiz-http @ ~] wire)  `this
  =/  current  api.state
  ?~  current  `this
  =/  pending  u.current
  ?.  =(i.t.wire id.pending)  `this
  ?:  ?=([%behn %wake *] sign)
    :_  this(api.state ~)
    =/  cards  (private-cards bowl (refuse id.pending 504 'api-timeout'))
    ?.  ?=(?(%suite %conf) -.task.pending)  cards
    =/  ctx=context:build
      ?-  -.task.pending
        %suite  where.doc.task.pending
        %conf   where.doc.task.pending
      ==
    [[%pass wire %arvo %c %warp our.ctx desk.ctx ~] cards]
  ?:  &(?=(%conf -.task.pending) ?=([%clay %writ *] sign))
    =/  work  task.pending
    =/  replies  (snoc replies.work +>.sign)
    =/  todo  todo.work
    ?^  todo
      =/  next  work(todo t.todo, replies replies)
      :_  this(api.state `[id.pending until.pending next])
      ~[[%pass wire %arvo %c %warp i.todo]]
    =/  got
      ?:  saved.work  (take-saved:build doc.work +>.sign)
      (draft:build doc.work replies)
    :_  this(api.state ~)
    :-  [%pass wire %arvo %b %rest until.pending]
    (private-cards bowl (conf-response id.pending got))
  ?.  &(?=(%suite -.task.pending) ?=([%clay %writ *] sign))  `this
  =/  got  (take-built:suite doc.task.pending +>.sign)
  =/  response=(list card)
    ?:  ?=(%invalid -.got)
      (reply id.pending 422 (diagnostic-out:codec +.got))
    %+  reply  id.pending
    :-  200
    %-  pairs:enjs:format
    :~  ['context' (context-out:codec where.doc.got)]
        ['arms' a+(turn available.got |=(name=term s+name))]
    ==
  :_  this(api.state ~)
  :-  [%pass wire %arvo %b %rest until.pending]
  (private-cards bowl response)
::
++  on-watch
  ::  Eyre uses a guest identity for anonymous HTTP, even on a fake ship.
  |=  path=path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%http-response @ ~]  `this
  ==
::
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-fail   on-fail:def
--
