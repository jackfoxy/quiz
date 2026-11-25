/-  app=quiz-app
/+  *test, job=quiz-job, engine=quiz-engine, build=quiz-build, suite=quiz-suite
/=  agent  /lib/quiz-agent
/=  packaged  /app/quiz
/=  action-mark  /mar/quiz/action
/=  update-mark  /mar/quiz/update
|%
::
++  bol
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    src  ~zod
    dap  %quiz
    now  ~2026.10.14
    eny  0v123
  ==
::
++  request
  ^-  request:app
  [[%draft '|%  ++  fate  |=(@ud &)  --'] %quiz [%ud 1] ~ ~ ~ [%run ~]]
::
++  queued
  |=  total=@ud
  ^-  state:job
  =/  s  initial:job
  |-
  ?:  =(total 0)  s
  =/  next  (admit:job s request now:bol 0v123)
  ?>  ?=(%.y -.next)
  $(s p.next, total (dec total))
::
++  running
  |=  [total=@ud accepted=@ud]
  ^-  state:job
  =/  s  (activate:job (queued total) now:bol)
  =/  cfg  defaults:engine
  =.  cfg  cfg(requested 100, samples-per-slice.bounds 2)
  =/  parts=parts:engine
    [!>(|=(n=@ud &)) `!>(|=([size=@ud rng=_og] size)) ~ ~ %pass]
  =/  run  (init:engine 0v123 cfg parts)
  =.  run  run(accepted.counts accepted, attempted.counts accepted)
  =/  rec  (~(got by records.saved.s) 1)
  =.  rec  rec(status %running, config `cfg)
  %=  s
    active  `[1 [%property run]]
    records.saved  (~(put by records.saved.s) 1 rec)
  ==
::
++  get-record
  |=  [s=state:job id=run-id:app]
  ^-  record:app
  (~(got by records.saved.s) id)
::
++  test-admit-fifo-and-one-active
  ^-  tang
  =/  s  (queued 3)
  =/  a  (activate:job s now:bol)
  =/  done  (finish:job a 1 [%passed ~ ~] now:bol)
  =/  b  (activate:job done now:bol)
  ;:  weld
    (expect-eq !>(~[1 2 3]) !>(queue.saved.s))
    (expect-eq !>(~[3 2 1]) !>(order.saved.s))
    (expect-eq !>(1) !>(id:(need active.a)))
    (expect-eq !>(2) !>(id:(need active.b)))
    (expect !>(=(a (activate:job a now:bol))))
    (expect-eq !>(%building) !>(status:(get-record a 1)))
  ==
::
++  test-queue-limit
  ^-  tang
  =/  got  (admit:job (queued queue-max:job) request now:bol 0v0)
  (expect !>(?=([%.n %queue-full] got)))
::
++  test-admission-limits
  ^-  tang
  ::  A patch is checked once merged, after the build, not on admission.
  =/  cfg  defaults:engine
  =/  req=request:app  request
  =/  changes=patch:app  *patch:app
  =.  req  req(config `changes(requested `10.001))
  =/  patched  (admit:job initial:job req now:bol 0v0)
  =/  oversized  (bex (mul 8 source-bytes.bounds.cfg))
  =.  req  req(source [%draft oversized], config ~)
  =/  bad-source  (admit:job initial:job req now:bol 0v0)
  ;:  weld
    (expect !>(?=(%.y -.patched)))
    (expect !>(?=([%.n %source-size] bad-source)))
  ==
::
++  test-suite-request-preserved
  ^-  tang
  =/  req  request
  =.  req  req(source [%suite /tests/example/hoon ~[%test-one]])
  =/  admitted  (admit:job initial:job req now:bol 0v123)
  ?>  ?=(%.y -.admitted)
  =/  rec  (get-record p.admitted 1)
  ;:  weld
    (expect !>(=(req request.rec)))
    (expect !>(=(~ seed.rec)))
    (expect !>(=(~ config.rec)))
    (expect !>(?=([%suite * %unavailable] counts.rec)))
  ==
::
++  test-slice-budget
  ^-  tang
  =/  before  (running 1 0)
  =/  after  (advance:job before now:bol)
  =/  rec  (get-record after 1)
  ?>  ?=(%property -.counts.rec)
  ;:  weld
    (expect-eq !>(2) !>(attempted.counts.rec))
    (expect-eq !>(2) !>(accepted.counts.rec))
    (expect !>(=(%running status.rec)))
  ==
::
++  test-completion
  ^-  tang
  =/  s  (advance:job (running 1 99) now:bol)
  =/  rec  (get-record s 1)
  ?>  ?=(%property -.counts.rec)
  ;:  weld
    (expect !>(?=([~ %passed ~ ~] result.rec)))
    (expect !>(=(%done status.rec)))
    (expect !>(=(~ active.s)))
    (expect-eq !>(100) !>(accepted.counts.rec))
    (expect !>(=(s (advance:job s now:bol))))
  ==
::
++  test-queued-cancellation
  ^-  tang
  =/  s  (cancel:job (queued 3) 2 now:bol)
  =/  rec  (get-record s 2)
  ;:  weld
    (expect !>(?=([~ %cancelled %request] result.rec)))
    (expect-eq !>(~[1 3]) !>(queue.saved.s))
    (expect !>(=(s (cancel:job s 2 now:bol))))
    (expect !>(=(s (cancel:job s 999 now:bol))))
  ==
::
++  test-active-cancellation-before-next-sample
  ^-  tang
  =/  s  (running 2 0)
  =/  pending  (cancel:job s 1 now:bol)
  =/  done  (advance:job pending now:bol)
  =/  rec  (get-record done 1)
  ;:  weld
    (expect !>(=(%cancelling status:(get-record pending 1))))
    (expect !>(=(~ result:(get-record pending 1))))
    (expect !>(?=([~ %cancelled %request] result.rec)))
    (expect !>(=(counts:(get-record s 1) counts.rec)))
    (expect !>(=(~ active.done)))
    (expect-eq !>(~[2]) !>(queue.saved.done))
  ==
::
++  test-retention-protects-pending
  ^-  tang
  =/  s  (queued 4)
  =.  s  (finish:job s 1 [%passed ~ ~] now:bol)
  =.  s  (finish:job s 2 [%passed ~ ~] now:bol)
  =.  s  (retain:job s 1)
  ;:  weld
    (expect-eq !>(~[4 3 2]) !>(order.saved.s))
    (expect-eq !>(~[3 4]) !>(queue.saved.s))
    (expect !>(!(~(has by records.saved.s) 1)))
    (expect !>(=(s (delete:job s 3))))
    (expect !>(=(s (delete:job s 999))))
    (expect !>(!(~(has by records.saved:(delete:job s 2)) 2)))
  ==
::
++  test-reload-cancels-pending-keeps-completed
  ^-  tang
  =/  s  (running 3 7)
  =.  s  (finish:job s 3 [%passed ~ ~] now:bol)
  =/  restored  (restore:job saved.s now:bol)
  =/  one  (get-record restored 1)
  =/  two  (get-record restored 2)
  ;:  weld
    (expect !>(?=([~ %cancelled %reload] result.one)))
    (expect !>(?=([~ %cancelled %reload] result.two)))
    (expect !>(=((get-record s 3) (get-record restored 3))))
    (expect !>(=(~ active.restored)))
    (expect !>(=(~ queue.saved.restored)))
    (expect !>(=(~ timer.restored)))
  ==
::
++  test-save-strips-execution
  ^-  tang
  =/  s  (running 2 7)
  =/  a  ~(. agent bol)
  =.  a  a(state s)
  =/  saved  !<(versioned-state:app on-save.a)
  =/  loaded  (on-load.a !>(saved))
  =/  round-trip  !<(versioned-state:app on-save:+.loaded)
  =/  expected  (restore:job saved.s now:bol)
  ;:  weld
    (expect !>(=(saved [%0 saved.s])))
    (expect !>(=(~ queue.+.round-trip)))
    (expect !>(=(records.+.round-trip records.saved.expected)))
  ==
::
++  test-poke-auth
  ^-  tang
  =/  bowl  bol
  %-  expect-fail
  |.  (on-poke:~(. agent bowl(src ~nec)) %quiz-action !>([%run request]))
::
++  test-watch-auth
  ^-  tang
  =/  bowl  bol
  %-  expect-fail
  |.  (on-watch:~(. agent bowl(src ~nec)) /runs)
::
++  test-poke-mark-and-type
  ^-  tang
  ;:  weld
    %-  expect-fail
    |.  (on-poke:~(. agent bol) %noun !>([%run request]))
    %-  expect-fail
    |.  (on-poke:~(. agent bol) %quiz-action !>(42))
  ==
::
++  test-poke-and-timer-wire
  ^-  tang
  =/  got  (on-poke:~(. agent bol) %quiz-action !>([%run request]))
  =/  timers
    %+  skim  -.got
    |=(c=card:agent:gall ?=([%pass * %arvo %b %wait *] c))
  ?>  ?=([* ~] timers)
  =/  timer  i.timers
  ?>  ?=([%pass * %arvo %b %wait *] timer)
  ;:  weld
    (expect-eq !>(`wire`/quiz/tick/1) !>(p.timer))
    (expect-eq !>(~[1]) !>(queue.saved.state:+.got))
    (expect-eq !>(2) !>(next-token.saved.state:+.got))
  ==
::
++  test-watch-initial-and-scry
  ^-  tang
  =/  a  ~(. agent bol)
  =.  a  a(state (queued 1))
  =/  watched  (on-watch.a /run/1)
  =/  fact  (head -.watched)
  =/  got  (on-peek.a /x/run/1)
  ?>  ?=([~ ~ *] got)
  =/  rec  !<(record:app q.u.u.got)
  ;:  weld
    (expect-eq !>(1) !>(id.rec))
    (expect !>(?=([%give %fact ~ %quiz-update *] fact)))
    (expect !>(=([~ ~] (on-peek.a /x/run/99))))
    (expect !>(=(~ (on-peek.a /x/run/nope))))
    (expect !>(=(~ (on-peek.a ~[%x %run '01']))))
    (expect !>(=(~ (on-peek.a /x/run/1/extra))))
  ==
::
++  test-slices-adapt
  ::  Quick wakes double the slice up to the ceiling; slow ones halve it.
  ^-  tang
  =/  t0  now:bol
  =/  first  (adapt:job initial:job t0)
  =/  quick  (adapt:job first (add t0 ~s0..0100))
  =/  slow  (adapt:job quick (add t0 ~s1))
  =/  full  first(pace [1.000 t0])
  =/  capped  (adapt:job full (add t0 ~s0..0100))
  ;:  weld
    (expect-eq !>(8) !>(slice.pace.first))
    (expect-eq !>(16) !>(slice.pace.quick))
    (expect-eq !>(8) !>(slice.pace.slow))
    (expect-eq !>(1.000) !>(slice.pace.capped))
  ==
::
++  test-summaries-scry
  ::  One row per run, newest first, with the outcome once finished.
  ^-  tang
  =/  s  (queued 2)
  =.  s  (finish:job s 1 [%passed ~ ~] now:bol)
  =/  a  ~(. agent bol)
  =.  a  a(state s)
  =/  got  (on-peek.a /x/summaries)
  ?>  ?=([~ ~ *] got)
  =/  rows  !<((list summary:app) q.u.u.got)
  %+  expect-eq
    !>  ^-  (list summary:app)
        :~  [2 %draft %queued ~]
            [1 %draft %done `%passed]
        ==
  !>(rows)
