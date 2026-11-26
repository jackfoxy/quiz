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
  ::  Labels mark a put that replaces a live key and a wait that expires
  ::  one; with ++alts, Find examples for each label reaches the shortest
  ::  story for each.
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
  =/  [repeated=? expired=?]  (cases ops)
  %^  classify:prop  repeated  'repeated-key'
  %^  classify:prop  expired  'expired'
  (same:prop !>((model ops)) !>(got))
::
++  cases
  ::  Whether a put replaced a live key, and whether a wait expired one.
  |=  ops=(list op)
  ^-  [repeated=? expired=?]
  =/  now  start
  =|  dues=(map @tas @da)
  =/  seen=[repeated=? expired=?]  [| |]
  |-
  ?~  ops  seen
  ?-    -.i.ops
      %put
    =?  repeated.seen  (~(has by dues) key.i.ops)  &
    $(ops t.ops, dues (~(put by dues) key.i.ops (add now ttl.i.ops)))
  ::
      %wait
    =/  later  (add now span.i.ops)
    =/  kept=(list [@tas @da])
      (skim ~(tap by dues) |=([k=@tas d=@da] (gth d later)))
    =?  expired.seen  (lth (lent kept) ~(wyt by dues))  &
    $(ops t.ops, now later, dues (~(gas by *(map @tas @da)) kept))
  ==
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
  ::  Key toward %a, value toward 0, times toward one second.
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
  ::  Every key to %a at once, so a repeated key stays repeated.
  |=  ops=(list op)
  ^-  (list (list op))
  =/  moved  (turn ops |=(o=op ?:(?=(%put -.o) o(key %a) o)))
  ?:(=(moved ops) ~ ~[moved])
::
++  alts
  ::  33-expiry-agent-bug's shrinker: delete operations, shrink each one,
  ::  then rename every key at once.
  %+  alts-of:gen  (list op)
  (shrink-then:gen (shrink-list:gen shrink-op) rename)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
