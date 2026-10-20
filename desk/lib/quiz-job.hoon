/-  app=quiz-app
/+  engine=quiz-engine, build=quiz-build, suite=quiz-suite, replay=quiz-replay
|%
  ::  Pure FIFO lifecycle. Only transient work contains compiled vases.
  ::
+$  work
  $%  [%waiting ~]
      $:  %draft  doc=prepared:build
          requests=(list [ship desk (unit rave:clay)])
          replies=(list riot:clay)
      ==
      [%file doc=prepared:build]
      [%suite-build doc=document:suite]
      [%property state:engine]
      [%suite state:suite]
  ==
::
+$  state
  $:  saved=state-0:app
      active=(unit [id=run-id:app work=work])
      timer=(unit [token=@ud when=@da])
      build-token=(unit @ud)
  ==
::
++  initial
  ^-  state
  [[1 1 ~ ~ ~] ~ ~ ~]
::
++  queue-max  100
::
++  admit
  ::  Reject oversized requests before retaining them. Replay ignores overrides.
  |=  [s=state req=request:app now=@da entropy=@uv]
  ^-  (each state term)
  ?:  (gte (lent queue.saved.s) queue-max)  [%.n %queue-full]
  =/  original  replay-of.req
  =/  replay=(unit record:replay)
    ?~  original  ~
    =/  old  (~(get by records.saved.s) u.original)
    ?~  old  ~
    replay.u.old
  ?:  &(!=(~ original) =(~ replay))  [%.n %replay-unavailable]
  =.  req
    ?~  replay  req
    :*  [%draft source.u.replay]  desk.where.u.replay
        [%ud revision.where.u.replay]  `config.u.replay
        `seed.u.replay  original
    ==
  =/  cfg  config.req
  ?:  ?&(?=(^ cfg) !(valid-config:build u.cfg))  [%.n %conf-range]
  ?:  ?&  ?=(%draft -.source.req)
          (gth (met 3 text.source.req) source-bytes.bounds:defaults:engine)
      ==
    [%.n %source-size]
  ?.  (safe-name:build desk.req)  [%.n %desk]
  ?:  ?&(?=(%suite -.source.req) (gth (lent arms.source.req) queue-max))
    [%.n %suite-arms]
  ?:  ?&(?=(%suite -.source.req) !(levy arms.source.req safe-name:build))
    [%.n %suite-arm]
  =/  valid-path
    ?-  -.source.req
      %draft  %.y
      %file   (safe-path:build path.source.req)
      %suite  (safe-path:build path.source.req)
    ==
  ?.  valid-path
    [%.n %path]
  =/  id  next-id.saved.s
  =/  rec=record:app
    :*  id  req  ~  replay
        ?:(?=(%suite -.source.req) ~ `?~(seed.req entropy u.seed.req))
        ?:(?=(%suite -.source.req) ~ cfg)  version:engine
        %queued
        ?:  ?=(%suite -.source.req)
          [%suite *counters:suite %unavailable]
        [%property *counters:engine]
        ~  now  now  ~
    ==
  :-  %.y
  %=  s
    next-id.saved  +(id)
    records.saved  (~(put by records.saved.s) id rec)
    order.saved  [id order.saved.s]
    queue.saved  (snoc queue.saved.s id)
  ==
::
++  activate
  |=  [s=state now=@da]
  ^-  state
  ?:  !=(~ active.s)  s
  =/  todo  queue.saved.s
  ?~  todo  s
  =/  rec  (~(got by records.saved.s) i.todo)
  =.  rec  rec(status %building, updated now)
  %=  s
    active  `[id.rec [%waiting ~]]
    queue.saved  t.todo
    records.saved  (~(put by records.saved.s) id.rec rec)
  ==
::
++  retain
  ::  Prune oldest completed records only; active and queued jobs survive.
  |=  [s=state maximum=@ud]
  ^-  state
  =/  ids  order.saved.s
  =/  kept=(list run-id:app)  ~
  =/  completed  0
  |-
  ?~  ids  s(order.saved (flop kept))
  =/  rec  (~(got by records.saved.s) i.ids)
  ?.  =(%done status.rec)  $(ids t.ids, kept [i.ids kept])
  ?:  (lth completed maximum)
    $(ids t.ids, kept [i.ids kept], completed +(completed))
  $(ids t.ids, s s(records.saved (~(del by records.saved.s) i.ids)))
::
++  finish
  |=  [s=state id=run-id:app out=outcome:app now=@da]
  ^-  state
  =/  rec  (~(got by records.saved.s) id)
  =.  rec  rec(status %done, result `out, updated now, finished `now)
  =/  current  active.s
  =.  s
    ?:  ?&(?=(^ current) =(id id.u.current))
      s(active ~, build-token ~)
    s
  =.  s
    %=  s
      records.saved  (~(put by records.saved.s) id rec)
      queue.saved  (skim queue.saved.s |=(n=run-id:app !=(n id)))
    ==
  =/  cap
    ?~  config.rec  retained-runs.bounds:defaults:engine
    retained-runs.bounds.u.config.rec
  (retain s cap)
::
++  cancel
  |=  [s=state id=run-id:app now=@da]
  ^-  state
  =/  found  (~(get by records.saved.s) id)
  ?~  found  s
  =/  rec  u.found
  ?:  =(%done status.rec)  s
  ?:  =(%queued status.rec)  (finish s id [%cancelled %request] now)
  =.  rec  rec(status %cancelling, updated now)
  s(records.saved (~(put by records.saved.s) id rec))
::
++  interrupt
  ::  The runtime aborted the previous tick's event: a %jinx CPU limit,
  ::  operator interrupt or memory exhaustion. The event rolled back, so
  ::  blame what that tick ran: the active job's slice, or else the build
  ::  of the queue head. Never retry: deterministic work would hang again.
  |=  [s=state now=@da]
  ^-  state
  =/  current  active.s
  ?~  current
    =/  todo  queue.saved.s
    ?~  todo  s
    (finish s i.todo [%interrupted %building ~ ~] now)
  =/  id  id.u.current
  =/  rec  (~(got by records.saved.s) id)
  =/  during=?(%building %running %shrinking)
    ?:(?=(?(%running %shrinking) status.rec) status.rec %building)
  =/  work  work.u.current
  =/  proof=(unit evidence:app)
    ?.  ?=(%property -.work)  ~
    =/  shrink  shrink.work
    ?~  shrink  ~
    `(persist-evidence evidence.u.shrink)
  =/  arm=(unit term)
    ?.  ?=(%suite -.work)  ~
    =/  todo  remaining.work
    ?~(todo ~ `i.todo)
  (finish s id [%interrupted during proof arm] now)
