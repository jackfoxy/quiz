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
+$  pace
  ::  The next property slice's step count, and the last slice's wake time.
  ::  0 and the bunt date mean not yet measured.
  [slice=@ud last=@da]
::
+$  state
  $:  saved=state-0:app
      active=(unit [id=run-id:app work=work])
      timer=(unit [token=@ud when=@da])
      build-token=(unit @ud)
      =pace
      ::  When an aborted tick began, until the next wake judges the abort.
      aborted=(unit @da)
  ==
::
++  initial
  ::  No runs or jobs; ids and tokens start at 1; default timeouts.
  ^-  state
  [[1 1 ~ ~ ~ default-timeouts] ~ ~ ~ *pace ~]
::
++  queue-max  100
::
++  slice-start
  ::  Steps in a job's first property slice, before any timing.
  8
::
++  slice-quick
  ::  Wake-to-wake span below which the next slice doubles.
  (div ~s1 20)
::
++  slice-slow
  ::  Wake-to-wake span above which the next slice halves.
  (div ~s1 4)
::
++  default-timeouts
  ::  Property call 10 s, draft build 30 s, suite arm 1 min.
  ^-  timeouts:app
  [call-time:engine ~s30 ~m1]
::
++  valid-timeouts
  ::  Each limit from one second to one hour.
  |=  value=timeouts:app
  ^-  ?
  =/  limits=(list @dr)  ~[call.value build.value arm.value]
  %+  levy  limits
  |=(limit=@dr &((gte limit ~s1) (lte limit ~h1)))
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
    ::  The record's replay inputs, not a patch, give the conf.
    :*  [%draft source.u.replay]  desk.where.u.replay
        [%ud revision.where.u.replay]  ~
        `seed.u.replay  original  [%run ~]
    ==
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
        ?~(replay ~ `config.u.replay)  version:engine
        %queued
        ?:  ?=(%suite -.source.req)
          [%suite *counters:suite %unavailable]
        [%property *counters:engine *distribution:engine 0]
        ~  now  now  ~  ~
    ==
  :-  %.y
  %=  s
    next-id.saved  +(id)
    records.saved  (~(put by records.saved.s) id rec)
    order.saved  [id order.saved.s]
    queue.saved  (snoc queue.saved.s id)
  ==
::
++  merge
  ::  A document's conf with a request's patch applied.
  |=  [base=conf:engine =patch:app]
  ^-  conf:engine
  :*  (fall requested.patch requested.base)
      (fall attempts-max.patch attempts-max.base)
      (fall drops-max.patch drops-max.base)
      (fall duplicates-max.patch duplicates-max.base)
      (fall size-start.patch size-start.base)
      (fall size-max.patch size-max.base)
      (fall duplicates.patch duplicates.base)
      (fall bounds.patch bounds.base)
      (fall on-timeout.patch on-timeout.base)
  ==
::
++  summarize
  ::  A record's history row.
  |=  rec=record:app
  ^-  summary:app
  =/  result  result.rec
  =/  outcome=(unit @tas)
    ?~  result  ~
    ?:  ?=(%suite -.u.result)  `status.u.result
    `-.u.result
  =/  kind
    ?:  ?=(%preview -.mode.request.rec)  %preview
    -.source.request.rec
  [id.rec kind status.rec outcome]
::
++  activate
  ::  Start the queue head building, unless a job is already active.
  |=  [s=state now=@da]
  ^-  state
  ?:  !=(~ active.s)  s
  =/  todo  queue.saved.s
  ?~  todo  s
  =/  rec  (~(got by records.saved.s) i.todo)
  =.  rec  rec(status %building, updated now)
  %=  s
    active  `[id.rec [%waiting ~]]
    pace  *pace
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
  ::  Record the outcome, drop the run from active and the queue, then
  ::  prune history to the run's retained-runs bound.
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
      queue.saved  (skip queue.saved.s (cury test id))
    ==
  =/  cap
    ?~  config.rec  retained-runs.bounds:defaults:engine
    retained-runs.bounds.u.config.rec
  (retain s cap)
::
++  cancel
  ::  Missing and finished runs are no-ops. A queued run ends now; an
  ::  active one is marked %cancelling and stops at its next slice.
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
  ::  `spent` is the wall time from the tick's wake to the error wake.
  |=  [s=state now=@da spent=@dr]
  ^-  state
  =/  current  active.s
  ?~  current
    =/  todo  queue.saved.s
    ?~  todo  s
    (finish s i.todo [%interrupted %building ~ ~] now)
  =/  id  id.u.current
  =/  rec  (~(got by records.saved.s) id)
  ::  A stored sample or candidate means the aborted tick was its fate: the
  ::  run's timeout policy decides, and the run goes on. The tang does not
  ::  name the cause, but wall time is never less than CPU time, so an
  ::  abort sooner than the call limit was Ctrl-C or the loom: interrupt.
  =/  work  work.u.current
  ?:  ?&  ?=(%property -.work)
          ?=(^ pending.+.work)
          !=(%interrupt on-timeout.config.+.work)
          (gte spent time.+.work)
      ==
    =/  running  (timed-out:engine +.work)
    =.  rec
      %=  rec
        counts  [%property counts.running seen-tags.running size.running]
        updated  now
        status  ?:(=(~ shrink.running) %running %shrinking)
      ==
    %=  s
      records.saved  (~(put by records.saved.s) id rec)
      active  `[id [%property running]]
    ==
  =/  during=?(%building %running %shrinking)
    ?:(?=(?(%running %shrinking) status.rec) status.rec %building)
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
    order.saved  (skip order.saved.s (cury test id))
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
  =/  fresh=state  [saved(queue ~) ~ ~ ~ *pace ~]
  (retain fresh retained-runs.bounds:defaults:engine)
