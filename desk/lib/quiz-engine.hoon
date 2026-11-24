/+  legacy=quiz, auto=quiz-auto
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
      trace-steps=@ud
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
+$  table-row
  ::  Required share, in whole percent, of one table's entries for a value.
  [table=@t value=@t percent=@ud]
::
+$  confidence
  ::  %confident decides when wrong at most 1 in 10^certainty, and passes
  ::  a row at tolerance percent of its share.
  [certainty=@ud tolerance=@ud]
::
+$  coverage
  ::  A document's ++cover, ++cover-table and ++confidence together.
  [=cover tables=(list table-row) =confidence]
::
+$  expectation  ?(%pass %fail)
::
+$  parts
  $:  fate=vase
      norn=(unit vase)
      alts=(unit vase)
      cover=(unit coverage)
      expect=expectation
  ==
::
+$  distribution
  [labels=(map @t @ud) tables=(map @t (map @t @ud))]
::
+$  shortfall
  ::  A label's row, or a table's value row with that table's name.
  [label=@t want=@ud got=@ud table=(unit @t)]
::
+$  requirement
  ::  A row with its hits and the count its share is taken of.
  [=shortfall hits=@ud total=@ud]
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
  ::  `trace` holds the last trace-steps shrink steps, newest first.
  $:  why=failure
      original=vase
      shrunk=vase
      texts=[original=@t shrunk=@t]
      trace=(list trace-row)
  ==
::
+$  reason
  ::  What became of one shrink candidate: it replaced the best sample
  ::  (%accepted, or %timeout when it hung under %fail), passed, dropped,
  ::  failed another way, was not lighter, or was seen before.
  ?(%accepted %timeout %passed %dropped %other-failure %heavier %visited)
::
+$  trace-row
  ::  An alts call on the best sample, or one candidate's fate. Weights and
  ::  text are absent where the step did not compute them.
  $%  [%alts best=@ud count=@ud]
      [%candidate weight=(unit @ud) why=reason text=(unit @t)]
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
+$  preview-row
  ::  One previewed sample: the size it was made at, its value and text,
  ::  whether the duplicate policy would skip it, and, when asked for, the
  ::  fate's verdict kind and labels.
  $:  size=@ud
      value=*
      text=@t
      repeat=?
      verdict=(unit @tas)
      labels=(list @t)
  ==
::
+$  candidate-row
  ::  One alts candidate of the first previewed sample. Weight is absent,
  ::  and lighter false, when the candidate could not be shown.
  [value=* text=@t weight=(unit @ud) lighter=?]
::
+$  preview
  ::  A preview in progress: its request and the rows so far, newest first.
  $:  count=@ud
      verdicts=?
      alts=?
      rows=(list preview-row)
      first=(unit [=vase weight=@ud])
  ==
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
      [%preview rows=(list preview-row) candidates=(list candidate-row)]
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
      preview=(unit preview)
      ::  A document's ++within: its calls' limit, below the ship's.
      within=(unit @dr)
  ==
::
++  version
  ::  Bump when deterministic generation/evaluation/shrinking semantics change.
  ^-  @tas
  %quiz-engine-13
::
++  defaults
  ::  100 passes within 10.000 attempts, 1.000 drops and duplicates; size
  ::  from 1, uncapped; %mug duplicates; a timeout interrupts the run.
  ^-  conf
  :*  100  10.000  1.000  1.000  1  0  %mug
      :*  262.144  10.000  1.000  100  65.536  16.384  16.384  262.144
          4.194.304  100  1.000  100
      ==
      %interrupt
  ==
::
++  call-time
  ::  Default CPU limit per user call; the app sets `time` from its settings.
  ~s10
::
++  call-limit
  ::  The limit a slice's calls run under: the ship-wide limit, lowered by
  ::  a document's ++within.
  |=  [ship=@dr within=(unit @dr)]
  ^-  @dr
  ?~(within ship (min ship u.within))
::
++  within-min
  ::  The shortest ++within: 10 ms.
  (div ~s1 100)
::
++  within-max  ~h1
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
      ~  0  *counters  ~  ~  call-time  [~ ~]  ~  ~  ~  ~
  ==
::
++  preview-max
  ::  Most samples one preview makes.
  100
::
++  candidate-max
  ::  Most alts candidates a preview shows.
  20
