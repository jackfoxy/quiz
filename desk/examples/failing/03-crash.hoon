/+  engine=quiz-engine
|%
  ::  Deliberately partial: decrementing zero crashes before comparison.
  ::
::
++  fate
  |=  value=@ud
  =(value +((dec value)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