::
++  persist-evidence
  ::  Drop type information; the engine rendered each kept sample once.
  |=  proof=counterexample:engine
  ^-  evidence:app
  :*  why.proof
      [q.original.proof original.texts.proof]
      [q.shrunk.proof shrunk.texts.proof]
      trace.proof
  ==
::
++  persist-examples
  ::  One rendered example per label, in label order.
  |=  kept=(map @t example:engine)
  ^-  examples:app
  %+  turn  (sort ~(tap by kept) |=([a=[@t *] b=[@t *]] (aor -.a -.b)))
  |=  [label=@t =example:engine]
  [label q.vase.example text.example]
::
++  persist-outcome
  ::  An engine outcome without vases: evidence and examples keep their
  ::  nouns and rendered text.
  |=  [out=outcome:engine kept=(map @t example:engine)]
  ^-  outcome:app
  ?-  -.out
    ?(%exhausted %passed-unexpectedly %preview)  out
    %passed     [%passed warnings.out (persist-examples kept)]
    %uncovered  [%uncovered shortfalls.out (persist-examples kept)]
    %failed  [%failed (persist-evidence +.out)]
    %failed-as-expected  [%failed-as-expected (persist-evidence +.out)]
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
++  adapt
  ::  Size the next property slice from the span since the last wake. That
  ::  span holds the previous slice's event, so a quick one doubles the
  ::  slice and a slow one halves it, within the engine's ceiling. Results
  ::  do not depend on slicing, only how often progress is committed.
  |=  [s=state now=@da]
  ^-  state
  =/  slice  ?:(=(0 slice.pace.s) slice-start slice.pace.s)
  ?:  =(*@da last.pace.s)  s(pace [slice now])
  =/  span  (sub now (min now last.pace.s))
  =/  ceiling  samples-per-slice.bounds:defaults:engine
  =.  slice
    ?:  (lth span slice-quick)  (min ceiling (mul 2 slice))
    ?:  (gth span slice-slow)  (max 1 (div slice 2))
    slice
  s(pace [slice now])
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
      ::  A settings change applies from the next slice; a document's
      ::  ++within can only lower it.
      =.  time.running
        (call-limit:engine call.timeouts.saved.s within.running)
      ::  A split run does one kind of work per tick, so an abort has one
      ::  culprit.
      =/  cap  samples-per-slice.bounds.config.running
      =/  left
        ?.  =(%interrupt on-timeout.config.running)  1
        (min cap ?:(=(0 slice.pace.s) slice-start slice.pace.s))
      =/  shrinking  !=(~ shrink.running)
      =.  running
        |-  ^-  state:engine
        ?:  |(=(left 0) !=(~ result.running))  running
        =/  next  (step:engine running)
        ?:  &(!shrinking !=(~ shrink.next))  next
        $(running next, left (dec left))
      =.  rec
        %=  rec
          counts  [%property counts.running seen-tags.running size.running]
          updated  now
          status  ?:(=(~ shrink.running) %running %shrinking)
          call  `time.running
        ==
      =.  s
        %=  s
          records.saved  (~(put by records.saved.s) id rec)
          active  `[id [%property running]]
        ==
      =/  result  result.running
      ?~  result  s
      (finish s id (persist-outcome u.result examples.running) now)
    %suite
      =/  running
        ~>  %jinx.arm.timeouts.saved.s
        (step:suite +.work)
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
