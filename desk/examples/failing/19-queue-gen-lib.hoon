/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  Example 11's queue bug, generated and shrunk with quiz-gen instead of
  ::  a hand-written norn and alts. The norn draws commands, then removes
  ::  any pop the precondition forbids; the alts is shrink-list over a
  ::  command shrinker, filtered by the same precondition. Tags render as
  ::  numbers: %push 1.752.397.168, %pop 7.368.560, %size 1.702.521.203.
  ::
::
+$  cmd  $%([%push v=@ud] [%pop ~] [%size ~])
::
+$  queue  [front=(list @ud) back=(list @ud)]
::
++  model-step
  |=  [items=(list @ud) =cmd]
  ^-  [* (list @ud)]
  ?-  -.cmd
    %push  [~ (snoc items v.cmd)]
    %pop   ?~(items [~ ~] [`i.items t.items])
    %size  [(lent items) items]
  ==
::
++  queue-step
  |=  [q=queue =cmd]
  ^-  [* queue]
  ?-    -.cmd
    %push  [~ q(back [v.cmd back.q])]
    %size  [(add (lent front.q) (lent back.q)) q]
  ::
      %pop
    ?^  front.q  [`i.front.q [t.front.q back.q]]
    ?>  ?=(^ back.q)
    ::  Bug: should take the head of (flop back.q).
    [`i.back.q [t.back.q ~]]
  ==
::
++  repair
  ::  Keep a pop only while the queue holds an item.
  |=  cmds=(list cmd)
  ^-  (list cmd)
  =/  held  0
  |-
  ?~  cmds  ~
  ?-  -.i.cmds
    %push  [i.cmds $(cmds t.cmds, held +(held))]
    %size  [i.cmds $(cmds t.cmds)]
    %pop   ?:(=(0 held) $(cmds t.cmds) [i.cmds $(cmds t.cmds, held (dec held))])
  ==
::
++  valid
  |=  cmds=(list cmd)
  ^-  ?
  =(cmds (repair cmds))
::
++  fate
  |=  cmds=*
  ^-  ?(? %drop)
  =/  cmds  ;;((list cmd) cmds)
  ?.  (valid cmds)  %drop
  =/  items=(list @ud)  ~
  =/  q=queue  [~ ~]
  |-
  ?~  cmds  &
  =/  want  (model-step items i.cmds)
  =/  got  (queue-step q i.cmds)
  ?.  =(-.want -.got)  |
  ?.  =(+.want (weld front.+.got (flop back.+.got)))  |
  $(cmds t.cmds, items +.want, q +.got)
::
++  command
  ^-  (norn:gen cmd)
  =/  push=(norn:gen cmd)  (cook:gen (range:gen 0 99) |=(v=@ud [%push v]))
  =/  pop=(norn:gen cmd)  |=([@ud _og] [%pop ~])
  =/  size=(norn:gen cmd)  |=([@ud _og] [%size ~])
  (frequency:gen ~[[3 push] [2 pop] [1 size]])
::
++  shrink-cmd
  |=  c=cmd
  ^-  (list cmd)
  ?.  ?=(%push -.c)  ~
  (turn (shrink-atom:gen v.c) |=(v=@ [%push v]))
::
++  norn
  ^-  (norn:gen (list cmd))
  (cook:gen (list-of:gen 0 40 command) repair)
::
++  alts
  %+  alts-of:gen  (list cmd)
  (shrink-keep:gen valid (shrink-list:gen shrink-cmd))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
