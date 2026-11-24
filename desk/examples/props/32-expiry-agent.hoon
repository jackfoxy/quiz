/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop, h=quiz-harness
/=  drive  /fixtures/quiz-harness/drive-expiry
|%
  ::  A model of an expiring key store against the fixed agent.
  ::  run-clock keeps the behn timers each put sets and fires them as the
  ::  generated waits pass, so the property checks the agent's timer
  ::  handling with no real time. A second put of a key %rests the first
  ::  put's timer, and the agent agrees with the model.
  ::  33-expiry-agent-bug runs the same model against the unfixed agent.
  ::
+$  op  $%([%put key=@tas val=@ud ttl=@dr] [%wait span=@dr])
::
++  start  ~2026.1.1
::
++  fate
  |=  raw=*
  =/  ops  ;;((list op) raw)
  =/  events=(list event:h)  (turn ops to-event)
  =/  res  (run-clock:h ~ start (handle:drive %.y) events)
  ?:  ?=(%| -.res)  |
  =/  got  ~(key by ;;(store:drive state.p.res))
  (same:prop !>((model ops)) !>(got))
::
++  to-event
  |=  o=op
  ^-  event:h
  ?-  -.o
    %put   [%poke %expiry-action !>(o)]
    %wait  [%wait span.o]
  ==
::
++  model
  ::  Keys whose latest put has not yet expired. A wake at the due time
  ::  deletes, so a key due exactly at `now` is gone.
  |=  ops=(list op)
  ^-  (set @tas)
  =/  now  start
  =|  dues=(map @tas @da)
  |-
  ?~  ops  ~(key by dues)
  ?-    -.i.ops
      %put
    $(ops t.ops, dues (~(put by dues) key.i.ops (add now ttl.i.ops)))
  ::
      %wait
    =/  later  (add now span.i.ops)
    =/  kept=(list [@tas @da])
      (skim ~(tap by dues) |=([k=@tas d=@da] (gth d later)))
    $(ops t.ops, now later, dues (~(gas by *(map @tas @da)) kept))
  ==
::
++  seconds
  ::  Whole seconds, 1 to 5.
  (cook:gen (range:gen 1 5) (cury mul ~s1))
::
++  norn
  =/  key  (elements:gen `(list @tas)`~[%a %b])
  =/  put=(norn:gen op)
    %+  cook:gen  (trip:gen key (range:gen 0 9) seconds)
    |=([k=@tas v=@ud t=@dr] `op`[%put k v t])
  =/  wait=(norn:gen op)  (cook:gen seconds |=(d=@dr `op`[%wait d]))
  (list-of:gen 0 12 (frequency:gen ~[[2 put] [1 wait]]))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
