/-  app=quiz-app
/+  default-agent, job=quiz-job, engine=quiz-engine
/+  build=quiz-build, suite=quiz-suite, replay=quiz-replay
::  Gall adapter: pinned Clay builds and publication around the pure job core.
::
=+  state=initial:job
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    ops
      |%
      ::
      ++  parse-id
        |=  text=@ta
        ^-  (unit run-id:app)
        =/  parsed  (slaw %ud text)
        ?~  parsed  ~
        ?.  &((gth u.parsed 0) =(text (scot %ud u.parsed)))  ~
        parsed
      ::
      ++  begin
        ::  Pin once at activation; all source/import reads share this revision.
        |=  [s=state:job id=run-id:app]
        ^-  (quip card:agent:gall state:job)
        =/  rec  (~(got by records.saved.s) id)
        =/  req  request.rec
        =/  pinned  (pin:build our.bowl desk.req revision.req now.bowl)
        ?:  ?=(%.n -.pinned)
          [~ (finish:job s id [%invalid p.pinned] now.bowl)]
        =/  source  source.req
        =/  read
          ?-  -.source
            %draft
              =/  saved  replay.rec
              =/  path  ?~(saved /draft/hoon path.u.saved)
              (prepare:suite p.pinned path text.source ~)
            %file  (prepare-file:suite p.pinned path.source ~)
            %suite  (prepare-file:suite p.pinned path.source arms.source)
          ==
        ?:  ?=(%.n -.read)
          [~ (finish:job s id [%invalid p.read] now.bowl)]
        =/  raw  p.read
        =.  rec
          rec(snapshot `[where.raw path.raw source.raw (shax source.raw)])
        =.  s  s(records.saved (~(put by records.saved.s) id rec))
        ?:  ?=(%suite -.source)
          (send-build s(active `[id [%suite-build raw]]) (request:suite raw))
        =/  prepared
          =/  saved  replay.rec
          ?^  saved  (resolve:replay our.bowl now.bowl u.saved)
          (prepare:build where.raw path.raw source.raw)
        ?:  ?=(%.n -.prepared)
          [~ (finish:job s id [%invalid p.prepared] now.bowl)]
        =/  doc  p.prepared
        ?:  ?=(%file -.source)
          (send-build s(active `[id [%file doc]]) (saved-request:build doc))
        =/  requests  (draft-requests:build doc)
        ?~  requests  (property-ready s id doc (draft:build doc ~))
        (send-build s(active `[id [%draft doc t.requests ~]]) i.requests)
      ::
      ++  send-build
        |=  [s=state:job request=[ship desk (unit rave:clay)]]
        ^-  (quip card:agent:gall state:job)
        =/  token  next-token.saved.s
        :_  s(next-token.saved +(token), build-token `token)
        ~[[%pass /quiz/build/(scot %ud token) %arvo %c %warp request]]
      ::
      ++  property-ready
        |=  [s=state:job id=run-id:app doc=prepared:build built=result:build]
        ^-  (quip card:agent:gall state:job)
        ?:  ?=(%invalid -.built)
          [~ (finish:job s id built now.bowl)]
        =/  rec  (~(got by records.saved.s) id)
        =/  override  config.request.rec
        =/  cfg  ?~(override config.settings.built u.override)
        =/  override-seed  seed.request.rec
        =/  seed
          ?^  override-seed  u.override-seed
          =/  doc-seed  seed.settings.built
          ?~(doc-seed (need seed.rec) u.doc-seed)
        =/  captured  (capture:replay doc seed cfg)
        ?:  ?=(%.n -.captured)
          [~ (finish:job s id [%invalid p.captured] now.bowl)]
        =.  rec
          %=  rec
            replay  `p.captured
            seed  `seed
            config  `cfg
            status  %running
            updated  now.bowl
          ==
        :-  ~
        %=  s
          active  `[id [%property (init:engine seed cfg parts.built)]]
          records.saved  (~(put by records.saved.s) id rec)
        ==
      ::
      ++  publish
        ::  Notify both subscriptions of changes, then schedule one wake.
        |=  [old=state-0:app next=state:job cards=(list card:agent:gall)]
        ^-  (quip card:agent:gall _this)
        =/  changes=(list card:agent:gall)
          %+  roll  ~(tap by records.saved.next)
          |=  [[id=run-id:app rec=record:app] out=(list card:agent:gall)]
          =/  was  (~(get by records.old) id)
          ?:  =(was `rec)  out
          :_  out
          :*  %give  %fact  ~[/runs /run/(scot %ud id)]
              %quiz-update  !>(`update:app`[%run rec])
          ==
        =.  cards  (weld changes cards)
        =/  removed=(list card:agent:gall)
          %+  roll  order.old
          |=  [id=run-id:app out=(list card:agent:gall)]
          ?:  (~(has by records.saved.next) id)  out
          =/  fact=card:agent:gall
            :*  %give  %fact  ~[/runs /run/(scot %ud id)]
                %quiz-update  !>(`update:app`[%deleted id])
            ==
          [fact [%give %kick ~[/run/(scot %ud id)] ~] out]
        =.  cards  (weld cards removed)
        =?  cards  !=(order.old order.saved.next)
          :_  cards
          :*  %give  %fact  ~[/runs]  %quiz-update
              !>(`update:app`[%runs order.saved.next])
          ==
        =/  active  active.next
        =/  needs-wake
          ?~  active  !=(~ queue.saved.next)
          =/  rec  (~(got by records.saved.next) id.u.active)
          |(=(%cancelling status.rec) =(~ build-token.next))
        ?:  |(!needs-wake !=(~ timer.next))  [cards this(state next)]
        =/  token  next-token.saved.next
        =/  when  (add now.bowl (div ~s1 100))
        :_  this(state next(next-token.saved +(token), timer `[token when]))
        (snoc cards [%pass /quiz/tick/(scot %ud token) %arvo %b %wait when])
      --
::
++  on-init  `this
::
++  on-save
  ^-  vase
  !>([%0 saved.state])
::
++  on-load
  |=  old=vase
  ^-  (quip card:agent:gall _this)
  =/  loaded  !<(versioned-state:app old)
  (publish:ops +.loaded (restore:job +.loaded now.bowl) ~)
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card:agent:gall _this)
  ?>  =(our.bowl src.bowl)
  ?:  =(%quiz-submit mark)
    =/  [ticket=@ta req=request:app]  !<([@ta request:app] vase)
    =/  id  next-id.saved.state
    =/  admitted  (admit:job state req now.bowl eny.bowl)
    ~|  ?:(?=(%.n -.admitted) p.admitted %admit)
    ?>  ?=(%.y -.admitted)
    =/  response=card:agent:gall
      :*  %pass  /quiz-admitted  %agent  [our.bowl %quiz-web]
          %poke  %quiz-admitted  !>([ticket id])
      ==
    (publish:ops saved.state p.admitted ~[response])
  ?>  =(%quiz-action mark)
  =/  command  !<(action:app vase)
  =/  next=state:job
    ?-  -.command
      %run
        =/  admitted  (admit:job state +.command now.bowl eny.bowl)
        ~|  ?:(?=(%.n -.admitted) p.admitted %admit)
        ?>  ?=(%.y -.admitted)
        p.admitted
      %cancel  (cancel:job state id.command now.bowl)
      %delete  (delete:job state id.command)
      %clear
        =/  ids  order.saved.state
        =/  s  state
        |-  ^-  state:job
        ?~  ids  s
        $(ids t.ids, s (delete:job s i.ids))
    ==
  (publish:ops saved.state next ~)
::
++  on-watch
  |=  =path
  ^-  (quip card:agent:gall _this)
  ?>  =(our.bowl src.bowl)
  ?:  =(/runs path)
    :_  this
    ~[[%give %fact ~ %quiz-update !>(`update:app`[%runs order.saved.state])]]
  ?>  ?=([%run @ ~] path)
  =/  id  (parse-id:ops i.t.path)
  ?>  ?=(^ id)
  =/  rec  (~(get by records.saved.state) u.id)
  ?>  ?=(^ rec)
  :_  this
  ~[[%give %fact ~ %quiz-update !>(`update:app`[%run u.rec])]]
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?:  =(/x/runs path)  ``noun+!>(order.saved.state)
  ?:  =(/x/limits path)  ``noun+!>(defaults:engine)
  ?:  =(/x/version path)  ``noun+!>(version:engine)
  ?.  ?=([%x %run @ ~] path)  ~
  =/  id  (parse-id:ops i.t.t.path)
  ?~  id  ~
  =/  rec  (~(get by records.saved.state) u.id)
  ?~  rec  [~ ~]
  ``noun+!>(u.rec)
::
++  on-leave  on-leave:def
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card:agent:gall _this)
  `this
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card:agent:gall _this)
  ?:  ?=([%quiz %tick @ ~] wire)
    =/  timer  timer.state
    ?~  timer  `this
    ?.  =((scot %ud token.u.timer) i.t.t.wire)  `this
    ?.  ?=([%behn %wake *] sign-arvo)  `this
    =/  next=state:job  state(timer ~)
    ::  A failed wake is retried without consuming a slice.
    ?^  +>.sign-arvo  (publish:ops saved.state next ~)
    =.  next  (advance:job next now.bowl)
    =.  next  (activate:job next now.bowl)
    =/  current  active.next
    ?:  ?&(?=(^ current) ?=(%waiting -.work.u.current))
      =/  started  (begin:ops next id.u.current)
      (publish:ops saved.state +.started -.started)
    (publish:ops saved.state next ~)
  ?.  ?=([%quiz %build @ ~] wire)  `this
  =/  token  build-token.state
  ?~  token  `this
  ?.  =((scot %ud u.token) i.t.t.wire)  `this
  ?.  ?=([%clay %writ *] sign-arvo)  `this
  =/  current  active.state
  ?~  current  `this
  =/  rec  (~(got by records.saved.state) id.u.current)
  ?:  =(%cancelling status.rec)  `this
  =/  next=state:job  state(build-token ~)
  =/  work  work.u.current
  =/  taken=(quip card:agent:gall state:job)
    ?+  -.work  [~ next]
      %file
        =/  built  (take-saved:build doc.work p.sign-arvo)
        (property-ready:ops next id.rec doc.work built)
      %suite-build
        =/  built  (take-built:suite doc.work p.sign-arvo)
        ?:  ?=(%invalid -.built)
          [~ (finish:job next id.rec built now.bowl)]
        =.  rec
          %=  rec
            status  %running
            updated  now.bowl
            counts  [%suite counts.built %unavailable]
          ==
        :-  ~
        %=  next
          active  `[id.rec [%suite +.built]]
          records.saved  (~(put by records.saved.next) id.rec rec)
        ==
      %draft
        =/  replies  [p.sign-arvo replies.work]
        =/  todo  requests.work
        ?^  todo
          =.  next
            next(active `[id.rec work(requests t.todo, replies replies)])
          (send-build:ops next i.todo)
        =/  built  (draft:build doc.work (flop replies))
        (property-ready:ops next id.rec doc.work built)
    ==
  (publish:ops saved.state +.taken -.taken)
::
++  on-fail  on-fail:def
--