::
++  previewing
  ::  Turn a fresh run into a preview of `count` samples, at most
  ::  preview-max. A preview has no budgets, so a result init set from them
  ::  is cleared.
  |=  [s=state count=@ud verdicts=? alts=?]
  ^-  state
  =/  wanted  (min count preview-max)
  s(result ~, preview `[wanted verdicts alts ~ ~])
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
  ::  The default is quiz-auto's type-directed fill.
  |=  [time=@dr size=@ud rng=_og sample=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [size=@ud rng=_og sample=vase custom=(unit vase)]
    ^-  vase
    ?~  custom  (fill:auto size rng sample)
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
  ?:  !=(~ preview.s)  (preview-step s)
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
++  preview-step
  ::  One preview step: make, show and, when asked, judge one sample, with
  ::  the run's streams and sizes, so sample i is a run's sample i up to the
  ::  run's first skipped repeat. A repeat is flagged, not skipped. After
  ::  the last sample, ++preview-end.
  |=  s=state
  ^-  state
  =/  p  (need preview.s)
  ?:  (gte (lent rows.p) count.p)  (preview-end s p)
  =/  [fill-rng=_og next-rng=_og]  (split-rng:legacy rng.s)
  =/  made  (generate time.s size.s fill-rng sample.s norn.compiled.s)
  ?.  ?=(%0 -.made)
    =/  why  (classify made)
    ?>  ?=(^ why)
    (stop-error s (source-stage s) why ~)
  =/  sam  !<(vase [p:!>(*vase) p.made])
  =/  made-at  size.s
  =.  s  s(rng next-rng, size (grow size.s size-max.config.s))
  =.  attempted.counts.s  +(attempted.counts.s)
  ?:  (gth (met 3 (jam q.sam)) sample-bytes.bounds.config.s)
    s(result `[%limited %sample-bytes ~])
  =/  hash  (mug q.sam)
  =/  repeat=?
    ?-  duplicates.config.s
      %allow  |
      %mug    (~(has by seen.s) hash)
      %exact  (lien (~(get ja seen.s) hash) |=(n=* =(n q.sam)))
    ==
  =?  seen.s  !repeat  (~(add ja seen.s) hash q.sam)
  =/  got  (show s sam ~)
  ?:  ?=(%.n -.got)  (unshown s (source-stage s) p.got ~)
  =/  judged=[(unit @tas) (list @t)]
    ?.  verdicts.p  [~ ~]
    =/  [found=verdict =tags]  (judge (sandbox time.s q.fate.compiled.s q.sam))
    [`?@(found found -.found) labels.tags]
  =/  row=preview-row  [made-at q.sam text.p.got repeat judged]
  =/  first  ?^(first.p first.p `[sam weight.p.got])
  s(preview `p(rows [row rows.p], first first))
::
++  preview-end
  ::  End a preview. With `alts`, one alts call on the first sample; up to
  ::  candidate-max candidates are shown, each marked lighter or not.
  |=  [s=state p=preview]
  ^-  state
  =/  rows  (flop rows.p)
  ?.  &(alts.p ?=(^ first.p))  s(preview ~, result `[%preview rows ~])
  =/  [sam=vase top=@ud]  u.first.p
  =/  made  (alternatives time.s sam alts.compiled.s)
  ?.  ?=(%0 -.made)
    =/  why  (classify made)
    ?>  ?=(^ why)
    (stop-error s %alts why ~)
  =/  all  !<((list vase) [p:!>(*(list vase)) p.made])
  =/  candidates=(list candidate-row)
    %+  turn  (scag candidate-max all)
    |=  c=vase
    ^-  candidate-row
    =/  got  (show s c ~)
    ?:  ?=(%.n -.got)  [q.c '' ~ |]
    [q.c text.p.got `weight.p.got (lth weight.p.got top)]
  s(preview ~, result `[%preview rows candidates])
