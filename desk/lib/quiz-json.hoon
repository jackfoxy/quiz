/-  app=quiz-app
/+  engine=quiz-engine, build=quiz-build, suite=quiz-suite, job=quiz-job
|%
  ::  HTTP codec. Decode under mule; never expose a parser crash to Eyre.
  ::  IDs are decimal strings; seeds and dates use Hoon aura strings.
  ::  Timeouts are whole seconds.
  ::
+$  command
  $%  [%run request:app]
      [%document-conf request:app]
      [%status id=@ud]
      [%cancel id=@ud]
      [%replay id=@ud]
      [%runs ~]
      [%contexts ~]
      [%suite-arms desk=@tas revision=case path=path]
      [%properties desk=@tas revision=@ud]
      [%timeouts ~]
      [%set-timeouts timeouts:app]
  ==
::
++  max-body  524.288
::
++  object
  ::  A JSON object's fields; anything else crashes.
  |=  value=json
  ^-  (map @t json)
  ?>  ?=([%o *] value)
  p.value
::
++  field
  ::  A required field; a missing one crashes.
  |=  [fields=(map @t json) key=@t]
  ^-  json
  (~(got by fields) key)
::
++  text
  ::  A JSON string; anything else crashes.
  |=  value=json
  ^-  @t
  ?>  ?=([%s *] value)
  p.value
::
++  natural
  ::  Only unsigned integer tokens; exponents/fractions are refused.
  |=  value=json
  ^-  @ud
  =/  raw=@t
    ?+  -.value  !!
      %s  p.value
      %n  p.value
    ==
  (need (rush raw dem))
::
++  name
  ::  A desk or arm name that passes safe-name.
  |=  value=json
  ^-  @tas
  =/  got  (text value)
  ?>  (safe-name:build got)
  `@tas`got
::
++  path-in
  ::  An array of segment strings that passes safe-path.
  |=  value=json
  ^-  path
  ?>  ?=([%a *] value)
  =/  got  (turn p.value text)
  ?>  (safe-path:build got)
  got
::
++  case-in
  ::  `{kind, value}`: kind ud (number), da (date text) or tas (name).
  |=  value=json
  ^-  case
  =/  fields  (object value)
  =/  kind  (text (field fields 'kind'))
  =/  val  (field fields 'value')
  ?+  kind  !!
    %ud   [%ud (natural val)]
    %da   [%da (slav %da (text val))]
    %tas  [%tas (name val)]
  ==