::
++  test-id-thousands
  ^-  tang
  =/  s  initial:job
  =/  got  (admit:job s(next-id.saved 1.000) request now:bol 0v0)
  ?>  ?=(%.y -.got)
  =/  a  ~(. agent bol)
  =.  a  a(state p.got)
  (expect !>(?=([~ ~ *] (on-peek.a /x/run/1.000))))
::
++  test-stale-wires-ignored
  ^-  tang
  =/  a  ~(. agent bol)
  =/  s  (running 1 0)
  =.  a  a(state s(timer `[10 now:bol]))
  =/  got  (on-arvo.a /quiz/tick/9 [%behn %wake ~])
  =/  wrong  (on-arvo.a /quiz/tick/10 [%clay %writ ~])
  =/  build  (on-arvo.a /quiz/build/9 [%clay %writ ~])
  ;:  weld
    (expect !>(=(a +.got)))
    (expect !>(=(~ -.got)))
    (expect !>(=(a +.wrong)))
    (expect !>(=(a +.build)))
  ==
::
++  test-tick-and-duplicate
  ^-  tang
  =/  a  ~(. agent bol)
  =/  s  (running 1 0)
  =.  a  a(state s(timer `[10 now:bol], next-token.saved 11))
  =/  got  (on-arvo.a /quiz/tick/10 [%behn %wake ~])
  =/  duplicate  (on-arvo:+.got /quiz/tick/10 [%behn %wake ~])
  =/  rec  (get-record state:+.got 1)
  ?>  ?=(%property -.counts.rec)
  ;:  weld
    (expect-eq !>(2) !>(attempted.counts.rec))
    (expect !>(=(+.got +.duplicate)))
    (expect !>(=(~ -.duplicate)))
    (expect !>(=(11 token:(need timer.state:+.got))))
  ==
