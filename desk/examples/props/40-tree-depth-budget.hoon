/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  Size as depth: a tree norn that gives each child the whole budget
  ::  less one. Size bounds the depth, but each level can double the nodes,
  ::  so a tree can hold up to 2^size - 1 of them, and cost grows
  ::  exponentially with size-max. Passing size unchanged would never stop
  ::  at all. 41-tree-divided-budget divides the budget instead.
  ::
  ::  The law is that mirroring twice changes nothing; the tables record
  ::  each tree's depth and its node count, rounded up to a power of two.
  ::
+$  tree  $@(~ [n=@ud l=tree r=tree])
::
++  mirror
  |=  t=tree
  ^-  tree
  ?~  t  ~
  [n.t $(t r.t) $(t l.t)]
::
++  depth
  |=  t=tree
  ^-  @ud
  ?~  t  0
  +((max $(t l.t) $(t r.t)))
::
++  nodes
  |=  t=tree
  ^-  @ud
  ?~  t  0
  +((add $(t l.t) $(t r.t)))
::
++  bucket
  ::  The node count rounded up to a power of two, as text.
  |=  count=@ud
  ^-  @t
  ?:  =(0 count)  '0'
  (crip "up to {(a-co:co (bex (xeb (dec count))))}")
::
++  fate
  |=  raw=*
  ^-  report:prop
  =/  t  ;;(tree raw)
  %^  tabulate:prop  'depth'  ~[(scot %ud (depth t))]
  %^  tabulate:prop  'nodes'  ~[(bucket (nodes t))]
  (same:prop !>(t) !>((mirror (mirror t))))
::
++  norn
  ::  A leaf with chance 1/4, or at size 0; otherwise two children, each
  ::  at size - 1.
  |=  [size=@ud rng=_og]
  ^-  tree
  ?:  =(0 size)  ~
  =^  leaf  rng  (rads:rng 4)
  ?:  =(0 leaf)  ~
  =^  value  rng  (rads:rng 100)
  =/  [one=_og two=_og]  (split:gen rng)
  [value $(size (dec size), rng one) $(size (dec size), rng two)]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100, size-max 12)]
--
