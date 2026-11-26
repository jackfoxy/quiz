::  Counter agent for quiz-harness. Built as a door over the bowl, as Gall
::  agents are. Deliberate bug: an add above ten is silently ignored, a lost
::  update that the document's model does not share.
::
=>  |%
    +$  op  $%([%add n=@ud] [%reset ~])
    --
=+  ct=0
|_  =bowl:gall
+*  this  .
++  on-init  `this
++  on-save  !>(ct)
++  on-load
  |=  old=vase
  ^-  (quip card:agent:gall _this)
  =.  ct  ;;(@ud q.old)
  `this
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card:agent:gall _this)
  ?>  =(%counter-action mark)
  =/  act  ;;(op q.vase)
  ?-  -.act
    %reset  =.  ct  0
            [~[[%give %fact ~[/count] %noun !>(ct)]] this]
    %add    ?:  (gth n.act 10)
              `this
            =.  ct  (add ct n.act)
            [~[[%give %fact ~[/count] %noun !>(ct)]] this]
  ==
--
