/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop, h=quiz-harness
/=  drive  /fixtures/quiz-harness/drive
|%
  ::  The same model against the same agent, now generating adds up to 99.
  ::  The agent ignores an add above ten, a lost update, so the model and
  ::  the agent disagree. The alts shrinks the event list with shrink-list
  ::  and each amount toward zero; the smallest failing amount is 11.
  ::
+$  op  $%([%add n=@ud] [%reset ~])
::
++  fate
  |=  raw=*
  =/  ops  ;;((list op) raw)
  =/  events
    %+  turn  ops
    |=  o=*
    ^-  event:h
    [%poke %counter-action !>(o)]
  =/  res  (run:h !>(0) handle:drive events)
  ?:  ?=(%| -.res)  |
  (same:prop !>((model ops)) !>(!<(@ud ;;(vase state.p.res))))
::
++  model
  |=  ops=(list op)
  ^-  @ud
  %+  roll  ops
  |=  [o=op acc=@ud]
  ?-  -.o
    %add    (add acc n.o)
    %reset  0
  ==
::
++  shrink-op
  |=  o=op
  ^-  (list op)
  ?-  -.o
    %add    (turn (shrink-atom:gen n.o) |=(m=@ud `op`[%add m]))
    %reset  ~
  ==
::
++  norn
  =/  make
    |=  n=@ud
    ^-  op
    ?:(=(n 0) [%reset ~] [%add n])
  (list-of:gen 0 20 (cook:gen (range:gen 0 99) make))
::
++  alts
  %+  alts-of:gen  (list op)
  (shrink-list:gen shrink-op)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
