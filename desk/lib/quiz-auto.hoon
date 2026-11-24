/+  legacy=quiz, gen=quiz-gen
|%
  ::  Type-directed defaults for documents with no ++norn or no ++alts.
  ::
  ::  ++fill makes a sample from the fate's sample type and ++sink shrinks
  ::  one. Both follow the frozen library's rules, and ++fill draws from
  ::  the RNG exactly as legacy fill does, so a sample of @ud, loobeans,
  ::  cells, faces and plain unions is unchanged. They differ in three
  ::  places:
  ::
  ::  - atoms whose aura has a meaning get valid values from quiz-gen:
  ::    text, ships, dates, spans, signed numbers, floats;
  ::  - a list, unit, set or map is recognized from its type and built and
  ::    shrunk as one, with quiz-gen's container generators and shrinkers;
  ::  - ++sink shrinks a union through the branch its value is in, and a
  ::    float or text through quiz-gen's shrinkers, where legacy offers
  ::    nothing or a raw atom.
  ::
  ::  Recognition reads the type only: a hold is expanded, never molded,
  ::  because molding a recursive type's subject can take minutes.
  ::
  ::  Usage, in a document that wants the default shrinker plus its own:
  ::    ++  alts  |=(v=vase (weld (sink:auto v) (custom v)))
  ::
+$  shape
  $%  [%list item=type]
      [%unit item=type]
      [%set item=type]
      [%map key=type value=type]
  ==
::
++  container-max
  ::  Most elements a default list, set or map holds.
  20
::
++  fill
  ::  A sample of the vase's type. Legacy rules and RNG use, except for
  ::  meaningful auras and recognized containers. A type it cannot fill,
  ::  such as a core, is returned unchanged, as legacy does.
  |=  [size=@ud rng=_og sax=vase]
  ^-  vase
  =/  new-rng  +:(rads:rng 1)
  =/  t  p.sax
  ?@  t
    ::  Legacy's own fill, so the sample keeps legacy's type for `*`.
    ?.  ?=(%noun t)  sax
    (~(fill quiz:legacy [size rng]) sax)
  ?-    -.t
      %atom
    ?^  q.t  sax(q u.q.t)
    =/  special  (atom-by-aura p.t size new-rng)
    sax(q ?^(special u.special (rad:new-rng size)))
  ::
      %cell
    =/  [one=_og two=_og]  (split-rng:legacy rng)
    =/  head=vase  $(rng one, sax [p.t ~])
    =/  tail=vase  $(rng two, sax [q.t ~])
    (slop head tail)
  ::
      %core  sax
      %face  sax(q q:$(sax [q.t q.sax]))
      %hint  sax(q q:$(sax [q.t q.sax]))
  ::
      %fork
    =/  types  ~(tap in p.t)
    =^  pick  new-rng  (rads:new-rng (lent types))
    $(rng new-rng, sax [(snag pick types) q.sax])
  ::
      %hold
    =/  open  (expand t)
    =/  found  (shape-of t open)
    ?~  found  $(sax [open q.sax])
    sax(q (fill-shape u.found size new-rng))
  ==
::
++  sink
  ::  Smaller samples, each with the sample's type. Usable as ++alts.
  |=  sax=vase
  ^-  (list vase)
  (turn (smaller p.sax q.sax) |=(n=* sax(q n)))
