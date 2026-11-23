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
++  test-work-root
  ^-  tang
  =/  got  (locate:files bol /work/folder/property/hoon)
  %+  expect-eq
  !>([%.y [[~zod %quiz [%da ~2026.10.15]] /data/quiz/folder/property/hoon &]])
  !>(got)
::
++  test-read-only-roots
  ^-  tang
  =/  examples  (locate:files bol /examples/example/hoon)
  =/  docs  (locate:files bol /docs/source-format/md)
  ?>  ?=(%.y -.examples)
  ?>  ?=(%.y -.docs)
  ;:  weld
    (expect-eq !>(/tests/examples/example/hoon) !>(rel.p.examples))
    (expect-eq !>(/doc/source-format/md) !>(rel.p.docs))
    (expect !>(!write.p.examples))
    (expect !>(!write.p.docs))
  ==
::
++  test-legacy-alias
  ^-  tang
  %+  expect-eq
  !>((locate:files bol /work/legacy/hoon))
  !>((locate:files bol /legacy/hoon))
::
++  test-property-example-roots
  ^-  tang
  =/  props  (locate:files bol /props/success/hoon)
  =/  failing  (locate:files bol /failing/crash/hoon)
  ?>  ?=(%.y -.props)
  ?>  ?=(%.y -.failing)
  ;:  weld
    (expect-eq !>(/examples/props/success/hoon) !>(rel.p.props))
    (expect-eq !>(/examples/failing/crash/hoon) !>(rel.p.failing))
    (expect !>(!write.p.props))
    (expect !>(!write.p.failing))
  ==
::
++  test-clay-selection-required
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
++  test-imports-engine
  ::  Only an `engine=quiz-engine` face on a /+ import marks a property.
  ^-  tang
  =/  yes=(list @t)
    :~  (source ~['/+  engine=quiz-engine'])
        (source ~['/-  app=quiz-app' '/+  gen=quiz-gen, engine=quiz-engine'])
        (source ~['/+  gen=quiz-gen,' '    engine=quiz-engine'])
        (source ~['::  a property' '/+  engine=quiz-engine'])
    ==
  =/  no=(list @t)
    :~  (source ~)
        (source ~['/+  quiz-engine'])
        (source ~['/+  e=quiz-engine'])
        (source ~['/+  *test, quiz'])
        (source ~['::  /+  engine=quiz-engine'])
    ==
  ;:  weld
    (expect !>((levy yes imports-engine:files)))
    (expect !>(!(lien no imports-engine:files)))
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
    (expect !>((levy yes has-fate:files)))
    (expect !>(!(lien no has-fate:files)))
  ==
::
++  test-imports-engine-long-source
  ::  The prelude is found however long the body after it.
  ^-  tang
  =/  body=wain  (reap 2.000 '::  padding line')
  =/  long  (source (weld `wain`~['/+  engine=quiz-engine'] body))
  ;:  weld
    (expect !>((gth (met 3 long) prelude-bytes:files)))
    (expect !>((imports-engine:files long)))
  ==
--
