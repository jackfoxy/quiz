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
  :*  requested  attempts  drops  duplicates  1  0  %mug
      bounds:defaults:engine  %interrupt
  ==
::
++  sizes
  ::  The size each of the next `n` samples is generated at.
  |=  [n=@ud s=state:engine]
  ^-  (list @ud)
  ?:  |(=(0 n) !=(~ result.s))  ~
  [size.s $(n (dec n), s (step:engine s))]
::
++  start
  |=  [fate=vase norn=(unit vase)]
  ^-  state:engine
  (init:engine 0v1 (config 3 10 5 5) [fate norn `no-alts ~ %pass])
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
    (expect-eq !>(`failure:engine`[%false ~ ~]) !>(why.result))
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
  =/  s  (init:engine 0v1 (config 0 0 0 0) [!>(|=(@ud !!)) ~ ~ ~ %pass])
  ;:  weld
    (expect !>(?=([~ %passed ~] result.s)))
    (expect-eq !>(*counters:engine) !>(counts.s))
    (expect !>(=(s (step:engine s))))
  ==
::
++  test-zero-budgets
  ^-  tang
  =/  compiled=parts:engine  [!>(|=(@ud !!)) ~ ~ ~ %pass]
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
  =/  compiled=parts:engine  [!>(|=(@ud &)) `sized `no-alts ~ %pass]
  =/  passed  (complete (init:engine 0v1 (config 1 1 1 1) compiled))
  =/  drop-parts=parts:engine  [!>(|=(@ud %drop)) `sized `no-alts ~ %pass]
  =/  dropped  (complete (init:engine 0v1 (config 1 1 1 1) drop-parts))
  =/  fail-parts=parts:engine  [!>(|=(@ud |)) `sized `no-alts ~ %pass]
  =/  failed  (complete (init:engine 0v1 (config 1 1 1 1) fail-parts))
  ;:  weld
    (expect !>(?=([~ %passed ~] result.passed)))
    (expect !>(?=([~ %exhausted %attempts %.y] result.dropped)))
    (expect !>(?=([~ %failed [%false ~ ~] * *] result.failed)))
  ==
::
++  boundary
  ::  Every budget is one sample: requested, attempts, drops, duplicates.
  |=  [fate=vase policy=timeout-policy:engine]
  ^-  state:engine
  =/  cfg  (config 1 1 1 1)
  (init:engine 0v1 cfg(on-timeout policy) [fate `sized `no-alts ~ %pass])
::
++  test-boundary-precedence-split
  ::  The last permitted attempt is judged before budgets apply: split
  ::  runs end as %interrupt runs do, with nothing left pending.
  ^-  tang
  =/  fates=(list vase)  ~[!>(|=(@ud &)) !>(|=(@ud %drop)) !>(|=(@ud |))]
  %-  zing
  %+  turn  fates
  |=  fate=vase
  ^-  tang
  =/  plain  (complete (boundary fate %interrupt))
  =/  fail  (complete (boundary fate %fail))
  =/  discard  (complete (boundary fate %discard))
  ;:  weld
    (expect-eq !>(result.plain) !>(result.fail))
    (expect-eq !>(result.plain) !>(result.discard))
    (expect-eq !>(counts.plain) !>(counts.fail))
    (expect-eq !>(counts.plain) !>(counts.discard))
    (expect !>(&(=(~ pending.fail) =(~ pending.discard))))
  ==
::
++  test-timeout-last-attempt
  ::  A hang on the only permitted attempt is still handled by the policy.
  ^-  tang
  =/  fate  !>(|=(@ud &))
  =/  failed
    (complete (timed-out:engine (step:engine (boundary fate %fail))))
  =/  discarded
    (complete (timed-out:engine (step:engine (boundary fate %discard))))
  ;:  weld
    (expect !>(?=([~ %failed [%timeout ~] * *] result.failed)))
    (expect !>(?=([~ %exhausted %attempts %.y] result.discarded)))
    (expect-eq !>(`counters:engine`[1 0 1 0 0 0]) !>(counts.discarded))
  ==
::
++  test-fixed-seed-resume
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] (rad:rng 65.536)))
  =/  compiled=parts:engine  [!>(|=(@ud &)) `give `no-alts ~ %pass]
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
  =/  compiled=parts:engine  [!>(|=(@ud |)) `give `no-alts ~ %pass]
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
  =/  done  (step:engine initial(sample-bytes.bounds.config 0))
  ;:  weld
    (expect !>(?=([~ %limited %sample-bytes ~] result.done)))
    (expect-eq !>(`counters:engine`[1 0 0 0 0 0]) !>(counts.done))
  ==
::
++  test-duplicate-small-domain
  ::  Mug deduplication exhausts a two-value domain long before ten passes.
  ^-  tang
  =/  s  (init:engine 0v1 (config 10 100 5 5) [!>(|=(? &)) ~ `no-alts ~ %pass])
  =/  done  (complete s)
  ;:  weld
    (expect !>(?=([~ %exhausted %duplicates *] result.done)))
    (expect !>((lte accepted.counts.done 2)))
  ==
