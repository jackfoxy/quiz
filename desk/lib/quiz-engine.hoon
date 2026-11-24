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
  ::  %warn reports shortfalls and %check fails on them, both at the
  ::  requested count. %confident tests on until Wilson bounds decide.
  [mode=?(%warn %check %confident) rows=(list [label=@t percent=@ud])]
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
+$  shown
  ::  A kept sample's rendering and its shrink weight, made together once.
  [text=@t weight=@]
::
+$  example  [=vase text=@t]
::
+$  counterexample
  $:  why=failure
      original=vase
      shrunk=vase
      texts=[original=@t shrunk=@t]
  ==
::
+$  limit-name
  $?  %requested  %shrink-candidates  %shrink-depth  %sample-bytes
      %rendered-bytes  %diagnostics-bytes  %alts-bytes  %labels
      %seen-bytes
  ==
::
+$  shrinking
  ::  `weight` is the shrunk sample's, so candidates need not reweigh it.
  $:  evidence=counterexample
      visited=(set @)
      pending=(unit (list vase))
      weight=@
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
      examples=(map @t example)
      pending=(unit [=vase =shown])
  ==
::
++  version
  ::  Bump when deterministic generation/evaluation/shrinking semantics change.
  ^-  @tas
  %quiz-engine-10
::
++  defaults
  ::  100 passes within 10.000 attempts, 1.000 drops and duplicates; size
  ::  from 1, uncapped; %mug duplicates; a timeout interrupts the run.
  ^-  conf
  :*  100  10.000  1.000  1.000  1  0  %mug
      :*  262.144  10.000  1.000  100  65.536  16.384  16.384  262.144
          4.194.304  100  1.000
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
  ::  Under %confident coverage a run past the requested count stops at a
  ::  deciding checkpoint, at requested-max, or when a budget ends it.
  |=  s=state
  ^-  state
  ?:  !=(~ result.s)  s
  ?:  !=(~ shrink.s)  s
  ?:  (gth requested.config.s requested-max.bounds.config.s)
    s(result `[%limited %requested ~])
  =/  accepted  accepted.counts.s
  =/  met  (gte accepted requested.config.s)
  =/  stats  (confident s)
  ?:  &(met !stats)  (conclude s &)
  =/  last  =(accepted requested-max.bounds.config.s)
  =/  decided
    ?.  &(met |(last (checkpoint s)))  s
    (conclude s last)
  ?^  result.decided  decided
  =/  budget=(unit ?(%attempts %drops %duplicates))
    ?:  (gte attempted.counts.s attempts-max.config.s)  `%attempts
    ?:  (gte dropped.counts.s drops-max.config.s)  `%drops
    ?:  ?&  !?=(%allow duplicates.config.s)
            (gte duplicate.counts.s duplicates-max.config.s)
        ==
      `%duplicates
    ~
  ?~  budget  s
  ::  Requested checks were met: the coverage decides, not the budget.
  ?:  met  (conclude s &)
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
    (stop-error s (source-stage s) why ~)
  ::  generate's maker already returns a vase. Unbox that trusted product;
  ::  molding its shared type tree again can expand recursive sample types.
  =/  sam  !<(vase [p:!>(*vase) p.made])
  =.  s
    s(rng next-rng, size (grow size.s size-max.config.s))
  =.  attempted.counts.s  +(attempted.counts.s)
  ::  Only the value counts: every sample shares the type.
  =/  bytes  (met 3 (jam q.sam))
  ?:  (gth bytes sample-bytes.bounds.config.s)
    s(result `[%limited %sample-bytes ~])
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
                seen-used  (add seen-used.s bytes)
              ==
    ==
  ?:  (gth seen-used.s seen-bytes.bounds.config.s)
    s(result `[%limited %seen-bytes ~])
  ?:  =(%interrupt on-timeout.config.s)  (evaluate s sam ~)
  ::  Under a split policy the fate runs on a later tick, from `pending`.
  ::  Show the sample first: the error wake after a timeout keeps it as
  ::  evidence and must run no user code.
  =/  got  (show s sam ~)
  ?:  ?=(%.n -.got)  (unshown s (source-stage s) p.got ~)
  s(pending `[sam p.got])
::
++  judge-pending
  ::  The fate on the sample or candidate a split tick stored.
  |=  s=state
  ^-  state
  =/  got  (need pending.s)
  =.  s  s(pending ~)
  ?^  shrink.s  (judge-candidate s vase.got `shown.got)
  (evaluate s vase.got `shown.got)
::
++  evaluate
  ::  Judge a generated sample. A pass counts and tallies, a drop counts,
  ::  and a failure starts shrinking. `seen` is the sample's rendering when
  ::  a split tick already made it.
  |=  [s=state sam=vase seen=(unit shown)]
  ^-  state
  =/  [found=verdict =tags]  (judge (sandbox time.s q.fate.compiled.s q.sam))
  ?-    found
      %pass
    (finish (tally s(accepted.counts +(accepted.counts.s)) sam seen tags))
  ::
      %drop
    (finish s(dropped.counts +(dropped.counts.s)))
  ::
      ^
    ?.  (fits diagnostics-bytes.bounds.config.s found)
      s(result `[%limited %diagnostics-bytes ~])
    =/  got  (show s sam seen)
    ?:  ?=(%.n -.got)  (unshown s (source-stage s) p.got ~)
    =/  evidence=counterexample  [found sam sam text.p.got text.p.got]
    s(shrink `[evidence (~(put in *(set @)) (mug q.sam)) ~ weight.p.got])
  ==
::
++  timed-out
  ::  The fate on `pending` exceeded its call limit. The aborted tick rolled
  ::  back, so the state still holds the sample. A discarded sample counts
  ::  as dropped; a discarded candidate is skipped. Under %fail a hanging
  ::  sample starts shrinking as a %timeout failure, and a hanging candidate
  ::  is accepted only while the failure is also a %timeout: a candidate
  ::  that hangs for a different kind of failure is skipped.
  ::  The stored sample was shown before it waited, so no user code runs.
  |=  s=state
  ^-  state
  =/  got  (need pending.s)
  =.  s  s(pending ~)
  ?:  ?=(%discard on-timeout.config.s)
    ?~  shrink.s  s(dropped.counts +(dropped.counts.s))
    s
  =/  [sam=vase text=@t weight=@]  got
  ?~  shrink.s
    =/  evidence=counterexample  [[%timeout ~] sam sam text text]
    s(shrink `[evidence *(set @) ~ weight])
  ?.  ?=([%timeout ~] why.evidence.u.shrink.s)  s
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  =/  work  u.shrink.s
  =.  evidence.work  evidence.work(shrunk sam, shrunk.texts text)
  ::  The candidate list is for the old best sample: ask alts again.
  s(shrink `work(weight weight, pending ~))
::
++  judge-candidate
  ::  Judge one shrink candidate whose weight was already checked. The
  ::  failure follows the shrunk sample, as its detail describes it.
  |=  [s=state sam=vase seen=(unit shown)]
  ^-  state
  =/  work  (need shrink.s)
  =/  found  -:(judge (sandbox time.s q.fate.compiled.s q.sam))
  ?@  found  s(shrink `work)
  ?.  (fits diagnostics-bytes.bounds.config.s found)
    s(shrink ~, result `[%limited %diagnostics-bytes `evidence.work])
  ?.  =(-.found -.why.evidence.work)  s(shrink `work)
  =/  got  (show s sam seen)
  ?:  ?=(%.n -.got)  (unshown s %alts p.got `evidence.work)
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  =.  evidence.work
    evidence.work(shrunk sam, why found, shrunk.texts text.p.got)
  s(shrink `work(weight weight.p.got, pending ~))
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
  ::  An untagged pass changes nothing: the totals already met their caps.
  |=  [s=state sam=vase seen=(unit shown) =tags]
  ^-  state
  ?:  &(=(~ labels.tags) =(~ tables.tags))  s
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
  =.  seen-tags.s  [counted rows]
  ::  Only a label's first sample is shown, so most passes render nothing.
  =/  fresh=(list @t)  (skip labels ~(has by examples.s))
  ?~  fresh  s
  =/  got  (show s sam seen)
  ?:  ?=(%.n -.got)  (unshown s (source-stage s) p.got ~)
  =/  new=(list [@t example])  (turn fresh (late [sam text.p.got]))
  s(examples (~(gas by examples.s) new))
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
  ::  A checkpoint was reached. Expected failure, then coverage. Under
  ::  %confident a row whose upper bound is below its share fails, and the
  ::  run passes once every lower bound reaches `tolerance` of its share;
  ::  otherwise it goes on. At the `final` checkpoint, or with no samples,
  ::  the plain threshold decides, as under %check.
  |=  [s=state final=?]
  ^-  state
  ?:  ?=(%fail expect.compiled.s)  s(result `[%passed-unexpectedly ~])
  =/  cover  cover.compiled.s
  =/  n  accepted.counts.s
  ?:  &(?=(^ cover) ?=(%confident mode.u.cover) !final (gth n 0))
    =/  rows  rows.u.cover
    =/  hits  |=(label=@t (~(gut by labels.seen-tags.s) label 0))
    =/  share  |=(percent=@ud (div:rd (sun:rd percent) .~100))
    =/  under=(list shortfall)
      %+  murn  rows
      |=  [label=@t percent=@ud]
      ^-  (unit shortfall)
      =/  k  (hits label)
      ?.  (lth:rd (wilson k n confidence-z) (share percent))  ~
      `[label percent (div (mul 100 k) n)]
    ?^  under  s(result `[%uncovered under])
    =/  enough
      %+  levy  rows
      |=  [label=@t percent=@ud]
      =/  low  (wilson (hits label) n (sub:rd .~0 confidence-z))
      (gte:rd low (mul:rd tolerance (share percent)))
    ?:  enough  s(result `[%passed ~])
    s
  =/  short  (shortfalls s)
  ?:  &(?=(^ cover) !?=(%warn mode.u.cover) ?=(^ short))
    s(result `[%uncovered short])
  s(result `[%passed short])
::
++  confident
  ::  Does the property ask for statistical coverage?
  |=  s=state
  ^-  ?
  =/  cover  cover.compiled.s
  &(?=(^ cover) ?=(%confident mode.u.cover))
::
++  checkpoint
  ::  Coverage is judged at requested times a power of two, as QuickCheck
  ::  does from 100, so repeated looks keep the error bounded.
  |=  s=state
  ^-  ?
  =/  wanted  requested.config.s
  =/  n  accepted.counts.s
  ?:  =(0 wanted)  &
  ?.  =(0 (mod n wanted))  |
  =/  ratio  (div n wanted)
  &((gth ratio 0) =(0 (dis ratio (dec ratio))))
::
++  confidence-z
  ::  Normal quantile for QuickCheck's default certainty: wrong 1 in 10^9.
  .~6.109410191663286
::
++  tolerance
  ::  A covered row needs this fraction of its share, as in QuickCheck.
  .~0.9
::
++  wilson
  ::  The Wilson score bound on the share behind `k` hits of `n`; a
  ::  negative `z` gives the lower bound, a positive one the upper.
  |=  [k=@ud n=@ud z=@rd]
  ^-  @rd
  =/  nn  (sun:rd n)
  =/  p  (div:rd (sun:rd k) nn)
  =/  zz  (mul:rd z z)
  =/  wide
    %+  add:rd  (div:rd (mul:rd p (sub:rd .~1 p)) nn)
    (div:rd zz (mul:rd .~4 (mul:rd nn nn)))
  =/  top
    (add:rd (add:rd p (div:rd zz (mul:rd .~2 nn))) (mul:rd z (sqt:rd wide)))
  (div:rd top (add:rd .~1 (div:rd zz nn)))
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
++  show
  ::  Render and weigh a sample that will be kept, reusing `seen` when a
  ::  split tick already made it. Both run virtualized: a vase from alts can
  ::  have a valid type but an invalid value, and shared subtrees can make a
  ::  small jam a huge tree. %.n ~ is text over rendered-bytes.
  |=  [s=state sam=vase seen=(unit shown)]
  ^-  (each shown (unit failure))
  ?^  seen  [%.y u.seen]
  =/  made
    %^  sandbox  time.s
      |=(v=vase `shown`[(crip ~(ram re (sell v))) (weight q.v)])
    sam
  ?.  ?=(%0 -.made)
    =/  why  (classify made)
    ?>  ?=(^ why)
    [%.n `why]
  =/  got  ;;(shown p.made)
  ?:  (gth (met 3 text.got) rendered-bytes.bounds.config.s)  [%.n ~]
  [%.y got]
