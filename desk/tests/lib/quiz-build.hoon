/+  build=quiz-build, engine=quiz-engine, *test
|%
::
++  prepare
  |=  source=@t
  (prepare:build [~zod %quiz 1] /draft/hoon source)
::
++  run
  |=  source=@t
  ^-  result:build
  =/  parsed  (prepare source)
  ?:  ?=(%.n -.parsed)  [%invalid p.parsed]
  (compile:build p.parsed ~)
::
++  check
  |=  core=vase
  =/  parsed  (prepare '|%  ++  fate  |=(a=@ud =(a a))  --')
  ?>  ?=(%.y -.parsed)
  (check-core:build p.parsed core)
::
++  bad
  |=  [code=@tas result=result:build]
  ^-  tang
  ?>  ?=(%invalid -.result)
  ;:  weld
    (expect-eq !>(code) !>(code.result))
    (expect-eq !>(/draft/hoon) !>(path.result))
    (expect !>(&((gth p.at.result 0) (gth q.at.result 0))))
  ==
::
++  test-basic
  ^-  tang
  =/  result  (run '|%  ++  fate  |=(a=@ud =(a a))  --')
  (expect !>(?=(%ready -.result)))
::
++  test-missing-fate
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  other  42
    --
  (bad %fate-missing result)
::
++  test-fate-not-gate
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  42
    --
  (bad %fate-type result)
::
++  test-fate-product
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  |=(@ud 42)
    --
  (bad %fate-type result)
::
++  test-norn-input
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  |=(@ud &)
    ++  norn  |=(@ud 0)
    --
  (bad %norn-type result)
::
++  test-norn-product
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  |=(@ud &)
    ++  norn  |=([@ud _og] [1 2])
    --
  (bad %norn-type result)
::
++  test-alts-input
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  |=(@ud &)
    ++  alts  |=(@ud ~)
    --
  (bad %alts-type result)
::
++  test-alts-product
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  |=(@ud &)
    ++  alts  |=(vase 42)
    --
  (bad %alts-type result)
::
++  test-conf-type
  ^-  tang
  =/  result
    %-  check
    !>
    =+  cfg=defaults:engine
    =>  [cfg=cfg ..zuse]
    |%
    ++  fate  |=(@ud &)
    ++  conf  42
    --
  (bad %conf-type result)
::
++  test-arm-crash
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  !!
    --
  (bad %arm result)
::
++  test-conf-range
  ^-  tang
  =/  result
    %-  check
    !>
    =+  cfg=defaults:engine
    =>  [cfg=cfg ..zuse]
    |%
    ++  fate  |=(@ud &)
    ++  conf
      [~ cfg(requested 10.001)]
    --
  (bad %conf-range result)
::
++  test-gates-not-executed
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  |=(@ud ^-(? !!))
    ++  norn  |=([@ud _og] ^-(@ud !!))
    ++  alts  |=(vase ^-((list vase) !!))
    --
  (expect !>(?=(%ready -.result)))
::
++  test-drop-and-conf
  ^-  tang
  =/  result
    %-  check
    !>
    =+  cfg=defaults:engine
    =>  [cfg=cfg ..zuse]
    |%
    ++  fate  |=(@ud %drop)
    ++  conf
      [[~ 0v123] cfg(requested 0)]
    --
  ?>  ?=(%ready -.result)
  ;:  weld
    (expect-eq !>(`(unit @uv)`[~ 0v123]) !>(seed.settings.result))
    (expect-eq !>(`@ud`0) !>(requested.config.settings.result))
  ==
::
++  test-syntax
  ^-  tang
  (bad %syntax (run '|%  ++  fate'))
::
++  test-compile
  ^-  tang
  (bad %compile (run '|%  ++  fate  missing-name  --'))
::
++  test-unsupported-preludes
  ^-  tang
  =/  runes=(list @t)  ~['/~' '/%' '/$' '/?']
  %-  zing
  %+  turn  runes
  |=  rune=@t
  (bad %unsupported-prelude (run (cat 3 rune '  foo')))
::
++  test-malformed-prelude
  ^-  tang
  (bad %prelude (run '/+  123  |%  ++  fate  |=(@ud &)  --'))
::
++  test-prelude-order
  ^-  tang
  (bad %prelude (run '/+  quiz  /-  urui  |%  --'))
