/+  engine=quiz-engine, prop=quiz-prop
|%
  ::  A fair coin lands heads about half the time; ++cover asks for at
  ::  least 40 percent heads. With %confident the run does not judge that
  ::  at 100 checks: the Wilson bounds cannot yet tell 50 from 40, so it
  ::  goes on to 200, 400 and so on until the lower bound reaches 90 percent
  ::  of the required share. Only two samples exist, so %allow evaluates
  ::  repeats.
  ::
::
++  fate
  |=  heads=?
  (classify:prop heads 'heads' &)
::
++  cover  [%confident ~[['heads' 40]]]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(duplicates %allow)]
--
