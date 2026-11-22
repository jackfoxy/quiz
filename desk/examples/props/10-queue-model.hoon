/+  engine=quiz-engine, quiz
|%
  ::  Model-based test: a two-list queue against a plain list model.
  ::
  ::  Each sample is a fresh command sequence. The fate folds the queue and
  ::  the model over it, comparing every reply and the full contents after
  ::  every command. Pop on an empty queue is total (it replies ~), so no
  ::  precondition is needed. The sample is typed `*` and molded inside the
  ::  fate to keep the vase small; tags render as numbers:
  ::  %push 1.752.397.168, %pop 7.368.560, %size 1.702.521.203.
  ::
::
+$  cmd  $%([%push v=@ud] [%pop ~] [%size ~])
::
+$  queue  [front=(list @ud) back=(list @ud)]
::
++  model-step
  ::  Reference: one list, front first.
  |=  [items=(list @ud) =cmd]
  ^-  [* (list @ud)]
  ?-  -.cmd
    %push  [~ (snoc items v.cmd)]
    %pop   ?~(items [~ ~] [`i.items t.items])
    %size  [(lent items) items]
  ==
::
++  queue-step
  ::  Pop from the front, push onto the back, reverse when front is empty.
  |=  [q=queue =cmd]
  ^-  [* queue]
  ?-    -.cmd
    %push  [~ q(back [v.cmd back.q])]
    %size  [(add (lent front.q) (lent back.q)) q]
  ::
      %pop
    =?  q  =(~ front.q)  [(flop back.q) ~]
    ?~  front.q  [~ q]
    [`i.front.q [t.front.q back.q]]
  ==
::
++  fate
  |=  cmds=*
  ^-  ?
  =/  cmds  ;;((list cmd) cmds)
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
  ::  Push, pop and size in ratio 3:2:1, values below 100. The stock list
  ::  norn gives at most xeb(size)-1 commands: 15 by sample 100.
  |=  [size=@ud rng=_og]
  ^-  (list cmd)
  =/  push=(norn:quiz cmd)
    |=  [size=@ud rng=_og]
    [%push (mod ((atom:norns:quiz @ud) size rng) 100)]
  =/  pop=(norn:quiz cmd)  ((const:norns:quiz cmd) [%pop ~])
  =/  count=(norn:quiz cmd)  ((const:norns:quiz cmd) [%size ~])
  =/  one=(norn:quiz cmd)
    ((freq:norns:quiz cmd) ~[[3 push] [2 pop] [1 count]])
  (((list:norns:quiz cmd) one) size rng)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