::
++  decode
  ::  A command, or ~ for any malformed body.
  |=  value=json
  ^-  (unit command)
  =/  got  (mule |.((command-in value)))
  ?:(?=(%.y -.got) `p.got ~)
::
++  command-in
  ::  Dispatch on `op`. Crashes on a malformed body; decode catches it.
  |=  value=json
  ^-  command
  =/  fields  (object value)
  =/  op  (text (field fields 'op'))
  ?+  op  !!
    %runs      [%runs ~]
    %contexts  [%contexts ~]
    %status    [%status (natural (field fields 'id'))]
    %cancel    [%cancel (natural (field fields 'id'))]
    %replay    [%replay (natural (field fields 'id'))]
    %timeouts  [%timeouts ~]
    %set-timeouts
      =/  seconds
        |=  key=@t
        ^-  @dr
        (mul ~s1 (natural (field fields key)))
      =/  value=timeouts:app
        [(seconds 'call-time') (seconds 'build-time') (seconds 'arm-time')]
      ?>  (valid-timeouts:job value)
      [%set-timeouts value]
    %suite-arms
      :*  %suite-arms
          (name (field fields 'desk'))
          (case-in (field fields 'revision'))
          (path-in (field fields 'path'))
      ==
    %properties
      :*  %properties
          (name (field fields 'desk'))
          (natural (field fields 'revision'))
      ==
    ?(%run %document-conf)
      =/  src  (object (field fields 'source'))
      =/  kind  (text (field src 'kind'))
      =/  source=source:app
        ?+  kind  !!
          %draft  [%draft (text (field src 'text'))]
          %file   [%file (path-in (field src 'path'))]
          %suite
            =/  arms  (field src 'arms')
            ?>  ?=([%a *] arms)
            [%suite (path-in (field src 'path')) (turn p.arms name)]
        ==
      =/  cfg=(unit patch:app)
        =/  val  (~(get by fields) 'config')
        ?~  val  ~
        ?:  ?=(%~ u.val)  ~
        `(patch-in u.val)
      =/  seed=(unit @uv)
        =/  val  (~(get by fields) 'seed')
        ?~  val  ~
        ?:  ?=(%~ u.val)  ~
        `(slav %uv (text u.val))
      =/  req=request:app
        :*  source  (name (field fields 'desk'))
            (case-in (field fields 'revision'))  cfg  seed  ~
        ==
      ?:  =(op %run)  [%run req]
      [%document-conf req]
  ==
::
++  decimal
  ::  A number as a decimal string, exact past JavaScript's 2^53.
  |=  value=@ud
  ^-  json
  =/  got  (numb:enjs:format value)
  ?>  ?=([%n *] got)
  s+p.got
::
++  path-out
  ::  A path as an array of segment strings.
  |=  value=path
  ^-  json
  a+(turn value (lead %s))
::
++  context-out
  ::  The pinned ship, desk and numeric revision.
  |=  value=context:build
  ^-  json
  %-  pairs:enjs:format
  :~  ['ship' s+(scot %p our.value)]
      ['desk' s+desk.value]
      ['revision' (decimal revision.value)]
  ==
::
++  diagnostic-out
  ::  Code, location, optional arm, trace lines and whether it was clipped.
  |=  value=diagnostic:build
  ^-  json
  %-  pairs:enjs:format
  :~  ['code' s+code.value]
      ['path' (path-out path.value)]
      ['line' (numb:enjs:format p.at.value)]
      ['column' (numb:enjs:format q.at.value)]
      ['arm' ?~(arm.value ~ s+u.arm.value)]
      ['trace' (trace-out trace.value)]
      ['clipped' b+clipped.value]
  ==
::
++  trace-out
  ::  A tang as an array of lines wrapped at 80 columns.
  |=  value=tang
  ^-  json
  =/  blocks=(list wall)  (turn value (cury wash [0 80]))
  =/  lines=wall  (zing blocks)
  a+(turn lines (cork crip (lead %s)))
::
++  failure-out
  ::  The failure kind and its detail; scry requests and bad products
  ::  are jammed @uv text.
  |=  value=failure:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['kind' s+-.value]
      :-  'detail'
      ?-  -.value
        %false        (detail-out detail.value)
        %crash        (trace-out trace.value)
        %scry         s+(scot %uv (jam request.value))
        %bad-product  s+(scot %uv (jam product.value))
        %timeout      ~
      ==
  ==
::
++  detail-out
  ::  A report's notes and optional want/got texts.
  |=  value=detail:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['notes' a+(turn notes.value (lead %s))]
      :-  'compared'
      ?~  compared.value  ~
      %-  pairs:enjs:format
      ~[['want' s+want.u.compared.value] ['got' s+got.u.compared.value]]
  ==
::
++  shortfalls-out
  ::  Coverage rows: label, required percent, observed percent (floored).
  |=  rows=(list shortfall:engine)
  ^-  json
  :-  %a
  %+  turn  rows
  |=  row=shortfall:engine
  %-  pairs:enjs:format
  :~  ['label' s+label.row]
      ['want' (numb:enjs:format want.row)]
      ['got' (numb:enjs:format got.row)]
  ==
::
++  examples-out
  ::  One example sample per label.
  |=  rows=examples:app
  ^-  json
  :-  %a
  %+  turn  rows
  |=  [label=@t =sample:app]
  (pairs:enjs:format ~[['label' s+label] ['sample' (sample-out sample)]])
::
++  distribution-out
  ::  Label and table-row counts over accepted samples.
  |=  value=distribution:engine
  ^-  json
  =/  counts
    |=  m=(map @t @ud)
    ^-  json
    %-  pairs:enjs:format
    (turn ~(tap by m) |=([k=@t v=@ud] [k (numb:enjs:format v)]))
  %-  pairs:enjs:format
  :~  ['labels' (counts labels.value)]
      :-  'tables'
      %-  pairs:enjs:format
      (turn ~(tap by tables.value) |=([k=@t m=(map @t @ud)] [k (counts m)]))
  ==
::
++  sample-out
  ::  Rendered text and the jammed noun as @uv text.
  |=  value=sample:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['text' s+text.value]
      ['noun-jam' s+(scot %uv (jam value.value))]
  ==
::
++  evidence-out
  ::  The failure, the original sample and the shrunk sample.
  |=  value=evidence:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['why' (failure-out why.value)]
      ['original' (sample-out original.value)]
      ['shrunk' (sample-out shrunk.value)]
  ==
::
++  summary-out
  ::  A history row: decimal id, source kind, status, nullable outcome.
  |=  value=summary:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' (decimal id.value)]
      ['kind' s+kind.value]
      ['status' s+status.value]
      ['outcome' ?~(outcome.value ~ s+u.outcome.value)]
  ==
::
++  outcome-out
  ::  `kind` plus that outcome's fields; absent evidence is null.
  |=  value=outcome:app
  ^-  json
  %-  pairs:enjs:format
  :-  ['kind' s+-.value]
  ?-  -.value
    %passed
      :~  ['warnings' (shortfalls-out warnings.value)]
          ['examples' (examples-out examples.value)]
      ==
    %uncovered
      :~  ['shortfalls' (shortfalls-out shortfalls.value)]
          ['examples' (examples-out examples.value)]
      ==
    %passed-unexpectedly  ~
    %failed  ~[['evidence' (evidence-out +.value)]]
    %failed-as-expected  ~[['evidence' (evidence-out +.value)]]
    %cancelled  ~[['reason' s+reason.value]]
    %interrupted
      :~  ['during' s+during.value]
          ['evidence' ?~(proof.value ~ (evidence-out u.proof.value))]
          ['arm' ?~(arm.value ~ s+u.arm.value)]
      ==
    %invalid  ~[['diagnostic' (diagnostic-out +.value)]]
    %exhausted
      ~[['budget' s+budget.value] ['all-dropped' b+all-dropped.value]]
    %limited
      :~  ['which' s+which.value]
          ['evidence' ?~(proof.value ~ (evidence-out u.proof.value))]
      ==
    %error
      :~  ['stage' s+stage.value]
          ['why' (failure-out why.value)]
          ['evidence' ?~(proof.value ~ (evidence-out u.proof.value))]
      ==
    %suite
      :~  ['status' s+status.value]
          ['sample-metrics' s+'unavailable']
          ['counts' (suite-counts counts.value)]
          :-  'arms'
          :-  %a
          %+  turn  arms.value
          |=  arm=arm-result:suite
          %-  pairs:enjs:format
          :~  ['name' s+name.arm]
              ['status' s+status.arm]
              ['trace' (trace-out trace.arm)]
              ['clipped' b+clipped.arm]
          ==
      ==
  ==
::
++  request-out
  ::  A request as submitted: desk, revision, seed, conf, replay origin
  ::  and source.
  |=  value=request:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['desk' s+desk.value]
      :-  'revision'
      %-  pairs:enjs:format
      :~  ['kind' s+-.revision.value]
          :-  'value'
          ?-  -.revision.value
            %ud   (decimal p.revision.value)
            %da   s+(scot %da p.revision.value)
            %tas  s+p.revision.value
            %uv   s+(scot %uv p.revision.value)
          ==
      ==
      ['seed' ?~(seed.value ~ s+(scot %uv u.seed.value))]
      ['config' ?~(config.value ~ (patch-out u.config.value))]
      ['replay-of' ?~(replay-of.value ~ (decimal u.replay-of.value))]
      :-  'source'
      %-  pairs:enjs:format
      :-  ['kind' s+-.source.value]
      ?-  -.source.value
        %draft  ~[['text' s+text.source.value]]
        %file   ~[['path' (path-out path.source.value)]]
        %suite
          :~  ['path' (path-out path.source.value)]
              ['arms' a+(turn arms.source.value (lead %s))]
          ==
      ==
  ==
::
++  record-out
  ::  A run record with counters, distribution, outcome and the pinned
  ::  source snapshot. Suites report sample metrics as unavailable.
  |=  value=record:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' (decimal id.value)]
      ['kind' s+-.source.request.value]
      ['request' (request-out request.value)]
      ['status' s+status.value]
      ['engine-version' s+engine-version.value]
      ['created' s+(scot %da created.value)]
      ['updated' s+(scot %da updated.value)]
      ['finished' ?~(finished.value ~ s+(scot %da u.finished.value))]
      ['seed' ?~(seed.value ~ s+(scot %uv u.seed.value))]
      ['config' ?~(config.value ~ (config-out u.config.value))]
      :-  'replay-of'
      ?~  replay-of.request.value  ~
      (decimal u.replay-of.request.value)
      :-  'counts'
      ?-  -.counts.value
        %property  (property-counts +<.counts.value size.counts.value)
        %suite     (suite-counts +<.counts.value)
      ==
      :-  'distribution'
      ?.  ?=(%property -.counts.value)  ~
      (distribution-out distribution.counts.value)
      :-  'sample-metrics'
      s+?:(?=(%suite -.counts.value) 'unavailable' 'available')
      ['outcome' ?~(result.value ~ (outcome-out u.result.value))]
      :-  'snapshot'
      ?~  snapshot.value  ~
      =/  snap  u.snapshot.value
      %-  pairs:enjs:format
      :~  ['context' (context-out where.snap)]
          ['path' (path-out path.snap)]
          ['source' s+source.snap]
          ['source-hash' s+(scot %uv source-hash.snap)]
      ==
  ==
::
++  patch-in
  ::  Conf fields to override. An absent or null field keeps the document's;
  ::  `bounds`, when given, is complete. The merged conf is checked later.
  |=  value=json
  ^-  patch:app
  =/  fields  (object value)
  =/  get
    |=  key=@t
    ^-  (unit json)
    =/  val  (~(get by fields) key)
    ?:(|(=(~ val) =(`~ val)) ~ val)
  :*  (bind (get 'requested') natural)
      (bind (get 'attempts-max') natural)
      (bind (get 'drops-max') natural)
      (bind (get 'duplicates-max') natural)
      (bind (get 'size-start') natural)
      (bind (get 'size-max') natural)
      (bind (get 'duplicates') policy-in)
      (bind (get 'bounds') bounds-in)
      (bind (get 'on-timeout') timeout-in)
  ==
