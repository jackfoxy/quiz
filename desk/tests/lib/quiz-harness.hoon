/+  h=quiz-harness, *test
/=  drive  /fixtures/quiz-harness/drive
/=  drive-expiry  /fixtures/quiz-harness/drive-expiry
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
::
++  start-time  ~2026.1.1
::
++  log
  ::  A clocked handler with no agent. A poke of [?(%wait %rest) wire time]
  ::  emits that behn card; %arvo and %agent events are logged with `now`.
  ::  A poke of %crash crashes.
  |=  [ev=event:h now=@da st=*]
  ^-  [(list card:agent:gall) *]
  =/  seen  ;;((list [wire @da]) st)
  ?+    -.ev  [~ st]
      %poke
    ?<  =(%crash mark.ev)
    =/  [kind=?(%wait %rest) =wire at=@da]
      ;;([?(%wait %rest) wire @da] q.vase.ev)
    ?:  ?=(%wait kind)  [~[[%pass wire %arvo %b %wait at]] st]
    [~[[%pass wire %arvo %b %rest at]] st]
  ::
    %arvo   [~ (snoc seen [wire.ev now])]
    %agent  [~ (snoc seen [wire.ev now])]
  ==
::
++  behn-card
  ::  A poke asking ++log for a behn card at start-time plus `after`.
  |=  [kind=?(%wait %rest) =wire after=@dr]
  ^-  event:h
  [%poke %timer !>([kind wire (add start-time after)])]
::
++  test-clock-wake-order
  ::  Earliest first; equal times in the order set; the clock ends at the
  ::  wait's end and no timer is left.
  ^-  tang
  =/  events=(list event:h)
    :~  (behn-card %wait /b ~s2)
        (behn-card %wait /a ~s1)
        (behn-card %wait /c ~s2)
        [%wait ~s5]
    ==
  =/  res  (run-clock:h ~ start-time log events)
  ?>  ?=(%& -.res)
  =/  at  |=(d=@dr (add start-time d))
  ;:  weld
    %+  expect-eq
      !>(`(list [wire @da])`~[[/a (at ~s1)] [/b (at ~s2)] [/c (at ~s2)]])
    !>(;;((list [wire @da]) state.p.res))
    (expect-eq !>((at ~s5)) !>(now.p.res))
    (expect-eq !>(`(list timer:h)`~) !>(timers.p.res))
  ==
::
++  test-clock-rest-and-pending
  ::  A rest cancels its timer; a timer past the wait stays pending.
  ^-  tang
  =/  events=(list event:h)
    :~  (behn-card %wait /a ~s1)
        (behn-card %rest /a ~s1)
        (behn-card %wait /b ~s5)
        [%wait ~s2]
    ==
  =/  res  (run-clock:h ~ start-time log events)
  ?>  ?=(%& -.res)
  ;:  weld
    (expect-eq !>(~) !>(state.p.res))
    (expect-eq !>((add start-time ~s2)) !>(now.p.res))
    %+  expect-eq  !>(`(list timer:h)`~[[(add start-time ~s5) /b]])
    !>(timers.p.res)
  ==
::
++  test-clock-signs-and-crash
  ::  An empty wait moves the clock; %agent reaches the handler at `now`;
  ::  a crash ends the run as data.
  ^-  tang
  =/  events=(list event:h)  ~[[%wait ~s3] [%agent /x %kick ~]]
  =/  res  (run-clock:h ~ start-time log events)
  =/  same  =(res (run-clock:h ~ start-time log events))
  ?>  ?=(%& -.res)
  =/  bad  (run-clock:h ~ start-time log ~[[%poke %crash !>(~)]])
  ;:  weld
    %+  expect-eq  !>(`(list [wire @da])`~[[/x (add start-time ~s3)]])
    !>(;;((list [wire @da]) state.p.res))
    (expect !>(?=(%| -.bad)))
    (expect !>(same))
  ==
::
++  test-card-filters
  ^-  tang
  =/  cards=(list card:agent:gall)
    :~  [%pass /p %agent [~zod %a] %poke %noun !>(1)]
        [%pass /q %agent [~nec %a] %poke %noun !>(2)]
        [%pass /w %agent [~zod %a] %watch /path]
        [%give %fact ~[/x] %noun !>(3)]
    ==
  ;:  weld
    (expect-eq !>(`@ud`1) !>((lent (pokes-to:h cards [~zod %a]))))
    (expect-eq !>(`@ud`1) !>((lent (watches-to:h cards [~zod %a]))))
    (expect-eq !>(`@ud`0) !>((lent (watches-to:h cards [~nec %a]))))
  ==
::
++  expiry-run
  ::  Keys left after two puts of %k, for 1 s then 2 s, and a 1 s wait.
  |=  fixed=?
  ^-  (set @tas)
  =/  put
    |=  [val=@ud ttl=@dr]
    ^-  event:h
    [%poke %expiry-action !>([%put %k val ttl])]
  =/  events=(list event:h)  ~[(put 0 ~s1) (put 1 ~s2) [%wait ~s1]]
  =/  handle  (handle:drive-expiry fixed)
  =/  res  (run-clock:h ~ start-time handle events)
  ?>  ?=(%& -.res)
  ~(key by ;;(store:drive-expiry state.p.res))
::
++  test-expiry-fixture
  ::  The bug: the first put's timer deletes the second put's value.
  ^-  tang
  ;:  weld
    (expect-eq !>(`(set @tas)`~) !>((expiry-run %.n)))
    (expect-eq !>((silt `(list @tas)`~[%k])) !>((expiry-run %.y)))
  ==
--
