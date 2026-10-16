/+  engine=quiz-engine, *test
|%
::
++  start
  |=  [fate=vase value=@ud alts=(unit vase)]
  ^-  state:engine
  =/  give  !>(|=([size=@ud rng=_og] value))
  (init:engine 0v1 defaults:engine [fate `give alts])
::
++  complete
  |=  s=state:engine
  ^-  state:engine
  =/  left  2.100
  |-
  ?:  !=(~ result.s)  s
  ?>  (gth left 0)
  $(s (step:engine s), left (dec left))
::
++  nine
  !>(|=(sam=vase ?:(=(q.sam 10) ~[sam(q 9)] *(list vase))))
::
++  countdown
  !>(|=(sam=vase ?>(?=(@ q.sam) ~[sam(q (dec q.sam))])))
::
++  test-threshold-500
  ^-  tang
  =/  s  (start !>(|=(a=@ud (lte a 500))) 1.024 ~)
  =/  checkpoint  (step:engine s)
  =/  done  (complete checkpoint)
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect !>(=(~ result.checkpoint)))
    (expect !>(?=(^ shrink.checkpoint)))
    (expect-eq !>(`*`1.024) !>(q.original.result))
    (expect-eq !>(`*`501) !>(q.shrunk.result))
    (expect-eq !>(`@ud`1) !>(attempted.counts.done))
    (expect !>((gth shrink-steps.counts.done 0)))
    (expect !>(=(done (complete s))))
    (expect !>(=(done (step:engine done))))
  ==
::
++  test-candidate-limit
  ^-  tang
  =/  alts  !>(|=(sam=vase ~[sam sam sam sam]))
  =/  s  (start !>(|=(@ud |)) 10 `alts)
  =/  done  (complete s(shrink-candidates.bounds.config 2))
  ;:  weld
    (expect !>(?=([~ %limited %shrink-candidates ^] result.done)))
    (expect-eq !>(`@ud`2) !>(shrink-tried.counts.done))
    (expect-eq !>(`@ud`0) !>(shrink-steps.counts.done))
  ==
::
++  test-depth-limit
  ^-  tang
  ::  Alts keeps producing a next failure; each call itself terminates.
  =/  s  (start !>(|=(@ud |)) 1.000.000 `countdown)
  =/  done  (complete s(shrink-depth.bounds.config 3))
  =/  result  (need result.done)
  ?>  ?=([%limited %shrink-depth ^] result)
  ;:  weld
    (expect-eq !>(`@ud`3) !>(shrink-tried.counts.done))
    (expect-eq !>(`@ud`3) !>(shrink-steps.counts.done))
    (expect-eq !>(`*`1.000.000) !>(q.original.u.evidence.result))
    (expect-eq !>(`*`999.997) !>(q.shrunk.u.evidence.result))
  ==
::
++  test-repeat-and-non-progress
  ^-  tang
  =/  alts  !>(|=(sam=vase ~[sam sam(q 20) sam(q 9) sam(q 9)]))
  =/  s  (start !>(|=(a=@ud =(a 9))) 10 `alts)
  =/  done  (complete s)
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`*`10) !>(q.shrunk.result))
    (expect-eq !>(`@ud`4) !>(shrink-tried.counts.done))
    (expect-eq !>(`@ud`0) !>(shrink-steps.counts.done))
  ==
::
++  test-cycle
  ^-  tang
  =/  alts  !>(|=(sam=vase ~[sam(q ?:(=(q.sam 10) 9 10))]))
  =/  done  (complete (start !>(|=(@ud |)) 10 `alts))
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`*`9) !>(q.shrunk.result))
    (expect-eq !>(`@ud`2) !>(shrink-tried.counts.done))
    (expect-eq !>(`@ud`1) !>(shrink-steps.counts.done))
  ==
::
++  test-category-retention
  ^-  tang
  =/  fates=(list vase)
    :~  !>(|=(a=@ud ^-(? ?:(=(a 10) %.n !!))))
        !>(|=(a=@ud ^-(? ?:(=(a 10) !! %.n))))
        !>(|=(a=@ud ?:(=(a 10) .^(? %cz /quiz-shrink-missing) %.n)))
        !>(|=(a=@ud ?:(=(a 10) 42 %.n)))
    ==
  %-  zing
  %+  turn  fates
  |=  fate=vase
  ^-  tang
  =/  done  (complete (start fate 10 `nine))
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`*`10) !>(q.shrunk.result))
    (expect-eq !>(`@ud`0) !>(shrink-steps.counts.done))
  ==
::
++  test-same-category-crash
  ^-  tang
  =/  done  (complete (start !>(|=(@ud ^-(? !!))) 10 `nine))
  =/  result  (need result.done)
  ?>  ?=([%failed [%crash *] * *] result)
  ;:  weld
    (expect-eq !>(`*`10) !>(q.original.result))
    (expect-eq !>(`*`9) !>(q.shrunk.result))
    (expect-eq !>(`@ud`1) !>(shrink-steps.counts.done))
  ==
::
++  test-skip-pass-and-drop
  ^-  tang
  =/  alts
    !>(|=(sam=vase ?:(=(q.sam 10) ~[sam(q 9) sam(q 8) sam(q 7)] ~)))
  =/  fate  !>(|=(a=@ud ?:(=(a 9) %drop =(a 8))))
  =/  done  (complete (start fate 10 `alts))
  =/  result  (need result.done)
  ?>  ?=(%failed -.result)
  ;:  weld
    (expect-eq !>(`*`7) !>(q.shrunk.result))
    (expect-eq !>(`counters:engine`[1 0 0 0 3 1]) !>(counts.done))
  ==
