/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  Dependent shrinking. The sample is a list with a seed; the fate
  ::  regenerates an index into the list from that seed. As the list
  ::  shrinks, the index is rebuilt for the shorter list, so every shrink
  ::  candidate stays valid and never indexes past the end.
  ::
  ::  The claim, deliberately false: the chosen element is never the last.
  ::
::
++  index
  |=  items=(list @ud)
  (range:gen 0 (dec (lent items)))
::
++  fate
  |=  [items=* seed=@uv size=@ud]
  ^-  ?(? %drop)
  =/  items  ;;((list @ud) items)
  ?~  items  %drop
  =/  at  (regen:gen index `(list @ud)`items seed size)
  (lth at (dec (lent items)))
::
++  norn
  ^-  $-([@ud _og] [(list @ud) @uv @ud])
  (seeded:gen (list-of:gen 0 10 (range:gen 0 99)))
::
++  alts
  %+  alts-of:gen  ,[(list @ud) @uv @ud]
  (shrink-seeded:gen (shrink-list:gen shrink-atom:gen))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
