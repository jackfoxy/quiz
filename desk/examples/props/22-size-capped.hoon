/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  A quadratic insertion sort agrees with +sort. Each list is as long as
  ::  the run's current size, which uncapped passes 60,000 by the hundredth
  ::  sample: lists that large outgrow the default sample-bytes limit, and
  ::  the quadratic sort slows with every sample. size-max 30 keeps every
  ::  list short.
  ::
::
++  fate
  ::  The sample is typed `*`: a recursive sample type would carry the
  ::  document's subject into every sample. See limitations.md.
  |=  raw=*
  =/  items  ;;((list @ud) raw)
  =((insertion items) (sort items lte))
::
++  insertion
  ::  Insert each item after the sorted prefix not larger than it.
  |=  items=(list @ud)
  ^-  (list @ud)
  =|  done=(list @ud)
  |-
  ?~  items  done
  =/  [low=(list @ud) high=(list @ud)]
    (skid done |=(n=@ud (lte n i.items)))
  $(items t.items, done (weld low [i.items high]))
::
++  norn
  (sized:gen |=(n=@ud (vector:gen n upto:gen)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(size-max 30)]
--
