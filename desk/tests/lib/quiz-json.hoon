/-  app=quiz-app
/+  *test, codec=quiz-json, engine=quiz-engine, job=quiz-job
|%
::
++  request
  ^-  request:app
  [[%draft '|%  ++  fate  |=(@ud &)  --'] %quiz [%ud 1] ~ `0v0 ~ [%run ~]]
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
++  test-preview-mode
  ::  The mode round-trips; an absent mode is a run.
  ^-  tang
  =/  base=request:app  request
  =/  preview=request:app  base(mode [%preview 20 & |])
  =/  req  (request-out:codec preview)
  ?>  ?=([%o *] req)
  =/  with  [%o (~(put by p.req) 'op' s+'run')]
  =/  without  [%o (~(del by (~(put by p.req) 'op' s+'run')) 'mode')]
  =/  as-preview=(unit command:codec)  `[%run preview]
  =/  as-run=(unit command:codec)  `[%run request]
  =/  search=request:app  base(mode [%examples 50])
  =/  found  (request-out:codec search)
  ?>  ?=([%o *] found)
  =/  as-search=(unit command:codec)  `[%run search]
  ;:  weld
    (expect-eq !>(as-preview) !>((decode:codec with)))
    (expect-eq !>(as-run) !>((decode:codec without)))
    %+  expect-eq  !>(as-search)
    !>((decode:codec [%o (~(put by p.found) 'op' s+'run')]))
  ==
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
  =/  changes=patch:app  *patch:app
  =.  changes  changes(requested `5, duplicates `%exact)
  =.  req  req(config `changes, seed `0v123)
  =/  jon  (request-out:codec req)
  ?>  ?=([%o *] jon)
  =/  got  (decode:codec [%o (~(put by p.jon) 'op' s+'run')])
  (expect !>(=(got `[%run req])))
::
++  test-patch-shape-refused
  ::  Ranges are checked on the merged conf; only shapes are refused here.
  ^-  tang
  =/  jon  command
  ?>  ?=([%o *] jon)
  =/  bad  (pairs:enjs:format ~[['requested' s+'many']])
  =/  fine  (pairs:enjs:format ~[['requested' n+'0']])
  ;:  weld
    (expect-eq !>(~) !>((decode:codec [%o (~(put by p.jon) 'config' bad)])))
    (expect !>(?=(^ (decode:codec [%o (~(put by p.jon) 'config' fine)]))))
  ==
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
        ['{"op":"delete","id":"123"}' [%delete 123]]
        ['{"op":"clear"}' [%clear ~]]
        :-  '{"op":"properties","desk":"quiz","revision":"1000"}'
        [%properties %quiz 1.000]
    ==
  %-  zing
  %+  turn  commands
  |=  [body=@t wanted=command:codec]
  ^-  tang
  =/  got  (decode:codec (need (de:json:html body)))
  (expect !>(=(got `wanted)))
::
++  test-cover-row-encodes
  ::  Bounds are percentages with two decimals; a threshold names why.
  ^-  tang
  =/  row=cover-row:engine
    :*  %confident  'heads'  ~  377  800  47  40  &
        `[.~0.4253 .~0.05]  `[%threshold %requested-max]
    ==
  =/  fields  (object:codec (cover-row-out:codec row))
  ;:  weld
    (expect-eq !>(`json`n+'42.53') !>((~(got by fields) 'low')))
    (expect-eq !>(`json`n+'5.00') !>((~(got by fields) 'high')))
    =/  want=json
      (pairs:enjs:format ~[['kind' s+'threshold'] ['why' s+'requested-max']])
    (expect-eq !>(want) !>((~(got by fields) 'decision')))
  ==
::
++  test-outcomes-encode
  ^-  tang
  =/  steps=(list trace-row:engine)
    :~  [%candidate `1 %accepted `'1']
        [%candidate ~ %visited ~]
        [%alts (bex 70) 2]
    ==
  =/  proof=evidence:app  [[%false ~ ~] [42 '42'] [1 '1'] steps]
  =/  detailed=evidence:app
    [[%false ~['too big' 'second'] `['1' '2']] [42 '42'] [1 '1'] ~]
  =/  short=(list shortfall:engine)  ~[['empty' 20 5 ~] ['3' 10 0 `'length']]
  =/  examples=examples:app  ~[['small' [1 '1']] ['big' [99 '99']]]
  =/  rows=(list cover-row:engine)
    :~  [%check 'empty' ~ 5 100 5 20 | ~ ~]
        :*  %confident  'heads'  ~  377  800  47  40  &
            `[.~0.4253 .~0.5174]  `[%established ~]
        ==
        [%confident 'tails' `'side' 0 0 0 10 | ~ `[%threshold %attempts]]
    ==
  =/  outcomes=(list outcome:app)
    :~  [%passed ~ ~ ~]
        [%passed short examples rows]
        [%uncovered short examples rows]
        [%passed-unexpectedly ~]
        [%failed proof]
        [%failed detailed]
        [%failed-as-expected detailed]
        [%limited %labels ~]
        [%error %alts [%crash ~[[%leaf "broken"]]] `proof]
        [%limited %shrink-depth `proof]
        [%exhausted %drops &]
        [%cancelled %reload]
        [%interrupted %shrinking `proof ~]
        [%interrupted %running ~ `%test-loop]
        :^  %preview
          ~[[1 1 '1' | `%pass ~['odd']] [2 1 '1' & ~ ~]]
          ~[[0 '0' `1 &] [5 '5' ~ |]]
        [2 1 ~[1 2] ~[3 3] (malt ~[[%pass 1]]) (malt ~[['odd' 1]])]
        :*  %examples
            :~  ['even' [0 '0'] 1 3 7 %done]
                ['big' [100 '100'] 101 9 40 %limited]
            ==
            ~['huge']
            `%attempts
            `proof
        ==
        [%examples ~ ~ ~ ~]
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
::
++  test-timeouts-commands
  ::  Whole seconds on the wire, from one second to one hour.
  ^-  tang
  =/  set
    '{"op":"set-timeouts","call-time":"5","build-time":30,"arm-time":"60"}'
  =/  got  (decode:codec (need (de:json:html set)))
  =/  zero  '{"op":"set-timeouts","call-time":0,"build-time":30,"arm-time":60}'
  =/  long
    '{"op":"set-timeouts","call-time":3601,"build-time":30,"arm-time":60}'
  =/  out  (timeouts-out:codec [~s5 ~s30 ~m1])
  =/  query  (decode:codec (need (de:json:html '{"op":"timeouts"}')))
  ;:  weld
    (expect !>(=(got `[%set-timeouts ~s5 ~s30 ~m1])))
    (expect-eq !>(~) !>((decode:codec (need (de:json:html zero)))))
    (expect-eq !>(~) !>((decode:codec (need (de:json:html long)))))
    (expect !>(=(`[%timeouts ~] query)))
    (expect-eq !>(n+'5') !>((field:codec (object:codec out) 'call-time')))
    (expect-eq !>(n+'60') !>((field:codec (object:codec out) 'arm-time')))
  ==
::
++  test-distribution-encodes
  ^-  tang
  =/  added  (admit:job initial:job request ~2026.10.15 0v0)
  ?>  ?=(%.y -.added)
  =/  rec  (~(got by records.saved.p.added) 1)
  =/  labels  (malt `(list [@t @ud])`~[['even' 3]])
  =/  rows  (malt `(list [@t (map @t @ud)])`~[['size' labels]])
  =.  counts.rec  [%property *counters:engine [labels rows] 0]
  =/  fields  (object:codec (record-out:codec rec))
  =/  want=json
    %-  pairs:enjs:format
    :~  ['labels' (pairs:enjs:format ~[['even' n+'3']])]
        :-  'tables'
        (pairs:enjs:format ~[['size' (pairs:enjs:format ~[['even' n+'3']])]])
    ==
  (expect-eq !>(want) !>((field:codec fields 'distribution')))
--
