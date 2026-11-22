/+  build=quiz-build, engine=quiz-engine, quiz, prop=quiz-prop, *test
/*  queue-model  %hoon  /examples/props/10-queue-model/hoon
/*  queue-bug  %hoon  /examples/failing/11-queue-model-bug/hoon
/*  labels  %hoon  /examples/props/12-labels-coverage/hoon
/*  compared  %hoon  /examples/failing/13-expected-actual/hoon
/*  uncovered  %hoon  /examples/failing/14-coverage-shortfall/hoon
/*  expected  %hoon  /examples/props/15-expect-failure/hoon
|%
  ::  Bundled model-based examples, built by the document builder and run
  ::  to completion by the engine. Pins the counters quoted in examples.md.
  ::
::
++  run
  ::  Imports are the document's /+ libraries, in prelude order. The path
  ::  only locates diagnostics; a digit-led segment needs a cord.
  |=  [=path source=@t imports=(list vase)]
  ^-  state:engine
  =/  parsed  (prepare:build [~zod %quiz 1] path source)
  ?>  ?=(%.y -.parsed)
  =/  built  (compile:build p.parsed imports)
  ::  On a build failure, show the builder's diagnostic.
  ~|  ?:(?=(%invalid -.built) [code.built arm.built trace.built] ~)
  ?>  ?=(%ready -.built)
  =/  seed  (need seed.settings.built)
  =/  s  (init:engine seed config.settings.built parts.built)
  =/  left  20.000
  |-
  ?:  !=(~ result.s)  s
  ?>  (gth left 0)
  $(s (step:engine s), left (dec left))
::
++  test-queue-model
  ^-  tang
  =/  imports  ~[!>(engine) !>(quiz)]
  =/  path=path  /examples/props/'10-queue-model'/hoon
  =/  done  (run path queue-model imports)
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[107 100 0 7 0 0]) !>(counts.done))
  ==
::
++  test-queue-model-bug
  ^-  tang
  =/  path=path  /examples/failing/'11-queue-model-bug'/hoon
  =/  done  (run path queue-bug ~[!>(engine)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  original
    :~  [%size ~]  [%push 97]  [%size ~]  [%push 7]  [%push 78]  [%size ~]
        [%pop ~]  [%size ~]  [%push 22]  [%pop ~]  [%size ~]  [%size ~]
    ==
  ;:  weld
    (expect-eq !>(`counters:engine`[14 11 0 2 68 20]) !>(counts.done))
    (expect-eq !>(`failure:engine`[%false ~ ~]) !>(why.result))
    (expect-eq !>(`*`original) !>(q.original.result))
    %+  expect-eq  !>(`*`~[[%push 0] [%push 1] [%pop ~]])
    !>(q.shrunk.result)
  ==
::
++  test-labels-coverage
  ^-  tang
  =/  path=path  /examples/props/'12-labels-coverage'/hoon
  =/  done  (run path labels ~[!>(engine) !>(quiz) !>(prop)])
  =/  want  (malt `(list [@t @ud])`~[['empty' 1] ['short' 15] ['long' 84]])
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[104 100 0 4 0 0]) !>(counts.done))
    (expect-eq !>(want) !>(labels.seen-tags.done))
  ==
::
++  test-expected-actual
  ^-  tang
  =/  path=path  /examples/failing/'13-expected-actual'/hoon
  =/  done  (run path compared ~[!>(engine) !>(prop)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  note  'halving then doubling should give the value back'
  ;:  weld
    (expect-eq !>(`counters:engine`[5 2 0 2 3 1]) !>(counts.done))
    (expect-eq !>(`*`3) !>(q.original.result))
    (expect-eq !>(`*`1) !>(q.shrunk.result))
    %+  expect-eq  !>(`failure:engine`[%false ~[note] `['1' '0']])
    !>(why.result)
  ==
::
++  test-coverage-shortfall
  ^-  tang
  =/  path=path  /examples/failing/'14-coverage-shortfall'/hoon
  =/  done  (run path uncovered ~[!>(engine) !>(quiz) !>(prop)])
  =/  short=(list shortfall:engine)  ~[['empty' 10 1]]
  ;:  weld
    %+  expect-eq  !>(`(unit outcome:engine)``[%uncovered short])
    !>(result.done)
    (expect-eq !>(`counters:engine`[104 100 0 4 0 0]) !>(counts.done))
  ==
::
++  test-expect-failure
  ^-  tang
  =/  path=path  /examples/props/'15-expect-failure'/hoon
  =/  done  (run path expected ~[!>(engine)])
  =/  result  (need result.done)
  ?>  ?=(%failed-as-expected -.result)
  ;:  weld
    (expect-eq !>(`counters:engine`[13 6 0 6 4 1]) !>(counts.done))
    (expect-eq !>(`*`11) !>(q.original.result))
    (expect-eq !>(`*`10) !>(q.shrunk.result))
  ==
--
