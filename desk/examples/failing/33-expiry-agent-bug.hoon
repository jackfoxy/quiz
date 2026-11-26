/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop, h=quiz-harness
/=  drive  /fixtures/quiz-harness/drive-expiry
|%
  ::  A model of an expiring key store against the agent without its fix.
  ::  run-clock keeps the behn timers each put sets and fires them as the
  ::  generated waits pass. A second put of a key leaves the first put's
  ::  timer running, so that wake deletes the newer value early, while the
  ::  model keeps it until its own time to live.
  ::
  ::  The alts deletes ops, lowers values and times, and renames every key
  ::  to %a together; the smallest failure is two puts of one key and one
  ::  wait between their expiries.
  ::
+$  op  $%([%put key=@tas val=@ud ttl=@dr] [%wait span=@dr])
::
++  start  ~2026.1.1
::
++  fate
  |=  raw=*
  =/  ops  ;;((list op) raw)
  =/  events=(list event:h)  (turn ops to-event)
  =/  res  (run-clock:h ~ start (handle:drive %.n) events)
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
++  shrink-op
  |=  o=op
  ^-  (list op)
  =/  secs  (shrink-via:gen (curr div ~s1) (cury mul ~s1) (shrink-toward:gen 1))
  ?-    -.o
      %wait
    (turn (secs span.o) |=(d=@dr `op`[%wait d]))
  ::
      %put
    =/  keys=(list op)  ?:(=(%a key.o) ~ ~[o(key %a)])
    =/  vals  (turn (shrink-atom:gen val.o) |=(v=@ud `op`o(val v)))
    =/  ttls  (turn (secs ttl.o) |=(d=@dr `op`o(ttl d)))
    :(weld keys vals ttls)
  ==
::
++  rename
  ::  Every key to %a at once: the failure needs two puts of one key, so
  ::  moving one copy alone would lose it.
  |=  ops=(list op)
  ^-  (list (list op))
  =/  moved  (turn ops |=(o=op ?:(?=(%put -.o) o(key %a) o)))
  ?:(=(moved ops) ~ ~[moved])
::
++  alts
  %+  alts-of:gen  (list op)
  (shrink-then:gen (shrink-list:gen shrink-op) rename)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