::
++  test-seen-matches-evaluated
  ::  Each evaluated sample's mug is kept once; duplicates add none.
  ^-  tang
  =/  fate  !>(|=(a=@ud ?:(=(0 (mod a 2)) & %drop)))
  =/  s  (init:engine 0v1 (config 8 200 50 50) [fate ~ `no-alts ~ %pass])
  =/  done
    =/  left  200
    |-  ^-  state:engine
    ?:  !=(~ result.s)  s
    ?>  (gth left 0)
    $(s (step:engine s), left (dec left))
  =/  counts  counts.done
  ;:  weld
    (expect !>(?=([~ %passed ~] result.done)))
    (expect !>((gth duplicate.counts 0)))
    %+  expect-eq  !>((add accepted.counts dropped.counts))
    !>(~(wyt by seen.done))
  ==
::
++  test-size-progression
  ::  The default growth: one more each sample, then about 1.1 times.
  ^-  tang
  =/  s  (init:engine 0v1 (config 20 40 5 5) [!>(|=(@ud &)) `sized ~ ~ %pass])
  %+  expect-eq  !>(`(list @ud)`~[1 2 3 4 5 6 7 8 9 10 11 13 15 17])
  !>((sizes 14 s))
::
++  test-size-start-and-cap
  ::  size-start sets the first size; size-max holds every later one.
  ^-  tang
  =/  cfg  (config 20 40 5 5)
  =/  =parts:engine  [!>(|=(@ud &)) `sized ~ ~ %pass]
  =/  capped  (init:engine 0v1 cfg(size-start 5, size-max 8) parts)
  =/  zero  (init:engine 0v1 cfg(size-start 0) parts)
  =/  low  (init:engine 0v1 cfg(size-start 9, size-max 4) parts)
  ;:  weld
    %+  expect-eq  !>(`(list @ud)`~[5 6 7 8 8 8])
    !>((sizes 6 capped(duplicates.config %allow)))
    (expect-eq !>(`@ud`1) !>(size.zero))
    (expect-eq !>(`@ud`4) !>(size.low))
  ==
::
++  test-allow-small-domain
  ::  %allow evaluates repeats, so a two-value domain reaches ten passes.
  ^-  tang
  =/  cfg  (config 10 100 5 0)
  =/  =parts:engine  [!>(|=(? &)) ~ `no-alts ~ %pass]
  =/  done  (complete (init:engine 0v1 cfg(duplicates %allow) parts))
  ;:  weld
    (expect !>(?=([~ %passed ~] result.done)))
    (expect-eq !>(`counters:engine`[10 10 0 0 0 0]) !>(counts.done))
    (expect-eq !>(*(jar @ *)) !>(seen.done))
  ==
::
++  test-exact-collision
  ::  Two nouns with one mug: %mug skips the second, %exact evaluates it.
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] ?:(=(size 1) 28.731 188.973)))
  =/  fate  !>(|=(a=@ud =(a 28.731)))
  =/  cfg  (config 3 10 5 5)
  =/  =parts:engine  [fate `give `no-alts ~ %pass]
  =/  done  (complete (init:engine 0v1 cfg(duplicates %exact) parts))
  ;:  weld
    (expect !>(?=([~ %failed [%false ~ ~] * *] result.done)))
    (expect-eq !>(`counters:engine`[2 1 0 0 0 0]) !>(counts.done))
  ==
