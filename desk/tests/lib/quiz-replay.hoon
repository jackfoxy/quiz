/+  replay=quiz-replay, build=quiz-build, engine=quiz-engine, *test
|%
::
++  source
  %-  crip
  ;:  weld
    "|%  ++  fate  |=(n=@ud (lte n 500))  "
    "++  norn  |=([size=@ud rng=_og] (add 501 (rad:rng 64)))  --"
  ==
::
++  snapshot
  ^-  record:replay
  =/  doc  (prepare:build [~zod %quiz 1] /property/hoon source)
  ?>  ?=(%.y -.doc)
  =/  cfg  defaults:engine
  =/  saved  (capture:replay p.doc 0v123 cfg(requested 3))
  ?>  ?=(%.y -.saved)
  p.saved
::
++  complete
  |=  s=state:engine
  ^-  state:engine
  =/  left  2.000
  |-
  ?:  !=(~ result.s)  s
  ?>  (gth left 0)
  $(s (step:engine s), left (dec left))
::
++  bad
  |=  [expected=@tas saved=record:replay]
  ^-  tang
  =/  parsed  (prepare:replay saved)
  ?>  ?=(%.n -.parsed)
  (expect-eq !>(expected) !>(code.p.parsed))
::
++  test-capture-inputs
  ^-  tang
  =/  saved  snapshot
  ;:  weld
    (expect-eq !>(source) !>(source.saved))
    (expect-eq !>(`@uv`(shax source)) !>(source-hash.saved))
    (expect-eq !>(`@uv`0v123) !>(seed.saved))
    (expect-eq !>(`@ud`3) !>(requested.config.saved))
    (expect-eq !>(version:engine) !>(engine-version.saved))
    (expect-eq !>(`context:build`[~zod %quiz 1]) !>(where.saved))
  ==
::
++  test-reproduces-counterexample
  ^-  tang
  =/  saved  snapshot
  =/  first  (start:replay saved ~)
  ?>  ?=(%.y -.first)
  =/  done  (complete p.first)
  =/  persisted  (cue (jam saved))
  =/  second  (start:replay ;;(record:replay persisted) ~)
  ?>  ?=(%.y -.second)
  =/  again  (complete p.second)
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect !>(=(result.done result.again)))
    (expect !>(=(counts.done counts.again)))
    (expect !>(=(seed.done seed.again)))
    (expect !>(=(config.done config.again)))
    (expect !>(?=([%false ~] why.result)))
    (expect !>((gth !<(@ud original.result) 500)))
    (expect-eq !>(`@ud`501) !>(!<(@ud shrunk.result)))
  ==
::
++  test-overrides-preserved
  ^-  tang
  =/  saved  snapshot
  =/  text
    %-  crip
    ;:  weld
      "|%  ++  fate  |=(@ud &)  ++  conf  "
      "[[~ 0v999] [2 10.000 1.000 1.000 "
      "[262.144 10.000 1.000 100 65.536 16.384 16.384 262.144 100 25]]]  --"
    ==
  =.  source.saved  text
  =.  source-hash.saved  (shax text)
  =.  requested.config.saved  0
  =.  seed.saved  0v456
  =/  started  (start:replay saved ~)
  ?>  ?=(%.y -.started)
  ;:  weld
    (expect !>(?=([~ %passed ~] result.p.started)))
    (expect-eq !>(`@uv`0v456) !>(seed.p.started))
    (expect-eq !>(`@ud`0) !>(attempted.counts.p.started))
  ==
::
++  test-tampered-source
  ^-  tang
  =/  saved  snapshot
  (bad %source-hash saved(source '42'))
::
++  test-engine-version
  ^-  tang
  =/  saved  snapshot
  (bad %engine-version saved(engine-version %unknown))
::
++  test-config-range
  ^-  tang
  =/  saved  snapshot
  (bad %conf-range saved(requested.config 10.001))
::
++  test-source-limit
  ^-  tang
  =/  saved  snapshot
  (bad %source-size saved(source-bytes.bounds.config 1))
::
++  test-invalid-context
  ^-  tang
  =/  saved  snapshot
  (bad %case saved(revision.where 0))
::
++  test-ship-mismatch
  ^-  tang
  =/  resolved  (resolve:replay ~nec ~2026.10.14 snapshot)
  ?>  ?=(%.n -.resolved)
  (expect-eq !>(%ship-unavailable) !>(code.p.resolved))
::
++  test-limited-replay
  ^-  tang
  =/  saved  snapshot
  =.  shrink-depth.bounds.config.saved  0
  =.  seed.saved  0v0
  =/  first  (start:replay saved ~)
  ?>  ?=(%.y -.first)
  =/  original  (complete p.first)
  =/  second  (start:replay saved ~)
  ?>  ?=(%.y -.second)
  =/  again  (complete p.second)
  ;:  weld
    (expect !>(?=([~ %limited %shrink-depth ^] result.original)))
    (expect !>(=(result.original result.again)))
    (expect !>(=(counts.original counts.again)))
    (expect-eq !>(`@uv`0v0) !>(seed.again))
  ==
--
