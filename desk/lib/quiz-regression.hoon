/-  app=quiz-app
/+  build=quiz-build
|%
  ::  A run's shrunk counterexample as a regression suite: the property
  ::  document's prelude and core, verbatim, then one test arm requiring
  ::  the fate to pass that sample. It fails until the bug is fixed. The
  ::  sample is the cue of its jam, exact for any type; the rendered text
  ::  is a comment, since it does not parse back to the same noun.
  ::
+$  made
  $%  [%suite name=@t text=@t]
      [%refused code=@tas]
      [%invalid diagnostic:build]
  ==
::
++  proof
  ::  A finished property run's counterexample, or why it has none. A
  ::  failure the document expects is not a bug to keep failing.
  |=  rec=record:app
  ^-  (each evidence:app @tas)
  ?~  result.rec  [%.n %run-unfinished]
  =/  out  u.result.rec
  ?:  ?=(%failed -.out)  [%.y +.out]
  ?:  ?=(%failed-as-expected -.out)  [%.n %failed-as-expected]
  =/  held=(unit evidence:app)
    ?+  -.out  ~
      %error        proof.out
      %limited      proof.out
      %interrupted  proof.out
      %examples     proof.out
    ==
  ?~  held  [%.n %no-counterexample]
  [%.y u.held]
::
++  make
  ::  The suite text, checked to parse as a document would be at the run's
  ::  pinned context. The real build happens when the saved suite runs.
  |=  rec=record:app
  ^-  made
  =/  got  (proof rec)
  ?:  ?=(%.n -.got)  [%refused p.got]
  ?~  snapshot.rec  [%refused %no-counterexample]
  =/  snap  u.snapshot.rec
  =/  all=tape  (trip source.snap)
  =/  header  (header-rule:build [1 1] all)
  ?~  q.header  [%invalid (issue:build %prelude path.snap p.header ~ ~)]
  ::  The prelude keeps the comments after it; the core loses trailing space.
  =/  body=tape  q.q.u.q.header
  =/  prelude=tape  (scag (sub (lent all) (lent body)) all)
  =/  core=tape
    =/  back  (flop body)
    |-  ^-  tape
    ?~  back  ~
    ?:  |(=(' ' i.back) =(`@`10 i.back))  $(back t.back)
    (flop back)
  =/  name  (crip "regression-{(a-co:co id.rec)}")
  =/  from=tape
    ?:  ?=(%draft -.source.request.rec)  "a draft"
    (spud path.snap)
  =/  shown=wain
    %+  turn  (to-wain:format text.shrunk.p.got)
    |=(line=@t (cat 3 '::    ' line))
  =/  at=tape
    "%{(trip desk.where.snap)} revision {(a-co:co revision.where.snap)}"
  =/  lines=wain
    ;:  weld
      :~  (crip "::  Regression from run {(a-co:co id.rec)} of")
          (crip "::    {from}")
          (crip "::  at {at}. Its shrunk counterexample,")
      ==
      shown
      :~  '::  must pass the fate. It fails until the bug is fixed.'
          '::'
          '=>'
          (crip core)
          '|%'
          %-  crip
          "++  counterexample  (cue {(scow %uv (jam value.shrunk.p.got))})"
          '::'
      ==
      test-arm
    ==
  =/  text  (cat 3 (crip prelude) (of-wain:format (snoc lines '')))
  =/  checked
    (prepare:build where.snap /data/quiz/[name]/hoon text)
  ?:  ?=(%.n -.checked)  [%invalid p.checked]
  [%suite name text]
::
++  test-arm
  ::  The fixed test core. A crash or a drop is reported as such; a false
  ::  report adds its notes and compared values.
  ^-  wain
  :~  '+$  told'
      '  $:  %report  %.n'
      '      [notes=(list @t) compared=(unit [want=@t got=@t])]'
      '      *'
      '  =='
      '::'
      '++  test-counterexample'
      '  ^-  tang'
      '  =/  got  (mule |.((slum fate counterexample)))'
      '  ?:  ?=(%| -.got)'
      '    [leaf+"the fate crashed on the counterexample" p.got]'
      '  =/  product  p.got'
      '  ?:  |(=(%.y product) ?=([%report %.y *] product))  ~'
      '  ?:  |(=(%drop product) ?=([%report %drop *] product))'
      '    ~[leaf+"the fate dropped the counterexample"]'
      '  :-  leaf+"the fate failed the counterexample"'
      '  =/  said  (mole |.(;;(told product)))'
      '  ?~  said  ~'
      '  %+  weld  (turn notes.u.said |=(note=@t leaf+(trip note)))'
      '  ?~  compared.u.said  ~'
      '  :~  leaf+"want: {(trip want.u.compared.u.said)}"'
      '      leaf+"got: {(trip got.u.compared.u.said)}"'
      '  =='
      '--'
  ==
--