::
++  test-exact-repeats
  ::  %exact still skips an equal noun, and charges each kept noun's bytes.
  ^-  tang
  =/  give  !>(|=([size=@ud rng=_og] `@ud`7))
  =/  cfg  (config 3 10 5 2)
  =/  =parts:engine  [!>(|=(@ud &)) `give `no-alts ~ %pass]
  =/  done  (complete (init:engine 0v1 cfg(duplicates %exact) parts))
  ;:  weld
    (expect !>(?=([~ %exhausted %duplicates %.n] result.done)))
    (expect-eq !>(`counters:engine`[3 1 0 2 0 0]) !>(counts.done))
    (expect-eq !>((met 3 (jam 7))) !>(seen-used.done))
  ==
::
++  test-seen-bytes-limit
  ::  Kept nouns beyond seen-bytes stop an %exact run.
  ^-  tang
  =/  cfg  (config 10 40 5 5)
  =.  cfg  cfg(duplicates %exact, seen-bytes.bounds 3)
  =/  =parts:engine  [!>(|=(@ud &)) `sized `no-alts ~ %pass]
  =/  done  (complete (init:engine 0v1 cfg parts))
  (expect !>(?=([~ %limited %seen-bytes ~] result.done)))
::
++  finished
  ::  Run to completion with a generous bound for label and limit tests.
  |=  [cfg=conf:engine =parts:engine]
  ^-  state:engine
  =/  s  (init:engine 0v1 cfg parts)
  =/  left  400
  |-
  ?:  !=(~ result.s)  s
  ?>  (gth left 0)
  $(s (step:engine s), left (dec left))
::
++  parity
  ::  Sizes 1 to 10 in order: five odd and five even samples.
  !>  |=  n=@ud
      ^-  report:engine
      =/  tag  ?:(=(0 (mod n 2)) 'even' 'odd')
      [%report & [~ ~] ~[tag tag] ~[['parity' tag] ['all' 'x']]]
::
++  test-render-cap-only-kept
  ::  Only kept samples render: untagged passes ignore rendered-bytes, a
  ::  label's first example is held to it.
  ^-  tang
  ::  Old rules stopped both: '10' and 'n=10' are over their caps.
  =/  cfg  (config 10 20 5 5)
  =/  one  cfg(rendered-bytes.bounds 1)
  =/  three  cfg(rendered-bytes.bounds 3)
  =/  plain  (finished one [!>(|=(@ud &)) `sized `no-alts ~ %pass])
  =/  tagged  (finished three [parity `sized `no-alts ~ %pass])
  ;:  weld
    (expect !>(?=([~ %passed ~] result.plain)))
    (expect !>(?=([~ %passed ~] result.tagged)))
    (expect-eq !>('n=1') !>(text:(~(got by examples.tagged) 'odd')))
  ==
::
++  test-report-tags
  ::  Labels count once per sample; table rows count every value.
  ^-  tang
  =/  done  (finished (config 10 20 5 5) [parity `sized `no-alts ~ %pass])
  =/  tables  tables.seen-tags.done
  ;:  weld
    (expect !>(?=([~ %passed ~] result.done)))
    %+  expect-eq  !>((malt `(list [@t @ud])`~[['even' 5] ['odd' 5]]))
    !>(labels.seen-tags.done)
    %+  expect-eq  !>((malt `(list [@t @ud])`~[['x' 10]]))
    !>((~(got by tables) 'all'))
    (expect-eq !>(`*`1) !>(q.vase:(~(got by examples.done) 'odd')))
    (expect-eq !>(`*`2) !>(q.vase:(~(got by examples.done) 'even')))
  ==