::
++  test-prelude-imports
  ^-  tang
  =/  source
    %-  crip
    ;:  weld
      "/-  a=urui, *docket  /+  q=quiz  /=  e  /lib/quiz-engine  "
      "/*  text  %txt  /fixture/txt  |%  ++  fate  |=(@ud &)  --"
    ==
  =/  parsed  (prepare source)
  ?>  ?=(%.y -.parsed)
  =/  deps  deps.p.parsed
  ;:  weld
    (expect-eq !>(`@ud`5) !>((lent deps)))
    (expect-eq !>(/sur/urui/hoon) !>(path:(snag 0 deps)))
    (expect-eq !>(`(unit term)`~) !>(face:(snag 1 deps)))
    (expect-eq !>(/lib/quiz/hoon) !>(path:(snag 2 deps)))
    (expect-eq !>(/lib/quiz-engine/hoon) !>(path:(snag 3 deps)))
    (expect-eq !>(%.n) !>(build:(snag 4 deps)))
  ==
::
++  test-import-marks
  ^-  tang
  ;:  weld
    (bad %import-mark (run '/*  x  %json  /x/json  |%  --'))
    (bad %import-mark (run '/*  x  %txt  /x/hoon  |%  --'))
  ==
::
++  test-import-count
  ^-  tang
  (bad %imports (run '/+  quiz  |%  ++  fate  |=(@ud &)  --'))
::
++  test-location
  ^-  tang
  =/  source  '::  comment\0a|%\0a++  fate  42\0a--'
  =/  result  (run source)
  ?>  ?=(%invalid -.result)
  ;:  weld
    (bad %fate-type result)
    (expect-eq !>(`hair`[3 1]) !>(at.result))
    (expect-eq !>(`(unit term)`[~ %fate]) !>(arm.result))
  ==
::
++  test-validation
  ^-  tang
  =/  oversized  (bex (mul 8 source-bytes.bounds:defaults:engine))
  =/  good  ['quiz' [%ud 1] /examples/['01-prop']/hoon %hoon '']
  =/  desk  (validate:build 'bad/desk' [%ud 1] /p/hoon %hoon '')
  =/  zero  (validate:build 'quiz' [%ud 0] /p/hoon %hoon '')
  =/  label  (validate:build 'quiz' [%tas %now] /p/hoon %hoon '')
  =/  empty  (validate:build 'quiz' [%ud 1] / %hoon '')
  =/  traversal
    (validate:build 'quiz' [%ud 1] ~['..' %hoon] %hoon '')
  =/  mark  (validate:build 'quiz' [%ud 1] /p/txt %txt '')
  =/  size  (validate:build 'quiz' [%ud 1] /p/hoon %hoon oversized)
  ;:  weld
    (expect !>(=(~ (validate:build good))))
    (expect !>(?=([~ code=%desk *] desk)))
    (expect !>(?=([~ code=%case *] zero)))
    (expect !>(?=([~ code=%case *] label)))
    (expect !>(?=([~ code=%path *] empty)))
    (expect !>(?=([~ code=%path *] traversal)))
    (expect !>(?=([~ code=%mark *] mark)))
    (expect !>(?=([~ code=%source-size *] size)))
  ==
::
++  test-config-bounds
  ^-  tang
  =/  cfg  defaults:engine
  ;:  weld
    (expect !>((valid-config:build cfg)))
    (expect !>(!(valid-config:build cfg(attempts-max 10.001))))
    (expect !>(!(valid-config:build cfg(drops-max 1.001))))
    (expect !>(!(valid-config:build cfg(duplicates-max 1.001))))
    (expect !>(!(valid-config:build cfg(samples-per-slice.bounds 0))))
    (expect !>(!(valid-config:build cfg(sample-bytes.bounds 65.537))))
    (expect !>(!(valid-config:build cfg(requested-max.bounds 10.001))))
    (expect !>(!(valid-config:build cfg(shrink-depth.bounds 101))))
    (expect !>(!(valid-config:build cfg(shrink-candidates.bounds 1.001))))
    (expect !>(!(valid-config:build cfg(alts-bytes.bounds 262.145))))
    (expect !>(!(valid-config:build cfg(source-bytes.bounds 0))))
    (expect !>(!(valid-config:build cfg(rendered-bytes.bounds 0))))
    (expect !>(!(valid-config:build cfg(diagnostics-bytes.bounds 0))))
    (expect !>(!(valid-config:build cfg(retained-runs.bounds 0))))
  ==
