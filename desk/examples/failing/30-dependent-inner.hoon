/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  Inner-value shrinking. The sample is a length bound with a seed; the
  ::  fate regenerates a list of at most that many values from the seed.
  ::  The claim, deliberately false: every value is below 90.
  ::
  ::  shrink-seeded first lowers the bound, rebuilding the list each time.
  ::  Once the bound cannot drop, it shrinks the list itself, pinned in the
  ::  sample's last field: chunks are deleted and values lowered until one
  ::  value of 90 is left.
  ::
::
++  values
  |=  bound=@ud
  (list-of:gen 1 bound (range:gen 0 99))
::
++  fate
  |=  [bound=@ud seed=@uv size=@ud pin=(unit (list @ud))]
  ^-  ?
  =/  items=(list @ud)  (regen:gen values bound seed size pin)
  (levy items (curr lth 90))
::
++  norn
  ^-  $-([@ud _og] [@ud @uv @ud (unit (list @ud))])
  (seeded:gen (range:gen 1 20))
::
++  alts
  %+  alts-of:gen  ,[@ud @uv @ud (unit (list @ud))]
  %^  shrink-seeded:gen  (shrink-toward:gen 1)  values
  (shrink-list:gen shrink-atom:gen)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
