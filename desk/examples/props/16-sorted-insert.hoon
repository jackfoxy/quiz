/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  Inserting into a sorted list keeps it sorted and adds the value.
  ::  quiz-gen builds sorted lists directly; quiz-prop labels where the value
  ::  landed, so the run shows that every position was exercised. ++alts
  ::  shrinks the list and the value, so Find examples for each label
  ::  reaches the smallest insert at each position.
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
  =/  place=@t
    ?~  items  'empty'
    ?:  (lte new i.items)  'front'
    ?:  (gth new (rear items))  'end'
    'middle'
  %+  label:prop  place
  %-  all:prop
  :~  (same:prop !>(got) !>((sort got lte)))
      (same:prop !>(+((lent items))) !>((lent got)))
  ==
::
++  norn
  ^-  $-([@ud _og] [(list @ud) @ud])
  (pair:gen (sorted:gen @ud 0 30 (range:gen 0 99) lte) (range:gen 0 99))
::
++  alts
  ::  A candidate whose list is unsorted fails the law; a run never shrinks
  ::  a pass, and a search rejects it.
  %+  alts-of:gen  ,[(list @ud) @ud]
  (shrink-pair:gen (shrink-list:gen shrink-atom:gen) shrink-atom:gen)
::
++  cover  [%check ~[['front' 5] ['middle' 20] ['end' 5]]]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
