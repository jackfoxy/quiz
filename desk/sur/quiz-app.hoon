/+  engine=quiz-engine, build=quiz-build, suite=quiz-suite, replay=quiz-replay
|%
  ::  Public wire and durable state. No compiled vases are stored here.
  ::
+$  run-id  @ud
::
+$  source
  $%  [%draft text=@t]
      [%file path=path]
      [%suite path=path arms=(list term)]
  ==
::
+$  patch
  ::  Conf fields a request sets; ~ keeps the document's value. Merged in
  ::  %quiz after the build, so a client need not compile to override.
  $:  requested=(unit @ud)
      attempts-max=(unit @ud)
      drops-max=(unit @ud)
      duplicates-max=(unit @ud)
      size-start=(unit @ud)
      size-max=(unit @ud)
      duplicates=(unit policy:engine)
      bounds=(unit limits:engine)
      on-timeout=(unit timeout-policy:engine)
  ==
::
+$  mode
  ::  Run the property, or preview `count` samples without a run's
  ::  budgets: with `verdicts` the fate judges each one, with `alts` the
  ::  first one's shrink candidates are shown.
  $%  [%run ~]
      [%preview count=@ud verdicts=? alts=?]
  ==
::
+$  request
  $:  source=source
      desk=@tas
      revision=case
      config=(unit patch)
      seed=(unit @uv)
      replay-of=(unit run-id)
      =mode
  ==
::
+$  timeouts
  ::  Ship-wide %jinx CPU limits: one property call, one draft build, one
  ::  suite arm. Operational settings, never part of a replayable conf.
  [call=@dr build=@dr arm=@dr]
::
+$  action
  $%  [%run request]
      [%cancel id=run-id]
      [%delete id=run-id]
      [%clear ~]
      [%timeouts timeouts]
  ==
::
+$  status  ?(%queued %building %running %shrinking %cancelling %done)
::
+$  sample  [value=* text=@t]
::
+$  evidence
  ::  `trace` is the engine's shrink trace, newest step first.
  $:  why=failure:engine
      original=sample
      shrunk=sample
      trace=(list trace-row:engine)
  ==
::
+$  examples  (list [label=@t =sample])
::
+$  outcome
  $%  [%passed warnings=(list shortfall:engine) =examples]
      [%uncovered shortfalls=(list shortfall:engine) =examples]
      [%passed-unexpectedly ~]
      [%failed evidence]
      [%failed-as-expected evidence]
      [%error stage=error-stage:engine why=failure:engine proof=(unit evidence)]
      [%limited which=limit-name:engine proof=(unit evidence)]
      [%exhausted budget=?(%attempts %drops %duplicates) all-dropped=?]
      [%invalid diagnostic:build]
      [%cancelled reason=?(%request %reload)]
      $:  %interrupted
          during=?(%building %running %shrinking)
          proof=(unit evidence)
          arm=(unit term)
      ==
      [%suite outcome:suite]
      $:  %preview
          rows=(list preview-row:engine)
          candidates=(list candidate-row:engine)
      ==
  ==
::
+$  snapshot
  [where=context:build path=path source=@t source-hash=@uv]
::
+$  progress
  $%  [%property counters:engine =distribution:engine size=@ud]
      [%suite counters:suite sample-metrics=%unavailable]
  ==
::
+$  record
  $:  id=run-id
      request=request
      snapshot=(unit snapshot)
      replay=(unit record:replay)
      seed=(unit @uv)
      config=(unit conf:engine)
      engine-version=@tas
      status=status
      counts=progress
      result=(unit outcome)
      created=@da
      updated=@da
      finished=(unit @da)
      ::  The call limit a property's last slice ran under.
      call=(unit @dr)
  ==
::
+$  summary
  ::  One history row, enough to label a run without its whole record.
  ::  `outcome` is the result's kind, or a suite's passed/failed status.
  $:  id=run-id
      kind=?(%draft %file %suite %preview)
      =status
      outcome=(unit @tas)
  ==
::
+$  update
  $%  [%run record]
      [%runs ids=(list run-id)]
      [%deleted id=run-id]
      [%timeouts timeouts]
  ==
::
+$  state-0
  $:  next-id=@ud
      next-token=@ud
      records=(map run-id record)
      order=(list run-id)
      queue=(list run-id)
      =timeouts
  ==
::
+$  versioned-state  [%0 state-0]
--
