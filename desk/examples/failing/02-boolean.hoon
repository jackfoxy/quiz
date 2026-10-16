/+  engine=quiz-engine
|%
  ::  Deliberately false: integer division by two loses an odd remainder.
  ::
::
++  fate
  |=  value=@ud
  =(value (mul 2 (div value 2)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
