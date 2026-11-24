/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  The search tree of 17-bst-delete-bug, with coordinated shrinking.
  ::  The deleted key must also be in the tree, so shrinking either copy
  ::  alone loses the failure. shrink-equal views the sample as one list,
  ::  the deleted key first, and replaces every copy of a value at once, so
  ::  the run reaches a smaller tree than example 17's [~[12 0 13] 12].
  ::
::
+$  tree  $@(~ [key=@ud left=tree right=tree])
::
++  put
  |=  [t=tree k=@ud]
  ^-  tree
  ?~  t  [k ~ ~]
  ?:  =(k key.t)  t
  ?:  (lth k key.t)  t(left $(t left.t))
  t(right $(t right.t))
::
++  del
  |=  [t=tree k=@ud]
  ^-  tree
  ?~  t  ~
  ?:  (lth k key.t)  t(left $(t left.t))
  ?:  (gth k key.t)  t(right $(t right.t))
  ?~  left.t  right.t
  ?~  right.t  left.t
  ::  Bug: the right subtree is lost.
  left.t
::
++  keys
  |=  t=tree
  ^-  (list @ud)
  ?~  t  ~
  (weld $(t left.t) [key.t $(t right.t)])
::
++  fate
  |=  [items=* gone=@ud]
  ^-  ?
  =/  items  ;;((list @ud) items)
  =/  t  (roll items |=([k=@ud t=tree] (put t k)))
  =/  want  (skip ~(tap in (silt items)) |=(k=@ud =(k gone)))
  =((sort want lth) (keys (del t gone)))
::
++  norn
  ^-  $-([@ud _og] [(list @ud) @ud])
  (pair:gen (list-of:gen 0 12 (range:gen 0 19)) (range:gen 0 19))
::
++  alts
  %+  alts-of:gen  ,[(list @ud) @ud]
  %+  shrink-then:gen
    (shrink-pair:gen (shrink-list:gen shrink-atom:gen) shrink-atom:gen)
  %^  shrink-via:gen  join  split
  (shrink-equal:gen shrink-atom:gen)
::
++  join
  ::  The deleted key, then the tree's keys.
  |=  [items=(list @ud) gone=@ud]
  ^-  (list @ud)
  [gone items]
::
++  split
  |=  all=(list @ud)
  ^-  [(list @ud) @ud]
  ?~  all  [~ 0]
  [t.all i.all]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