::
++  test-alts-errors
  ^-  tang
  =/  alts=(list vase)
    :~  !>(|=(vase ^-((list vase) ~|(%alts-crash !!))))
        !>(|=(vase .^((list vase) %cz /quiz-shrink-missing)))
        !>(|=(vase 42))
    ==
  %-  zing
  %+  turn  alts
  |=  alternative=vase
  ^-  tang
  =/  done  (complete (start !>(|=(@ud |)) 10 `alternative))
  =/  result  (need result.done)
  ?>  ?=([%error %alts * ^] result)
  ;:  weld
    (expect-eq !>(`*`10) !>(q.original.u.evidence.result))
    (expect-eq !>(`@ud`0) !>(shrink-tried.counts.done))
    (expect !>(=(done (step:engine done))))
  ==
::
++  test-unrenderable-candidate
  ^-  tang
  =/  alts  !>(|=(vase ~[[[%cell %noun %noun] 0]]))
  =/  done  (complete (start !>(|=(@ud |)) 10 `alts))
  ;:  weld
    (expect !>(?=([~ %error %alts [%crash *] ^] result.done)))
    (expect-eq !>(`@ud`1) !>(shrink-tried.counts.done))
  ==
::
++  test-zero-shrink-budgets
  ^-  tang
  =/  alts  !>(|=(vase ^-((list vase) !!)))
  =/  s  (start !>(|=(@ud |)) 10 `alts)
  =/  a  (complete s(shrink-candidates.bounds.config 0))
  =/  b  (complete s(shrink-depth.bounds.config 0))
  ;:  weld
    (expect !>(?=([~ %limited %shrink-candidates ^] result.a)))
    (expect !>(?=([~ %limited %shrink-depth ^] result.b)))
    (expect-eq !>(`@ud`0) !>(shrink-tried.counts.a))
    (expect-eq !>(`@ud`0) !>(shrink-tried.counts.b))
  ==
::
++  test-last-candidate-completes
  ^-  tang
  =/  s  (start !>(|=(a=@ud !=(a 10))) 10 `nine)
  =/  done  (complete s(shrink-candidates.bounds.config 1))
  ;:  weld
    (expect !>(?=([~ %failed * * *] result.done)))
    (expect-eq !>(`@ud`1) !>(shrink-tried.counts.done))
  ==
::
++  test-sample-cap
  ^-  tang
  =/  s  (start !>(|=(@ud |)) (bex 1.024) ~)
  =/  done  (complete s(sample-bytes.bounds.config 64))
  ;:  weld
    (expect !>(?=([~ %limited %sample-bytes ~] result.done)))
    (expect !>(=(~ shrink.done)))
    (expect-eq !>(`@ud`1) !>(attempted.counts.done))
  ==
::
++  test-render-cap
  ^-  tang
  =/  s  (start !>(|=(@ud |)) 10 ~)
  =/  done  (complete s(rendered-bytes.bounds.config 1))
  (expect !>(?=([~ %limited %rendered-bytes ~] result.done)))
::
++  test-oversized-candidate
  ^-  tang
  =/  alts  !>(|=(sam=vase ~[sam(q (bex 1.024))]))
  =/  s  (start !>(|=(@ud |)) 10 `alts)
  =/  done  (complete s(sample-bytes.bounds.config 64))
  =/  result  (need result.done)
  ?>  ?=([%limited %sample-bytes ^] result)
  ;:  weld
    (expect-eq !>(`*`10) !>(q.original.u.evidence.result))
    (expect-eq !>(`*`10) !>(q.shrunk.u.evidence.result))
    (expect !>(=(~ shrink.done)))
  ==
::
++  test-alts-output-cap
  ^-  tang
  =/  s  (start !>(|=(@ud |)) 10 `nine)
  =/  done  (complete s(alts-bytes.bounds.config 1))
  (expect !>(?=([~ %limited %alts-bytes ^] result.done)))
::
++  test-diagnostics-cap
  ^-  tang
  =/  s  (start !>(|=(@ud (bex 2.048))) 10 ~)
  =/  done  (complete s(diagnostics-bytes.bounds.config 8))
  (expect !>(?=([~ %limited %diagnostics-bytes ~] result.done)))
::
++  test-alts-diagnostics-cap
  ^-  tang
  =/  alts  !>(|=(vase ^-((list vase) ~|(%large-alts-trace !!))))
  =/  s  (start !>(|=(@ud |)) 10 `alts)
  =/  done  (complete s(diagnostics-bytes.bounds.config 16))
  (expect !>(?=([~ %limited %diagnostics-bytes ^] result.done)))
::
++  test-requested-cap
  ^-  tang
  =/  s  (start !>(|=(@ud &)) 10 ~)
  =/  done  (complete s(requested.config 10.001))
  (expect !>(?=([~ %limited %requested ~] result.done)))
::
++  test-resume-pending-candidates
  ^-  tang
  =/  s  (start !>(|=(a=@ud (lte a 500))) 1.024 ~)
  =/  pending  (step:engine (step:engine s))
  =/  done  (complete pending)
  ;:  weld
    (expect !>(=(done (complete s))))
    (expect-eq !>(`@ud`0) !>(shrink-tried.counts.pending))
    (expect-eq !>(`@ud`1) !>(attempted.counts.pending))
  ==
--
