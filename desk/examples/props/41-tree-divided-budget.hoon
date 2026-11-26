/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  Size as a budget: each node spends one unit and divides the rest
  ::  between its children at random, so a tree has at most size nodes
  ::  and cost grows with size-max, not exponentially. Its depth stays near
  ::  that of a random search tree. Compare 40-tree-depth-budget, which
  ::  gives each child nearly the whole budget.
  ::
  ::  The law and tables are 40's: mirroring twice changes nothing; depth,
  ::  and node count rounded up to a power of two.
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
  ::  A leaf with chance 1/4, or at size 0; otherwise a node that keeps
  ::  one unit and gives its children a random split of the rest.
  |=  [size=@ud rng=_og]
  ^-  tree
  ?:  =(0 size)  ~
  =^  leaf  rng  (rads:rng 4)
  ?:  =(0 leaf)  ~
  =^  value  rng  (rads:rng 100)
  =/  rest  (dec size)
  =^  left  rng  (rads:rng +(rest))
  =/  [one=_og two=_og]  (split:gen rng)
  [value $(size left, rng one) $(size (sub rest left), rng two)]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100, size-max 12)]
--