::
++  judge-pending
  ::  The fate on the sample or candidate a split tick stored.
  |=  s=state
  ^-  state
  =/  got  (need pending.s)
  =.  s  s(pending ~)
  ?^  shrink.s  (judge-candidate s vase.got `shown.got weight.shown.got)
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
    =/  evidence=counterexample  [found sam sam [text.p.got text.p.got] ~]
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
  =/  [sam=vase text=@t weight=@]  got
  =/  cap  trace-steps.bounds.config.s
  =/  row
    |=  why=reason
    ^-  trace-row
    [%candidate `weight why `(clip text)]
  ?:  ?=(%discard on-timeout.config.s)
    ?~  shrink.s  s(dropped.counts +(dropped.counts.s))
    s(shrink `(log cap u.shrink.s (row %dropped)))
  ?~  shrink.s
    =/  evidence=counterexample  [[%timeout ~] sam sam [text text] ~]
    s(shrink `[evidence *(set @) ~ weight])
  ?.  ?=([%timeout ~] why.evidence.u.shrink.s)
    s(shrink `(log cap u.shrink.s (row %other-failure)))
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  =/  work  (log cap u.shrink.s (row %timeout))
  =.  evidence.work  evidence.work(shrunk sam, shrunk.texts text)
  ::  The candidate list is for the old best sample: ask alts again.
  s(shrink `work(weight weight, pending ~))
::
++  judge-candidate
  ::  Judge one shrink candidate of weight `w`, already checked lighter.
  ::  The failure follows the shrunk sample, as its detail describes it.
  ::  Each candidate's fate goes into the trace; a rejected candidate's
  ::  text is rendered only for the trace, and a rendering failure there
  ::  leaves the text out rather than changing the run.
  |=  [s=state sam=vase seen=(unit shown) w=@ud]
  ^-  state
  =/  work  (need shrink.s)
  =/  cap  trace-steps.bounds.config.s
  =/  found  -:(judge (sandbox time.s q.fate.compiled.s q.sam))
  =/  rejected
    |=  why=reason
    ^-  state
    =/  text  (trace-text s sam seen)
    s(shrink `(log cap work [%candidate `w why text]))
  ?@  found  (rejected ?:(?=(%pass found) %passed %dropped))
  ?.  (fits diagnostics-bytes.bounds.config.s found)
    s(shrink ~, result `[%limited %diagnostics-bytes `evidence.work])
  ?.  =(-.found -.why.evidence.work)  (rejected %other-failure)
  =/  got  (show s sam seen)
  ?:  ?=(%.n -.got)  (unshown s %alts p.got `evidence.work)
  =.  shrink-steps.counts.s  +(shrink-steps.counts.s)
  =.  evidence.work
    evidence.work(shrunk sam, why found, shrunk.texts text.p.got)
  =.  work  (log cap work [%candidate `w %accepted `(clip text.p.got)])
  s(shrink `work(weight weight.p.got, pending ~))
::
++  log
  ::  Add a row to the trace, keeping the newest `cap` rows.
  |=  [cap=@ud work=shrinking row=trace-row]
  ^-  shrinking
  ?:  =(0 cap)  work
  ::  Typed first: +scag keeps its argument's type, and a literal cell
  ::  cannot hold the empty list.
  =/  rows=(list trace-row)  [row trace.evidence.work]
  work(trace.evidence (scag cap rows))
::
++  trace-text
  ::  A rejected candidate's text for the trace, or ~ when tracing is off
  ::  or rendering fails.
  |=  [s=state sam=vase seen=(unit shown)]
  ^-  (unit @t)
  ?:  =(0 trace-steps.bounds.config.s)  ~
  ?^  seen  `(clip text.u.seen)
  =/  made
    (sandbox time.s |=(v=vase `@t`(crip ~(ram re (sell v)))) sam)
  ?.  ?=(%0 -.made)  ~
  =/  text  ((soft @t) p.made)
  ?~(text ~ `(clip u.text))
::
++  clip
  ::  At most trace-bytes of a rendering, marked when cut.
  |=  text=@t
  ^-  @t
  ?:  (lte (met 3 text) trace-bytes)  text
  (cat 3 (end [3 (sub trace-bytes 3)] text) '...')
::
++  trace-bytes
  ::  Longest text a trace row keeps.
  160
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
  ::  the comparison itself is exact. A table row whose table has no
  ::  entries is short unless it requires nothing.
  |=  s=state
  ^-  (list shortfall)
  %+  murn  (requirements s)
  |=  req=requirement
  ^-  (unit shortfall)
  =/  want  want.shortfall.req
  ?:  &(?=(^ table.shortfall.req) =(0 total.req) (gth want 0))
    `shortfall.req
  ?:  (gte (mul 100 hits.req) (mul want total.req))  ~
  `shortfall.req
::
++  requirements
  ::  Every coverage row with its hits and total. A label counts accepted
  ::  samples; a table row counts its value among that table's entries.
  ::  `got` is filled with the floored percentage.
  |=  s=state
  ^-  (list requirement)
  =/  cover  cover.compiled.s
  ?~  cover  ~
  =/  share
    |=  [hits=@ud total=@ud]
    ?:(=(0 total) 0 (div (mul 100 hits) total))
  =/  accepted  accepted.counts.s
  =/  labels=(list requirement)
    %+  turn  rows.cover.u.cover
    |=  [label=@t percent=@ud]
    =/  hits  (~(gut by labels.seen-tags.s) label 0)
    [[label percent (share hits accepted) ~] hits accepted]
  =/  tables=(list requirement)
    %+  turn  tables.u.cover
    |=  row=table-row
    =/  counts  (~(gut by tables.seen-tags.s) table.row ~)
    =/  total  (roll ~(val by counts) add)
    =/  hits  (~(gut by counts) value.row 0)
    [[value.row percent.row (share hits total) `table.row] hits total]
  (weld labels tables)
::
++  conclude
  ::  A checkpoint was reached. Expected failure, then coverage. Under
  ::  %confident a row whose upper bound is below its share fails, and the
  ::  run passes once every lower bound reaches the tolerance of its share;
  ::  otherwise it goes on. A table row with no entries yet is undecided.
  ::  At the `final` checkpoint, or with no samples, the plain threshold
  ::  decides, as under %check.
  |=  [s=state final=?]
  ^-  state
  ?:  ?=(%fail expect.compiled.s)  s(result `[%passed-unexpectedly ~])
  =/  cover  cover.compiled.s
  =/  n  accepted.counts.s
  ?:  &(?=(^ cover) ?=(%confident mode.cover.u.cover) !final (gth n 0))
    =/  reqs  (requirements s)
    =/  z  (z-for certainty.confidence.u.cover)
    =/  tolerance  (div:rd (sun:rd tolerance.confidence.u.cover) .~100)
    =/  share  |=(percent=@ud (div:rd (sun:rd percent) .~100))
    =/  under=(list shortfall)
      %+  murn  reqs
      |=  req=requirement
      ^-  (unit shortfall)
      ?:  =(0 total.req)  ~
      =/  top  (wilson hits.req total.req z)
      ?.  (lth:rd top (share want.shortfall.req))  ~
      `shortfall.req
    ?^  under  s(result `[%uncovered under])
    =/  enough
      %+  levy  reqs
      |=  req=requirement
      ?:  =(0 total.req)  |
      =/  low  (wilson hits.req total.req (sub:rd .~0 z))
      (gte:rd low (mul:rd tolerance (share want.shortfall.req)))
    ?:  enough  s(result `[%passed ~])
    s
  =/  short  (shortfalls s)
  ?:  &(?=(^ cover) !?=(%warn mode.cover.u.cover) ?=(^ short))
    s(result `[%uncovered short])
  s(result `[%passed short])
::
++  confident
  ::  Does the property ask for statistical coverage?
  |=  s=state
  ^-  ?
  =/  cover  cover.compiled.s
  &(?=(^ cover) ?=(%confident mode.cover.u.cover))
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
++  default-confidence
  ::  QuickCheck's checkCoverage: wrong 1 in 10^9; a row passes at 90
  ::  percent of its share.
  ^-  confidence
  [9 90]
::
++  confidence-z
  ::  The normal quantile for the default certainty.
  (z-for certainty:default-confidence)
::
++  z-for
  ::  The normal quantile z with P(|Z| > z) = 10^-k, for k from 1 to 15.
  |=  k=@ud
  ^-  @rd
  ~|  [%certainty k]
  ?>  &((gte k 1) (lte k (lent z-table)))
  (snag (dec k) z-table)
::
++  z-table
  ::  -inv_cdf(10^-k / 2) for k = 1 to 15.
  ^-  (list @rd)
  :~  .~1.6448536269514726  .~2.5758293035489  .~3.2905267314918945
      .~3.890591886413094  .~4.417173413469022  .~4.89163847569859
      .~5.326723886384497  .~5.730728868236289  .~6.1094102048693975
      .~6.466951087240515  .~6.806502490740626  .~7.130506848171323
      .~7.440902150642369  .~7.739256319504373  .~8.02685888253454
  ==
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
  ::  Default (quiz-auto) and custom alts and product validation share the
  ::  refusing sandbox.
  ::  Only the list of cells is checked: molding each candidate's type with
  ::  `vase` walks recursive types such as `(list @ud)` through their whole
  ::  subject. A bad type crashes later, inside ++show's sandbox.
  |=  [time=@dr sam=vase custom=(unit vase)]
  ^-  toon
  =/  maker
    |=  [sam=vase custom=(unit vase)]
    ^-  (list [* *])
    ?~  custom  (sink:auto sam)
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
    =/  cap  trace-steps.bounds.config.s
    =.  work  (log cap work [%alts weight.work (lent candidates)])
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
  =/  cap  trace-steps.bounds.config.s
  ?:  (~(has in visited.work) hash)
    s(shrink `(log cap work [%candidate ~ %visited ~]))
  =.  visited.work  (~(put in visited.work) hash)
  ::  Weighed virtualized: a small jam can be a huge tree.
  =/  weighed  (sandbox time weight q.sam)
  ?.  ?=(%0 -.weighed)
    =/  why  (classify weighed)
    ?>  ?=(^ why)
    (stop-error s %alts why `evidence)
  =/  w  ;;(@ p.weighed)
  ?.  (lth w weight.work)
    s(shrink `(log cap work [%candidate `w %heavier ~]))
  ?:  =(%interrupt on-timeout.config.s)
    (judge-candidate s(shrink `work) sam ~ w)
  ::  Split: the candidate is shown, then waits in `pending` for its tick.
  =/  got  (show s sam ~)
  ?:  ?=(%.n -.got)  (unshown s %alts p.got `evidence)
  s(shrink `work, pending `[sam p.got])
--
