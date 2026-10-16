/+  engine=quiz-engine, quiz
|%
  ::  Adding an offset to each list element changes its sum by length*offset.
  ::
::
++  fate
  ::  Keep the vase type small; validate the generated list inside the gate.
  |=  [items=* offset=@ud]
  ^-  ?
  =/  items  ;;((list @ud) items)
  =/  shifted  (turn items |=(value=@ud (add value offset)))
  =/  expected  (add (roll items add) (mul (lent items) offset))
  =(expected (roll shifted add))
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  [(list @ud) @ud]
  =/  atoms=(norn:quiz @ud)  (atom:norns:quiz @ud)
  =/  lists=(norn:quiz (list @ud))  ((list:norns:quiz @ud) atoms)
  =/  pair  ((cell:norns:quiz (list @ud) @ud) lists atoms)
  (pair size rng)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
