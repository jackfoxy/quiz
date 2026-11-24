/+  engine=quiz-engine
|%
  ::  Type-directed defaults. There is no ++norn and no ++alts: quiz-auto
  ::  reads the sample's type. `name` is an @t, so it is printable text;
  ::  `tags` is a list of @tas, so it is a list of valid terms. The claim,
  ::  deliberately false: a record never has more than two tags.
  ::
  ::  The default shrinker recognizes the list, deletes tags, empties the
  ::  name, and lowers each term toward %a, so the counterexample is three
  ::  tags of %a and an empty name.
  ::
::
++  fate
  |=  [name=@t tags=(list @tas)]
  ^-  ?
  (lte (lent tags) 2)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