::
++  test-clear-keeps-active
  ^-  tang
  =/  s  (running 2 0)
  =.  s  (finish:job s 2 [%passed ~ ~] now:bol)
  =/  a  ~(. agent bol)
  =.  a  a(state s)
  =/  got  (on-poke.a %quiz-action !>([%clear ~]))
  ;:  weld
    (expect-eq !>(~[1]) !>(order.saved.state:+.got))
    (expect !>(!=(~ active.state:+.got)))
    (expect !>(!=(~ -.got)))
  ==
::
++  test-version-and-limits
  ^-  tang
  =/  a  ~(. packaged bol)
  =/  version  (need (need (on-peek.a /x/version)))
  =/  limits  (need (need (on-peek.a /x/limits)))
  ;:  weld
    (expect-eq !>(version:engine) q.version)
    (expect-eq !>(defaults:engine) q.limits)
  ==
::
++  test-marks
  ^-  tang
  =/  action=action:app  [%run request]
  =/  update=update:app  [%runs ~[1]]
  ;:  weld
    (expect !>(=(action noun:~(grow action-mark action))))
    (expect !>(=(update noun:~(grow update-mark update))))
  ==
::
++  test-cancel-pending-build
  ^-  tang
  =/  s  (activate:job (queued 1) now:bol)
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon '42')
  ?>  ?=(%.y -.doc)
  =.  s  s(active `[1 [%file p.doc]], build-token `10)
  =/  a  ~(. agent bol)
  =.  a  a(state s(next-token.saved 11))
  =/  pending  (on-poke.a %quiz-action !>([%cancel 1]))
  =/  ignored  (on-arvo:+.pending /quiz/build/10 [%clay %writ ~])
  =/  done  (on-arvo:+.ignored /quiz/tick/11 [%behn %wake ~])
  =/  late  (on-arvo:+.done /quiz/build/10 [%clay %writ ~])
  =/  rec  (get-record state:+.done 1)
  ;:  weld
    (expect !>(=(+.pending +.ignored)))
    (expect !>(?=([~ %cancelled %request] result.rec)))
    (expect !>(=(~ build-token.state:+.done)))
    (expect !>(=(+.done +.late)))
  ==
