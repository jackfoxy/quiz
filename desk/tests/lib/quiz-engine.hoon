/+  engine=quiz-engine, *test
|%
::
++  sized  !>(|=([size=@ud rng=_og] ^-(@ud size)))
::
++  no-alts  !>(|=(vase *(list vase)))
::
++  config
  |=  [requested=@ud attempts=@ud drops=@ud duplicates=@ud]
  ^-  conf:engine
  [requested attempts drops duplicates bounds:defaults:engine]
::
++  start
  |=  [fate=vase norn=(unit vase)]
  ^-  state:engine
  (init:engine 0v1 (config 3 10 5 5) [fate norn `no-alts])
::
++  complete
  ::  A broken completion condition must fail instead of hanging the suite.
  |=  s=state:engine
  ^-  state:engine
  =/  left  20
  |-
  ?:  !=(~ result.s)  s
  ?>  (gth left 0)
  $(s (step:engine s), left (dec left))
::
++  test-init-and-one-step
  ^-  tang
  =/  s  (start !>(|=(@ud &)) `sized)
  =/  next  (step:engine s)
  ;:  weld
    (expect-eq !>(`@uv`1) !>(seed.s))
    (expect-eq !>(`@ud`1) !>(size.s))
    (expect-eq !>(*(unit outcome:engine)) !>(result.s))
    (expect-eq !>(`counters:engine`[1 1 0 0 0 0]) !>(counts.next))
    (expect-eq !>(*(unit outcome:engine)) !>(result.next))
    (expect-eq !>(`counters:engine`[0 0 0 0 0 0]) !>(counts.s))
  ==
::
++  test-passed
  ^-  tang
  =/  done  (complete (start !>(|=(@ud &)) `sized))
  ;:  weld
    (expect-eq !>(`(unit outcome:engine)`[~ %passed ~]) !>(result.done))
    (expect-eq !>(`counters:engine`[3 3 0 0 0 0]) !>(counts.done))
    (expect !>(=(done (step:engine done))))
  ==
::
++  test-drops-do-not-accept
  ^-  tang
  =/  fate  !>(|=(a=@ud ?:(=(a 1) %drop %.y)))
  =/  done  (complete (start fate `sized))
  ;:  weld
    (expect !>(?=([~ %passed ~] result.done)))
    (expect-eq !>(`counters:engine`[4 3 1 0 0 0]) !>(counts.done))
  ==
::
++  test-false-and-counters
  ^-  tang
  =/  fate  !>(|=(a=@ud ?:(=(a 1) %drop =(a 2))))
  =/  done  (complete (start fate `sized))
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`failure:engine`[%false ~]) !>(why.result))
    (expect-eq !>([p:(slot 6 fate) 3]) !>(original.result))
    (expect-eq !>(original.result) !>(shrunk.result))
    (expect-eq !>(`counters:engine`[3 1 1 0 0 0]) !>(counts.done))
    (expect !>(=(done (step:engine done))))
  ==
::
++  test-crash-trace
  ^-  tang
  =/  fate  !>(|=(@ud ^-(? ~|(%engine-crash !!))))
  =/  done  (complete (start fate `sized))
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ?>  ?=(%crash -.why.result)
  ;:  weld
    (expect !>(?=(^ trace.why.result)))
    (expect-eq !>(`counters:engine`[1 0 0 0 0 0]) !>(counts.done))
  ==
::
++  test-scry
  ^-  tang
  =/  fate  !>(|=(@ud .^(? %cz /quiz-engine-missing)))
  =/  done  (complete (start fate `sized))
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect !>(?=([%scry *] why.result)))
    (expect-eq !>(`counters:engine`[1 0 0 0 0 0]) !>(counts.done))
  ==
::
++  test-bad-products
  ^-  tang
  =/  atom-fate  !>(|=(@ud 42))
  =/  cell-fate  !>(|=(@ud [0 1]))
  =/  atom-done  (complete (start atom-fate `sized))
  =/  cell-done  (complete (start cell-fate `sized))
  =/  a  (need result.atom-done)
  =/  b  (need result.cell-done)
  ?>  ?=([%failed [%bad-product *] * *] a)
  ?>  ?=([%failed [%bad-product *] * *] b)
  ;:  weld
    (expect-eq !>(`*`42) !>(product.why.a))
    (expect-eq !>(`*`[0 1]) !>(product.why.b))
  ==
::
++  test-norn-crash
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] ^-(@ud ~|(%norn-crash !!))))
  =/  done  (step:engine (start !>(|=(@ud &)) `give))
  =/  result  (need result.done)
  ?>  ?=([%error %norn [%crash *] ~] result)
  ;:  weld
    (expect !>(?=(^ trace.why.result)))
    (expect-eq !>(*counters:engine) !>(counts.done))
    (expect !>(=(done (step:engine done))))
  ==
::
++  test-norn-scry
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] .^(@ud %cz /quiz-engine-missing)))
  =/  done  (step:engine (start !>(|=(@ud &)) `give))
  ;:  weld
    (expect !>(?=([~ %error %norn [%scry *] ~] result.done)))
    (expect-eq !>(*counters:engine) !>(counts.done))
  ==
::
++  test-default-generation-crash
  ^-  tang
  ::  Inject an invalid size to make default atom generation call rad with 0.
  =/  s  (start !>(|=(@ud &)) ~)
  =/  done  (step:engine s(size 0))
  ;:  weld
    (expect !>(?=([~ %error %generate [%crash *] ~] result.done)))
    (expect-eq !>(*counters:engine) !>(counts.done))
  ==
::
++  test-default-generation
  ^-  tang
  =/  s  (start !>(|=(@ud &)) ~)
  =/  done  (complete s)
  ;:  weld
    (expect !>(?=([~ %passed ~] result.done)))
    (expect-eq !>(`@ud`3) !>(accepted.counts.done))
    (expect !>(=(done (complete s))))
  ==
::
++  test-all-dropped
  ^-  tang
  =/  done  (complete (start !>(|=(@ud %drop)) `sized))
  ;:  weld
    (expect !>(?=([~ %exhausted %drops %.y] result.done)))
    (expect-eq !>(`counters:engine`[5 0 5 0 0 0]) !>(counts.done))
    (expect !>(=(done (step:engine done))))
  ==
