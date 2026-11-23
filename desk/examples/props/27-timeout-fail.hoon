/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  A fate that never returns for inputs above ten. Under on-timeout %fail
  ::  each hanging sample is a %timeout failure, and shrinking keeps only
  ::  hanging inputs, so the run ends at the smallest one, 11. Each hanging
  ::  candidate costs a full call limit, so run this with a short one (the
  ::  browser test sets 2 s). Expected runtime: a few call limits.
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
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20, on-timeout %fail)]
--
