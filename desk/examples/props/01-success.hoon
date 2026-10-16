/+  engine=quiz-engine
|%
  ::  Increment then decrement is an identity on unsigned atoms.
  ::
::
++  fate
  |=  value=@ud
  =(value (dec +(value)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
