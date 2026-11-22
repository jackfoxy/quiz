/+  quiz
|%
  ::  Reusable generators and shrinkers for app property documents.
  ::
  ::  Generators are norns, gates on [size rng]. Every generator here is
  ::  total in size: size 0 behaves as size 1. An empty choice crashes with
  ::  a named ~| message, which a run reports as a generation %error.
  ::
  ::  Shrinkers are typed gates from a value to smaller candidates, simplest
  ::  first. Each candidate weighs strictly less than its input, except
  ::  where an arm says otherwise, so the engine never discards one for
  ::  failing to make progress. Unlike QuickCheck, equal-weight candidates
  ::  such as permutations are never offered.
  ::
  ::  ++alts-of adapts a typed shrinker to a document's ++alts. It molds the
  ::  sample's noun, so it also works for samples typed `*`.
  ::
  ::  Usage:
  ::    /+  gen=quiz-gen
  ::    ++  norn  (list-of:gen 0 40 (range:gen 0 99))
  ::    ++  alts  (alts-of:gen (list @ud) (shrink-list:gen shrink-atom:gen))
  ::
++  norn  |$  [item]  $-([@ud _og] item)
++  shrink  |$  [item]  $-(item (list item))
::
++  split
  ::  Two independent streams.
  |=  rng=_og
  ^-  [_og _og]
  (split-rng:quiz rng)
::
::  +|  Atoms
::
++  range
  ::  Uniform in [low, high], whatever the size.
  |=  [low=@ud high=@ud]
  ~|  [%range-empty low high]
  ?>  (lte low high)
  ^-  (norn @ud)
  |=  [size=@ud rng=_og]
  (add low (rad:rng +((sub high low))))
::
++  upto
  ::  Uniform in [0, size].
  ^-  (norn @ud)
  |=  [size=@ud rng=_og]
  (rad:rng +(size))
::
++  signed
  ::  Uniform magnitude in [0, size], either sign.
  ^-  (norn @sd)
  |=  [size=@ud rng=_og]
  =^  sign  rng  (rads:rng 2)
  (new:si =(0 sign) (rad:rng +(size)))
::
++  ship
  ::  A galaxy, star or planet, each class equally likely.
  ^-  (norn @p)
  |=  [size=@ud rng=_og]
  =^  class  rng  (rads:rng 3)
  (rad:rng (bex (bex (add 3 class))))
::
++  date
  ::  Within size seconds either side of ~2000.1.1. No ambient time.
  ^-  (norn @da)
  |=  [size=@ud rng=_og]
  =/  offset  (mul ~s1 (rad:rng +((mul 2 size))))
  (sub (add ~2000.1.1 offset) (mul ~s1 size))
::
++  span
  ::  Whole seconds in [0, size].
  ^-  (norn @dr)
  |=  [size=@ud rng=_og]
  (mul ~s1 (rad:rng +(size)))
::
++  real
  ::  Any finite double, from random bits; size is ignored.
  ^-  (norn @rd)
  |=  [size=@ud rng=_og]
  =/  bits  (raw:rng 64)
  ::  An all-ones exponent is infinity or NaN; clear its lowest bit.
  =/  exponent  (cut 0 [52 11] bits)
  ?.  =(exponent 0x7ff)  bits
  (dis bits (not 0 64 (bex 52)))
::
++  real-single
  ::  Any finite single, from random bits; size is ignored.
  ^-  (norn @rs)
  |=  [size=@ud rng=_og]
  =/  bits  (raw:rng 32)
  =/  exponent  (cut 0 [23 8] bits)
  ?.  =(exponent 0xff)  bits
  (dis bits (not 0 32 (bex 23)))
::
++  text-max
  ::  Longest generated text. The engine's size grows without bound, past
  ::  50,000 by the 100th sample, so text length is capped as well.
  32
::
++  chars
  ::  Up to size characters, at most text-max, from the given alphabet.
  |=  alphabet=tape
  ~|  %chars-empty
  ?<  =(~ alphabet)
  ^-  (norn tape)
  =/  count  (lent alphabet)
  |=  [size=@ud rng=_og]
  =^  len  rng  (rads:rng +((min size text-max)))
  =|  out=tape
  |-
  ?:  =(0 len)  out
  =^  pick  rng  (rads:rng count)
  $(len (dec len), out [(snag pick alphabet) out])
