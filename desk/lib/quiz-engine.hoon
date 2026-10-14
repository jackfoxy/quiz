/+  legacy=quiz
|%
  ::  Resumable app engine. The legacy runner remains frozen.
  ::  One step generates at most one sample and evaluates at most one fate.
  ::  Virtualization catches crashes/scries; it cannot preempt a looping gate.
  ::
::  Source/retention/slice limits are consumed by later app layers.
+$  limits
  $:  source-bytes=@ud
      requested-max=@ud
      shrink-candidates=@ud
      shrink-depth=@ud
      sample-bytes=@ud
      rendered-bytes=@ud
      diagnostics-bytes=@ud
      alts-bytes=@ud
      retained-runs=@ud
      samples-per-slice=@ud
  ==
::
+$  conf
  $:  requested=@ud
      attempts-max=@ud
      drops-max=@ud
      duplicates-max=@ud
      bounds=limits
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
+$  counterexample  [why=failure original=vase shrunk=vase]
::
+$  limit-name
  $?  %requested  %shrink-candidates  %shrink-depth  %sample-bytes
      %rendered-bytes  %diagnostics-bytes  %alts-bytes
  ==
::
+$  shrinking
  $:  evidence=counterexample
      visited=(set @)
      pending=(unit (list vase))
  ==
::
+$  error-stage  ?(%norn %generate %alts)
::
+$  outcome
  $%  [%passed ~]
      [%failed counterexample]
      $:  %error  stage=error-stage
          why=failure  evidence=(unit counterexample)
      ==
      [%limited which=limit-name evidence=(unit counterexample)]
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
      shrink=(unit shrinking)
      result=(unit outcome)
  ==
::
++  defaults
  ^-  conf
  :*  100  10.000  1.000  1.000
      [262.144 10.000 1.000 100 65.536 16.384 16.384 262.144 100 25]
  ==
::
++  init
  ::  Compiled parts must already be type-checked by the source builder.
  ::  Zero requested passes immediately; zero budgets stop before generation.
  ::  Use defaults with field overrides for the app configuration.
  |=  [seed=@uv config=conf compiled=parts]
  ^-  state
  %-  finish
  :*  seed  config  compiled  (slot 6 fate.compiled)
      1  ~(. og seed)  *(set @)  *counters  ~  ~
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
  ?:  !=(~ shrink.s)  s
  ?:  (gth requested.config.s requested-max.bounds.config.s)
    s(result `[%limited %requested ~])
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
  ::  The failure sample is included in attempted. Terminal states are stable.
  ::  A shrinking step calls alts once OR considers one candidate.
  |=  s=state
  ^-  state
  =.  s  (finish s)
  ?:  !=(~ result.s)  s
  ?:  !=(~ shrink.s)  (shrink-step s)
  =/  [fill-rng=_og next-rng=_og]  (split-rng:legacy rng.s)
  =/  made  (generate size.s fill-rng sample.s norn.compiled.s)
  ?.  ?=(%0 -.made)
    =/  why  (classify made)
    ?>  ?=(^ why)
    =/  stage  ?:(=(~ norn.compiled.s) %generate %norn)
    (stop-error s stage why ~)
  =/  sam  ;;(vase p.made)
  =.  s
    s(rng next-rng, size (add +(size.s) (div (mul size.s 2) 21)))
  =.  attempted.counts.s  +(attempted.counts.s)
  =/  capped  (sample-limit sam bounds.config.s)
  ?:  ?=(%.n -.capped)
    =/  stage  ?:(=(~ norn.compiled.s) %generate %norn)
    (stop-error s stage p.capped ~)
  =/  limit  p.capped
  ?^  limit  s(result `[%limited u.limit ~])
  =/  hash  (mug q.sam)
  ?:  (~(has in seen.s) hash)
    (finish s(duplicate.counts +(duplicate.counts.s)))
  =.  seen.s  (~(put in seen.s) hash)
  =/  found  (classify (mong [q.fate.compiled.s q.sam] |=(^ ~)))
  ?-  found
    %pass  (finish s(accepted.counts +(accepted.counts.s)))
    %drop  (finish s(dropped.counts +(dropped.counts.s)))
    ^      ?.  (fits diagnostics-bytes.bounds.config.s found)
             s(result `[%limited %diagnostics-bytes ~])
           s(shrink `[[found sam sam] (~(put in *(set @)) hash) ~])
  ==