::
++  bounds-in
  ::  Every limit of a conf's bounds, each required.
  |=  value=json
  ^-  limits:engine
  =/  fields  (object value)
  :*  (natural (field fields 'source-bytes'))
      (natural (field fields 'requested-max'))
      (natural (field fields 'shrink-candidates'))
      (natural (field fields 'shrink-depth'))
      (natural (field fields 'sample-bytes'))
      (natural (field fields 'rendered-bytes'))
      (natural (field fields 'diagnostics-bytes'))
      (natural (field fields 'alts-bytes'))
      (natural (field fields 'seen-bytes'))
      (natural (field fields 'retained-runs'))
      (natural (field fields 'samples-per-slice'))
  ==
::
++  timeout-in
  ::  interrupt, fail or discard.
  |=  value=json
  ^-  timeout-policy:engine
  =/  tag  (text value)
  ?+  tag  ~|(%bad-on-timeout !!)
    %interrupt  %interrupt
    %fail       %fail
    %discard    %discard
  ==
::
++  policy-in
  ::  The duplicate policy: mug, exact or allow.
  |=  value=json
  ^-  policy:engine
  =/  tag  (text value)
  ?+  tag  ~|(%bad-duplicates !!)
    %mug    %mug
    %exact  %exact
    %allow  %allow
  ==
