/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  Inner-value shrinking. The sample is a length bound with a seed; the
  ::  fate regenerates a list of at most that many values from the seed.
  ::  The claim, deliberately false: every value is below 90.
  ::
  ::  ++dep bundles the parts with dependent:gen: molds for the bound and
  ::  the list, the bound's generator and shrinker, ++values, and the
  ::  list's shrinker. Its shrinker first lowers the bound, rebuilding the
  ::  list each time. Once the bound cannot drop, it shrinks the list
  ::  itself, pinned in the sample's last field: chunks are deleted and
  ::  values lowered until one value of 90 is left. 20-dependent spells
  ::  the same parts out with seeded and shrink-seeded.
  ::
::
++  values
  |=  bound=@ud
  (list-of:gen 1 bound (range:gen 0 99))
::
++  dep
  %:  dependent:gen  @ud  (list @ud)
    (range:gen 1 20)
    (shrink-toward:gen 1)
    values
    (shrink-list:gen shrink-atom:gen)
  ==
::
++  fate
  |=  raw=sample:dep
  ^-  ?
  =/  [bound=@ud items=(list @ud)]  (both:dep raw)
  (levy items (curr lth 90))
::
++  norn  norn:dep
::
++  alts  alts:dep
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