::
++  printable
  ::  Printable ASCII, space to tilde.
  ^-  tape
  (turn (gulf 32 126) |=(c=@ `@tD`c))
::
++  cord
  ::  Printable ASCII text of at most size bytes, and at most text-max.
  ^-  (norn @t)
  |=  [size=@ud rng=_og]
  (crip ((chars printable) size rng))
::
++  knot
  ::  A valid @ta: lowercase, digits, `-`, `.`, `~` and `_`.
  ^-  (norn @ta)
  |=  [size=@ud rng=_og]
  =/  alphabet  (weld "abcdefghijklmnopqrstuvwxyz0123456789" "-._~")
  (crip ((chars alphabet) size rng))
::
++  term
  ::  A valid nonempty @tas: a lowercase letter, then letters, digits and
  ::  single hyphens, never ending in a hyphen.
  ^-  (norn @tas)
  |=  [size=@ud rng=_og]
  =/  letters  "abcdefghijklmnopqrstuvwxyz"
  =/  [one=_og two=_og]  (split rng)
  =/  head  (snag (rad:one 26) letters)
  =/  rest  ((chars (weld letters "0123456789-")) size two)
  =/  text=tape  [head rest]
  ::  Collapse hyphen runs and drop a trailing hyphen.
  =/  clean
    |-  ^-  tape
    ?~  text  ~
    ?:  &(=('-' i.text) |(=(~ t.text) ?=([%'-' *] t.text)))
      $(text t.text)
    [i.text $(text t.text)]
  (crip clean)
::
::  +|  Choice
::
++  elements
  ::  Uniform over a nonempty list of values.
  |*  items=(list)
  ~|  %elements-empty
  ?<  =(~ items)
  ::  +homo widens a literal list's exact type to a general list.
  =/  pool  (homo items)
  =/  count  (lent pool)
  |=  [size=@ud rng=_og]
  (snag (rad:rng count) pool)
::
++  one-of
  ::  Uniform over a nonempty list of generators of one type.
  |*  gens=(list $-([@ud _og] *))
  ~|  %one-of-empty
  ?<  =(~ gens)
  =/  pool  (homo gens)
  =/  count  (lent pool)
  |=  [size=@ud rng=_og]
  =^  pick  rng  (rads:rng count)
  ((snag pick pool) size rng)
::
++  frequency
  ::  Weighted choice; the total weight must be positive.
  |*  pairs=(list [@ud $-([@ud _og] *)])
  =/  pool  (homo pairs)
  =/  total  (roll (turn pool head) add)
  ~|  %frequency-empty
  ?>  (gth total 0)
  |=  [size=@ud rng=_og]
  =^  pick  rng  (rads:rng total)
  =/  rest  pool
  |-
  ?~  rest  !!
  ?:  (lth pick -.i.rest)  (+.i.rest size rng)
  $(rest t.rest, pick (sub pick -.i.rest))