::
++  test-report-verdicts
  ::  A report's verdict maps like a bare one; only passes are tallied.
  ^-  tang
  =/  fate
    !>  |=  n=@ud
        ^-  report:engine
        [%report ?:(=(0 (mod n 2)) & %drop) [~ ~] ~['seen'] ~]
  =/  done  (finished (config 4 20 10 5) [fate `sized `no-alts ~ %pass])
  ;:  weld
    (expect !>(?=([~ %passed ~] result.done)))
    (expect-eq !>(`@ud`4) !>(dropped.counts.done))
    (expect-eq !>(`(unit @ud)``4) !>((~(get by labels.seen-tags.done) 'seen')))
  ==
::
++  test-bad-report
  ^-  tang
  =/  fate  !>(|=(n=@ud [%report 7 ~]))
  =/  done  (finished (config 3 10 5 5) [fate `sized `no-alts ~ %pass])
  (expect !>(?=([~ %failed [%bad-product *] * *] result.done)))
::
++  test-label-limits
  ::  An oversized label or too many distinct labels stops the run.
  ^-  tang
  =/  long  !>(|=(n=@ud [%report & [~ ~] ~[(fil 3 257 'a')] ~]))
  =/  many  !>(|=(n=@ud [%report & [~ ~] ~[(scot %ud n)] ~]))
  =/  cfg  (config 200 400 5 5)
  =/  a  (finished cfg [long `sized `no-alts ~ %pass])
  =/  b  (finished cfg [many `sized `no-alts ~ %pass])
  ;:  weld
    (expect !>(?=([~ %limited %labels ~] result.a)))
    (expect !>(?=([~ %limited %labels ~] result.b)))
    (expect-eq !>(`@ud`100) !>(~(wyt by labels.seen-tags.b)))
  ==
::
++  test-coverage
  ::  Half the samples are even: 50 percent is met, 60 percent is not.
  ^-  tang
  =/  cfg  (config 10 20 5 5)
  =/  with
    |=  =cover:engine
    ^-  parts:engine
    [parity `sized `no-alts `cover %pass]
  =/  met  (finished cfg (with %check ~[['even' 50]]))
  =/  warn  (finished cfg (with %warn ~[['even' 60]]))
  =/  check  (finished cfg (with %check ~[['even' 60]]))
  =/  short=(list shortfall:engine)  ~[['even' 60 50]]
  ;:  weld
    (expect !>(?=([~ %passed ~] result.met)))
    (expect-eq !>(``outcome:engine`[%passed short]) !>(result.warn))
    (expect-eq !>(``outcome:engine`[%uncovered short]) !>(result.check))
  ==
::
++  test-expect-failure
  ^-  tang
  =/  cfg  (config 5 20 5 5)
  =/  fails  !>(|=(n=@ud (lth n 3)))
  =/  holds  !>(|=(n=@ud &))
  =/  a  (finished cfg [fails `sized `no-alts ~ %fail])
  =/  b  (finished cfg [holds `sized `no-alts ~ %fail])
  ;:  weld
    (expect !>(?=([~ %failed-as-expected *] result.a)))
    (expect !>(?=([~ %passed-unexpectedly ~] result.b)))
  ==
::
++  test-detail-follows-shrink
  ::  The failure's notes describe the shrunk sample, not the original.
  ^-  tang
  =/  fate
    !>  |=  n=@ud
        ^-  report:engine
        [%report (lte n 3) [~[(scot %ud n)] ~] ~ ~]
  =/  eight  !>(|=([size=@ud rng=_og] 8))
  =/  done  (finished (config 3 10 5 5) [fate `eight ~ ~ %pass])
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`*`8) !>(q.original.result))
    (expect-eq !>(`*`4) !>(q.shrunk.result))
    (expect-eq !>(`failure:engine`[%false ~['4'] ~]) !>(why.result))
  ==
::
++  test-call-time-default
  ::  Every user call runs under %jinx; a returning call is unaffected.
  ^-  tang
  =/  limit  call-time:engine
  =/  crashed  (sandbox:engine limit |=(n=@ud !!) 0)
  =/  fresh  (start !>(|=(n=@ud &)) ~)
  ;:  weld
    (expect-eq !>(~s10) !>(limit))
    (expect-eq !>(limit) !>(time.fresh))
    (expect-eq !>(%quiz-engine-7) !>(version:engine))
    %+  expect-eq  !>(`toon`[%0 42])
    !>((sandbox:engine limit |=(n=@ud +(n)) 41))
    (expect !>(?=(%2 -.crashed)))
  ==
::
++  split-config
  ::  Under %fail, generation and evaluation are separate ticks.
  |=  policy=timeout-policy:engine
  ^-  conf:engine
  =/  cfg  (config 3 10 5 5)
  cfg(on-timeout policy)
::
++  test-split-generation-then-evaluation
  ::  A split tick stores the sample; the next tick evaluates it.
  ^-  tang
  =/  fate  !>(|=(a=@ud &))
  =/  s  (init:engine 0v1 (split-config %fail) [fate `sized `no-alts ~ %pass])
  =/  stored  (step:engine s)
  =/  done  (step:engine stored)
  ;:  weld
    (expect !>(?=(^ pending.stored)))
    (expect-eq !>(`counters:engine`[1 0 0 0 0 0]) !>(counts.stored))
    (expect !>(=(~ pending.done)))
    (expect-eq !>(`counters:engine`[1 1 0 0 0 0]) !>(counts.done))
  ==
::
++  test-interrupt-policy-never-splits
  ::  Under the default policy a sample is judged in the same tick.
  ^-  tang
  =/  fate  !>(|=(a=@ud &))
  =/  s  (init:engine 0v1 (config 3 10 5 5) [fate `sized `no-alts ~ %pass])
  =/  next  (step:engine s)
  ;:  weld
    (expect !>(=(~ pending.next)))
    (expect-eq !>(`counters:engine`[1 1 0 0 0 0]) !>(counts.next))
  ==
::
++  test-split-matches-interrupt
  ::  With no timeouts, a split run reaches the same outcome and counters.
  ^-  tang
  =/  fate  !>(|=(a=@ud (lth a 50)))
  =/  split  (finished (split-config %fail) [fate `sized `no-alts ~ %pass])
  =/  plain
    (finished (split-config %interrupt) [fate `sized `no-alts ~ %pass])
  ;:  weld
    (expect-eq !>(result.plain) !>(result.split))
    (expect-eq !>(counts.plain) !>(counts.split))
  ==
::
++  test-timeout-discard-sample
  ::  A discarded sample counts as dropped and clears pending.
  ^-  tang
  =/  fate  !>(|=(a=@ud &))
  =/  s
    (init:engine 0v1 (split-config %discard) [fate `sized `no-alts ~ %pass])
  =/  stored  (step:engine s)
  =/  got  (timed-out:engine stored)
  ;:  weld
    (expect !>(=(~ pending.got)))
    (expect-eq !>(`counters:engine`[1 0 1 0 0 0]) !>(counts.got))
    (expect !>(=(~ result.got)))
  ==
::
++  test-timeout-fail-starts-shrinking
  ::  A hanging sample under %fail shrinks as a %timeout failure.
  ^-  tang
  =/  fate  !>(|=(a=@ud &))
  =/  s  (init:engine 0v1 (split-config %fail) [fate `sized `no-alts ~ %pass])
  =/  got  (timed-out:engine (step:engine s))
  ?>  ?=(^ shrink.got)
  ;:  weld
    (expect !>(=(~ pending.got)))
    (expect !>(?=([%timeout ~] why.evidence.u.shrink.got)))
    %+  expect-eq  !>(q.original.evidence.u.shrink.got)
    !>(q.shrunk.evidence.u.shrink.got)
  ==
::
++  test-timeout-candidate-accepted-as-timeout
  ::  A hanging candidate shrinks the timed-out sample further.
  ^-  tang
  =/  fate  !>(|=(a=@ud &))
  =/  s  (init:engine 0v1 (split-config %fail) [fate `sized `no-alts ~ %pass])
  =/  start  (timed-out:engine (step:engine s))
  =/  work  (need shrink.start)
  =/  cand  !>(`@ud`0)
  =.  shrink.start  `work(pending `~[cand])
  =.  pending.start  `[cand '0' 1]
  =/  got  (timed-out:engine start)
  ;:  weld
    (expect-eq !>(`@ud`1) !>(shrink-steps.counts.got))
    (expect-eq !>(`@ud`0) !>(q.shrunk.evidence:(need shrink.got)))
    (expect !>(=(~ pending:(need shrink.got))))
  ==
::
++  test-timeout-candidate-other-category-skipped
  ::  A hanging candidate of a %false failure is skipped, not accepted.
  ^-  tang
  =/  fate  !>(|=(a=@ud |))
  =/  s  (init:engine 0v1 (split-config %fail) [fate `sized `no-alts ~ %pass])
  =/  failed=state:engine  (step:engine s)
  =/  cand  !>(`@ud`0)
  =.  shrink.failed
    :-  ~
    :^  [[%false ~ ~] !>(`@ud`5) !>(`@ud`5) '5' '5']
      *(set @)
    `~[cand]
    6
  =.  pending.failed  `[cand '0' 1]
  =/  got  (timed-out:engine failed)
  ;:  weld
    (expect !>(=(~ pending.got)))
    (expect-eq !>(`@ud`5) !>(q.shrunk.evidence:(need shrink.got)))
    (expect-eq !>(`@ud`0) !>(shrink-steps.counts.got))
  ==
--
