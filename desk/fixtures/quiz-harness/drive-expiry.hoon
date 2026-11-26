::  Drives the expiry fixture through quiz-harness's ++run-clock. Each
::  event reloads the saved state at the clock's time, as Gall does, then
::  applies a poke or a behn wake and saves again. The saved state is the
::  store's noun: molding a vase whose type is a map walks the map's whole
::  compile-time subject, which takes minutes.
::
/+  h=quiz-harness
/=  expiry  /fixtures/quiz-harness/expiry
|%
++  handle
  ::  The agent with or without its fix. Other events change nothing.
  |=  fixed=?
  |=  [ev=event:h now=@da st=*]
  ^-  [(list card:agent:gall) *]
  =/  bol  (bowl-at:h ~zod ~zod now 0v1 %quiz)
  =/  ag  ~(. (expiry fixed) bol)
  =/  saved=vase  [p:!>(*store) st]
  =/  [c1=(list card:agent:gall) d1=_ag]  (on-load:ag saved)
  ?+    -.ev  [c1 q:on-save:d1]
      %poke
    =/  [c2=(list card:agent:gall) d2=_ag]  (on-poke:d1 mark.ev vase.ev)
    [(weld c1 c2) q:on-save:d2]
  ::
      %arvo
    =/  [c2=(list card:agent:gall) d2=_ag]
      (on-arvo:d1 wire.ev sign-arvo.ev)
    [(weld c1 c2) q:on-save:d2]
  ==
::
+$  store  (map @tas [val=@ud due=@da])
--
