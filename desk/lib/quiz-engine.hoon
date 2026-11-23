/+  legacy=quiz
|%
  ::  Resumable app engine. The legacy runner remains frozen.
  ::  One step generates at most one sample and evaluates at most one fate.
  ::  Virtualization catches crashes/scries. Each user call also runs under
  ::  a %jinx CPU limit, `time` in the state: a timeout bails the whole Gall
  ::  event, uncatchably, and the Gall adapter records that event's job as
  ::  interrupted. The limit is operational, not part of the replayable conf.
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
      seen-bytes=@ud
      retained-runs=@ud
      samples-per-slice=@ud
  ==
::
+$  timeout-policy
  ::  What a sample whose fate exceeds the call limit does. %interrupt is
  ::  the default: the whole run ends %interrupted. %fail shrinks it as a
  ::  %timeout failure; %discard counts it as dropped and carries on.
  ?(%interrupt %fail %discard)
::
+$  policy
  ::  How repeated samples are treated. %mug skips a repeated mug, %exact
  ::  skips only an equal noun, %allow evaluates every sample.
  ?(%mug %exact %allow)
::
+$  conf
  $:  requested=@ud
      attempts-max=@ud
      drops-max=@ud
      duplicates-max=@ud
      size-start=@ud
      size-max=@ud
      duplicates=policy
      bounds=limits
      on-timeout=timeout-policy
  ==
::
+$  verdict-product  ?(? %drop)
::
+$  detail
  ::  Author-supplied explanation of a false verdict, rendered by the fate.
  [notes=(list @t) compared=(unit [want=@t got=@t])]
::
+$  report
  ::  A fate may return this in place of a bare verdict; see quiz-prop.
  $:  %report
      ok=verdict-product
      =detail
      labels=(list @t)
      tables=(list [table=@t value=@t])
  ==
::
+$  tags  [labels=(list @t) tables=(list [table=@t value=@t])]
::
+$  cover
  ::  Required share, in whole percent, of accepted samples per label.
  [mode=?(%warn %check) rows=(list [label=@t percent=@ud])]
::
+$  expectation  ?(%pass %fail)
::
+$  parts
  $:  fate=vase
      norn=(unit vase)
      alts=(unit vase)
      cover=(unit cover)
      expect=expectation
  ==
::
+$  distribution
  [labels=(map @t @ud) tables=(map @t (map @t @ud))]
::
+$  shortfall  [label=@t want=@ud got=@ud]
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
  $%  [%false =detail]
      [%timeout ~]
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
      %rendered-bytes  %diagnostics-bytes  %alts-bytes  %labels
      %seen-bytes
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
  $%  [%passed warnings=(list shortfall)]
      [%uncovered shortfalls=(list shortfall)]
      [%passed-unexpectedly ~]
      [%failed counterexample]
      [%failed-as-expected counterexample]
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
      seen=(jar @ *)
      seen-used=@ud
      counts=counters
      shrink=(unit shrinking)
      result=(unit outcome)
      time=@dr
      seen-tags=distribution
      examples=(map @t vase)
      pending=(unit vase)
  ==
::
++  version
  ::  Bump when deterministic generation/evaluation/shrinking semantics change.
  ^-  @tas
  %quiz-engine-6
::
++  defaults
  ^-  conf
  :*  100  10.000  1.000  1.000  1  0  %mug
      :*  262.144  10.000  1.000  100  65.536  16.384  16.384  262.144
          4.194.304  100  25
      ==
      %interrupt
  ==
::
++  call-time
  ::  Default CPU limit per user call; the app sets `time` from its settings.
  ~s10
::
++  label-max
  ::  Distinct labels, and distinct table rows, one run may record.
  100
::
++  label-bytes
  ::  Longest label, table name or table value, in bytes.
  256
::
++  init
  ::  Compiled parts must already be type-checked by the source builder.
  ::  Zero requested passes immediately; zero budgets stop before generation.
  ::  Use defaults with field overrides for the app configuration.
  ::  Size starts at size-start, at least 1, held at size-max when set.
  |=  [seed=@uv config=conf compiled=parts]
  ^-  state
  =/  start  (max 1 size-start.config)
  =/  size  ?:(=(0 size-max.config) start (min size-max.config start))
  %-  finish
  :*  seed  config  compiled  (slot 6 fate.compiled)  size  ~(. og seed)
      ~  0  *counters  ~  ~  call-time  [~ ~]  ~  ~
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
        ?:  =(p.evaluated %.n)  [%false ~ ~]
        ?:  =(p.evaluated %drop)  %drop
        [%bad-product p.evaluated]
  ==