::
++  unit-of
  ::  ~ with chance 1/(size+2); otherwise a value.
  |*  item=$-([@ud _og] *)
  |=  [size=@ud rng=_og]
  =^  pick  rng  (rads:rng (add 2 size))
  ?:  =(0 pick)  ~
  `(item size rng)
::
::  +|  Containers
::
++  list-of
  ::  Length uniform in [low, top], where top is high capped at the larger
  ::  of low and size. Each element draws from its own split stream.
  |*  [low=@ud high=@ud item=$-([@ud _og] *)]
  ~|  [%list-of-range low high]
  ?>  (lte low high)
  |=  [size=@ud rng=_og]
  =/  top  (min high (max low size))
  =^  extra  rng  (rads:rng +((sub top low)))
  =/  len  (add low extra)
  =/  out  *(list _(item size rng))
  |-
  ?:  =(0 len)  out
  =/  [here=_og next=_og]  (split rng)
  $(len (dec len), rng next, out [(item size here) out])
::
++  nonempty
  |*  [high=@ud item=$-([@ud _og] *)]
  (list-of 1 (max 1 high) item)
::
++  vector
  ::  Exactly len elements.
  |*  [len=@ud item=$-([@ud _og] *)]
  (list-of len len item)
::
++  set-of
  ::  Up to high distinct elements of the given mold. The mold keeps +silt
  ::  off a wet element type.
  |*  [kind=mold high=@ud item=$-([@ud _og] *)]
  =/  make  (list-of 0 high item)
  |=  [size=@ud rng=_og]
  =/  items=(list kind)  (make size rng)
  (silt items)
::
++  map-of
  |*  $:  key-kind=mold  value-kind=mold  high=@ud
          key=$-([@ud _og] *)  value=$-([@ud _og] *)
      ==
  =/  make  (list-of 0 high (pair key value))
  |=  [size=@ud rng=_og]
  =/  items=(list [key-kind value-kind])  (make size rng)
  (malt items)
::
++  sublist
  ::  Each element kept with chance one half, order preserved.
  |*  items=(list)
  =/  pool  (homo items)
  |=  [size=@ud rng=_og]
  =/  rest  pool
  =/  out  `_pool`~
  |-
  ?~  rest  (flop out)
  =^  keep  rng  (rads:rng 2)
  $(rest t.rest, out ?:(=(0 keep) out [i.rest out]))
::
++  shuffle
  ::  A uniform permutation (Fisher–Yates).
  |*  items=(list)
  =/  pool  (homo items)
  |=  [size=@ud rng=_og]
  =/  rest  pool
  =/  out  `_pool`~
  |-
  ?~  rest  out
  =^  pick  rng  (rads:rng (lent rest))
  =/  chosen  (snag pick `_pool`rest)
  =/  left  `_pool`(oust [pick 1] `_pool`rest)
  $(rest left, out [chosen out])
::
++  sorted
  ::  A list-of of the given element mold, sorted by the given order. The
  ::  mold keeps +sort off a wet element type, which it cannot fuse.
  |*  [kind=mold low=@ud high=@ud item=$-([@ud _og] *) order=$-([* *] ?)]
  =/  make  (list-of low high item)
  |=  [size=@ud rng=_og]
  =/  items=(list kind)  (make size rng)
  (sort items order)
::
::  +|  Composition
::
++  pair
  |*  [a=$-([@ud _og] *) b=$-([@ud _og] *)]
  |=  [size=@ud rng=_og]
  =/  [one=_og two=_og]  (split rng)
  [(a size one) (b size two)]
::
++  trip
  |*  [a=$-([@ud _og] *) b=$-([@ud _og] *) c=$-([@ud _og] *)]
  |=  [size=@ud rng=_og]
  =/  [one=_og rest=_og]  (split rng)
  =/  [two=_og three=_og]  (split rest)
  [(a size one) (b size two) (c size three)]
::
++  cook
  ::  Map a function over a generator's output.
  |*  [item=$-([@ud _og] *) fun=$-(* *)]
  |=  [size=@ud rng=_og]
  (fun (item size rng))
::
++  bind
  ::  Dependent generation: the second generator depends on the first value.
  |*  [item=$-([@ud _og] *) next=$-(* $-([@ud _og] *))]
  |=  [size=@ud rng=_og]
  =/  [one=_og two=_og]  (split rng)
  ((next (item size one)) size two)
::
++  such-that
  ::  Retry with growing size until pred holds; crash after tries attempts.
  ::  Prefer constructing the domain directly when most values fail.
  |*  [item=$-([@ud _og] *) pred=$-(* ?) tries=@ud]
  |=  [size=@ud rng=_og]
  =/  left  tries
  |-
  ~|  [%such-that-gave-up tries]
  ?>  (gth left 0)
  =/  [here=_og next=_og]  (split rng)
  =/  value  (item size here)
  ?:  (pred value)  value
  $(left (dec left), rng next, size +(size))
::
++  seeded
  ::  For dependent shrinking: a value with a seed and size from which a
  ::  dependent value is regenerated by ++regen inside the fate.
  |*  item=$-([@ud _og] *)
  |=  [size=@ud rng=_og]
  =/  [one=_og two=_og]  (split rng)
  [value=(item size one) seed=`@uv`(raw:two 128) size=size]
::
++  regen
  ::  The dependent value for an outer value, from the stored seed.
  |*  [make=$-(* $-([@ud _og] *)) outer=* seed=@uv size=@ud]
  ((make outer) size ~(. og seed))
::
::  +|  Shrinkers
::
++  shrink-atom
  ::  Toward 0: 0, then n-n/2, n-n/4, ..., n-1.
  |=  n=@
  ^-  (list @)
  ?:  =(0 n)  ~
  =/  step  n
  =|  out=(list @)
  |-
  ?:  =(0 step)  (flop out)
  $(step (div step 2), out [(sub n step) out])
::
++  shrink-toward
  ::  Toward a floor: values below it are never offered.
  |=  floor=@
  |=  n=@
  ^-  (list @)
  ?:  (lte n floor)  ~
  (turn (shrink-atom (sub n floor)) |=(d=@ (add floor d)))
::
++  shrink-list
  ::  Delete chunks of n/1, n/2, ..., 1 elements, then shrink one element
  ::  with the element shrinker.
  |*  item=$-(* (list))
  |=  items=(list _+<.item)
  =/  whole  (lent items)
  =/  deletions  *(list _items)
  =.  deletions
    =/  chunk  whole
    |-
    ?:  =(0 chunk)  deletions
    =/  starts  (gulf 0 (dec (div whole chunk)))
    =/  cut-out
      %+  turn  starts
      |=  i=@ud
      =/  before  (scag (mul i chunk) items)
      `_items`(weld before (slag (mul +(i) chunk) items))
    $(chunk (div chunk 2), deletions (weld deletions cut-out))
  =/  edits  *(list _items)
  =.  edits
    =/  index  0
    |-
    ?:  =(index whole)  edits
    =/  before  (scag index items)
    =/  after  (slag +(index) items)
    =/  smaller  (item (snag index items))
    =/  made  (turn smaller |=(e=_+<.item `_items`(weld before [e after])))
    $(index +(index), edits (weld edits made))
  (weld deletions edits)
::
++  shrink-pair
  ::  Shrink the left, then the right.
  |*  [a=$-(* (list)) b=$-(* (list))]
  |=  [x=_+<.a y=_+<.b]
  %+  weld
    (turn (a x) |=(v=_+<.a [v y]))
  (turn (b y) |=(v=_+<.b [x v]))
::
++  shrink-unit
  ::  ~ first, then smaller inner values.
  |*  item=$-(* (list))
  |=  value=(unit _+<.item)
  ?~  value  ~
  [~ (turn (item u.value) |=(v=_+<.item `v))]
