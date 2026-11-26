/+  engine=quiz-engine
|%
  ::  Seed 0v123 produces 541; default shrinking reaches 501 in this example.
  ::
::
++  fate
  |=  value=@ud
  (lte value 500)
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  (add 501 (rad:rng 64))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
