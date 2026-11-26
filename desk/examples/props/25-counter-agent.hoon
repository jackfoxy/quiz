/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop, h=quiz-harness
/=  drive  /fixtures/quiz-harness/drive
|%
  ::  Model-based test of a counter agent through the pure harness. The
  ::  model adds each amount; the agent drops adds above ten, so this
  ::  property keeps amounts 0 to 9, where the two agree. Resets are
  ::  generated at 10.
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
++  norn
  =/  make
    |=  n=@ud
    ^-  op
    ?:(=(n 10) [%reset ~] [%add n])
  (list-of:gen 0 20 (cook:gen (range:gen 0 10) make))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
