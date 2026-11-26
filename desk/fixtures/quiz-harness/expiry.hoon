::  Expiring key store for quiz-harness's simulated clock. A put stores a
::  value and sets a behn timer for its time to live; the wake deletes the
::  key. A gate over `fixed`, so one file gives both agents.
::
::  Deliberate bug when `fixed` is %.n: a second put of a key does not
::  %rest the first put's timer, so that older wake deletes the newer
::  value early.
::
=>  |%
    +$  action  [%put key=@tas val=@ud ttl=@dr]
    +$  items  (map @tas [val=@ud due=@da])
    --
|=  fixed=?
=|  =items
|_  =bowl:gall
+*  this  .
++  on-init  `this
++  on-save  !>(items)
++  on-load
  |=  old=vase
  ^-  (quip card:agent:gall _this)
  =.  items  ;;(^items q.old)
  `this
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card:agent:gall _this)
  ?>  =(%expiry-action mark)
  =/  act  ;;(action q.vase)
  =/  due  (add now.bowl ttl.act)
  =/  =wire  /expire/[key.act]
  =/  old  (~(get by items) key.act)
  =/  rest=(list card:agent:gall)
    ?.  &(fixed ?=(^ old))  ~
    ~[[%pass wire %arvo %b %rest due.u.old]]
  =.  items  (~(put by items) key.act [val.act due])
  :_  this
  (snoc rest [%pass wire %arvo %b %wait due])
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card:agent:gall _this)
  ?.  ?=([%expire @ ~] wire)  `this
  ?.  ?=([%behn %wake *] sign-arvo)  `this
  `this(items (~(del by items) i.t.wire))
--
