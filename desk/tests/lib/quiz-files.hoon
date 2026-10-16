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
--
