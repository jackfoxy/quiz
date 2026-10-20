/+  engine=quiz-engine
|%
  ::  Exclude zero from the partial decrement/increment identity.
  ::
::
++  fate
  |=  value=@ud
  ?:  =(value 0)  %drop
  =(value +((dec value)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