::
++  judge
  ::  Classify a fate product. A report is molded under virtualization, so
  ::  a malformed one is a bad product. Only a report carries tags.
  |=  evaluated=toon
  ^-  [verdict tags]
  ?.  ?=([%0 %report *] evaluated)  [(classify evaluated) ~ ~]
  =/  got  (mole |.(;;(report p.evaluated)))
  ?~  got  [[%bad-product p.evaluated] ~ ~]
  =/  r=report  u.got
  =/  =tags  [labels.r tables.r]
  ?:  ?=(%drop ok.r)  [%drop tags]
  ?:  ok.r  [%pass tags]
  [[%false detail.r] tags]
::
++  generate
  ::  Both default fill and the custom norn execute inside the same sandbox.
  |=  [time=@dr size=@ud rng=_og sample=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [size=@ud rng=_og sample=vase custom=(unit vase)]
    ^-  vase
    ?~  custom
      (~(fill quiz:legacy [size rng]) sample)
    [p.sample (slum q.u.custom [size rng])]
  (sandbox time maker [size rng sample custom])
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
    (conclude s)
  =/  budget=(unit ?(%attempts %drops %duplicates))
    ?:  (gte attempted.counts.s attempts-max.config.s)  `%attempts
    ?:  (gte dropped.counts.s drops-max.config.s)  `%drops
    ?:  ?&  !?=(%allow duplicates.config.s)
            (gte duplicate.counts.s duplicates-max.config.s)
        ==
      `%duplicates
    ~
  ?~  budget  s
  ::  Duplicates do not prevent all evaluated samples from being drops.
  =/  all-dropped  &(=(accepted.counts.s 0) (gth dropped.counts.s 0))
  s(result `[%exhausted u.budget all-dropped])
::
++  step
  ::  Attempted counts generated samples, including duplicates and failures.
  ::  Generation errors count no sample. Only %.y increments accepted.
  ::  Drops and duplicates consume their own budgets, never requested.
  ::  Which samples count as duplicates follows the conf's policy; under
  ::  %allow none do, and the duplicates budget is ignored.
  ::  The failure sample is included in attempted. Terminal states are stable.
  ::  A shrinking step calls alts once OR considers one candidate.
  ::  A stored sample was generated within budget: judge it before budgets
  ::  apply, or a split run would never judge its last permitted attempt.
  |=  s=state
  ^-  state
  ?:  !=(~ result.s)  s
  ::  `!=` rather than `?=`: narrowing `pending` would block the write below.
  ?:  !=(~ pending.s)  (judge-pending s)
  =.  s  (finish s)
  ?:  !=(~ result.s)  s
  ?:  !=(~ shrink.s)  (shrink-step s)
  =/  [fill-rng=_og next-rng=_og]  (split-rng:legacy rng.s)
  =/  time  time.s
  =/  made  (generate time size.s fill-rng sample.s norn.compiled.s)
  ?.  ?=(%0 -.made)
    =/  why  (classify made)
    ?>  ?=(^ why)
    =/  stage  ?:(=(~ norn.compiled.s) %generate %norn)
    (stop-error s stage why ~)
  ::  generate's maker already returns a vase. Unbox that trusted product;
  ::  molding its shared type tree again can expand recursive sample types.
  =/  sam  !<(vase [p:!>(*vase) p.made])
  =.  s
    s(rng next-rng, size (grow size.s size-max.config.s))
  =.  attempted.counts.s  +(attempted.counts.s)
  =/  capped  (sample-limit time sam bounds.config.s)
  ?:  ?=(%.n -.capped)
    =/  stage  ?:(=(~ norn.compiled.s) %generate %norn)
    (stop-error s stage p.capped ~)
  =/  limit  p.capped
  ?^  limit  s(result `[%limited u.limit ~])
  =/  hash  (mug q.sam)
  =/  repeat=?
    ?-  duplicates.config.s
      %allow  |
      %mug    (~(has by seen.s) hash)
      %exact  (lien (~(get ja seen.s) hash) |=(n=* =(n q.sam)))
    ==
  ?:  repeat
    (finish s(duplicate.counts +(duplicate.counts.s)))
  =.  s
    ?-  duplicates.config.s
      %allow  s
      %mug    s(seen (~(put by seen.s) hash ~))
      %exact  %=  s
                seen       (~(add ja seen.s) hash q.sam)
                seen-used  (add seen-used.s (met 3 (jam q.sam)))
              ==
    ==
  ?:  (gth seen-used.s seen-bytes.bounds.config.s)
    s(result `[%limited %seen-bytes ~])
  ::  Under the split policy the fate runs on a later tick, from `pending`.
  ?.  =(%interrupt on-timeout.config.s)  s(pending `sam)
  (evaluate s sam)
::
++  judge-pending
  ::  The fate on the sample or candidate a split tick stored.
  |=  s=state
  ^-  state
  =/  sam=vase  (need pending.s)
  =.  s  s(pending ~)
  ?^  shrink.s  (judge-candidate s sam)
  (evaluate s sam)
::
++  evaluate
  ::  Judge a generated sample. A pass counts and tallies, a drop counts,
  ::  and a failure starts shrinking.
  |=  [s=state sam=vase]
  ^-  state
  =/  hash  (mug q.sam)
  =/  [found=verdict =tags]  (judge (sandbox time.s q.fate.compiled.s q.sam))
  ?-  found
    %pass  (finish (tally s(accepted.counts +(accepted.counts.s)) sam tags))
    %drop  (finish s(dropped.counts +(dropped.counts.s)))
    ^      ?.  (fits diagnostics-bytes.bounds.config.s found)
             s(result `[%limited %diagnostics-bytes ~])
           s(shrink `[[found sam sam] (~(put in *(set @)) hash) ~])
  ==
::
++  timed-out
  ::  The fate on `pending` exceeded its call limit. The aborted tick rolled
  ::  back, so the state still holds the sample. A discarded sample counts
  ::  as dropped; a discarded candidate is skipped. Under %fail a hanging
  ::  sample starts shrinking as a %timeout failure, and a hanging candidate
  ::  is accepted only while the failure is also a %timeout: a candidate
  ::  that hangs for a different kind of failure is skipped.
  |=  s=state
  ^-  state
  =/  sam=vase  (need pending.s)
  =.  s  s(pending ~)
  ?:  ?=(%discard on-timeout.config.s)
    ?~  shrink.s  s(dropped.counts +(dropped.counts.s))
    s
  ?~  shrink.s
    s(shrink `[[[%timeout ~] sam sam] *(set @) ~])
  ?.  ?=([%timeout ~] why.evidence.u.shrink.s)  s
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  ::  The candidate list is for the old best sample: ask alts again.
  s(shrink `u.shrink.s(shrunk.evidence sam, pending ~))
::
++  judge-candidate
  ::  Judge one shrink candidate whose weight was already checked. The
  ::  failure follows the shrunk sample, as its detail describes it.
  |=  [s=state sam=vase]
  ^-  state
  =/  work  (need shrink.s)
  =/  found  -:(judge (sandbox time.s q.fate.compiled.s q.sam))
  ?@  found  s(shrink `work)
  ?.  (fits diagnostics-bytes.bounds.config.s found)
    s(shrink ~, result `[%limited %diagnostics-bytes `evidence.work])
  ?.  =(-.found -.why.evidence.work)  s(shrink `work)
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  s(shrink `work(shrunk.evidence sam, why.evidence found, pending ~))
::
++  grow
  ::  The next sample's size: about 1.1 times larger, plus one, held at
  ::  the cap when the cap is nonzero.
  |=  [size=@ud cap=@ud]
  ^-  @ud
  =/  next  (add +(size) (div (mul size 2) 21))
  ?:(=(0 cap) next (min cap next))