::
++  smaller
  ::  Smaller nouns of type `t` than `n`, simplest first.
  |=  [t=type n=*]
  ^-  (list *)
  ?@  t
    ?.  ?=(%noun t)  ~
    ?^  n  ~[-.n +.n]
    ?:  =(0 n)  ~
    ~[(div n 2) (dec n)]
  ?-    -.t
      %atom
    ?^  q.t  ~
    ?^  n  ~
    (atom-smaller p.t n)
  ::
      %cell
    ?@  n  ~
    ::  Legacy order: each left candidate with each right one, then the
    ::  left value with each right one; the left alone only when the right
    ::  has none.
    =/  lefts=(list *)  $(t p.t, n -.n)
    =/  rights=(list *)  $(t q.t, n +.n)
    =/  right  +.n
    =/  left  -.n
    ::  Test without narrowing: a narrowed list breaks the wet +weld.
    ?:  =(~ rights)  (turn lefts |=(l=* [l right]))
    =/  both=(list (list *))
      (turn lefts |=(l=* `(list *)`(turn rights |=(r=* [l r]))))
    =/  mixed=(list *)  (zing both)
    =/  kept=(list *)  (turn rights |=(r=* [left r]))
    (weld mixed kept)
  ::
      %core  ~
      %face  $(t q.t)
      %hint  $(t q.t)
  ::
      %fork
    =/  types  ~(tap in p.t)
    |-  ^-  (list *)
    ?~  types  ~
    ?:  (shallow i.types n)  ^$(t i.types)
    $(types t.types)
  ::
      %hold
    =/  open  (expand t)
    =/  found  (shape-of t open)
    ?~  found  $(t open)
    (shape-smaller u.found n)
  ==
::
::  +|  Shapes
::
++  expand
  ::  One hold, expanded as legacy fill expands it.
  |=  t=type
  ^-  type
  ?.  ?=([%hold *] t)  t
  p:(~(mint ut p.t) %noun q.t)
::
++  shape-of
  ::  A list, unit, set or map, from a hold and its expansion: a fork of
  ::  null and one cell with that container's faces, whose recursive part
  ::  is the same hold again.
  |=  [held=type open=type]
  ^-  (unit shape)
  ?.  ?=([%fork *] open)  ~
  =/  members  ~(tap in p.open)
  ?.  ?=([* * ~] members)  ~
  =/  null=type  [%atom %n `0]
  =/  cell=type
    ?:  =(null i.members)  i.t.members
    ?:  =(null i.t.members)  i.members
    %void
  ?:  ?=([%cell [%face %i *] [%face %t [%hold *]]] cell)
    =/  rest  q.q.cell
    ?.  |(=(rest held) =((expand rest) open))  ~
    `[%list q.p.cell]
  ?:  &(?=([%cell * [%face %u *]] cell) =(null p.cell))
    `[%unit q.q.cell]
  ?.  ?=([%cell [%face %n *] [%cell [%face %l *] [%face %r *]]] cell)  ~
  ?.  =(q.p.q.cell q.q.q.cell)  ~
  =/  item  q.p.cell
  =/  pair  (open-all item)
  ?:  ?=([%cell [%face %p *] [%face %q *]] pair)
    `[%map q.p.pair q.q.pair]
  `[%set item]
::
++  open-all
  ::  Expand holds and drop hints until neither is left.
  |=  t=type
  ^-  type
  ?:  ?=([%hold *] t)  $(t (expand t))
  ?:  ?=([%hint *] t)  $(t q.t)
  t
::
++  fill-shape
  ::  A container's value; elements are filled from their own types.
  |=  [=shape size=@ud rng=_og]
  ^-  *
  =/  norn-for
    |=  t=type
    |=([size=@ud rng=_og] `*`q:(fill size rng [t ~]))
  ?-    -.shape
      %list  ((list-of:gen 0 container-max (norn-for item.shape)) size rng)
      %unit  ((unit-of:gen (norn-for item.shape)) size rng)
  ::
      %set
    =/  items=(list *)
      ((list-of:gen 0 container-max (norn-for item.shape)) size rng)
    (silt items)
  ::
      %map
    =/  entry  (pair:gen (norn-for key.shape) (norn-for value.shape))
    =/  entries=(list [* *])
      ((list-of:gen 0 container-max entry) size rng)
    (malt entries)
  ==
::
++  shape-smaller
  ::  A container's candidates, through quiz-gen's shrinkers, with each
  ::  element shrunk by its own type.
  |=  [=shape n=*]
  ^-  (list *)
  ?-    -.shape
      %list
    =/  each=$-(* (list *))  |=(e=* (smaller item.shape e))
    ((shrink-list:gen each) ;;((list *) n))
  ::
      %unit
    ?@  n  ~
    =/  inner=(list *)  (smaller item.shape +.n)
    [~ (turn inner |=(v=* `(unit *)``v))]
  ::
      %set
    =/  each=$-(* (list *))  |=(e=* (smaller item.shape e))
    =/  lists=(list (list *))  ((shrink-list:gen each) ~(tap in ;;((set *) n)))
    (turn lists |=(l=(list *) (silt l)))
  ::
      %map
    ::  A plain gate, not a $- cast: shrink-list types its list from the
    ::  gate's sample, which a $- cast would widen to *.
    =/  each
      |=  [k=* v=*]
      ^-  (list [* *])
      =/  keys=(list *)  (smaller key.shape k)
      =/  vals=(list *)  (smaller value.shape v)
      (weld (turn keys |=(c=* [c v])) (turn vals |=(c=* [k c])))
    =/  entries=(list [* *])  ~(tap by ;;((map * *) n))
    =/  lists=(list (list [* *]))  ((shrink-list:gen each) entries)
    (turn lists |=(l=(list [* *]) (malt l)))
  ==
