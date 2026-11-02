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
+$  request
  $:  source=source
      desk=@tas
      revision=case
      config=(unit conf:engine)
      seed=(unit @uv)
      replay-of=(unit run-id)
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
+$  evidence  [why=failure:engine original=sample shrunk=sample]
::
+$  outcome
  $%  [%passed ~]
      [%failed evidence]
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
  ==
::
+$  snapshot
  [where=context:build path=path source=@t source-hash=@uv]
::
+$  progress
  $%  [%property counters:engine]
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