::
++  config-out
  ::  A complete conf, with every bound.
  |=  value=conf:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['requested' (numb:enjs:format requested.value)]
      ['attempts-max' (numb:enjs:format attempts-max.value)]
      ['drops-max' (numb:enjs:format drops-max.value)]
      ['duplicates-max' (numb:enjs:format duplicates-max.value)]
      ['size-start' (numb:enjs:format size-start.value)]
      ['size-max' (numb:enjs:format size-max.value)]
      ['duplicates' s+duplicates.value]
      ['on-timeout' s+on-timeout.value]
      ['bounds' (bounds-out bounds.value)]
  ==
::
++  patch-out
  ::  A request's patch, field for field as patch-in reads it; null keeps.
  |=  value=patch:app
  ^-  json
  =/  num  |=(n=(unit @ud) ^-(json ?~(n ~ (numb:enjs:format u.n))))
  %-  pairs:enjs:format
  :~  ['requested' (num requested.value)]
      ['attempts-max' (num attempts-max.value)]
      ['drops-max' (num drops-max.value)]
      ['duplicates-max' (num duplicates-max.value)]
      ['size-start' (num size-start.value)]
      ['size-max' (num size-max.value)]
      ['duplicates' ?~(duplicates.value ~ s+u.duplicates.value)]
      ['on-timeout' ?~(on-timeout.value ~ s+u.on-timeout.value)]
      ['bounds' ?~(bounds.value ~ (bounds-out u.bounds.value))]
  ==
