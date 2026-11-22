/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  A binary search tree against a sorted-set model. Deleting a key whose
  ::  node has two children wrongly keeps only the left subtree.
  ::
  ::  The sample is a key list and a key to delete. quiz-gen shrinks the
  ::  list by deleting chunks, then shrinks keys and the deleted key toward
  ::  zero, to a three-key tree whose root is deleted.
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
  (shrink-pair:gen (shrink-list:gen shrink-atom:gen) shrink-atom:gen)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