::
++  test-duplicates-exhaust
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] `@ud`7))
  =/  done  (complete (start !>(|=(@ud &)) `give))
  ;:  weld
    (expect !>(?=([~ %exhausted %duplicates %.n] result.done)))
    (expect-eq !>(`counters:engine`[6 1 0 5 0 0]) !>(counts.done))
  ==
::
++  test-hash-collision
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] ?:(=(size 1) 28.731 188.973)))
  =/  fate  !>(|=(a=@ud =(a 28.731)))
  =/  done  (complete (start fate `give))
  ;:  weld
    (expect-eq !>((mug 28.731)) !>((mug 188.973)))
    (expect !>(?=([~ %exhausted %duplicates %.n] result.done)))
    (expect-eq !>(`counters:engine`[6 1 0 5 0 0]) !>(counts.done))
  ==
::
++  test-all-dropped-with-duplicates
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] `@ud`7))
  =/  done  (complete (start !>(|=(@ud %drop)) `give))
  ;:  weld
    (expect !>(?=([~ %exhausted %duplicates %.y] result.done)))
    (expect-eq !>(`counters:engine`[6 0 1 5 0 0]) !>(counts.done))
  ==
::
++  test-attempt-budget
  ^-  tang
  =/  s  (start !>(|=(@ud &)) `sized)
  =/  done  (complete s(attempts-max.config 2))
  ;:  weld
    (expect !>(?=([~ %exhausted %attempts %.n] result.done)))
    (expect-eq !>(`counters:engine`[2 2 0 0 0 0]) !>(counts.done))
  ==
::
++  test-zero-requested
  ^-  tang
  =/  s  (init:engine 0v1 (config 0 0 0 0) [!>(|=(@ud !!)) ~ ~])
  ;:  weld
    (expect !>(?=([~ %passed ~] result.s)))
    (expect-eq !>(*counters:engine) !>(counts.s))
    (expect !>(=(s (step:engine s))))
  ==
::
++  test-zero-budgets
  ^-  tang
  =/  compiled=parts:engine  [!>(|=(@ud !!)) ~ ~]
  =/  a  (init:engine 0v1 (config 1 0 5 5) compiled)
  =/  b  (init:engine 0v1 (config 1 5 0 5) compiled)
  =/  c  (init:engine 0v1 (config 1 5 5 0) compiled)
  ;:  weld
    (expect !>(?=([~ %exhausted %attempts %.n] result.a)))
    (expect !>(?=([~ %exhausted %drops %.n] result.b)))
    (expect !>(?=([~ %exhausted %duplicates %.n] result.c)))
    (expect !>(=(a (step:engine a))))
    (expect !>(=(b (step:engine b))))
    (expect !>(=(c (step:engine c))))
  ==
::
++  test-boundary-precedence
  ^-  tang
  =/  compiled=parts:engine  [!>(|=(@ud &)) `sized `no-alts]
  =/  passed  (complete (init:engine 0v1 (config 1 1 1 1) compiled))
  =/  drop-parts=parts:engine  [!>(|=(@ud %drop)) `sized `no-alts]
  =/  dropped  (complete (init:engine 0v1 (config 1 1 1 1) drop-parts))
  =/  fail-parts=parts:engine  [!>(|=(@ud |)) `sized `no-alts]
  =/  failed  (complete (init:engine 0v1 (config 1 1 1 1) fail-parts))
  ;:  weld
    (expect !>(?=([~ %passed ~] result.passed)))
    (expect !>(?=([~ %exhausted %attempts %.y] result.dropped)))
    (expect !>(?=([~ %failed [%false ~] * *] result.failed)))
  ==
::
++  test-fixed-seed-resume
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] (rad:rng 65.536)))
  =/  compiled=parts:engine  [!>(|=(@ud &)) `give `no-alts]
  =/  first  (init:engine 0v1a (config 3 10 5 5) compiled)
  =/  checkpoint  (step:engine (step:engine first))
  =/  done  (complete first)
  =/  other  (complete (init:engine 0v1b (config 3 10 5 5) compiled))
  ;:  weld
    (expect !>(=(done (complete checkpoint))))
    (expect !>(=(done (complete first))))
    (expect !>(!=(seen.done seen.other)))
    (expect-eq !>(`counters:engine`[2 2 0 0 0 0]) !>(counts.checkpoint))
  ==
