/+  build=quiz-build, engine=quiz-engine
|%
  ::  Clay test cores, using -test's test-* discovery and tang contract.
  ::  One step runs one arm. Sample-level legacy metrics are unavailable.
  ::  Each arm's compile and run is bounded by the arm-time %jinx CPU limit.
  ::
+$  document
  [where=context:build path=path source=@t selected=(list term)]
::
+$  arm-result
  [name=term status=?(%passed %failed %crashed %invalid) trace=tang clipped=?]
::
+$  counters
  [total=@ud completed=@ud passed=@ud failed=@ud crashed=@ud invalid=@ud]
::
+$  outcome
  $:  status=?(%passed %failed)
      counts=counters
      arms=(list arm-result)
      sample-metrics=%unavailable
  ==
::
+$  state
  $:  doc=document
      core=vase
      available=(list term)
      remaining=(list term)
      finished=(list arm-result)
      counts=counters
      result=(unit outcome)
  ==
::
+$  result  $%([%ready state] [%invalid diagnostic:build])
::
++  arm-time
  ::  Fixed: suites have no conf. Legacy property arms can run many checks.
  ~m1
::
++  prepare
  ::  Suites use ordinary Ford, not the property document prelude parser.
  |=  [where=context:build path=path source=@t selected=(list term)]
  ^-  (each document diagnostic:build)
  =/  bad  (validate:build desk.where [%ud revision.where] path %hoon source)
  ?^  bad  [%.n u.bad]
  [%.y [where path source selected]]
::
++  prepare-file
  ::  Call with an available pinned context returned by build's pin gate.
  |=  [where=context:build path=path selected=(list term)]
  ^-  (each document diagnostic:build)
  =/  bad  (validate:build desk.where [%ud revision.where] path %hoon '')
  ?^  bad  [%.n u.bad]
  =/  root=(list @ta)
    /(scot %p our.where)/[desk.where]/(scot %ud revision.where)
  ?.  .^(? %cu (weld root path))
    [%.n (issue:build %source path [1 1] ~ ~)]
  (prepare where path .^(@t %cx (weld root path)) selected)
::
++  request
  ::  Send this payload as %c %warp, after prepare and context resolution.
  |=  doc=document
  ^-  [ship desk (unit rave:clay)]
  [our.where.doc desk.where.doc `[%sing %a [%ud revision.where.doc] path.doc]]
::
++  discover
  ::  Normalize wrappers before distinguishing a non-core from an empty core.
  |=  [doc=document core=vase]
  ^-  result
  =/  typ  p.core
  |-  ^-  result
  ?+  -.typ
    [%invalid (issue:build %suite-not-core path.doc [1 1] ~ ~)]
    %hold  $(typ ~(repo ut typ))
    %hint  $(typ q.typ)
    %face  $(typ q.typ)
    %core
      =.  p.core  typ
      =/  names=(list term)
        %+  skim  (sloe typ)
        |=(name=term =((end [3 5] name) 'test-'))
      ?:  =(~ names)
        [%invalid (issue:build %suite-no-tests path.doc [1 1] ~ ~)]
      =/  chosen=(set term)  (silt selected.doc)
      ?.  =((lent selected.doc) (lent ~(tap in chosen)))
        [%invalid (issue:build %suite-duplicate path.doc [1 1] ~ ~)]
      =/  absent=(list term)
        (skim selected.doc |=(name=term !(lien names |=(n=term =(n name)))))
      ?^  absent
        [%invalid (issue:build %suite-arm path.doc [1 1] `i.absent ~)]
      =.  names  (sort names |=([a=term b=term] !(aor a b)))
      =/  selected
        ?:  =(~ selected.doc)  names
        (skim names |=(name=term (~(has in chosen) name)))
      :*  %ready  doc  core  names  selected
          ~  [(lent selected) 0 0 0 0 0]  ~
      ==
  ==
::
++  take-built
  |=  [doc=document reply=riot:clay]
  ^-  result
  ?~  reply  [%invalid (issue:build %build path.doc [1 1] ~ ~)]
  ?.  ?&  =(%a p.p.u.reply)
          =([%ud revision.where.doc] q.p.u.reply)
          =(desk.where.doc r.p.u.reply)
          =(path.doc q.u.reply)
      ==
    [%invalid (issue:build %build-context path.doc [1 1] ~ ~)]
  ?.  =(%vase p.r.u.reply)
    [%invalid (issue:build %build-mark path.doc [1 1] ~ ~)]
  =/  decoded  (mule |.(!<(vase q.r.u.reply)))
  ?:  ?=(%.n -.decoded)
    [%invalid (issue:build %build-product path.doc [1 1] ~ p.decoded)]
  (discover doc p.decoded)
::
++  run-arm
  ::  Mint against tang as -test does. Do not execute while discovering.
  ::  App suites deny scries so a failed scry cannot escape into Gall.
  |=  [core=vase name=term]
  ^-  arm-result
  =/  compiled
    ~>  %jinx.arm-time
    %-  ~(mule vi |)
    |.  q:(~(mint ut p.core) p:!>(*tang) [%limb name])
  =/  verdict=[status=?(%passed %failed %crashed %invalid) trace=tang]
    ?:  ?=(%.n -.compiled)  [%invalid p.compiled]
    =/  ran
      ~>  %jinx.arm-time
      (~(mule vi |) |.(;;(tang .*(q.core p.compiled))))
    ?:  ?=(%.n -.ran)  [%crashed p.ran]
    [?:(=(~ p.ran) %passed %failed) p.ran]
  =/  cap  diagnostics-bytes.bounds:defaults:engine
  =/  fits  (fits:engine cap trace.verdict)
  [name status.verdict ?:(fits trace.verdict ~) !fits]
::
++  step
  ::  Continue after failures. Completed states are stable.
  |=  s=state
  ^-  state
  ?:  !=(~ result.s)  s
  =/  todo  remaining.s
  ?~  todo
    =/  passed  =(passed.counts.s total.counts.s)
    =/  out=outcome
      [?:(passed %passed %failed) counts.s (flop finished.s) %unavailable]
    s(result `out)
  =/  arm  (run-arm core.s i.todo)
  =.  remaining.s  t.todo
  =.  finished.s  [arm finished.s]
  =.  completed.counts.s  +(completed.counts.s)
  =.  counts.s
    ?-  status.arm
      %passed   counts.s(passed +(passed.counts.s))
      %failed   counts.s(failed +(failed.counts.s))
      %crashed  counts.s(crashed +(crashed.counts.s))
      %invalid  counts.s(invalid +(invalid.counts.s))
    ==
  ?:  !=(~ remaining.s)  s
  $(s s)
--
