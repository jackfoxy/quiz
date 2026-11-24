/+  build=quiz-build, engine=quiz-engine, quiz, prop=quiz-prop, gen=quiz-gen,
    fun=quiz-fun, h=quiz-harness, *test
/=  drive  /fixtures/quiz-harness/drive
/*  queue-model  %hoon  /examples/props/10-queue-model/hoon
/*  queue-bug  %hoon  /examples/failing/11-queue-model-bug/hoon
/*  labels  %hoon  /examples/props/12-labels-coverage/hoon
/*  compared  %hoon  /examples/failing/13-expected-actual/hoon
/*  uncovered  %hoon  /examples/failing/14-coverage-shortfall/hoon
/*  expected  %hoon  /examples/props/15-expect-failure/hoon
/*  insert  %hoon  /examples/props/16-sorted-insert/hoon
/*  bst  %hoon  /examples/failing/17-bst-delete-bug/hoon
/*  parse  %hoon  /examples/props/18-parse-print/hoon
/*  queue-gen  %hoon  /examples/failing/19-queue-gen-lib/hoon
/*  dependent  %hoon  /examples/failing/20-dependent/hoon
/*  allow  %hoon  /examples/props/21-small-domain-allow/hoon
/*  capped  %hoon  /examples/props/22-size-capped/hoon
/*  fusion  %hoon  /examples/props/23-map-fusion/hoon
/*  swap  %hoon  /examples/failing/24-filter-map-swap/hoon
/*  counter-src  %hoon  /examples/props/25-counter-agent/hoon
/*  counter-bug-src  %hoon  /examples/failing/26-counter-agent-bug/hoon
/*  confident  %hoon  /examples/props/28-confident-coverage/hoon
/*  coordinated  %hoon  /examples/failing/29-bst-coordinated/hoon
/*  inner  %hoon  /examples/failing/30-dependent-inner/hoon
/*  floats  %hoon  /examples/failing/31-float-associativity/hoon
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
  ~|  ?:(?=(%.n -.parsed) p.parsed ~)
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
::
++  test-sorted-insert
  ^-  tang
  =/  path=path  /examples/props/'16-sorted-insert'/hoon
  =/  done  (run path insert ~[!>(engine) !>(gen) !>(prop)])
  =/  want
    %-  malt
    `(list [@t @ud])`~[['empty' 3] ['front' 18] ['middle' 65] ['end' 14]]
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[100 100 0 0 0 0]) !>(counts.done))
    (expect-eq !>(want) !>(labels.seen-tags.done))
  ==
::
++  test-bst-delete-bug
  ::  Keys and the deleted key shrink independently, so they stop at a
  ::  three-key tree whose root is deleted.
  ^-  tang
  =/  path=path  /examples/failing/'17-bst-delete-bug'/hoon
  =/  done  (run path bst ~[!>(engine) !>(gen)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`counters:engine`[18 17 0 0 60 6]) !>(counts.done))
    %+  expect-eq  !>(`*`[~[2 19 18 12 6 15 7 3 15] 12])
    !>(q.original.result)
    (expect-eq !>(`*`[~[12 0 13] 12]) !>(q.shrunk.result))
  ==
::
++  test-parse-print
  ^-  tang
  =/  path=path  /examples/props/'18-parse-print'/hoon
  =/  done  (run path parse ~[!>(engine) !>(gen) !>(prop)])
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[100 100 0 0 0 0]) !>(counts.done))
  ==
::
++  test-queue-gen-lib
  ::  The library-built shrinker reaches example 11's minimum.
  ^-  tang
  =/  path=path  /examples/failing/'19-queue-gen-lib'/hoon
  =/  done  (run path queue-gen ~[!>(engine) !>(gen)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  original  ~[[%push 97] [%push 27] [%pop ~] [%size ~]]
  ;:  weld
    (expect-eq !>(`counters:engine`[4 3 0 0 46 7]) !>(counts.done))
    (expect-eq !>(`*`original) !>(q.original.result))
    %+  expect-eq  !>(`*`~[[%push 0] [%push 1] [%pop ~]])
    !>(q.shrunk.result)
  ==
::
++  test-dependent
  ::  The list shrinks to one element, whose index is necessarily the last.
  ^-  tang
  =/  path=path  /examples/failing/'20-dependent'/hoon
  =/  done  (run path dependent ~[!>(engine) !>(gen)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  start  ;;([(list @ud) @uv @ud (unit @ud)] q.original.result)
  =/  end  ;;([(list @ud) @uv @ud (unit @ud)] q.shrunk.result)
  ;:  weld
    (expect-eq !>(`counters:engine`[1 0 0 0 5 2]) !>(counts.done))
    =/  want=[(list @ud) @ud (unit @ud)]  [~[19] 1 ~]
    (expect-eq !>(want) !>([-.start +>.start]))
    =/  want=[(list @ud) @ud (unit @ud)]  [~[0] 0 ~]
    (expect-eq !>(want) !>([-.end +>.end]))
    (expect-eq !>(+<.start) !>(+<.end))
  ==
::
++  test-small-domain-allow
  ::  Repeats are evaluated, so four samples cover 100 checks.
  ^-  tang
  =/  path=path  /examples/props/'21-small-domain-allow'/hoon
  =/  done  (run path allow ~[!>(engine) !>(prop)])
  =/  want
    %-  malt
    ^-  (list [@t @ud])
    ~[['both' 28] ['a only' 21] ['b only' 28] ['neither' 23]]
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[100 100 0 0 0 0]) !>(counts.done))
    (expect-eq !>(want) !>(labels.seen-tags.done))
  ==
::
++  test-size-capped
  ::  Size grows to the cap and stays there.
  ^-  tang
  =/  path=path  /examples/props/'22-size-capped'/hoon
  =/  done  (run path capped ~[!>(engine) !>(gen)])
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[100 100 0 0 0 0]) !>(counts.done))
    (expect-eq !>(`@ud`30) !>(size.done))
  ==
::
++  test-map-fusion
  ^-  tang
  =/  path=path  /examples/props/'23-map-fusion'/hoon
  =/  done  (run path fusion ~[!>(engine) !>(gen) !>(fun)])
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[100 100 0 0 0 0]) !>(counts.done))
  ==
::
++  test-filter-map-swap
  ::  Keys never shrink, so the item stays 8: the key p's case names.
  ^-  tang
  =/  path=path  /examples/failing/'24-filter-map-swap'/hoon
  =/  done  (run path swap ~[!>(engine) !>(gen) !>(fun) !>(prop)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  shrunk  [~[8] [~ 0] [~[[8 &]] |]]
  =/  notes  ~['f = {_ -> 0}' 'p = {8 -> %.y, _ -> %.n}']
  ;:  weld
    (expect-eq !>(`counters:engine`[8 7 0 0 37 5]) !>(counts.done))
    (expect-eq !>(`*`shrunk) !>(q.shrunk.result))
    %+  expect-eq
      !>(`failure:engine`[%false notes `['~[0]' '~']])
    !>(why.result)
  ==
::
++  test-counter-agent
  ::  Adds stay at most nine, where the agent and the model agree.
  ^-  tang
  =/  path=path  /examples/props/'25-counter-agent'/hoon
  =/  done
    (run path counter-src ~[!>(engine) !>(gen) !>(prop) !>(h) !>(drive)])
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[105 100 0 5 0 0]) !>(counts.done))
  ==
::
++  test-counter-agent-bug
  ::  The lost update shrinks to one add of eleven.
  ^-  tang
  =/  path=path  /examples/failing/'26-counter-agent-bug'/hoon
  =/  done
    (run path counter-bug-src ~[!>(engine) !>(gen) !>(prop) !>(h) !>(drive)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  shrunk  ;;((list [%add @ud]) q.shrunk.result)
  ;:  weld
    (expect-eq !>(`counters:engine`[2 1 0 0 21 4]) !>(counts.done))
    (expect-eq !>(~[[%add 11]]) !>(shrunk))
    %+  expect-eq
      !>(`failure:engine`[%false ~ `['11' '0']])
    !>(why.result)
  ==
::
++  test-confident-coverage
  ::  Undecided at 100, 200 and 400 checks; covered at 800.
  ^-  tang
  =/  path=path  /examples/props/'28-confident-coverage'/hoon
  =/  done  (run path confident ~[!>(engine) !>(prop)])
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[800 800 0 0 0 0]) !>(counts.done))
    %+  expect-eq  !>((malt `(list [@t @ud])`~[['heads' 377]]))
    !>(labels.seen-tags.done)
  ==
::
++  test-bst-coordinated
  ::  Equal keys shrink together, below example 17's [~[12 0 13] 12].
  ^-  tang
  =/  path=path  /examples/failing/'29-bst-coordinated'/hoon
  =/  done  (run path coordinated ~[!>(engine) !>(gen)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`counters:engine`[18 17 0 0 146 14]) !>(counts.done))
    (expect-eq !>(`*`[~[1 0 2] 1]) !>(q.shrunk.result))
  ==
::
++  test-dependent-inner
  ::  The bound stops shrinking; the pinned list shrinks to ~[90].
  ^-  tang
  =/  path=path  /examples/failing/'30-dependent-inner'/hoon
  =/  done  (run path inner ~[!>(engine) !>(gen)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  start  ;;([@ud @uv @ud (unit (list @ud))] q.original.result)
  =/  end  ;;([@ud @uv @ud (unit (list @ud))] q.shrunk.result)
  =/  want=[@ud @uv @ud (unit (list @ud))]  [1 0v0 0 `~[90]]
  ;:  weld
    (expect-eq !>(`counters:engine`[3 2 0 0 24 5]) !>(counts.done))
    =/  begin=[@ud @ud (unit (list @ud))]  [8 3 ~]
    (expect-eq !>(begin) !>([-.start +>.start]))
    (expect-eq !>(want) !>(end))
  ==
::
++  test-float-associativity
  ::  Rounded sums differ; the triple shrinks to short decimals.
  ^-  tang
  =/  path=path  /examples/failing/'31-float-associativity'/hoon
  =/  done  (run path floats ~[!>(engine) !>(gen)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  want=[@rd @rd @rd]  [.~-1.2 .~-1 .~1]
  ;:  weld
    (expect-eq !>(`counters:engine`[6 5 0 0 33 4]) !>(counts.done))
    (expect-eq !>(want) !>(;;([@rd @rd @rd] q.shrunk.result)))
  ==
--
