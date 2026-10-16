/+  engine=quiz-engine
|%
  ::  Shrink even positive inputs by two; never leave that semantic domain.
  ::
::
++  fate
  |=  value=@ud
  ?>  &(=(0 (mod value 2)) (gth value 0))
  (lte value 500)
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  (mul 2 (add 251 (rad:rng 32)))
::
++  alts
  |=  sample=vase
  ^-  (list vase)
  =/  value  !<(@ud sample)
  ?:  (lte value 2)  ~
  ~[sample(q (sub value 2))]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