::
++  test-fixed-seed-counterexample
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] (rad:rng 65.536)))
  =/  compiled=parts:engine  [!>(|=(@ud |)) `give `no-alts]
  =/  a  (complete (init:engine 0v1a (config 3 10 5 5) compiled))
  =/  b  (complete (init:engine 0v1a (config 3 10 5 5) compiled))
  =/  c  (complete (init:engine 0v1b (config 3 10 5 5) compiled))
  ;:  weld
    (expect-eq !>(result.a) !>(result.b))
    (expect !>(!=(result.a result.c)))
  ==
::
++  test-recursive-sample-type-limit
  ^-  tang
  =/  fate  !>(|=(items=(list @ud) =(items (flop (flop items)))))
  =/  give
    !>  |=  [size=@ud rng=_og]
        ^-  (list @ud)
        ~[size]
  =/  initial  (start fate `give)
  =/  done  (step:engine initial(sample-bytes.bounds.config 1))
  ;:  weld
    (expect !>(?=([~ %limited %sample-bytes ~] result.done)))
    (expect-eq !>(`counters:engine`[1 0 0 0 0 0]) !>(counts.done))
  ==
::
++  test-call-time-default
  ::  Every user call runs under %jinx; a returning call is unaffected.
  ^-  tang
  =/  limit  call-time.bounds:defaults:engine
  =/  crashed  (sandbox:engine limit |=(n=@ud !!) 0)
  ;:  weld
    (expect-eq !>(~s10) !>(limit))
    (expect-eq !>(%quiz-engine-2) !>(version:engine))
    %+  expect-eq  !>(`toon`[%0 42])
    !>((sandbox:engine limit |=(n=@ud +(n)) 41))
    (expect !>(?=(%2 -.crashed)))
  ==
--
