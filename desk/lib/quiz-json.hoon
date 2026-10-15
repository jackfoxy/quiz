/-  app=quiz-app
/+  engine=quiz-engine, build=quiz-build, suite=quiz-suite
|%
  ::  HTTP codec. Decode under mule; never expose a parser crash to Eyre.
  ::  IDs are decimal strings; seeds and dates use Hoon aura strings.
  ::
+$  command
  $%  [%run request:app]
      [%status id=@ud]
      [%cancel id=@ud]
      [%replay id=@ud]
      [%runs ~]
      [%contexts ~]
      [%suite-arms desk=@tas revision=case path=path]
  ==
::
++  max-body  524.288
::
++  object
  |=  value=json
  ^-  (map @t json)
  ?>  ?=([%o *] value)
  p.value
::
++  field
  |=  [fields=(map @t json) key=@t]
  ^-  json
  (~(got by fields) key)
::
++  text
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
  |=  value=json
  ^-  @tas
  =/  got  (text value)
  ?>  (safe-name:build got)
  `@tas`got
::
++  path-in
  |=  value=json
  ^-  path
  ?>  ?=([%a *] value)
  =/  got  (turn p.value text)
  ?>  (safe-path:build got)
  got
::
++  case-in
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
  |=  value=json
  ^-  (unit command)
  =/  got  (mule |.((command-in value)))
  ?:(?=(%.y -.got) `p.got ~)
::
++  command-in
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
    %suite-arms
      :*  %suite-arms
          (name (field fields 'desk'))
          (case-in (field fields 'revision'))
          (path-in (field fields 'path'))
      ==
    %run
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
      =/  cfg=(unit conf:engine)
        =/  val  (~(get by fields) 'config')
        ?~  val  ~
        ?:  ?=(%~ u.val)  ~
        `(config-in u.val)
      =/  seed=(unit @uv)
        =/  val  (~(get by fields) 'seed')
        ?~  val  ~
        ?:  ?=(%~ u.val)  ~
        `(slav %uv (text u.val))
      :*  %run  source
          (name (field fields 'desk'))
          (case-in (field fields 'revision'))
          cfg  seed  ~
      ==
  ==
::
++  decimal
  |=  value=@ud
  ^-  json
  =/  got  (numb:enjs:format value)
  ?>  ?=([%n *] got)
  s+p.got
::
++  path-out
  |=  value=path
  ^-  json
  a+(turn value |=(part=@ta s+part))
::
++  context-out
  |=  value=context:build
  ^-  json
  %-  pairs:enjs:format
  :~  ['ship' s+(scot %p our.value)]
      ['desk' s+desk.value]
      ['revision' (decimal revision.value)]
  ==
::
++  diagnostic-out
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
  |=  value=tang
  ^-  json
  =/  blocks=(list wall)
    (turn value |=(item=tank ^-(wall (wash [0 80] item))))
  =/  lines=wall  (zing blocks)
  a+(turn lines |=(line=tape s+(crip line)))
::
++  failure-out
  |=  value=failure:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['kind' s+-.value]
      :-  'detail'
      ?-  -.value
        %false        ~
        %crash        (trace-out trace.value)
        %scry         s+(scot %uv (jam request.value))
        %bad-product  s+(scot %uv (jam product.value))
      ==
  ==
::
++  sample-out
  |=  value=sample:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['text' s+text.value]
      ['noun-jam' s+(scot %uv (jam value.value))]
  ==
::
++  evidence-out
  |=  value=evidence:app
  ^-  json
  %-  pairs:enjs:format
  :~  ['why' (failure-out why.value)]
      ['original' (sample-out original.value)]
      ['shrunk' (sample-out shrunk.value)]
  ==
::
++  outcome-out
  |=  value=outcome:app
  ^-  json
  %-  pairs:enjs:format
  :-  ['kind' s+-.value]
  ?-  -.value
    %passed  ~
    %failed  ~[['evidence' (evidence-out +.value)]]
    %cancelled  ~[['reason' s+reason.value]]
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
      ['config' ?~(config.value ~ (config-out u.config.value))]
      ['replay-of' ?~(replay-of.value ~ (decimal u.replay-of.value))]
      :-  'source'
      %-  pairs:enjs:format
      :-  ['kind' s+-.source.value]
      ?-  -.source.value
        %draft  ~[['text' s+text.source.value]]
        %file   ~[['path' (path-out path.source.value)]]
        %suite
          :~  ['path' (path-out path.source.value)]
              ['arms' a+(turn arms.source.value |=(arm=term s+arm))]
          ==
      ==
  ==
::
++  record-out
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
        %property  (property-counts +.counts.value)
        %suite     (suite-counts +<.counts.value)
      ==
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
++  config-in
  |=  value=json
  ^-  conf:engine
  =/  fields  (object value)
  =/  bounds  (object (field fields 'bounds'))
  =/  cfg=conf:engine
    :*  (natural (field fields 'requested'))
        (natural (field fields 'attempts-max'))
        (natural (field fields 'drops-max'))
        (natural (field fields 'duplicates-max'))
        :*  (natural (field bounds 'source-bytes'))
            (natural (field bounds 'requested-max'))
            (natural (field bounds 'shrink-candidates'))
            (natural (field bounds 'shrink-depth'))
            (natural (field bounds 'sample-bytes'))
            (natural (field bounds 'rendered-bytes'))
            (natural (field bounds 'diagnostics-bytes'))
            (natural (field bounds 'alts-bytes'))
            (natural (field bounds 'retained-runs'))
            (natural (field bounds 'samples-per-slice'))
        ==
    ==
  ?>  (valid-config:build cfg)
  cfg
::
++  config-out
  |=  value=conf:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['requested' (numb:enjs:format requested.value)]
      ['attempts-max' (numb:enjs:format attempts-max.value)]
      ['drops-max' (numb:enjs:format drops-max.value)]
      ['duplicates-max' (numb:enjs:format duplicates-max.value)]
      ['bounds' (bounds-out bounds.value)]
  ==
::
++  bounds-out
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
      ['retained-runs' (numb:enjs:format retained-runs.value)]
      ['samples-per-slice' (numb:enjs:format samples-per-slice.value)]
  ==
::
++  property-counts
  |=  value=counters:engine
  ^-  json
  %-  pairs:enjs:format
  :~  ['attempted' (numb:enjs:format attempted.value)]
      ['accepted' (numb:enjs:format accepted.value)]
      ['dropped' (numb:enjs:format dropped.value)]
      ['duplicate' (numb:enjs:format duplicate.value)]
      ['shrink-tried' (numb:enjs:format shrink-tried.value)]
      ['shrink-steps' (numb:enjs:format shrink-steps.value)]
  ==
::
++  suite-counts
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
