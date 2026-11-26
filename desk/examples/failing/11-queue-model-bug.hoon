/+  engine=quiz-engine
|%
  ::  Intentionally failing model-based test with a precondition.
  ::
  ::  The queue's pop is partial: popping an empty queue crashes, so the
  ::  norn only generates a pop while the model holds an item, and alts
  ::  only offers shorter sequences that keep that precondition. The bug:
  ::  when the front list is empty, pop forgets to reverse the back list
  ::  and returns the newest item. Tags render as numbers:
  ::  %push 1.752.397.168, %pop 7.368.560, %size 1.702.521.203.
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
++  valid
  ::  Pop only while the queue holds an item.
  |=  cmds=(list cmd)
  ^-  ?
  =/  held  0
  |-
  ?~  cmds  &
  ?-  -.i.cmds
    %push  $(cmds t.cmds, held +(held))
    %size  $(cmds t.cmds)
    %pop   ?:(=(0 held) | $(cmds t.cmds, held (dec held)))
  ==
::
++  fate
  ::  A replayed or hand-written sample can still break the precondition.
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
++  norn
  ::  Up to 40 commands. A pop is drawn only while an item is held.
  |=  [size=@ud rng=_og]
  ^-  (list cmd)
  =^  left  rng  (rads:rng (min 40 +(size)))
  =|  out=(list cmd)
  =/  held  0
  |-
  ?:  =(0 left)  (flop out)
  =^  roll  rng  (rads:rng 3)
  ?:  &(=(0 roll) (gth held 0))
    $(left (dec left), out [[%pop ~] out], held (dec held))
  ?:  =(1 roll)
    $(left (dec left), out [[%size ~] out])
  =^  value  rng  (rads:rng 100)
  $(left (dec left), out [[%push value] out], held +(held))
::
++  alts
  ::  Delete one command, then halve or zero one pushed value; keep only
  ::  candidates that satisfy the precondition. Each weighs less.
  |=  sample=vase
  ^-  (list vase)
  =/  cmds  ;;((list cmd) q.sample)
  =/  spots=(list @ud)  (gulf 1 (lent cmds))
  =/  deleted=(list (list cmd))
    (turn spots |=(i=@ud `(list cmd)`(oust [(dec i) 1] cmds)))
  =/  smaller=(list (list cmd))
    %-  zing
    %+  turn  spots
    |=  i=@ud
    ^-  (list (list cmd))
    =/  c=cmd  (snag (dec i) cmds)
    ?.  ?=(%push -.c)  ~
    ?:  =(0 v.c)  ~
    =/  before=(list cmd)  (scag (dec i) cmds)
    =/  after=(list cmd)  (slag i cmds)
    =/  zero=(list cmd)  (weld before `(list cmd)`[[%push 0] after])
    ?:  =(1 v.c)  ~[zero]
    =/  half=(list cmd)
      (weld before `(list cmd)`[[%push (div v.c 2)] after])
    ~[half zero]
  =/  kept=(list (list cmd))  (skim (weld deleted smaller) valid)
  (turn kept |=(c=(list cmd) sample(q c)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