::
++  test-body-scry
  ^-  tang
  (bad %compile (run '.^(* %cx /this-must-not-be-read)'))
::
++  test-arm-scry
  ^-  tang
  =/  result
    %-  check
    !>
    =>  ..zuse
    |%
    ++  fate  .^(* %cx /this-must-not-be-read)
    --
  (bad %arm result)
::
++  test-non-core
  ^-  tang
  (bad %fate-missing (check !>(42)))
::
++  test-trace-cap
  ^-  tang
  =/  trace=tang
    ~[[%leaf (reap 20.000 'x')]]
  =/  diag  (issue:build %compile /draft/hoon [2 3] ~ trace)
  ;:  weld
    (expect !>(clipped.diag))
    (expect !>(=(~ trace.diag)))
    (expect-eq !>(`hair`[2 3]) !>(at.diag))
  ==
::
++  test-saved-reply
  ^-  tang
  =/  parsed  (prepare '|%  ++  fate  |=(@ud &)  --')
  ?>  ?=(%.y -.parsed)
  =/  doc  p.parsed
  =/  reply=rant:clay  [[%a [%ud 1] %quiz] /draft/hoon %noun !>(42)]
  ;:  weld
    (bad %build (take-saved:build doc ~))
    (bad %build-mark (take-saved:build doc `reply))
    (bad %build-product (take-saved:build doc `reply(p.r %vase)))
    (bad %build-context (take-saved:build doc `reply(q /other/hoon)))
    %+  expect-eq
      !>([~zod %quiz `[%sing %a [%ud 1] /draft/hoon]])
    !>((saved-request:build doc))
  ==
::
++  test-source-conf-bound
  ^-  tang
  =/  result
    %-  check
    !>
    =+  cfg=defaults:engine
    =>  [cfg=cfg ..zuse]
    |%
    ++  fate  |=(@ud &)
    ++  conf  [~ cfg(source-bytes.bounds 1)]
    --
  (bad %source-size result)
::
++  test-import-replies
  ^-  tang
  =/  parsed  (prepare '/+  quiz  |%  ++  fate  |=(@ud &)  --')
  ?>  ?=(%.y -.parsed)
  =/  doc  p.parsed
  =/  reply=rant:clay
    [[%a [%ud 1] %quiz] /lib/quiz/hoon %vase !>(42)]
  ;:  weld
    (bad %imports (draft:build doc ~))
    (bad %import (draft:build doc ~[~]))
    (bad %import-type (draft:build doc ~[`reply]))
    (bad %import-mark (draft:build doc ~[`reply(p.r %noun)]))
    (bad %import-context (draft:build doc ~[`reply(q.p [%ud 2])]))
    %+  expect-eq
      !>(~[[~zod %quiz `[%sing %a [%ud 1] /lib/quiz/hoon]]])
    !>((draft-requests:build doc))
  ==
::
++  test-raw-import
  ^-  tang
  =/  parsed
    (prepare '/*  text  %txt  /x/txt  |%  ++  fate  |=(@ud !=(~ text))  --')
  ?>  ?=(%.y -.parsed)
  =/  reply=rant:clay  [[%x [%ud 1] %quiz] /x/txt %txt !>(`wain`~['hi'])]
  =/  result  (draft:build p.parsed ~[`reply])
  ?>  ?=(%ready -.result)
  ;:  weld
    (expect !>(!<(? (slam fate.parts.result !>(`@ud`1)))))
    (bad %import-type (draft:build p.parsed ~[`reply(q.r !>(42))]))
  ==
::
++  test-other-raw-marks
  ^-  tang
  =/  cases=(list [source=@t mark=mark payload=vase])
    :~
      :-  '/*  v  %hoon  /x/hoon  |%  ++  fate  |=(@ud =(v v))  --'
      [%hoon !>('text')]
      :-  '/*  v  %noun  /x/noun  |%  ++  fate  |=(@ud =(v 7))  --'
      [%noun !>(7)]
    ==
  %-  zing
  %+  turn  cases
  |=  [source=@t mark=mark payload=vase]
  =/  parsed  (prepare source)
  ?>  ?=(%.y -.parsed)
  =/  reply=rant:clay
    [[%x [%ud 1] %quiz] /x/[mark] mark payload]
  =/  result  (draft:build p.parsed ~[`reply])
  ?>  ?=(%ready -.result)
  (expect !>(!<(? (slam fate.parts.result !>(`@ud`1)))))
--
