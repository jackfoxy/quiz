/-  app=quiz-app
/+  *test, codec=quiz-json, engine=quiz-engine, job=quiz-job
|%
::
++  request
  ^-  request:app
  [[%draft '|%  ++  fate  |=(@ud &)  --'] %quiz [%ud 1] ~ `0v0 ~]
::
++  command
  ^-  json
  =/  req  (request-out:codec request)
  ?>  ?=([%o *] req)
  [%o (~(put by p.req) 'op' s+'run')]
::
++  test-run-decoder
  ^-  tang
  =/  got  (decode:codec command)
  =/  wanted=(unit command:codec)  `[%run request]
  (expect-eq !>(wanted) !>(got))
::
++  test-source-kinds
  ^-  tang
  =/  sources=(list source:app)
    :~  [%file /examples/props/pass/hoon]
        [%suite ~[%tests %examples '02-boxcar' %hoon] ~[%test-one]]
    ==
  %-  zing
  %+  turn  sources
  |=  source=source:app
  ^-  tang
  =/  req=request:app  request
  =.  req  req(source source)
  =/  jon  (request-out:codec req)
  ?>  ?=([%o *] jon)
  =/  got  (decode:codec [%o (~(put by p.jon) 'op' s+'run')])
  (expect !>(=(got `[%run req])))
::
++  test-case-kinds
  ^-  tang
  =/  cases=(list case)  ~[[%ud 42] [%tas %label] [%da ~2026.10.15]]
  %-  zing
  %+  turn  cases
  |=  rev=case
  ^-  tang
  =/  req=request:app  request
  =.  req  req(revision rev)
  =/  jon  (request-out:codec req)
  ?>  ?=([%o *] jon)
  =/  got  (decode:codec [%o (~(put by p.jon) 'op' s+'run')])
  (expect !>(=(got `[%run req])))
::
++  test-config-seed-round-trip
  ^-  tang
  =/  req=request:app  request
  =.  req  req(config `defaults:engine, seed `0v123)
  =/  jon  (request-out:codec req)
  ?>  ?=([%o *] jon)
  =/  got  (decode:codec [%o (~(put by p.jon) 'op' s+'run')])
  (expect !>(=(got `[%run req])))
::
++  test-config-range-refused
  ^-  tang
  =/  cfg  defaults:engine
  =.  cfg  cfg(samples-per-slice.bounds 0)
  =/  jon  command
  ?>  ?=([%o *] jon)
  =/  got
    (decode:codec [%o (~(put by p.jon) 'config' (config-out:codec cfg))])
  (expect-eq !>(~) !>(got))
::
++  test-invalid-fields
  ^-  tang
  =/  values=(list [key=@t value=json])
    :~  ['desk' s+'../base']
        ['desk' n+'1']
        ['revision' s+'now']
        ['seed' s+'not-a-seed']
        ['seed' n+'0']
        ['config' b+&]
        ['source' ~]
    ==
  =/  jon  command
  ?>  ?=([%o *] jon)
  %-  zing
  %+  turn  values
  |=  [key=@t value=json]
  ^-  tang
  =/  got  (decode:codec [%o (~(put by p.jon) key value)])
  (expect-eq !>(~) !>(got))
::
++  test-invalid-paths
  ^-  tang
  =/  paths=(list path)
    :~  ~  ~['..' 'hoon']  ~['a/b' 'hoon']  ~['' 'hoon']
        ~['CAPS' 'hoon']
    ==
  %-  zing
  %+  turn  paths
  |=  path=path
  ^-  tang
  %-  expect-fail
  |.  (path-in:codec (path-out:codec path))
::
++  test-query-commands
  ^-  tang
  =/  commands=(list [body=@t wanted=command:codec])
    :~  ['{"op":"runs"}' [%runs ~]]
        ['{"op":"contexts"}' [%contexts ~]]
        ['{"op":"status","id":"123"}' [%status 123]]
        ['{"op":"cancel","id":123}' [%cancel 123]]
        ['{"op":"replay","id":"123"}' [%replay 123]]
    ==
  %-  zing
  %+  turn  commands
  |=  [body=@t wanted=command:codec]
  ^-  tang
  =/  got  (decode:codec (need (de:json:html body)))
  (expect !>(=(got `wanted)))
::
++  test-outcomes-encode
  ^-  tang
  =/  proof=evidence:app  [[%false ~] [42 '42'] [1 '1']]
  =/  outcomes=(list outcome:app)
    :~  [%passed ~]
        [%failed proof]
        [%error %alts [%crash ~[[%leaf "broken"]]] `proof]
        [%limited %shrink-depth `proof]
        [%exhausted %drops &]
        [%cancelled %reload]
    ==
  %-  zing
  %+  turn  outcomes
  |=  value=outcome:app
  ^-  tang
  =/  jon  (outcome-out:codec value)
  =/  got  (need (de:json:html (en:json:html jon)))
  (expect-eq !>(jon) !>(got))
::
++  test-queued-record-encodes
  ^-  tang
  =/  added  (admit:job initial:job request ~2026.10.15 0v0)
  ?>  ?=(%.y -.added)
  =/  rec  (~(got by records.saved.p.added) 1)
  =/  jon  (record-out:codec rec)
  =/  fields  (object:codec jon)
  ;:  weld
    (expect-eq !>(s+'queued') !>((field:codec fields 'status')))
    (expect-eq !>(~) !>((field:codec fields 'snapshot')))
    (expect-eq !>(~) !>((field:codec fields 'outcome')))
    %+  expect-eq  !>((request-out:codec request))
    !>((field:codec fields 'request'))
  ==
--
