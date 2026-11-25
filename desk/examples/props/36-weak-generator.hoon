/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  Example 16's insert law with a weak generator: arbitrary lists, of
  ::  which the fate discards every unsorted one. The run passes, but the
  ::  lists that survive are short. Preview 200 samples with verdicts and
  ::  read the generator summary: most samples are dropped, and almost
  ::  every kept one is labelled 'short'. 37-insert-generated fixes the
  ::  norn instead of the fate.
  ::
::
++  insert
  |=  [items=(list @ud) new=@ud]
  ^-  (list @ud)
  ?~  items  ~[new]
  ?:  (lte new i.items)  [new items]
  [i.items $(items t.items)]
::
++  sorted
  |=  items=(list @ud)
  ^-  ?
  ?~  items  &
  ?~  t.items  &
  &((lte i.items i.t.items) $(items t.items))
::
++  fate
  |=  [items=* new=@ud]
  ^-  report:prop
  =/  items  ;;((list @ud) items)
  ?.  (sorted items)  (lift:prop %drop)
  =/  got  (insert items new)
  %+  label:prop  ?:((lth (lent items) 3) 'short' 'long')
  (same:prop !>(got) !>((sort got lte)))
::
++  norn
  ^-  $-([@ud _og] [(list @ud) @ud])
  (pair:gen (list-of:gen 0 30 (range:gen 0 99)) (range:gen 0 99))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100, size-max 8)]
--
