/+  build=quiz-build, engine=quiz-engine, quiz, prop=quiz-prop, gen=quiz-gen,
    fun=quiz-fun, h=quiz-harness, *test
/=  drive  /fixtures/quiz-harness/drive
/=  drive-expiry  /fixtures/quiz-harness/drive-expiry
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
/*  expiry-src  %hoon  /examples/props/32-expiry-agent/hoon
/*  expiry-bug-src  %hoon  /examples/failing/33-expiry-agent-bug/hoon
/*  typed  %hoon  /examples/failing/34-typed-defaults/hoon
/*  table  %hoon  /examples/props/35-cover-table/hoon
/*  weak  %hoon  /examples/props/36-weak-generator/hoon
/*  strong  %hoon  /examples/props/37-insert-generated/hoon
/*  custom  %hoon  /examples/failing/09-custom-alts/hoon
/*  order  %hoon  /examples/failing/38-shrink-order/hoon
/*  together  %hoon  /examples/failing/39-shrink-together/hoon
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
  (run-steps path source imports ~ ~)
::
++  run-steps
  ::  As ++run, with the shrink trace's length set when `steps` is given,
  ::  or as a preview of `count` samples with verdicts when that is.
  |=  $:  =path  source=@t  imports=(list vase)
          steps=(unit @ud)  count=(unit @ud)
      ==
  ^-  state:engine
  =/  parsed  (prepare:build [~zod %quiz 1] path source)
  ~|  ?:(?=(%.n -.parsed) p.parsed ~)
  ?>  ?=(%.y -.parsed)
  =/  built  (compile:build p.parsed imports)
  ::  On a build failure, show the builder's diagnostic.
  ~|  ?:(?=(%invalid -.built) [code.built arm.built trace.built] ~)
  ?>  ?=(%ready -.built)
  =/  seed  (need seed.settings.built)
  =/  cfg  config.settings.built
  =?  trace-steps.bounds.cfg  ?=(^ steps)  u.steps
  =/  s  (init:engine seed cfg parts.built)
  =?  s  ?=(^ count)  (previewing:engine s u.count & |)
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
  =/  short=(list shortfall:engine)  ~[['empty' 10 1 ~]]
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
::
++  test-expiry-agent
  ::  With its fix, the agent's timers agree with the model.
  ^-  tang
  =/  path=path  /examples/props/'32-expiry-agent'/hoon
  =/  imports=(list vase)
    ~[!>(engine) !>(gen) !>(prop) !>(h) !>(drive-expiry)]
  =/  done  (run path expiry-src imports)
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[115 100 0 15 0 0]) !>(counts.done))
  ==
::
++  test-expiry-agent-bug
  ::  The early expiry shrinks to two puts of one key and a wait.
  ^-  tang
  =/  path=path  /examples/failing/'33-expiry-agent-bug'/hoon
  =/  imports=(list vase)
    ~[!>(engine) !>(gen) !>(prop) !>(h) !>(drive-expiry)]
  =/  done  (run path expiry-bug-src imports)
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  =/  want=(list *)
    ~[[%put %a 0 ~s1] [%put %a 0 ~s2] [%wait ~s1]]
  ;:  weld
    (expect-eq !>(`counters:engine`[9 6 0 2 56 7]) !>(counts.done))
    (expect-eq !>(`*`want) !>(q.shrunk.result))
  ==
::
++  test-typed-defaults
  ::  No norn or alts: the list is recognized and shrinks to three %a tags.
  ^-  tang
  =/  path=path  /examples/failing/'34-typed-defaults'/hoon
  =/  done  (run path typed ~[!>(engine)])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`counters:engine`[3 2 0 0 44 8]) !>(counts.done))
    (expect-eq !>(`*`['' ~[%a %a %a]]) !>(q.shrunk.result))
  ==
::
++  test-cover-table
  ::  Each required value is at least 5 percent of the table's entries.
  ^-  tang
  =/  path=path  /examples/props/'35-cover-table'/hoon
  =/  done  (run path table ~[!>(engine) !>(gen) !>(prop)])
  =/  least  (~(gut by tables.seen-tags.done) 'least' ~)
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[164 100 0 64 0 0]) !>(counts.done))
    (expect-eq !>(`@ud`99) !>((roll ~(val by least) add)))
  ==
::
++  test-weak-generator
  ::  36 passes on mostly dropped samples and short lists; 37, generating
  ::  sorted lists, drops none and makes long ones common.
  ^-  tang
  =/  imports  ~[!>(engine) !>(gen) !>(prop)]
  =/  weak-path=path  /examples/props/'36-weak-generator'/hoon
  =/  strong-path=path  /examples/props/'37-insert-generated'/hoon
  =/  one  (run weak-path weak imports)
  =/  two  (run strong-path strong imports)
  =/  long
    |=  s=state:engine
    ^-  @ud
    (~(gut by labels.seen-tags.s) 'long' 0)
  ::  Preview's generator summary shows the same, 200 samples each.
  =/  summed
    |=  [=path source=@t]
    ^-  summary:engine
    =/  done  (run-steps path source imports ~ `200)
    =/  out  (need result.done)
    ?>  ?=(%preview -.out)
    summary.out
  =/  weak-sum  (summed weak-path weak)
  =/  strong-sum  (summed strong-path strong)
  =/  drops
    |=  sum=summary:engine
    ^-  @ud
    (~(gut by verdicts.sum) %drop 0)
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.one))
    (expect-eq !>(`(unit outcome:engine)``[%passed ~]) !>(result.two))
    (expect-eq !>(`counters:engine`[324 100 215 9 0 0]) !>(counts.one))
    (expect-eq !>(`counters:engine`[101 100 0 1 0 0]) !>(counts.two))
    (expect-eq !>(`[@ud @ud]`[6 61]) !>([(long one) (long two)]))
    %+  expect-eq  !>(`[@ud @ud]`[132 0])
    !>([(drops weak-sum) (drops strong-sum)])
    =/  weak-long  (~(gut by labels.weak-sum) 'long' 0)
    =/  strong-long  (~(gut by labels.strong-sum) 'long' 0)
    (expect-eq !>(`[@ud @ud]`[1 119]) !>([weak-long strong-long]))
  ==
::
++  test-shrink-order
  ::  One bug, two shrinkers: field by field reaches ~[[4 1]]; quantity
  ::  and price shrinking together stop at a heavier order.
  ^-  tang
  =/  imports  ~[!>(engine) !>(gen)]
  =/  one  (run /examples/failing/'38-shrink-order'/hoon order imports)
  =/  two  (run /examples/failing/'39-shrink-together'/hoon together imports)
  =/  a  (need result.one)
  =/  b  (need result.two)
  ?>  &(?=(%failed -.a) ?=(%failed -.b))
  =/  start  ~[[4 13] [0 33] [0 18]]
  ;:  weld
    (expect-eq !>(`*`start) !>(q.original.a))
    (expect-eq !>(`*`start) !>(q.original.b))
    (expect-eq !>(`counters:engine`[1 0 0 0 35 6]) !>(counts.one))
    (expect-eq !>(`*`~[[4 1]]) !>(q.shrunk.a))
    (expect-eq !>(`counters:engine`[1 0 0 0 9 2]) !>(counts.two))
    (expect-eq !>(`*`~[[4 13]]) !>(q.shrunk.b))
  ==
::
++  test-trace-invariant
  ::  The shrink trace never changes a run: examples 09, 11, 17 and 29
  ::  end identically with tracing off, apart from the trace itself.
  ^-  tang
  =/  both
    |=  [=path source=@t imports=(list vase)]
    ^-  ?
    =/  on  (run-steps path source imports `100 ~)
    =/  off  (run-steps path source imports `0 ~)
    =/  a  (need result.on)
    =/  b  (need result.off)
    ?>  &(?=(%failed -.a) ?=(%failed -.b))
    ?&  =(counts.on counts.off)
        =(q.shrunk.a q.shrunk.b)
        =(texts.a texts.b)
        =(~ trace.b)
        ?=(^ trace.a)
    ==
  =/  with-gen  ~[!>(engine) !>(gen)]
  ;:  weld
    %-  expect
    !>((both /examples/failing/'09-custom-alts'/hoon custom ~[!>(engine)]))
    =/  queue=path  /examples/failing/'11-queue-model-bug'/hoon
    (expect !>((both queue queue-bug ~[!>(engine)])))
    (expect !>((both /examples/failing/'17-bst-delete-bug'/hoon bst with-gen)))
    %-  expect
    !>((both /examples/failing/'29-bst-coordinated'/hoon coordinated with-gen))
  ==
--