::
++  test-build-failure-advances-queue
  ^-  tang
  =/  s  (activate:job (queued 2) now:bol)
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon '42')
  ?>  ?=(%.y -.doc)
  =.  s  s(active `[1 [%file p.doc]], build-token `10)
  =/  a  ~(. agent bol)
  =.  a  a(state s(next-token.saved 11))
  =/  done  (on-arvo.a /quiz/build/10 [%clay %writ ~])
  =/  rec  (get-record state:+.done 1)
  ;:  weld
    (expect !>(?=([~ %invalid *] result.rec)))
    (expect !>(=(~ active.state:+.done)))
    (expect !>(=(11 token:(need timer.state:+.done))))
    (expect-eq !>(~[2]) !>(queue.saved.state:+.done))
  ==
::
++  test-draft-dependency-wires
  ^-  tang
  =/  text
    '/+  first=quiz, second=quiz-engine  |%  ++  fate  |=(@ud &)  --'
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon text)
  ?>  ?=(%.y -.doc)
  =/  requests  (draft-requests:build p.doc)
  =/  s  (activate:job (queued 1) now:bol)
  =.  s
    %=  s
      active  `[1 [%draft p.doc (slag 1 requests) ~]]
      build-token  `10
      next-token.saved  11
    ==
  =/  a  ~(. agent bol)
  =.  a  a(state s)
  =/  next  (on-arvo.a /quiz/build/10 [%clay %writ ~])
  =/  old  (on-arvo:+.next /quiz/build/10 [%clay %writ ~])
  =/  expected=card:agent:gall
    [%pass /quiz/build/11 %arvo %c %warp (snag 1 requests)]
  ;:  weld
    (expect !>(=(~[expected] -.next)))
    (expect !>(=(+.next +.old)))
    (expect !>(=(~ timer.state:+.next)))
  ==
::
++  test-suite-one-arm-per-slice
  ^-  tang
  =/  doc=document:suite  [[~zod %quiz 1] /tests/demo/hoon '' ~]
  =/  core  |%  ++  test-one  *tang  ++  test-two  *tang  --
  =/  built  (discover:suite doc !>(core))
  ?>  ?=(%ready -.built)
  =/  s  (activate:job (queued 1) now:bol)
  =.  s  s(active `[1 [%suite +.built]])
  =/  first  (advance:job s now:bol)
  =/  second  (advance:job first now:bol)
  =/  rec  (get-record first 1)
  =/  done  (get-record second 1)
  ?>  ?=(%suite -.counts.rec)
  ;:  weld
    (expect-eq !>(1) !>(completed:+<.counts.rec))
    (expect !>(=(~ result.rec)))
    (expect !>(?=([~ %suite %passed *] result.done)))
  ==
::
++  test-outcome-strips-vases
  ^-  tang
  =/  evidence=counterexample:engine
    [[%false ~ ~] !>(`@ud`541) !>(`@ud`501) ['541' '501'] ~]
  =/  got  (persist-outcome:job [%failed evidence] ~)
  ?>  ?=(%failed -.got)
  ;:  weld
    (expect-eq !>(541) !>(value.original.got))
    (expect-eq !>(501) !>(value.shrunk.got))
    (expect-eq !>('501') !>(text.shrunk.got))
    (expect !>(=(got (cue (jam got)))))
  ==
::
++  test-patch-merge-checked
  ::  A patch edits only its fields; an out-of-range merge is %invalid.
  ^-  tang
  =/  text  '|%  ++  fate  |=(@ud &)  --'
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon text)
  ?>  ?=(%.y -.doc)
  =/  core
    !>  |%  ++  fate  |=(@ud &)  --
  =/  reply=rant:clay  [[%a [%ud 1] %quiz] /draft/hoon %vase !>(core)]
  =/  ready
    |=  changes=patch:app
    ^-  record:app
    =/  s  (activate:job (queued 1) now:bol)
    =/  rec  (get-record s 1)
    =.  rec  rec(request request.rec(config `changes))
    =.  s  s(records.saved (~(put by records.saved.s) 1 rec))
    =/  a  ~(. agent bol)
    =.  a  a(state s(active `[1 [%file p.doc]], build-token `10))
    (get-record state:+:(on-arvo.a /quiz/build/10 [%clay %writ `reply]) 1)
  =/  none=patch:app  *patch:app
  =/  edited  (ready none(size-max `40))
  =/  bad  (ready none(requested `10.001))
  =/  base  defaults:engine
  ;:  weld
    (expect-eq !>(`base(size-max 40)) !>(config.edited))
    (expect !>(?=([~ %invalid %conf-range *] result.bad)))
  ==
::
++  test-property-settings-and-replay
  ^-  tang
  =/  text  '|%  ++  fate  |=(@ud &)  --'
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon text)
  ?>  ?=(%.y -.doc)
  =/  s  (activate:job (queued 1) now:bol)
  =/  rec  (get-record s 1)
  =/  changes=patch:app  *patch:app
  =.  rec  rec(request request.rec(config `changes(requested `3), seed `0v0))
  =.  s  s(records.saved (~(put by records.saved.s) 1 rec))
  =/  a  ~(. agent bol)
  =.  a  a(state s(active `[1 [%file p.doc]], build-token `10))
  =/  core
    !>  |%  ++  fate  |=(@ud &)  --
  =/  reply=rant:clay
    [[%a [%ud 1] %quiz] /draft/hoon %vase !>(core)]
  =/  ready  (on-arvo.a /quiz/build/10 [%clay %writ `reply])
  =/  recorded  (get-record state:+.ready 1)
  =/  req  request
  =.  req  req(replay-of `1, seed `0v999)
  =/  admitted  (admit:job state:+.ready req now:bol 0v888)
  ?>  ?=(%.y -.admitted)
  =/  again  (get-record p.admitted 2)
  =/  saved  (need replay.recorded)
  ;:  weld
    (expect-eq !>(`@uv`0v0) !>(seed.saved))
    (expect-eq !>(3) !>(requested.config.saved))
    (expect !>(=(seed.recorded seed.again)))
    (expect !>(=(replay.recorded replay.again)))
    (expect !>(=(config.recorded config.again)))
  ==