::
++  tally
  ::  Count a passing sample's labels, once each, and its table rows; keep
  ::  the first sample per label as that label's example. An oversized tag
  ::  or too many distinct labels or rows stops the run.
  |=  [s=state sam=vase =tags]
  ^-  state
  =/  labels=(list @t)  ~(tap in (silt labels.tags))
  =/  cells=(list (list @t))
    (turn tables.tags |=([a=@t b=@t] `(list @t)`~[a b]))
  =/  flat=(list @t)  (zing cells)
  =/  texts=(list @t)  (weld labels flat)
  ?:  (lien texts |=(t=@t (gth (met 3 t) label-bytes)))
    s(result `[%limited %labels ~])
  ::  Each fold starts from the run's totals through the gate's sample.
  =/  count
    |=  [label=@t seen=(map @t @ud)]
    ^-  (map @t @ud)
    (~(put by seen) label +((~(gut by seen) label 0)))
  =/  counted  (roll labels count(seen labels.seen-tags.s))
  =/  add-row
    |=  [[table=@t value=@t] all=(map @t (map @t @ud))]
    ^-  (map @t (map @t @ud))
    (~(put by all) table (count value (~(gut by all) table ~)))
  =/  rows  (roll tables.tags add-row(all tables.seen-tags.s))
  =/  width=@ud
    (roll (turn ~(val by rows) |=(m=(map @t @ud) ~(wyt by m))) add)
  ?:  |((gth ~(wyt by counted) label-max) (gth width label-max))
    s(result `[%limited %labels ~])
  =/  keep
    |=  [label=@t kept=(map @t vase)]
    ^-  (map @t vase)
    ?:((~(has by kept) label) kept (~(put by kept) label sam))
  =/  kept  (roll labels keep(kept examples.s))
  s(seen-tags [counted rows], examples kept)