::
++  fits
  ::  Encoded noun bytes, including vase type where applicable. Post-call cap;
  ::  jam and the evaluated gate still allocate before this check can run.
  |=  [maximum=@ud value=*]
  ^-  ?
  (lte (met 3 (jam value)) maximum)
::
++  sample-limit
  ::  A vase returned by alts can have a valid type but an invalid value.
  ::  Keep rendering inside virtualization so such products become errors.
  |=  [sam=vase bounds=limits]
  ^-  (each (unit limit-name) failure)
  =/  inspect
    |=  [sam=vase bounds=limits]
    ^-  (unit limit-name)
    ?.  (fits sample-bytes.bounds sam)  `%sample-bytes
    =/  text  (crip ~(ram re (sell sam)))
    ?:  (gth (met 3 text) rendered-bytes.bounds)  `%rendered-bytes
    ~
  =/  checked  (mong [inspect [sam bounds]] |=(^ ~))
  ?:  ?=(%0 -.checked)  [%.y ;;((unit limit-name) p.checked)]
  =/  why  (classify checked)
  ?>  ?=(^ why)
  [%.n why]
::
++  stop-error
  |=  [s=state stage=error-stage why=failure evidence=(unit counterexample)]
  ^-  state
  ?.  (fits diagnostics-bytes.bounds.config.s why)
    s(shrink ~, result `[%limited %diagnostics-bytes evidence])
  s(shrink ~, result `[%error stage why evidence])
::
++  weight
  ::  Strict, well-founded progress: atoms weigh value+1, cells 1+children.
  ::  Equal-weight permutations and growing custom candidates are skipped.
  |=  value=*
  ^-  @
  ?@  value  +(value)
  +((add $(value -.value) $(value +.value)))
::
++  alternatives
  ::  Default/custom alts and product validation share the refusing sandbox.
  |=  [sam=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [sam=vase custom=(unit vase)]
    ^-  (list vase)
    ?~  custom  (sink:legacy sam)
    ;;((list vase) (slum q.u.custom sam))
  (mong [maker [sam custom]] |=(^ ~))
::
++  shrink-step
  |=  s=state
  ^-  state
  =/  work  (need shrink.s)
  =/  evidence  evidence.work
  ::  A known empty list is complete even on the last allowed candidate.
  ?:  =([~ ~] pending.work)
    s(shrink ~, result `[%failed evidence])
  =/  budget=(unit limit-name)
    ?:  (gte shrink-tried.counts.s shrink-candidates.bounds.config.s)
      `%shrink-candidates
    ?:  (gte shrink-steps.counts.s shrink-depth.bounds.config.s)
      `%shrink-depth
    ~
  ?^  budget
    s(shrink ~, result `[%limited u.budget `evidence])
  =/  pending  pending.work
  ?~  pending
    =/  made  (alternatives shrunk.evidence alts.compiled.s)
    ?.  ?=(%0 -.made)
      =/  why  (classify made)
      ?>  ?=(^ why)
      (stop-error s %alts why `evidence)
    ?.  (fits alts-bytes.bounds.config.s p.made)
      s(shrink ~, result `[%limited %alts-bytes `evidence])
    =/  candidates  ;;((list vase) p.made)
    s(shrink `work(pending `candidates))
  =/  candidates  u.pending
  ?~  candidates
    s(shrink ~, result `[%failed evidence])
  =/  sam  i.candidates
  =.  work  work(pending `t.candidates)
  =.  shrink-tried.counts.s  +(shrink-tried.counts.s)
  =/  capped  (sample-limit sam bounds.config.s)
  ?:  ?=(%.n -.capped)  (stop-error s %alts p.capped `evidence)
  =/  limit  p.capped
  ?^  limit
    s(shrink ~, result `[%limited u.limit `evidence])
  =/  hash  (mug q.sam)
  ?:  (~(has in visited.work) hash)  s(shrink `work)
  =.  visited.work  (~(put in visited.work) hash)
  ?.  (lth (weight q.sam) (weight q.shrunk.evidence))  s(shrink `work)
  =/  found  (classify (mong [q.fate.compiled.s q.sam] |=(^ ~)))
  ?@  found  s(shrink `work)
  ?.  (fits diagnostics-bytes.bounds.config.s found)
    s(shrink ~, result `[%limited %diagnostics-bytes `evidence])
  ?.  =(-.found -.why.evidence)  s(shrink `work)
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  s(shrink `work(shrunk.evidence sam, pending ~))
--