::
++  test-preview-job
  ::  A preview request starts the engine previewing; one slice ends it with
  ::  its rows, and history lists it as a preview.
  ^-  tang
  =/  text  '|%  ++  fate  |=(@ud &)  --'
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon text)
  ?>  ?=(%.y -.doc)
  =/  s  (activate:job (queued 1) now:bol)
  =/  rec  (get-record s 1)
  =.  rec  rec(request request.rec(mode [%preview 3 & |], seed `0v0))
  =.  s  s(records.saved (~(put by records.saved.s) 1 rec))
  =/  a  ~(. agent bol)
  =.  a  a(state s(active `[1 [%file p.doc]], build-token `10))
  =/  core
    !>  |%  ++  fate  |=(@ud &)  --
  =/  reply=rant:clay
    [[%a [%ud 1] %quiz] /draft/hoon %vase !>(core)]
  =/  ready  (on-arvo.a /quiz/build/10 [%clay %writ `reply])
  =/  done  (advance:job state:+.ready now:bol)
  =/  out  (get-record done 1)
  =/  result  (need result.out)
  ?>  ?=(%preview -.result)
  ;:  weld
    (expect-eq !>(%done) !>(status.out))
    (expect-eq !>(`@ud`3) !>((lent rows.result)))
    (expect !>((levy rows.result |=(r=preview-row:engine =(`%pass verdict.r)))))
    (expect-eq !>(%preview) !>(kind:(summarize:job out)))
  ==
::
++  test-replay-unavailable
  ^-  tang
  =/  req  request
  =.  req  req(replay-of `1)
  =/  got  (admit:job initial:job req now:bol 0v0)
  (expect !>(?=([%.n %replay-unavailable] got)))
::
++  test-delete-fact-and-kick
  ^-  tang
  =/  s  (finish:job (queued 1) 1 [%passed ~ ~] now:bol)
  =/  a  ~(. agent bol)
  =.  a  a(state s)
  =/  got  (on-poke.a %quiz-action !>([%delete 1]))
  =/  expected=card:agent:gall  [%give %kick ~[/run/1] ~]
  =/  facts
    %+  skim  -.got
    |=(c=card:agent:gall ?=([%give %fact *] c))
  ;:  weld
    (expect !>((lien -.got |=(c=card:agent:gall =(c expected)))))
    (expect-eq !>(2) !>((lent facts)))
    (expect !>(=(~ records.saved.state:+.got)))
    (expect !>(=(~ timer.state:+.got)))
  ==
::
++  test-delete-refuses-by-name
  ::  A missing or unfinished run is refused with a named trace, which
  ::  %quiz-web maps to 404 and 409.
  ^-  tang
  =/  a  ~(. agent bol)
  =.  a  a(state (running 2 0))
  =/  says
    |=  [id=run-id:app code=@tas]
    ^-  ?
    =/  got  (mule |.((on-poke.a %quiz-action !>([%delete id]))))
    ?:  ?=(%.y -.got)  |
    (lien p.got (cury test [%leaf (trip code)]))
  ;:  weld
    (expect !>((says 1 %run-unfinished)))
    (expect !>((says 2 %run-unfinished)))
    (expect !>((says 9 %run-not-found)))
    (expect !>(!(says 9 %run-unfinished)))
  ==
::
++  test-watch-unknown-path-and-id
  ^-  tang
  ;:  weld
    %-  expect-fail
    |.  (on-watch:~(. agent bol) /run/1)
    %-  expect-fail
    |.  (on-watch:~(. agent bol) /run/nope)
    %-  expect-fail
    |.  (on-watch:~(. agent bol) /elsewhere)
  ==
::
++  test-correlated-admission
  ^-  tang
  =/  prior  (queued 3)
  =/  a  ~(. agent bol)
  =.  a  a(state prior)
  =/  got  (on-poke.a %quiz-submit !>(['ticket' request]))
  =/  ticket=@ta  'ticket'
  =/  id=@ud  4
  =/  expected=card:agent:gall
    :*  %pass  /quiz-admitted  %agent  [~zod %quiz-web]
        %poke  %quiz-admitted  !>([ticket id])
    ==
  ;:  weld
    (expect !>((lien -.got |=(c=card:agent:gall =(c expected)))))
    (expect-eq !>(5) !>(next-id.saved.state:+.got))
    (expect-eq !>(request) !>(request:(get-record state:+.got 4)))
  ==
::
++  test-correlated-admission-foreign-denied
  ^-  tang
  =/  bowl  bol
  %-  expect-fail
  |.  (on-poke:~(. agent bowl(src ~nec)) %quiz-submit !>(['x' request]))
::
++  test-interrupt-running
  ^-  tang
  =/  s  (running 2 5)
  =/  got  (interrupt:job s now:bol ~s0)
  =/  rec  (get-record got 1)
  ;:  weld
    (expect !>(?=([~ %interrupted %running ~ ~] result.rec)))
    (expect !>(=(counts:(get-record s 1) counts.rec)))
    (expect !>(=(~ active.got)))
    (expect-eq !>(~[2]) !>(queue.saved.got))
  ==
::
++  test-interrupt-shrinking-keeps-evidence
  ^-  tang
  =/  s  (running 1 5)
  =/  current  (need active.s)
  ?>  ?=(%property -.work.current)
  =/  run=state:engine  +.work.current
  =/  best=counterexample:engine
    [[%false ~ ~] !>(`@ud`9) !>(`@ud`5) ['9' '5'] ~]
  =.  shrink.run  `[best ~ ~ 6]
  =/  rec  (get-record s 1)
  =.  s
    %=  s
      active  `[1 [%property run]]
      records.saved  (~(put by records.saved.s) 1 rec(status %shrinking))
    ==
  =/  got  (get-record (interrupt:job s now:bol ~s0) 1)
  ?>  ?=([~ %interrupted %shrinking [~ *] ~] result.got)
  =/  proof  (need proof.u.result.got)
  ;:  weld
    (expect-eq !>(9) !>(value.original.proof))
    (expect-eq !>(5) !>(value.shrunk.proof))
    (expect-eq !>('5') !>(text.shrunk.proof))
  ==
::
++  test-interrupt-suite-names-arm
  ^-  tang
  =/  doc=document:suite  [[~zod %quiz 1] /tests/demo/hoon '' ~]
  =/  core  |%  ++  test-one  *tang  ++  test-two  *tang  --
  =/  built  (discover:suite doc !>(core))
  ?>  ?=(%ready -.built)
  =/  s  (activate:job (queued 1) now:bol)
  =.  s  s(active `[1 [%suite +.built]])
  =/  first  (advance:job s now:bol)
  =/  current  (need active.first)
  ?>  ?=(%suite -.work.current)
  =/  next  (snag 0 remaining.+.work.current)
  =/  rec  (get-record (interrupt:job first now:bol ~s0) 1)
  (expect !>(=(result.rec `[%interrupted %running ~ `next])))
::
++  test-interrupt-blames-queue-head
  ^-  tang
  =/  s  (queued 2)
  =/  got  (interrupt:job s now:bol ~s0)
  =/  head  (get-record got 1)
  ;:  weld
    (expect !>(=(result.head `[%interrupted %building ~ ~])))
    (expect !>(=(%queued status:(get-record got 2))))
    (expect-eq !>(~[2]) !>(queue.saved.got))
    (expect !>(=(initial:job (interrupt:job initial:job now:bol ~s0))))
  ==
::
++  test-error-wake-interrupts-and-continues
  ^-  tang
  =/  a  ~(. agent bol)
  =/  s  (running 2 0)
  =.  a  a(state s(timer `[10 now:bol], next-token.saved 11))
  =/  error=(unit tang)  `~[leaf+"aborted"]
  ::  The error wake only notes the abort and asks for the judging wake.
  =/  noted  (on-arvo.a /quiz/tick/10 [%behn %wake error])
  =/  wake=card:agent:gall
    [%pass /quiz/tick/11 %arvo %b %wait (add now:bol (div ~s1 100))]
  =/  got  (on-arvo:+.noted /quiz/tick/11 [%behn %wake ~])
  =/  next  state:+.got
  =/  rec  (get-record next 1)
  ;:  weld
    (expect !>(=(~ result:(get-record state:+.noted 1))))
    (expect !>(=(wake (rear -.noted))))
    (expect !>(?=([~ %interrupted %running ~ ~] result.rec)))
    (expect !>(=(%queued status:(get-record next 2))))
    (expect-eq !>(12) !>(token:(need timer.next)))
    (expect !>(=(~ aborted.next)))
  ==
::
++  test-tick-finishes-before-starting
  ::  Separate ticks give an aborted event exactly one culprit.
  ^-  tang
  =/  a  ~(. agent bol)
  =/  s  (running 2 99)
  =.  a  a(state s(timer `[10 now:bol], next-token.saved 11))
  =/  got  (on-arvo.a /quiz/tick/10 [%behn %wake ~])
  =/  next  state:+.got
  =/  done  (get-record next 1)
  ;:  weld
    (expect !>(?=([~ %passed ~ ~] result.done)))
    (expect !>(=(~ active.next)))
    (expect !>(=(%queued status:(get-record next 2))))
    (expect-eq !>(11) !>(token:(need timer.next)))
  ==
::
++  test-slice-commits-new-counterexample
  ::  The slice stops at the first failure, before any alts call.
  ^-  tang
  =/  s  (activate:job (queued 1) now:bol)
  =/  cfg  defaults:engine
  =/  parts=parts:engine  [!>(|=(n=@ud |)) ~ ~ ~ %pass]
  =/  run  (init:engine 0v123 cfg parts)
  =/  rec  (get-record s 1)
  =.  s
    %=  s
      active  `[1 [%property run]]
      records.saved  (~(put by records.saved.s) 1 rec(status %running))
    ==
  =/  first  (advance:job s now:bol)
  =/  done  (get-record first 1)
  =/  stopped  (get-record (interrupt:job first now:bol ~s0) 1)
  ?>  ?=(%property -.counts.done)
  ;:  weld
    (expect !>(=(%shrinking status.done)))
    (expect-eq !>(1) !>(attempted.counts.done))
    (expect-eq !>(0) !>(shrink-tried.counts.done))
    (expect !>(?=([~ %interrupted %shrinking [~ *] ~] result.stopped)))
  ==
::
++  test-timeouts-action-and-scry
  ^-  tang
  =/  a  ~(. agent bol)
  =/  got  (on-poke.a %quiz-action !>([%timeouts ~s5 ~s20 ~m2]))
  =/  peek  (need (need (on-peek:+.got /x/timeouts)))
  =/  bad  (mule |.((on-poke.a %quiz-action !>([%timeouts ~ ~s20 ~m2]))))
  =/  long  (mule |.((on-poke.a %quiz-action !>([%timeouts ~s5 ~h2 ~m2]))))
  =/  fact=card:agent:gall
    :*  %give  %fact  ~[/timeouts]  %quiz-update
        !>(`update:app`[%timeouts ~s5 ~s20 ~m2])
    ==
  =/  watched  (on-watch:+.got /timeouts)
  =/  first=card:agent:gall  (snag 0 -.watched)
  ?>  ?=([%give %fact ~ %quiz-update *] first)
  =/  initial  !<(update:app q.cage.p.first)
  ;:  weld
    (expect !>(?=(^ (find ~[fact] -.got))))
    (expect !>(=(initial [%timeouts ~s5 ~s20 ~m2])))
    (expect-eq !>(`timeouts:app`[~s5 ~s20 ~m2]) q.peek)
    (expect-eq !>(default-timeouts:job) !>(timeouts.saved:initial:job))
    (expect !>(?=(%.n -.bad)))
    (expect !>(?=(%.n -.long)))
  ==
::
++  test-slice-applies-current-call-time
  ::  A settings change reaches an active run at its next slice.
  ^-  tang
  =/  s  (running 1 0)
  =.  timeouts.saved.s  [~s3 ~s30 ~m1]
  =/  after  (advance:job s now:bol)
  =/  current  (need active.after)
  ?>  ?=(%property -.work.current)
  =/  restored  (restore:job saved.s now:bol)
  ;:  weld
    (expect-eq !>(~s3) !>(time.+.work.current))
    (expect-eq !>([~s3 ~s30 ~m1]) !>(timeouts.saved.restored))
  ==
::
++  test-distribution-and-examples
  ::  Labels reach the record each slice; examples are rendered at the end.
  ^-  tang
  =/  s  (activate:job (queued 1) now:bol)
  =/  cfg  defaults:engine
  =.  cfg  cfg(requested 10)
  =/  fate
    !>  |=  n=@ud
        ^-  report:engine
        [%report & [~ ~] ~[?:(=(0 (mod n 2)) 'even' 'odd')] ~]
  =/  give  !>(|=([size=@ud rng=_og] size))
  =/  parts=parts:engine  [fate `give ~ ~ %pass]
  =/  run  (init:engine 0v123 cfg parts)
  =/  rec  (get-record s 1)
  =.  s
    %=  s
      active  `[1 [%property run]]
      records.saved  (~(put by records.saved.s) 1 rec(status %running))
      ::  One slice large enough for all ten samples.
      pace  [25 *@da]
    ==
  =/  done  (get-record (advance:job s now:bol) 1)
  ?>  ?=(%property -.counts.done)
  =/  result  (need result.done)
  ?>  ?=(%passed -.result)
  =/  values  (turn examples.result |=([@t =sample:app] value.sample))
  ;:  weld
    %+  expect-eq  !>((malt `(list [@t @ud])`~[['even' 5] ['odd' 5]]))
    !>(labels.distribution.counts.done)
    %+  expect-eq  !>(`(list @t)`~['even' 'odd'])
    !>((turn examples.result head))
    (expect-eq !>(`(list *)`~[2 1]) !>(values))
  ==
::
++  stored
  ::  Job 1 holds a sample under `policy`, as a split tick leaves it.
  |=  policy=timeout-policy:engine
  ^-  state:job
  =/  s  (running 2 0)
  =/  current  (need active.s)
  ?>  ?=(%property -.work.current)
  =/  run=state:engine  +.work.current
  =/  cfg  config.run
  =.  run  run(pending `[!>(0) '0' 1], config cfg(on-timeout policy))
  =/  rec  (get-record s 1)
  %=  s
    active  `[1 [%property run]]
    records.saved  (~(put by records.saved.s) 1 rec(status %running))
  ==
::
++  test-interrupt-pending-discards
  ::  An abort on a stored sample under %discard drops it and runs on.
  ^-  tang
  =/  s  (stored %discard)
  =/  got  (get-record (interrupt:job s now:bol call-time:engine) 1)
  ?>  ?=(%property -.counts.got)
  ;:  weld
    (expect-eq !>(`@ud`1) !>(dropped.+<.counts.got))
    (expect !>(=(%running status.got)))
    (expect !>(=(~ result.got)))
  ==
::
++  test-interrupt-pending-fails-as-timeout
  ::  Under %fail the same abort starts shrinking with a %timeout failure.
  ^-  tang
  =/  s  (stored %fail)
  =/  got  (get-record (interrupt:job s now:bol call-time:engine) 1)
  ;:  weld
    (expect !>(=(%shrinking status.got)))
    (expect !>(=(~ result.got)))
  ==
::
++  test-interrupt-pending-early-abort
  ::  An abort sooner than the call limit was not a timeout: Ctrl-C or the
  ::  loom interrupts the run under any policy.
  ^-  tang
  =/  early  (sub call-time:engine ~s1)
  =/  fail  (get-record (interrupt:job (stored %fail) now:bol early) 1)
  =/  discard
    (get-record (interrupt:job (stored %discard) now:bol early) 1)
  ;:  weld
    (expect !>(?=([~ %interrupted %running ~ ~] result.fail)))
    (expect !>(?=([~ %interrupted %running ~ ~] result.discard)))
  ==
::
++  test-error-wake-measures-spent
  ::  An error wake carries the aborted event's own `now`, so the agent
  ::  notes when the tick was due and judges on the next wake, timed from
  ::  there: a full call limit is a timeout, less is an interrupt.
  ^-  tang
  =/  a  ~(. agent bol)
  =/  error=(unit tang)  `~[leaf+"aborted"]
  =/  s  (stored %discard)
  =/  begun  a(state s(timer `[10 now:bol], next-token.saved 11))
  =/  held  state:+:(on-arvo.begun /quiz/tick/10 [%behn %wake error])
  =/  wake  /quiz/tick/(scot %ud token:(need timer.held))
  =/  after
    |=  gap=@dr
    ^-  record:app
    =/  later  bol
    =.  now.later  (add now:bol gap)
    =/  b  ~(. agent later)
    (get-record state:+:(on-arvo:b(state held) wake [%behn %wake ~]) 1)
  =/  slow  (after call-time:engine)
  =/  quick  (after ~s1)
  ;:  weld
    (expect-eq !>(`now:bol) !>(aborted.held))
    (expect !>(=(~ result:(get-record held 1))))
    (expect !>(=(%running status.slow)))
    (expect !>(?=([~ %interrupted %running ~ ~] result.quick)))
  ==
::
++  test-interrupt-without-pending-unchanged
  ::  An abort with nothing stored is still %interrupted under any policy.
  ^-  tang
  =/  s  (running 2 5)
  =/  current  (need active.s)
  ?>  ?=(%property -.work.current)
  =/  run=state:engine  +.work.current
  =/  cfg  config.run
  =.  run  run(config cfg(on-timeout %discard))
  =.  s  s(active `[1 [%property run]])
  =/  got  (get-record (interrupt:job s now:bol time.run) 1)
  (expect !>(?=([~ %interrupted %running ~ ~] result.got)))
::
++  test-within-lowers-call-limit
  ::  A slice runs under the lower of the ship's limit and ++within, and
  ::  records it; ++within never raises the ship's limit.
  ^-  tang
  =/  limit
    |=  within=(unit @dr)
    ^-  [@dr (unit @dr)]
    =/  s  (running 1 0)
    =/  current  (need active.s)
    ?>  ?=(%property -.work.current)
    =/  run=state:engine  +.work.current
    =.  within.run  within
    =.  s  s(active `[id.current [%property run]])
    =.  s  (advance:job s now:bol)
    =/  after  (need active.s)
    ?>  ?=(%property -.work.after)
    [time.+.work.after call:(get-record s 1)]
  ;:  weld
    (expect-eq !>([~s1 `~s1]) !>((limit `~s1)))
    (expect-eq !>([~s10 `~s10]) !>((limit ~)))
    (expect-eq !>([~s10 `~s10]) !>((limit `~s20)))
  ==
--
