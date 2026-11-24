/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  A fate that never returns for inputs above ten. Under on-timeout %fail
  ::  each hanging sample is a %timeout failure, and shrinking keeps only
  ::  hanging inputs, so the run ends at the smallest one, 11. Each hanging
  ::  candidate costs a full call limit, so ++within lowers this document's
  ::  limit to half a second, whatever the ship-wide Settings say.
  ::
::
++  fate
  |=  n=@ud
  ^-  ?(? %drop)
  ?:  (lth n 11)  &
  |-  ^-  ?(? %drop)
  $
::
++  norn
  (range:gen 0 99)
::
++  within  ~s0..8000
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20, on-timeout %fail)]
--
