/-  app=quiz-app
/+  regression=quiz-regression, build=quiz-build, engine=quiz-engine, *test
|%
::
++  zero-fate
  ::  A property that only 0 passes.
  %-  of-wain:format
  :~  '|%'
      '++  fate'
      '  |=  n=@ud'
      '  =(n 0)'
      '--'
  ==
::
++  evidence
  ::  A failure shrunk to 3.
  ^-  evidence:app
  [*failure:engine [30 '30'] [3 '3'] ~]
::
++  record-of
  ::  A finished draft run of `text` with outcome `out`.
  |=  [text=@t out=(unit outcome:app)]
  ^-  record:app
  =/  rec  *record:app
  =/  where=context:build  [~zod %quiz 9]
  %=  rec
    id        7
    request   request.rec(source [%draft text])
    snapshot  `[where /draft/hoon text (shax text)]
    result    out
  ==
::
++  suite-text
  ::  The generated text; crashes on a refusal.
  |=  rec=record:app
  ^-  @t
  =/  made  (make:regression rec)
  ?>  ?=(%suite -.made)
  text.made
::
++  run-test
  ::  Compile a suite text over zuse and run its one test arm.
  |=  text=@t
  ^-  tang
  =/  core  (slap !>(..zuse) (ream text))
  !<(tang (slap core (ream 'test-counterexample')))
::
++  test-regression-refusals
  ^-  tang
  =/  cases=(list [out=(unit outcome:app) code=@tas])
    :~  [~ %run-unfinished]
        [`[%failed-as-expected evidence] %failed-as-expected]
        [`[%passed ~ ~ ~] %no-counterexample]
        [`[%limited *limit-name:engine ~] %no-counterexample]
        [`[%interrupted %building ~ ~] %no-counterexample]
        [`[%cancelled %request] %no-counterexample]
    ==
  %-  zing
  %+  turn  cases
  |=  [out=(unit outcome:app) code=@tas]
  ^-  tang
  %+  expect-eq  !>(`made:regression`[%refused code])
  !>((make:regression (record-of zero-fate out)))
::
++  test-regression-evidence
  ::  Every outcome that carries a counterexample is accepted.
  ^-  tang
  =/  outs=(list outcome:app)
    :~  [%failed evidence]
        [%error *error-stage:engine *failure:engine `evidence]
        [%limited *limit-name:engine `evidence]
        [%interrupted %shrinking `evidence ~]
        [%examples ~ ~ ~ `evidence]
    ==
  %-  zing
  %+  turn  outs
  |=  out=outcome:app
  ^-  tang
  =/  made  (make:regression (record-of zero-fate `out))
  (expect-eq !>(%suite) !>(-.made))
::
++  test-regression-suite
  ::  The suite fails on the shrunk sample until the fate is fixed.
  ^-  tang
  =/  rec  (record-of zero-fate `[%failed evidence])
  =/  made  (make:regression rec)
  ?>  ?=(%suite -.made)
  =/  lines  (to-wain:format text.made)
  =/  fixed=wain
    %+  turn  lines
    |=(l=@t ?:(=('  =(n 0)' l) '  &' l))
  ;:  weld
    (expect-eq !>('regression-7') !>(name.made))
    %+  expect-eq
      !>  :~  '::  Regression from run 7 of'
              '::    a draft'
              '::  at %quiz revision 9. Its shrunk counterexample,'
              '::    3'
              '::  must pass the fate. It fails until the bug is fixed.'
              '::'
              '=>'
              '|%'
          ==
    !>((scag 8 lines))
    %+  expect-eq
      !>((crip "++  counterexample  (cue {(scow %uv (jam 3))})"))
    !>((snag 13 lines))
    %+  expect-eq  !>(~[leaf+"the fate failed the counterexample"])
    !>((run-test text.made))
    (expect-eq !>(*tang) !>((run-test (of-wain:format fixed))))
  ==
::
++  test-regression-prelude
  ::  The prelude and its trailing comments are kept verbatim; a saved
  ::  file is named by its path.
  ^-  tang
  =/  prelude  '/+  engine=quiz-engine\0a::  a note\0a\0a'
  =/  text  (cat 3 prelude zero-fate)
  =/  rec  (record-of text `[%failed evidence])
  =.  request.rec  request.rec(source [%file /props/zero/hoon])
  =.  snapshot.rec  `[[~zod %quiz 9] /props/zero/hoon text (shax text)]
  =/  got  (suite-text rec)
  ;:  weld
    (expect-eq !>(prelude) !>((end [3 (met 3 prelude)] got)))
    %+  expect-eq  !>('::    /props/zero/hoon')
    !>((snag 1 (to-wain:format (rsh [3 (met 3 prelude)] got))))
  ==
::
++  test-regression-report
  ::  A false report's notes and compared values follow the failure.
  ^-  tang
  =/  text
    %-  of-wain:format
    :~  '|%'
        '++  fate'
        '  |=  n=@ud'
        '  [%report %.n [~[\'too big\'] `[\'0\' \'3\']] ~ ~]'
        '--'
    ==
  =/  got  (run-test (suite-text (record-of text `[%failed evidence])))
  %+  expect-eq
    !>  :~  leaf+"the fate failed the counterexample"
            leaf+"too big"
            leaf+"want: 0"
            leaf+"got: 3"
        ==
  !>(got)
--
