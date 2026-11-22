/+  engine=quiz-engine, prop=quiz-prop
|%
  ::  Halving then doubling loses an odd remainder. The report shows the
  ::  expected and actual values, rendered with their types, and a note.
  ::
::
++  fate
  |=  value=@ud
  ^-  report:prop
  %+  note:prop  'halving then doubling should give the value back'
  (same:prop !>(value) !>((mul 2 (div value 2))))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
