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
  ::  One external input. The handler decides what each one means.
  $%  [%poke =mark =vase]
      [%watch =path]
      [%leave =path]
      [%peek =path]
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
--