::
++  bounds-out
  ::  Every limit in a conf's bounds.
  |=  value=limits:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['source-bytes' (numb:enjs:format source-bytes.value)]
      ['requested-max' (numb:enjs:format requested-max.value)]
      ['shrink-candidates' (numb:enjs:format shrink-candidates.value)]
      ['shrink-depth' (numb:enjs:format shrink-depth.value)]
      ['sample-bytes' (numb:enjs:format sample-bytes.value)]
      ['rendered-bytes' (numb:enjs:format rendered-bytes.value)]
      ['diagnostics-bytes' (numb:enjs:format diagnostics-bytes.value)]
      ['alts-bytes' (numb:enjs:format alts-bytes.value)]
      ['seen-bytes' (numb:enjs:format seen-bytes.value)]
      ['retained-runs' (numb:enjs:format retained-runs.value)]
      ['samples-per-slice' (numb:enjs:format samples-per-slice.value)]
  ==
::
++  timeouts-out
  ::  The three ship-wide CPU limits, in whole seconds.
  |=  value=timeouts:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['call-time' (numb:enjs:format (div call.value ~s1))]
      ['build-time' (numb:enjs:format (div build.value ~s1))]
      ['arm-time' (numb:enjs:format (div arm.value ~s1))]
  ==
::
++  property-counts
  ::  `size` is the size the next generated sample will use.
  |=  [value=counters:engine size=@ud]
  ^-  json
  %-  pairs:enjs:format
  :~  ['size' (numb:enjs:format size)]
      ['attempted' (numb:enjs:format attempted.value)]
      ['accepted' (numb:enjs:format accepted.value)]
      ['dropped' (numb:enjs:format dropped.value)]
      ['duplicate' (numb:enjs:format duplicate.value)]
      ['shrink-tried' (numb:enjs:format shrink-tried.value)]
      ['shrink-steps' (numb:enjs:format shrink-steps.value)]
  ==
::
++  suite-counts
  ::  Arm totals by status.
  |=  value=counters:suite
  ^-  json
  %-  pairs:enjs:format
  :~  ['total' (numb:enjs:format total.value)]
      ['completed' (numb:enjs:format completed.value)]
      ['passed' (numb:enjs:format passed.value)]
      ['failed' (numb:enjs:format failed.value)]
      ['crashed' (numb:enjs:format crashed.value)]
      ['invalid' (numb:enjs:format invalid.value)]
  ==
--
