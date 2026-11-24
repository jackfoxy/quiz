/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  Floating-point addition is not associative. The claim, deliberately
  ::  false: (a + b) + c equals a + (b + c) for every three doubles.
  ::
  ::  ++real starts with small whole numbers and fractions and grows with
  ::  size, so the first sums are exact and the property holds for a
  ::  while. Once a fraction such as 1/3 rounds, the two orders differ.
  ::  shrink-real moves each value toward zero, toward a whole number,
  ::  and toward fewer decimal places, so the shrunk triple is short.
  ::
::
++  fate
  |=  [a=@rd b=@rd c=@rd]
  ^-  ?
  (equ:rd (add:rd (add:rd a b) c) (add:rd a (add:rd b c)))
::
++  norn
  ^-  $-([@ud _og] [@rd @rd @rd])
  (trip:gen real:gen real:gen real:gen)
::
++  alts
  ::  A triple is [a [b c]]: shrink a, then the pair [b c].
  %+  alts-of:gen  ,[@rd @rd @rd]
  %+  shrink-pair:gen  shrink-real:gen
  (shrink-pair:gen shrink-real:gen shrink-real:gen)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
