/+  h=quiz-harness, *test
/=  drive  /fixtures/quiz-harness/drive
|%
++  test-pokes-and-facts
  ::  Two adds of 4 and 5 publish 4 then 9, one fact per poke.
  ^-  tang
  =/  events=(list event:h)
    :~  [%poke %counter-action !>([%add 4])]
        [%poke %counter-action !>([%add 5])]
    ==
  =/  res  (run:h !>(0) handle:drive events)
  ?>  ?=(%& -.res)
  =/  facts  (facts-on:h cards.p.res /count)
  (expect-eq !>(`@ud`2) !>((lent facts)))
::
++  test-lost-update-fixture
  ::  The fixture's bug: an add above ten is ignored.
  ^-  tang
  =/  events=(list event:h)  ~[[%poke %counter-action !>([%add 11])]]
  =/  res  (run:h !>(0) handle:drive events)
  ?>  ?=(%& -.res)
  (expect-eq !>(`@ud`0) !>(!<(@ud ;;(vase state.p.res))))
::
++  test-crash-is-data
  ::  A wrong mark crashes the door; the harness returns it, not a crash.
  ^-  tang
  =/  events=(list event:h)  ~[[%poke %wrong-mark !>(0)]]
  =/  res  (run:h !>(0) handle:drive events)
  (expect !>(?=(%| -.res)))
::
++  test-determinism
  ^-  tang
  =/  events=(list event:h)  ~[[%poke %counter-action !>([%add 3])]]
  %+  expect-eq  !>((run:h !>(0) handle:drive events))
  !>((run:h !>(0) handle:drive events))
::
++  test-cards-filter
  ^-  tang
  =/  events=(list event:h)  ~[[%poke %counter-action !>([%add 2])]]
  =/  res  (run:h !>(0) handle:drive events)
  ?>  ?=(%& -.res)
  ;:  weld
    (expect-eq !>(`@ud`1) !>((lent (cards-of:h cards.p.res %give))))
    (expect-eq !>(`@ud`0) !>((lent (cards-of:h cards.p.res %pass))))
  ==
::
++  test-star-vase
  ::  A vase typed * holding an op must still reach the door: the fixture
  ::  reads the noun, since !< would check the vase type.
  ^-  tang
  =/  raw=*  [%add 3]
  =/  events=(list event:h)  ~[[%poke %counter-action !>(raw)]]
  =/  res  (run:h !>(0) handle:drive events)
  (expect !>(?=(%& -.res)))
--