::
++  delete
  ::  Missing or unfinished IDs are no-ops; clear uses the same rule.
  |=  [s=state id=run-id:app]
  ^-  state
  =/  rec  (~(get by records.saved.s) id)
  ?~  rec  s
  ?.  =(%done status.u.rec)  s
  %=  s
    records.saved  (~(del by records.saved.s) id)
    order.saved  (skim order.saved.s |=(n=run-id:app !=(n id)))
  ==
::
++  restore
  ::  Saved counters and completed results survive; no execution is resumed.
  |=  [saved=state-0:app now=@da]
  ^-  state
  =.  records.saved
    %-  ~(run by records.saved)
    |=  rec=record:app
    ?:  =(%done status.rec)  rec
    rec(status %done, result `[%cancelled %reload], updated now, finished `now)
  (retain [saved(queue ~) ~ ~ ~] retained-runs.bounds:defaults:engine)
::
++  persist-evidence
  ::  Drop type information; render only already capped engine samples.
  |=  proof=counterexample:engine
  ^-  evidence:app
  :*  why.proof
      [q.original.proof (crip ~(ram re (sell original.proof)))]
      [q.shrunk.proof (crip ~(ram re (sell shrunk.proof)))]
  ==
::
++  persist-outcome
  |=  out=outcome:engine
  ^-  outcome:app
  ?-  -.out
    ?(%passed %exhausted)  out
    %failed  [%failed (persist-evidence +.out)]
    %error
      :*  %error  stage.out  why.out
          ?~(evidence.out ~ `(persist-evidence u.evidence.out))
      ==
    %limited
      :*  %limited  which.out
          ?~(evidence.out ~ `(persist-evidence u.evidence.out))
      ==
  ==
::
++  advance
  ::  A property slice consumes at most the configured number of steps.
  ::  It also ends when a counterexample is first found, so the evidence
  ::  is committed before any alts call can abort the event.
  ::  A suite slice always consumes one arm. Cancellation precedes all work.
  |=  [s=state now=@da]
  ^-  state
  =/  active  active.s
  ?~  active  s
  =/  id  id.u.active
  =/  rec  (~(got by records.saved.s) id)
  ?:  =(%cancelling status.rec)  (finish s id [%cancelled %request] now)
  =/  work  work.u.active
  ?+  -.work  s
    %property
      =/  running  +.work
      =/  left  samples-per-slice.bounds.config.running
      =/  shrinking  !=(~ shrink.running)
      =.  running
        |-  ^-  state:engine
        ?:  |(=(left 0) !=(~ result.running))  running
        =/  next  (step:engine running)
        ?:  &(!shrinking !=(~ shrink.next))  next
        $(running next, left (dec left))
      =.  rec
        %=  rec
          counts  [%property counts.running]
          updated  now
          status  ?:(=(~ shrink.running) %running %shrinking)
        ==
      =.  s
        %=  s
          records.saved  (~(put by records.saved.s) id rec)
          active  `[id [%property running]]
        ==
      =/  result  result.running
      ?~  result  s
      (finish s id (persist-outcome u.result) now)
    %suite
      =/  running  (step:suite +.work)
      =.  rec
        %=  rec
          counts  [%suite counts.running %unavailable]
          updated  now
          status  %running
        ==
      =.  s
        %=  s
          records.saved  (~(put by records.saved.s) id rec)
          active  `[id [%suite running]]
        ==
      =/  result  result.running
      ?~  result  s
      (finish s id [%suite u.result] now)
  ==
--
