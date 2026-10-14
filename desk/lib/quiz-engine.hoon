/+  legacy=quiz
|%
  ::  Resumable app engine. The legacy runner remains frozen.
  ::  One step generates at most one sample and evaluates at most one fate.
  ::  Virtualization catches crashes/scries; it cannot preempt a looping gate.
  ::
+$  conf
  $:  requested=@ud
      attempts-max=@ud
      drops-max=@ud
      duplicates-max=@ud
  ==
::
+$  parts  [fate=vase norn=(unit vase) alts=(unit vase)]
::
+$  counters
  $:  attempted=@ud
      accepted=@ud
      dropped=@ud
      duplicate=@ud
      shrink-tried=@ud
      shrink-steps=@ud
  ==
::
+$  failure
  $%  [%false ~]
      [%crash trace=tang]
      [%scry request=*]
      [%bad-product product=*]
  ==
::
+$  verdict  ?(%pass %drop failure)
::
+$  outcome
  $%  [%passed ~]
      [%failed why=failure original=vase shrunk=vase]
      [%error stage=?(%norn %generate) why=failure]
      [%exhausted budget=?(%attempts %drops %duplicates) all-dropped=?]
  ==
::
+$  state
  $:  seed=@uv
      config=conf
      compiled=parts
      sample=vase
      size=@ud
      rng=_og
      seen=(set @)
      counts=counters
      result=(unit outcome)
  ==
::
++  init
  ::  Compiled parts must already be type-checked by the source builder.
  ::  Zero requested passes immediately; zero budgets stop before generation.
  ::  Limits are explicit here; app defaults are added with bounded shrinking.
  |=  [seed=@uv config=conf compiled=parts]
  ^-  state
  %-  finish
  :*  seed  config  compiled  (slot 6 fate.compiled)
      1  ~(. og seed)  *(set @)  *counters  ~
  ==
::
++  classify
  ::  Retain the virtualized trace, blocked request, or unexpected product.
  |=  evaluated=toon
  ^-  verdict
  ?-  -.evaluated
    %1  [%scry p.evaluated]
    %2  [%crash p.evaluated]
    %0  ?:  =(p.evaluated %.y)  %pass
        ?:  =(p.evaluated %.n)  [%false ~]
        ?:  =(p.evaluated %drop)  %drop
        [%bad-product p.evaluated]
  ==
::
++  generate
  ::  Both default fill and the custom norn execute inside the same sandbox.
  |=  [size=@ud rng=_og sample=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [size=@ud rng=_og sample=vase custom=(unit vase)]
    ^-  vase
    ?~  custom
      (~(fill quiz:legacy [size rng]) sample)
    [p.sample (slum q.u.custom [size rng])]
  (mong [maker [size rng sample custom]] |=(^ ~))
::
++  finish
  ::  Completion wins when the last accepted sample also hits a budget.
  ::  Ties between budgets resolve attempts, drops, duplicates, in that order.
  |=  s=state
  ^-  state
  ?:  !=(~ result.s)  s
  ?:  =(accepted.counts.s requested.config.s)
    s(result `[%passed ~])
  =/  budget=(unit ?(%attempts %drops %duplicates))
    ?:  (gte attempted.counts.s attempts-max.config.s)  `%attempts
    ?:  (gte dropped.counts.s drops-max.config.s)  `%drops
    ?:  (gte duplicate.counts.s duplicates-max.config.s)  `%duplicates
    ~
  ?~  budget  s
  ::  Duplicates do not prevent all evaluated samples from being drops.
  =/  all-dropped  &(=(accepted.counts.s 0) (gth dropped.counts.s 0))
  s(result `[%exhausted u.budget all-dropped])
::
++  step
  ::  Attempted counts generated samples, including duplicates and failures.
  ::  Generation errors count no sample. Only %.y increments accepted.
  ::  Drops and duplicate mugs consume their own budgets, never requested.
  ::  The failure sample is included in attempted. Shrink counters stay zero
  ::  until the bounded shrink stepper is added. Terminal states are stable.
  |=  s=state
  ^-  state
  =.  s  (finish s)
  ?:  !=(~ result.s)  s
  =/  [fill-rng=_og next-rng=_og]  (split-rng:legacy rng.s)
  =/  made  (generate size.s fill-rng sample.s norn.compiled.s)
  ?.  ?=(%0 -.made)
    =/  why  (classify made)
    ?>  ?=(^ why)
    =/  stage  ?:(=(~ norn.compiled.s) %generate %norn)
    s(result `[%error stage why])
  =/  sam  ;;(vase p.made)
  =.  s
    s(rng next-rng, size (add +(size.s) (div (mul size.s 2) 21)))
  =.  attempted.counts.s  +(attempted.counts.s)
  =/  hash  (mug q.sam)
  ?:  (~(has in seen.s) hash)
    (finish s(duplicate.counts +(duplicate.counts.s)))
  =.  seen.s  (~(put in seen.s) hash)
  =/  found  (classify (mong [q.fate.compiled.s q.sam] |=(^ ~)))
  ?-  found
    %pass  (finish s(accepted.counts +(accepted.counts.s)))
    %drop  (finish s(dropped.counts +(dropped.counts.s)))
    ^      s(result `[%failed found sam sam])
  ==
--
