/+  *test, files=quiz-files
|%
++  bol
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    byk  [~zod %quiz %da ~2026.10.15]
    now  ~2026.10.15
  ==
::
++  test-only-clay-locations
  ::  Every workbench path is under /clay; the old virtual roots are gone.
  ^-  tang
  =/  gone=(list path)
    :~  /work/folder/property/hoon
        /draft/hoon
        /examples/example/hoon
        /props/success/hoon
        /failing/crash/hoon
        /docs/reference/source-format/md
    ==
  %-  zing
  %+  turn  gone
  |=  rel=path
  =/  got  (locate:files bol rel)
  ?>  ?=(%.n -.got)
  (expect-eq !>(400) !>(status.p.got))
::
++  test-clay-selection-required
  ::  A desk and a case, `now` or a revision number, come first.
  ^-  tang
  =/  missing  (locate:files bol /clay)
  =/  partial  (locate:files bol /clay/quiz)
  =/  bad  (locate:files bol /clay/quiz/nope/lib/quiz/hoon)
  ?>  ?=(%.n -.missing)
  ?>  ?=(%.n -.partial)
  ?>  ?=(%.n -.bad)
  ;:  weld
    (expect-eq !>(400) !>(status.p.missing))
    (expect-eq !>(400) !>(status.p.partial))
    (expect-eq !>(400) !>(status.p.bad))
  ==
::
++  source
  ::  Lines joined into a source text.
  |=  lines=wain
  ^-  @t
  (of-wain:format (weld lines `wain`~['|%' '++  fate  |=(@ud &)' '--']))
::
++  imports-engine
  ::  Whether the prelude imports quiz-engine.
  |=  text=@t
  ^-  ?
  (~(has in (silt (imports:files text))) /lib/quiz-engine/hoon)
::
++  test-imports-engine
  ::  A /+ import of quiz-engine, under any face, marks a property.
  ^-  tang
  =/  yes=(list @t)
    :~  (source ~['/+  engine=quiz-engine'])
        (source ~['/-  app=quiz-app' '/+  gen=quiz-gen, engine=quiz-engine'])
        (source ~['/+  gen=quiz-gen,' '    engine=quiz-engine'])
        (source ~['::  a property' '/+  engine=quiz-engine'])
        (source ~['/+  quiz-engine'])
        (source ~['/+  e=quiz-engine'])
    ==
  =/  no=(list @t)
    :~  (source ~)
        (source ~['/+  *test, quiz'])
        (source ~['/+  quiz-engine-extra'])
        (source ~['::  /+  engine=quiz-engine'])
    ==
  ;:  weld
    (expect !>((levy yes imports-engine)))
    (expect !>(!(lien no imports-engine)))
  ==
::
++  test-has-fate
  ::  `++  fate` at column 0, alone or before a space; nothing before it.
  ^-  tang
  =/  prelude  '/+  engine=quiz-engine'
  =/  yes=(list @t)
    :~  (source ~)
        (of-wain:format ~[prelude '|%' '++  fate' '  |=(@ud &)' '--'])
    ==
  =/  no=(list @t)
    :~  (of-wain:format ~[prelude '|%' '++  norn  !!' '--'])
        (of-wain:format ~[prelude '|%' '  ++  fate' '    |=(@ud &)' '--'])
        (of-wain:format ~[prelude '|%' '::  ++  fate' '--'])
        (of-wain:format ~[prelude '|%' '++  fate-helper  !!' '--'])
        (of-wain:format ~[prelude '|%' '++  fated  !!' '--'])
    ==
  ;:  weld
    (expect !>((levy yes (cury has-arm:files '++  fate'))))
    (expect !>(!(lien no (cury has-arm:files '++  fate'))))
  ==
::
++  test-role-of
  ::  A property needs the engine and ++fate; a suite needs /lib/test and a
  ::  ++test- arm, and is a quiz suite when it also imports a quiz library.
  ^-  tang
  =/  suite  (of-wain:format ~['/+  *test' '|%' '++  test-one  ~' '--'])
  =/  quiz-suite
    |=  prelude=@t
    ^-  @t
    (of-wain:format ~[prelude '|%' '++  test-one  ~' '--'])
  =/  both
    %-  of-wain:format
    ~['/+  e=quiz-engine' '|%' '++  fate  |=(@ud &)' '++  test-x  ~' '--']
  =/  bare  (of-wain:format ~['|%' '++  test  ~' '++  tests-x  ~' '--'])
  ::  a thread with test- arms and no /lib/test, as %base/ted/ph/ahoy
  =/  thread
    (of-wain:format ~['/+  *ph-io' '|%' '++  test-mesa-ames-1  ~' '--'])
  =/  quiet  (of-wain:format ~['/+  quiz' '|%' '++  test-one  ~' '--'])
  ;:  weld
    (expect-eq !>(`%suite) !>((role-of:files suite)))
    (expect-eq !>(`%property) !>((role-of:files both)))
    (expect-eq !>(`%property) !>((role-of:files (source ~['/+  quiz-engine']))))
    (expect-eq !>(~) !>((role-of:files (source ~))))
    (expect-eq !>(~) !>((role-of:files bare)))
    (expect-eq !>(~) !>((role-of:files thread)))
    (expect-eq !>(~) !>((role-of:files quiet)))
    %+  expect-eq  !>(`%quiz-suite)
    !>((role-of:files (quiz-suite '/+  *test, quiz')))
    %+  expect-eq  !>(`%quiz-suite)
    !>((role-of:files (quiz-suite '/+  *test, auto=quiz-auto')))
    %+  expect-eq  !>(`%quiz-suite)
    !>((role-of:files (quiz-suite '/+  e=quiz-engine, *test')))
    %+  expect-eq  !>(`%suite)
    !>((role-of:files (quiz-suite '/+  *test, quiz-gen')))
  ==
::
++  test-imports-engine-long-source
  ::  The prelude is found however long the body after it.
  ^-  tang
  =/  body=wain  (reap 2.000 '::  padding line')
  =/  long  (source (weld `wain`~['/+  engine=quiz-engine'] body))
  ;:  weld
    (expect !>((gth (met 3 long) prelude-bytes:files)))
    (expect !>((imports-engine long)))
  ==
--