::
++  unshown
  ::  A kept sample that rendered too long is a limit; one whose rendering
  ::  crashed is an error at `stage`.
  |=  $:  s=state
          stage=error-stage
          why=(unit failure)
          evidence=(unit counterexample)
      ==
  ^-  state
  ?~  why  s(shrink ~, result `[%limited %rendered-bytes evidence])
  (stop-error s stage u.why evidence)
::
++  source-stage
  ::  Where a generated sample came from.
  |=  s=state
  ^-  error-stage
  ?:(=(~ norn.compiled.s) %generate %norn)
::
++  stop-error
  ::  End the run as an error at `stage`, or %limited when the failure
  ::  exceeds the diagnostics cap.
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
  ::  Only the list of cells is checked: molding each candidate's type with
  ::  `vase` walks recursive types such as `(list @ud)` through their whole
  ::  subject. A bad type crashes later, inside ++show's sandbox.
  |=  [time=@dr sam=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [sam=vase custom=(unit vase)]
    ^-  (list [* *])
    ?~  custom  (sink:legacy sam)
    ;;((list [* *]) (slum q.u.custom sam))
  (sandbox time maker [sam custom])
::
++  shrink-step
  ::  Ask alts for candidates, or try the next one. The candidate and depth
  ::  budgets stop it as %limited; an exhausted list concludes the failure.
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
    ::  Unbox the checked list as vases without molding their types.
    =/  candidates  !<((list vase) [p:!>(*(list vase)) p.made])
    ::  Only values count, as for sample-bytes: a type with a recursive
    ::  mold carries its whole subject.
    =/  values=(list *)  (turn candidates tail)
    ?.  (fits alts-bytes.bounds.config.s values)
      s(shrink ~, result `[%limited %alts-bytes `evidence])
    s(shrink `work(pending `candidates))
  =/  candidates  u.pending
  ?~  candidates
    (failed s evidence)
  =/  sam  i.candidates
  =.  work  work(pending `t.candidates)
  =.  shrink-tried.counts.s  +(shrink-tried.counts.s)
  ?:  (gth (met 3 (jam q.sam)) sample-bytes.bounds.config.s)
    s(shrink ~, result `[%limited %sample-bytes `evidence])
  ::  The visited set is a mug-only loop guard whatever the policy; weight
  ::  decrease alone guarantees termination.
  =/  hash  (mug q.sam)
  ?:  (~(has in visited.work) hash)  s(shrink `work)
  =.  visited.work  (~(put in visited.work) hash)
  ::  Weighed virtualized: a small jam can be a huge tree.
  =/  weighed  (sandbox time weight q.sam)
  ?.  ?=(%0 -.weighed)
    =/  why  (classify weighed)
    ?>  ?=(^ why)
    (stop-error s %alts why `evidence)
  ?.  (lth ;;(@ p.weighed) weight.work)  s(shrink `work)
  ?:  =(%interrupt on-timeout.config.s)
    (judge-candidate s(shrink `work) sam ~)
  ::  Split: the candidate is shown, then waits in `pending` for its tick.
  =/  got  (show s sam ~)
  ?:  ?=(%.n -.got)  (unshown s %alts p.got `evidence)
  s(shrink `work, pending `[sam p.got])
--
