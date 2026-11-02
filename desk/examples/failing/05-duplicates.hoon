/+  engine=quiz-engine, quiz
|%
  ::  A constant generator cannot supply two distinct accepted samples.
  ::
::
++  fate
  |=  value=@ud
  =(value (dec +(value)))
::
++  norn
  ((const:norns:quiz @ud) 7)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 2, attempts-max 10, duplicates-max 3)]
--