::
++  shortfalls
  ::  Rows below their required share. `got` is the floored percentage;
  ::  the comparison itself is exact.
  |=  s=state
  ^-  (list shortfall)
  =/  cover  cover.compiled.s
  ?~  cover  ~
  =/  total  accepted.counts.s
  %+  murn  rows.u.cover
  |=  [label=@t percent=@ud]
  ^-  (unit shortfall)
  =/  hits  (~(gut by labels.seen-tags.s) label 0)
  ?:  (gte (mul 100 hits) (mul percent total))  ~
  =/  got  ?:(=(0 total) 0 (div (mul 100 hits) total))
  `[label percent got]
::
++  conclude
  ::  The requested count was reached. Expected failure, then coverage.
  |=  s=state
  ^-  state
  ?:  ?=(%fail expect.compiled.s)  s(result `[%passed-unexpectedly ~])
  =/  short  (shortfalls s)
  =/  cover  cover.compiled.s
  ?:  &(?=(^ cover) ?=(%check mode.u.cover) ?=(^ short))
    s(result `[%uncovered short])
  s(result `[%passed short])
::
++  failed
  ::  Shrinking ended. An expected failure is reported as such.
  |=  [s=state evidence=counterexample]
  ^-  state
  ?:  ?=(%fail expect.compiled.s)
    s(shrink ~, result `[%failed-as-expected evidence])
  s(shrink ~, result `[%failed evidence])
::
++  fits
  ::  Encoded noun bytes, including vase type where applicable. Post-call cap;
  ::  jam and the evaluated gate still allocate before this check can run.
  |=  [maximum=@ud value=*]
  ^-  ?
  (lte (met 3 (jam value)) maximum)
::
++  sandbox
  ::  Virtualize a user call under a %jinx CPU limit. A crash or scry
  ::  returns a toon; a timeout aborts the event and never returns here.
  |=  [time=@dr gate=* sample=*]
  ^-  toon
  ~>  %jinx.time
  (mong [gate sample] |=(^ ~))
::
++  sample-limit
  ::  A vase returned by alts can have a valid type but an invalid value.
  ::  Keep rendering inside virtualization so such products become errors.
  |=  [time=@dr sam=vase bounds=limits]
  ^-  (each (unit limit-name) failure)
  =/  inspect
    |=  [sam=vase bounds=limits]
    ^-  (unit limit-name)
    ?.  (fits sample-bytes.bounds sam)  `%sample-bytes
    =/  text  (crip ~(ram re (sell sam)))
    ?:  (gth (met 3 text) rendered-bytes.bounds)  `%rendered-bytes
    ~
  =/  checked  (sandbox time inspect [sam bounds])
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
  |=  [time=@dr sam=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [sam=vase custom=(unit vase)]
    ^-  (list vase)
    ?~  custom  (sink:legacy sam)
    ;;((list vase) (slum q.u.custom sam))
  (sandbox time maker [sam custom])
::
++  shrink-step
  |=  s=state
  ^-  state
  =/  work  (need shrink.s)
  =/  evidence  evidence.work
  ::  A known empty list is complete even on the last allowed candidate.
  ?:  =([~ ~] pending.work)
    (failed s evidence)
  =/  budget=(unit limit-name)
    ?:  (gte shrink-tried.counts.s shrink-candidates.bounds.config.s)
      `%shrink-candidates
    ?:  (gte shrink-steps.counts.s shrink-depth.bounds.config.s)
      `%shrink-depth
    ~
  ?^  budget
    s(shrink ~, result `[%limited u.budget `evidence])
  =/  time  time.s
  =/  pending  pending.work
  ?~  pending
    =/  made  (alternatives time shrunk.evidence alts.compiled.s)
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
    (failed s evidence)
  =/  sam  i.candidates
  =.  work  work(pending `t.candidates)
  =.  shrink-tried.counts.s  +(shrink-tried.counts.s)
  =/  capped  (sample-limit time sam bounds.config.s)
  ?:  ?=(%.n -.capped)  (stop-error s %alts p.capped `evidence)
  =/  limit  p.capped
  ?^  limit
    s(shrink ~, result `[%limited u.limit `evidence])
  ::  The visited set is a mug-only loop guard whatever the policy; weight
  ::  decrease alone guarantees termination.
  =/  hash  (mug q.sam)
  ?:  (~(has in visited.work) hash)  s(shrink `work)
  =.  visited.work  (~(put in visited.work) hash)
  ?.  (lth (weight q.sam) (weight q.shrunk.evidence))  s(shrink `work)
  ::  Split: the candidate waits in `pending` for its own tick.
  ?.  =(%interrupt on-timeout.config.s)  s(shrink `work, pending `sam)
  (judge-candidate s(shrink `work) sam)
--
