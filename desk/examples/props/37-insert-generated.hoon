/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  36-weak-generator repaired: the norn makes sorted lists directly, so
  ::  nothing is dropped and long lists are common. Preview it beside 36 and
  ::  compare the generator summaries; ++cover now holds that claim.
  ::
::
++  insert
  |=  [items=(list @ud) new=@ud]
  ^-  (list @ud)
  ?~  items  ~[new]
  ?:  (lte new i.items)  [new items]
  [i.items $(items t.items)]
::
++  fate
  |=  [items=* new=@ud]
  ^-  report:prop
  =/  items  ;;((list @ud) items)
  =/  got  (insert items new)
  %+  label:prop  ?:((lth (lent items) 3) 'short' 'long')
  (same:prop !>(got) !>((sort got lte)))
::
++  norn
  ^-  $-([@ud _og] [(list @ud) @ud])
  (pair:gen (sorted:gen @ud 0 30 (range:gen 0 99) lte) (range:gen 0 99))
::
++  cover  [%check ~[['long' 50]]]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100, size-max 8)]
--
