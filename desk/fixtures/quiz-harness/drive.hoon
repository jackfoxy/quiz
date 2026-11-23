::  Drives the counter fixture through quiz-harness: each event reloads the
::  saved state, as Gall does, then applies the event and saves again.
::
/+  h=quiz-harness
/=  counter  /fixtures/quiz-harness/counter
|%
++  handle
  ::  The events are pokes only here; watch, leave and peek are no-ops.
  |=  [ev=event:h st=*]
  ^-  [(list card:agent:gall) *]
  ?.  ?=([%poke *] ev)  [~ st]
  =/  bol  (bowl-at:h ~zod ~zod ~2026.1.1 0v1 %quiz)
  =/  ag  ~(. counter bol)
  =/  [c1=(list card:agent:gall) d1=_ag]  (on-load:ag ;;(vase st))
  =/  [c2=(list card:agent:gall) d2=_ag]  (on-poke:d1 mark.ev vase.ev)
  [(weld c1 c2) on-save:d2]
--