::
++  shrink-set
  ::  Through the element list. A treap may rebalance, so a candidate is not
  ::  guaranteed lighter; the engine discards any that is not.
  |*  item=$-(* (list))
  |=  items=(set _+<.item)
  (turn ((shrink-list item) ~(tap in items)) silt)
::
++  shrink-map
  |*  [key=$-(* (list)) value=$-(* (list))]
  |=  items=(map _+<.key _+<.value)
  (turn ((shrink-list (shrink-pair key value)) ~(tap by items)) malt)
::
++  shrink-via
  ::  Shrink through a representation: to, shrink, from.
  |*  [to=$-(* *) from=$-(* *) inner=$-(* (list))]
  |=  value=_+<.to
  (turn (inner (to value)) from)
::
++  shrink-keep
  ::  Only candidates satisfying an invariant or precondition.
  |*  [pred=$-(* ?) inner=$-(* (list))]
  |=  value=_+<.inner
  (skim (inner value) pred)
::
++  shrink-nothing
  |=  *
  ~
::
++  shrink-seeded
  ::  Shrink a ++seeded sample: the outer value, then a halved size. The
  ::  seed stays, so ++regen rebuilds a consistent dependent value.
  |*  outer=$-(* (list))
  |=  [value=_+<.outer seed=@uv size=@ud]
  %+  weld
    (turn (outer value) |=(v=_+<.outer [v seed size]))
  ?:  =(0 size)  ~
  ~[[value seed (div size 2)]]
::
::  +|  Adaptor
::
++  alts-of
  ::  A typed shrinker as a document's ++alts. The sample keeps its type.
  ::  Pass a mold: a tuple mold needs its comma, as in ,[(list @ud) @ud].
  |*  [kind=mold inner=$-(* (list))]
  |=  sample=vase
  ^-  (list vase)
  =/  value  ;;(kind q.sample)
  (turn (inner value) |=(v=* sample(q v)))
--
