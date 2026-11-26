/+  engine=quiz-engine, quiz, prop=quiz-prop, gen=quiz-gen
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
  ::  Labels mark the interesting cases: a pop on an empty queue, and a pop
  ::  that refills the front from the back. ++alts deletes commands and
  ::  shrinks pushed values, so Find examples for each label reaches the
  ::  smallest sequence that shows each case.
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
  ^-  report:prop
  =/  cmds  ;;((list cmd) cmds)
  =/  items=(list @ud)  ~
  =/  q=queue  [~ ~]
  =/  [empty=? refill=?]  [| |]
  |-
  ?~  cmds
    %^  classify:prop  empty  'empty-pop'
    (classify:prop refill 'refill' &)
  =/  popping  ?=(%pop -.i.cmds)
  =?  empty  &(popping =(~ items))  &
  =?  refill  &(popping =(~ front.q) !=(~ back.q))  &
  =/  want  (model-step items i.cmds)
  =/  got  (queue-step q i.cmds)
  ?.  =(-.want -.got)  (lift:prop |)
  ?.  =(+.want (weld front.+.got (flop back.+.got)))  (lift:prop |)
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
++  alts
  ::  Delete commands, then shrink one pushed value toward zero.
  %+  alts-of:gen  ,(list cmd)
  %-  shrink-list:gen
  |=  c=cmd
  ^-  (list cmd)
  ?.  ?=(%push -.c)  ~
  (turn (shrink-atom:gen v.c) |=(v=@ud [%push v]))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
