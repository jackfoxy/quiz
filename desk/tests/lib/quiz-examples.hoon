/+  build=quiz-build, engine=quiz-engine, quiz, *test
/*  queue-model  %hoon  /examples/props/10-queue-model/hoon
/*  queue-bug  %hoon  /examples/failing/11-queue-model-bug/hoon
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
    (expect-eq !>([%false ~]) !>(why.result))
    (expect-eq !>(`*`original) !>(q.original.result))
    %+  expect-eq  !>(`*`~[[%push 0] [%push 1] [%pop ~]])
    !>(q.shrunk.result)
  ==
--