::
++  shallow
  ::  Could `n` be of type `t`? Atoms, constants and cell heads are
  ::  checked a few levels down; deeper parts are assumed to fit.
  |=  [t=type n=*]
  ^-  ?
  =|  depth=@ud
  |-  ^-  ?
  ?:  (gth depth 4)  &
  ?@  t  =(%noun t)
  ?-    -.t
      %atom  &(?=(@ n) ?~(q.t & =(n u.q.t)))
      %cell  ?&(?=(^ n) $(t p.t, n -.n, depth +(depth)))
      %core  |
      %face  $(t q.t)
      %hint  $(t q.t)
      %hold  $(t (expand t), depth +(depth))
  ::
      %fork
    =/  types  ~(tap in p.t)
    |-  ^-  ?
    ?~  types  |
    ?:  ^$(t i.types, depth +(depth))  &
    $(types t.types)
  ==
::
::  +|  Atoms
::
++  atom-by-aura
  ::  A valid value for an aura with a meaning; ~ keeps legacy's draw.
  |=  [aura=@tas size=@ud rng=_og]
  ^-  (unit @)
  ?:  =('tD' aura)  `(add 32 (rad:rng 95))
  ?+  aura  ~
    %t    `(cord:gen size rng)
    %ta   `(knot:gen size rng)
    %tas  `(term:gen size rng)
    %p    `(ship:gen size rng)
    %da   `(date:gen size rng)
    %dr   `(span:gen size rng)
    %s    `(signed:gen size rng)
    %sd   `(signed:gen size rng)
    %rd   `(real:gen size rng)
    %rs   `(real-single:gen size rng)
  ==
::
++  atom-smaller
  ::  Smaller atoms that keep the aura's meaning; others as legacy.
  |=  [aura=@tas n=@]
  ^-  (list @)
  ?:  =('tD' aura)  ?:((gth n 'a') ~['a'] ~)
  ?+  aura  ?:(=(0 n) ~ ~[(div n 2) (dec n)])
    %t    (text-smaller n)
    %ta   (skim (text-smaller n) (sane %ta))
    %tas  (skim (text-smaller n) |=(c=@ &(!=(0 c) ((sane %tas) c))))
    %p    (shrink-atom:gen n)
    %s    (signed-smaller n)
    %sd   (signed-smaller n)
    %rd   (shrink-real:gen n)
    %rs   (shrink-real-single:gen n)
  ==
::
++  text-smaller
  ::  Fewer characters, then single characters above 'a' as 'a'. Both are
  ::  lighter: a shorter cord is a smaller atom.
  |=  text=@t
  ^-  (list @t)
  =/  chars=(list @tD)  (trip text)
  =/  each  |=(c=@tD ^-((list @tD) ?:((gth c 'a') ~['a'] ~)))
  =/  tapes=(list (list @tD))  ((shrink-list:gen each) chars)
  (turn tapes crip)
::
++  signed-smaller
  ::  Smaller magnitudes with the same sign: lighter in @s's encoding.
  |=  n=@s
  ^-  (list @s)
  =/  [plus=? size=@]  (old:si n)
  (turn (shrink-atom:gen size) |=(m=@ (new:si plus m)))
--
