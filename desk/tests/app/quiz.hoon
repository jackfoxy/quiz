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
  [[%draft '|%  ++  fate  |=(@ud &)  --'] %quiz [%ud 1] ~ ~ ~]
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
    [!>(|=(n=@ud &)) `!>(|=([size=@ud rng=_og] size)) ~]
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
  =/  done  (finish:job a 1 [%passed ~] now:bol)
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
  =/  cfg  defaults:engine
  =/  req=request:app  request
  =.  req  req(config `cfg(samples-per-slice.bounds 0))
  =/  bad-conf  (admit:job initial:job req now:bol 0v0)
  =/  oversized  (bex (mul 8 source-bytes.bounds.cfg))
  =.  req  req(source [%draft oversized], config ~)
  =/  bad-source  (admit:job initial:job req now:bol 0v0)
  ;:  weld
    (expect !>(?=([%.n %conf-range] bad-conf)))
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
    (expect !>(?=([~ %passed ~] result.rec)))
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
  =.  s  (finish:job s 1 [%passed ~] now:bol)
  =.  s  (finish:job s 2 [%passed ~] now:bol)
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
  =.  s  (finish:job s 3 [%passed ~] now:bol)
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
  =.  s  (finish:job s 2 [%passed ~] now:bol)
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
    [[%false ~] !>(`@ud`541) !>(`@ud`501)]
  =/  got  (persist-outcome:job [%failed evidence])
  ?>  ?=(%failed -.got)
  ;:  weld
    (expect-eq !>(541) !>(value.original.got))
    (expect-eq !>(501) !>(value.shrunk.got))
    (expect-eq !>('501') !>(text.shrunk.got))
    (expect !>(=(got (cue (jam got)))))
  ==
::
++  test-property-settings-and-replay
  ^-  tang
  =/  text  '|%  ++  fate  |=(@ud &)  --'
  =/  doc  (prepare:build [~zod %quiz 1] /draft/hoon text)
  ?>  ?=(%.y -.doc)
  =/  s  (activate:job (queued 1) now:bol)
  =/  rec  (get-record s 1)
  =/  cfg  defaults:engine
  =.  cfg  cfg(requested 3)
  =.  rec  rec(request request.rec(config `cfg, seed `0v0))
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
++  test-replay-unavailable
  ^-  tang
  =/  req  request
  =.  req  req(replay-of `1)
  =/  got  (admit:job initial:job req now:bol 0v0)
  (expect !>(?=([%.n %replay-unavailable] got)))
::
++  test-delete-fact-and-kick
  ^-  tang
  =/  s  (finish:job (queued 1) 1 [%passed ~] now:bol)
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
--
