/+  engine=quiz-engine
|%
  ::  Generate the positive domain directly instead of discarding zero.
  ::
::
++  fate
  |=  value=@ud
  =(value +((dec value)))
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  +((rad:rng size))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
