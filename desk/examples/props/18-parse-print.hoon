/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  Printing an atom with +scot and parsing it with +slav gives it back,
  ::  for decimal numbers, ships and knots. quiz-gen's aura generators make
  ::  valid values of each aura, which a raw atom generator would not.
  ::
::
++  fate
  ::  Spell the auras out: a mold such as `ship` from zuse would carry its
  ::  whole subject into the sample's type and exceed the sample-byte limit.
  |=  [number=@ud ship=@p name=@ta]
  ^-  report:prop
  %-  all:prop
  :~  (same:prop !>(number) !>((slav %ud (scot %ud number))))
      (same:prop !>(ship) !>((slav %p (scot %p ship))))
      (same:prop !>(name) !>((slav %ta (scot %ta name))))
  ==
::
++  norn
  ^-  $-([@ud _og] [@ud @p @ta])
  (trip:gen upto:gen ship:gen knot:gen)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
