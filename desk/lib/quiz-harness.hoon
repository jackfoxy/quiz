::  Pure agent harness: model-based testing of a Gall agent's door.
::
::  Properties stay pure. A harness run folds generated events through a
::  handler that the document writes over the agent's door. Each door arm
::  runs under mule, so a crash is returned as data, never as a property
::  crash. Scries stay refused, and replay stays exact: the bowl is built
::  from the sample, not the clock. See the reference, "Agent harness".
::
|%
+$  event
  ::  One external input. The handler decides what each one means. %agent
  ::  and %arvo carry a sign for on-agent and on-arvo; %wait advances the
  ::  clock of ++run-clock, which delivers due behn timers as %arvo wakes.
  $%  [%poke =mark =vase]
      [%watch =path]
      [%leave =path]
      [%peek =path]
      [%agent =wire =sign:agent:gall]
      [%arvo =wire =sign-arvo]
      [%wait span=@dr]
  ==
::
+$  timer  [due=@da =wire]
::
+$  clocked
  ::  A ++run-clock result: cards, saved state, the clock, pending timers.
  $:  cards=(list card:agent:gall)
      state=*
      now=@da
      timers=(list timer)
  ==
::
++  bowl-at
  ::  A bowl with only the fields a door reads set; now and eny are the
  ::  sample's, never the clock.
  |=  [our=ship src=ship now=@da eny=@uvJ dap=term]
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  our
    src  src
    now  now
    eny  eny
    dap  dap
  ==
::
++  run
  ::  Fold events through the handler from start. Each step returns the
  ::  cards it emitted and the next saved state. A crash in any step ends
  ::  the run as [%| tang]. Nothing is retried, so a candidate that crashes
  ::  is a failure of the same kind.
  |=  $:  start=*
          handle=$-([event *] [(list card:agent:gall) *])
          events=(list event)
      ==
  ^-  (each [cards=(list card:agent:gall) state=*] tang)
  =/  st=*  start
  =/  cards=(list card:agent:gall)  ~
  |-  ^-  (each [(list card:agent:gall) *] tang)
  ?~  events  [%& cards st]
  =/  ran  (mule |.((handle i.events st)))
  ?:  ?=(%| -.ran)  [%| p.ran]
  $(events t.events, cards (weld cards -.p.ran), st +.p.ran)
::
++  run-clock
  ::  As ++run, with a simulated clock: the handler also receives `now`.
  ::  Behn timers set by [%pass wire %arvo %b %wait due] cards are kept; a
  ::  %rest card cancels the first one with that wire and time. [%wait d]
  ::  advances the clock by d, first delivering every timer due by then as
  ::  [%arvo wire %behn %wake ~], at its due time, earliest first, ties in
  ::  the order set. A timer set during a wait fires within it when due.
  ::  The product's `timers` are those still pending, in the order set.
  |=  $:  start=*
          now=@da
          handle=$-([event @da *] [(list card:agent:gall) *])
          events=(list event)
      ==
  ^-  (each clocked tang)
  =/  st=*  start
  =|  cards=(list card:agent:gall)
  =|  timers=(list timer)
  |-
  ?~  events  [%& cards st now timers]
  =/  ev  i.events
  =/  due=(unit timer)
    ?.  ?=(%wait -.ev)  ~
    =/  until  (add now span.ev)
    %+  roll  timers
    |=  [t=timer best=(unit timer)]
    ?:  (gth due.t until)  best
    ?~  best  `t
    ?:((lth due.t due.u.best) `t best)
  ?:  ?=(%wait -.ev)
    ?~  due  $(events t.events, now (add now span.ev))
    ::  Deliver the earliest due timer, then wait out the rest.
    =/  left  (sub (add now span.ev) due.u.due)
    =/  wake=event  [%arvo wire.u.due %behn %wake ~]
    =/  ran  (mule |.((handle wake due.u.due st)))
    ?:  ?=(%| -.ran)  [%| p.ran]
    =/  rest  (drop-timer timers u.due)
    %=  $
      events  [[%wait left] t.events]
      now     due.u.due
      cards   (weld cards -.p.ran)
      st      +.p.ran
      timers  (track rest -.p.ran)
    ==
  =/  ran  (mule |.((handle ev now st)))
  ?:  ?=(%| -.ran)  [%| p.ran]
  %=  $
    events  t.events
    cards   (weld cards -.p.ran)
    st      +.p.ran
    timers  (track timers -.p.ran)
  ==
::
++  track
  ::  Pending timers after a step's cards: behn %wait adds, %rest cancels.
  |=  [timers=(list timer) cards=(list card:agent:gall)]
  ^-  (list timer)
  ?~  cards  timers
  =/  n=*  i.cards
  ?:  ?=([%pass * %arvo %b %wait @] n)
    =/  set  ;;([%pass =wire %arvo %b %wait due=@da] n)
    $(cards t.cards, timers (snoc timers [due.set wire.set]))
  ?:  ?=([%pass * %arvo %b %rest @] n)
    =/  gone  ;;([%pass =wire %arvo %b %rest due=@da] n)
    $(cards t.cards, timers (drop-timer timers [due.gone wire.gone]))
  $(cards t.cards)
::
++  drop-timer
  ::  Remove the first timer equal to `gone`.
  |=  [timers=(list timer) gone=timer]
  ^-  (list timer)
  ?~  timers  ~
  ?:  =(i.timers gone)  t.timers
  [i.timers $(timers t.timers)]
::
++  cards-of
  ::  Cards whose head tag matches, as in %pass or %give.
  |=  [cards=(list card:agent:gall) tag=@tas]
  ^-  (list card:agent:gall)
  (skim cards |=(c=card:agent:gall =(tag -.c)))
::
++  facts-on
  ::  %give %fact cards published on exactly this path.
  |=  [cards=(list card:agent:gall) =path]
  ^-  (list card:agent:gall)
  %+  skim  cards
  |=  c=card:agent:gall
  =/  n=*  c
  ?:  =(%give -.n)
    ?:  =(%fact -.+.n)  =(~[path] -.+.+.n)
    |
  |
::
++  pokes-to
  ::  %poke cards passed to one agent, as [ship agent].
  |=  [cards=(list card:agent:gall) =dock]
  ^-  (list card:agent:gall)
  %+  skim  cards
  |=  c=card:agent:gall
  =/  n=*  c
  ?&  ?=([%pass * %agent [@ @] %poke *] n)
      =(dock ;;(^dock +>+<.n))
  ==
::
++  watches-to
  ::  %watch cards passed to one agent, as [ship agent].
  |=  [cards=(list card:agent:gall) =dock]
  ^-  (list card:agent:gall)
  %+  skim  cards
  |=  c=card:agent:gall
  =/  n=*  c
  ?&  ?=([%pass * %agent [@ @] %watch *] n)
      =(dock ;;(^dock +>+<.n))
  ==
--
