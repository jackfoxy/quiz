/+  suite=quiz-suite, build=quiz-build, *test
|%
::
++  start
  |=  [source=@t selected=(list term)]
  ^-  result:suite
  =/  prepared  (prepare:suite [~zod %quiz 1] /suite/hoon source selected)
  ?>  ?=(%.y -.prepared)
  (discover:suite p.prepared (slap !>(..zuse) (ream source)))
::
++  complete
  |=  s=state:suite
  ^-  state:suite
  =/  left  20
  |-
  ?:  !=(~ result.s)  s
  ?>  (gth left 0)
  $(s (step:suite s), left (dec left))
::
++  bad
  |=  [expected=@tas result=result:suite]
  ^-  tang
  ?>  ?=(%invalid -.result)
  ;:  weld
    (expect-eq !>(expected) !>(code.result))
    (expect-eq !>(/suite/hoon) !>(path.result))
  ==
::
++  test-not-core
  ^-  tang
  (bad %suite-not-core (start '42' ~))
::
++  test-no-tests
  ^-  tang
  (bad %suite-no-tests (start '|%  ++  helper  42  --' ~))
::
++  test-prefix-and-order
  ^-  tang
  =/  source
    %-  crip
    ;:  weld
      "|%  ++  test-z  ~  ++  test-a  ~  ++  test  ~  "
      "++  testing  ~  ++  helper  ~  --"
    ==
  =/  built  (start source ~)
  ?>  ?=(%ready -.built)
  ;:  weld
    (expect-eq !>(`(list term)`~[%test-z %test-a]) !>(available.built))
    (expect-eq !>(`@ud`2) !>(total.counts.built))
    (expect !>(=(~ finished.built)))
  ==
::
++  test-selection
  ^-  tang
  =/  source  '|%  ++  test-a  ~  ++  test-z  !!  --'
  =/  built  (start source ~[%test-a])
  ?>  ?=(%ready -.built)
  =/  done  (complete +.built)
  ;:  weld
    (expect !>(?=([~ status=%passed *] result.done)))
    (expect-eq !>(`@ud`1) !>(completed.counts.done))
    (expect-eq !>(`(list term)`~[%test-a]) !>(remaining.built))
  ==
::
++  test-unknown-selection
  ^-  tang
  (bad %suite-arm (start '|%  ++  test-a  ~  --' ~[%test-missing]))
::
++  test-duplicate-selection
  ^-  tang
  =/  result  (start '|%  ++  test-a  ~  --' ~[%test-a %test-a])
  (bad %suite-duplicate result)
::
++  test-one-arm-per-step
  ^-  tang
  =/  built  (start '|%  ++  test-a  ~  ++  test-z  ~  --' ~)
  ?>  ?=(%ready -.built)
  =/  next  (step:suite +.built)
  =/  done  (step:suite next)
  ;:  weld
    (expect-eq !>(`@ud`1) !>(completed.counts.next))
    (expect !>(=(~ result.next)))
    (expect !>(?=([~ status=%passed *] result.done)))
    (expect !>(=(done (step:suite done))))
    (expect-eq !>(`@ud`0) !>(completed.counts.built))
  ==
::
++  test-outcomes-and-tang
  ^-  tang
  =/  source
    %-  crip
    ;:  weld
      "|%  ++  test-pass  ~  ++  test-fail  ~[[%leaf \"failure\"]]  "
      "++  test-crash  ~|(%suite-crash !!)  ++  test-type  42  --"
    ==
  =/  built  (start source ~)
  ?>  ?=(%ready -.built)
  =/  done  (complete +.built)
  =/  outcome  (need result.done)
  =/  names  (turn arms.outcome |=(arm-result:suite name))
  =/  failure  (snag (need (find ~[%test-fail] names)) arms.outcome)
  ;:  weld
    (expect-eq !>(`counters:suite`[4 4 1 1 1 1]) !>(counts.done))
    (expect-eq !>(%failed) !>(status.outcome))
    (expect-eq !>(%unavailable) !>(sample-metrics.outcome))
    (expect-eq !>(`tang`~[[%leaf "failure"]]) !>(trace.failure))
    (expect !>((lien arms.outcome |=(a=arm-result:suite ?=(^ trace.a)))))
  ==
::
++  test-scry-is-crash
  ^-  tang
  =/  source  '|%  ++  test-read  .^(tang %cx /unavailable)  --'
  =/  built  (start source ~)
  ?>  ?=(%ready -.built)
  =/  done  (complete +.built)
  ?>  ?=(^ finished.done)
  ;:  weld
    (expect-eq !>(`@ud`1) !>(crashed.counts.done))
    (expect !>(?=(^ trace.i.finished.done)))
  ==
::
++  test-trace-cap
  ^-  tang
  =/  source  '|%  ++  test-large  ~[[%leaf (reap 20.000 `@tD`120)]]  --'
  =/  built  (start source ~)
  ?>  ?=(%ready -.built)
  =/  done  (complete +.built)
  ?>  ?=(^ finished.done)
  ;:  weld
    (expect-eq !>(`@ud`1) !>(failed.counts.done))
    (expect !>(clipped.i.finished.done))
    (expect !>(=(~ trace.i.finished.done)))
  ==
::
++  test-clay-reply
  ^-  tang
  =/  prepared
    (prepare:suite [~zod %quiz 1] /suite/hoon '|%  --' ~)
  ?>  ?=(%.y -.prepared)
  =/  doc  p.prepared
  =/  core  (slap !>(..zuse) (ream '|%  ++  test-a  ~  --'))
  =/  reply=rant:clay  [[%a [%ud 1] %quiz] /suite/hoon %vase !>(core)]
  =/  built  (take-built:suite doc `reply)
  ;:  weld
    (expect !>(?=(%ready -.built)))
    (bad %build (take-built:suite doc ~))
    (bad %build-context (take-built:suite doc `reply(q.p [%ud 2])))
    (bad %build-mark (take-built:suite doc `reply(p.r %noun)))
    (bad %build-product (take-built:suite doc `reply(q.r !>(42))))
    %+  expect-eq
      !>([~zod %quiz `[%sing %a [%ud 1] /suite/hoon]])
    !>((request:suite doc))
  ==
::
++  test-path-validation
  ^-  tang
  =/  result  (prepare:suite [~zod %quiz 1] /suite/txt '' ~)
  ?>  ?=(%.n -.result)
  (expect-eq !>(%mark) !>(code.p.result))
::
++  test-faced-core
  ^-  tang
  =/  built  (start '^=  wrapped  |%  ++  test-a  ~  --' ~)
  ?>  ?=(%ready -.built)
  =/  done  (complete +.built)
  (expect !>(?=([~ status=%passed *] result.done)))
--
