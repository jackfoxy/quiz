/+  quiz, engine=quiz-engine, *test
|%
  ::  Characterization of lib/quiz's generators and the default fill.
  ::
  ::  These arms pin what lib/quiz's norns actually produce: domain,
  ::  reachable boundaries, distribution, determinism and RNG splitting,
  ::  plus the engine's size progression. Distribution checks use fixed
  ::  seeds and wide tolerances. They are deterministic snapshots, not
  ::  statistical tests, and should trip only on a real change to the
  ::  generators or the RNG. The library is frozen: a surprising result is
  ::  recorded in the docs, not fixed here.
  ::
::
++  draws
  ::  N deterministic draws, each from its own split of the seed's stream.
  |=  [n=@ud size=@ud seed=@uv gen=$-([@ud _og] *)]
  ^-  (list *)
  =/  rng  ~(. og seed)
  =|  out=(list *)
  |-
  ?:  =(0 n)  (flop out)
  =/  [here=_og next=_og]  (split-rng:quiz rng)
  $(n (dec n), rng next, out [(gen size here) out])
::
++  atoms  (atom:norns:quiz @ud)
::
++  filler
  ::  The default generator for a vase's type, used when there is no norn.
  |=  sample=vase
  |=  [size=@ud rng=_og]
  ^-  *
  q:(~(fill quiz:quiz [size rng]) sample)
::
++  tally
  |=  values=(list @)
  ^-  (map @ @ud)
  %+  roll  values
  |=  [value=@ seen=(map @ @ud)]
  (~(put by seen) value +((~(gut by seen) value 0)))
::
++  within
  |=  [got=@ud want=@ud tolerance=@ud]
  ^-  ?
  &((gte (add got tolerance) want) (lte got (add want tolerance)))
::
++  sizes
  ::  The size the engine passes to generation for each of n samples.
  |=  [n=@ud fate=vase]
  ^-  (list @ud)
  =/  cfg  defaults:engine
  =/  cfg  cfg(requested 1.000, attempts-max 2.000)
  =/  s  (init:engine 0v1 cfg [fate ~ ~ ~ %pass])
  =|  out=(list @ud)
  |-
  ?:  =(0 n)  (flop out)
  ?>  =(~ result.s)
  $(n (dec n), out [size.s out], s (step:engine s))
::
++  test-atom-domain
  ::  An atom drawn at size n lies in [0, n); size 1 yields only 0.
  ^-  tang
  %-  zing
  %+  turn  `(list @ud)`~[1 2 10 1.000]
  |=  size=@ud
  ^-  tang
  =/  got  ;;((list @ud) (draws 200 size 0v1 atoms))
  (expect !>((levy got (curr lth size))))
::
++  test-atom-boundaries
  ^-  tang
  =/  got  (silt ;;((list @ud) (draws 500 10 0v1 atoms)))
  ;:  weld
    (expect !>((~(has in got) 0)))
    (expect !>((~(has in got) 9)))
  ==
::
++  test-atom-size-zero
  ::  The atom norn is partial: size 0 asks rad for a value below 0.
  ^-  tang
  (expect-fail |.((atoms 0 ~(. og 0v1))))
::
++  test-const
  ^-  tang
  =/  seven  ((const:norns:quiz @ud) 7)
  =/  small  ;;((list @ud) (draws 50 1 0v1 seven))
  =/  large  ;;((list @ud) (draws 50 1.000 0v2 seven))
  (expect !>((levy (weld small large) |=(a=@ud =(a 7)))))
::
++  test-cell-independence
  ::  Each side gets its own split stream, so the sides rarely coincide.
  ^-  tang
  =/  pairs  ((cell:norns:quiz @ud @ud) atoms atoms)
  =/  got  ;;((list [@ud @ud]) (draws 200 100 0v1 pairs))
  =/  same  (lent (skim got |=([a=@ud b=@ud] =(a b))))
  (expect !>((lth same 20)))
::
++  test-list-length-bound
  ::  The list norn halves its stop chance per element: at most
  ::  xeb(size)-1 elements, and size 1 yields only ~.
  ^-  tang
  =/  lists  ((list:norns:quiz @ud) atoms)
  %-  zing
  %+  turn  `(list @ud)`~[1 2 16 1.024 65.536]
  |=  size=@ud
  ^-  tang
  =/  got  ;;((list (list @ud)) (draws 200 size 0v1 lists))
  =/  bound  (dec (xeb size))
  (expect !>((levy got |=(l=(list @ud) (lte (lent l) bound)))))
::
++  test-list-reaches-empty-and-max
  ^-  tang
  =/  lists  ((list:norns:quiz @ud) atoms)
  =/  big  ;;((list (list @ud)) (draws 1.000 1.024 0v1 lists))
  =/  small  ;;((list (list @ud)) (draws 200 4 0v1 lists))
  =/  long=(list @ud)  (turn big |=(l=(list @ud) (lent l)))
  =/  short=(list @ud)  (turn small |=(l=(list @ud) (lent l)))
  ;:  weld
    (expect-eq !>(`@ud`10) !>((roll long max)))
    (expect !>((lien short |=(n=@ud =(n 0)))))
  ==
::
++  test-list-elements
  ^-  tang
  =/  threes  ((list:norns:quiz @ud) ((const:norns:quiz @ud) 3))
  =/  got  ;;((list (list @ud)) (draws 100 1.024 0v1 threes))
  =/  flat=(list @ud)  (zing got)
  ;:  weld
    (expect !>((gth (lent flat) 0)))
    (expect !>((levy flat |=(a=@ud =(a 3)))))
  ==
::
++  test-noun-shape
  ::  Noun depth is bounded by halving; leaves stay below the size.
  ^-  tang
  =/  got  (draws 200 64 0v1 noun:norns:quiz)
  =/  depth
    |=  n=*
    ^-  @ud
    ?@  n  0
    +((max $(n -.n) $(n +.n)))
  =/  small
    |=  n=*
    ^-  ?
    ?@  n  (lth n 64)
    &($(n -.n) $(n +.n))
  ;:  weld
    (expect !>((levy got |=(n=* (lte (depth n) (dec (xeb 64)))))))
    (expect !>((levy got small)))
    (expect !>((lien got |=(n=* ?=(@ n)))))
    (expect !>((lien got |=(n=* ?=(^ n)))))
  ==
::
++  test-freq-weights
  ^-  tang
  =/  one  ((const:norns:quiz @ud) 1)
  =/  two  ((const:norns:quiz @ud) 2)
  =/  gen  ((freq:norns:quiz @ud) ~[[1 one] [3 two]])
  =/  got  ;;((list @ud) (draws 1.000 10 0v1 gen))
  =/  twos  (lent (skim got |=(a=@ud =(a 2))))
  (expect !>((within twos 750 75)))
::
++  test-freq-zero-weight
  ^-  tang
  =/  one  ((const:norns:quiz @ud) 1)
  =/  two  ((const:norns:quiz @ud) 2)
  =/  gen  ((freq:norns:quiz @ud) ~[[0 one] [1 two]])
  =/  got  ;;((list @ud) (draws 200 10 0v1 gen))
  (expect !>((levy got |=(a=@ud =(a 2)))))
::
++  test-freq-empty
  ::  No weight to choose from: rads is asked for a value below 0.
  ^-  tang
  =/  gen  ((freq:norns:quiz @ud) ~)
  (expect-fail |.((gen 10 ~(. og 0v1))))
::
++  test-pick-uniform
  ^-  tang
  =/  gens=(list (norn:quiz @ud))
    :~  ((const:norns:quiz @ud) 1)
        ((const:norns:quiz @ud) 2)
        ((const:norns:quiz @ud) 3)
    ==
  =/  got  ;;((list @ud) (draws 900 10 0v1 ((pick:norns:quiz @ud) gens)))
  =/  seen  (tally got)
  =/  each  |=(k=@ud (within (~(gut by seen) k 0) 300 60))
  ;:  weld
    (expect-eq !>(`@ud`3) !>(~(wyt by seen)))
    (expect !>((levy `(list @ud)`~[1 2 3] each)))
  ==
::
++  test-atom-uniform
  ^-  tang
  =/  seen  (tally ;;((list @ud) (draws 1.000 10 0v1 atoms)))
  =/  each  |=(k=@ud (within (~(gut by seen) k 0) 100 40))
  (expect !>((levy (gulf 0 9) each)))
::
++  test-determinism
  ::  The same seed and size give the same draws; another seed differs.
  ^-  tang
  =/  gens=(list $-([@ud _og] *))
    :~  atoms
        noun:norns:quiz
        ((list:norns:quiz @ud) atoms)
        ((cell:norns:quiz @ud @ud) atoms atoms)
    ==
  =/  same
    |=  gen=$-([@ud _og] *)
    =((draws 20 100 0v1 gen) (draws 20 100 0v1 gen))
  =/  differ
    |=  gen=$-([@ud _og] *)
    !=((draws 20 100 0v1 gen) (draws 20 100 0v2 gen))
  ;:  weld
    (expect !>((levy gens same)))
    (expect !>((levy gens differ)))
  ==
::
++  test-split-rng-distinct
  ::  Prefix-free paths: eight left-only and eight right-only splits give
  ::  sixteen distinct first draws.
  ^-  tang
  =/  walk
    |=  [left=? rng=_og]
    ^-  (list @)
    =/  n  8
    =|  out=(list @)
    |-
    ?:  =(0 n)  out
    =/  [l=_og r=_og]  (split-rng:quiz rng)
    =/  next  ?:(left l r)
    $(n (dec n), rng next, out [(raw:next 64) out])
  =/  root  ~(. og 0v1)
  =/  firsts=(list @)  (weld (walk & root) (walk | root))
  (expect-eq !>(`@ud`16) !>(~(wyt in (silt firsts))))
::
++  test-split-rng-not-parent
  ^-  tang
  =/  root  ~(. og 0v1)
  =/  [l=_og r=_og]  (split-rng:quiz root)
  =/  firsts=(list @)  ~[(raw:root 256) (raw:l 256) (raw:r 256)]
  (expect-eq !>(`@ud`3) !>(~(wyt in (silt firsts))))
::
++  test-split-bit-balance
  ::  Over 256 successive left children, each low bit of the first byte is
  ::  set about half the time. A coarse correlation check.
  ^-  tang
  =/  firsts=(list @)
    =/  rng  ~(. og 0v1)
    =/  n  256
    =|  out=(list @)
    |-
    ?:  =(0 n)  out
    =/  [l=_og r=_og]  (split-rng:quiz rng)
    $(n (dec n), rng r, out [(raw:l 8) out])
  =/  balanced
    |=  bit=@ud
    =/  set  (lent (skim firsts |=(a=@ =(1 (cut 0 [bit 1] a)))))
    (within set 128 32)
  (expect !>((levy (gulf 0 7) balanced)))
::
++  test-fill-fork
  ::  Default fill picks one branch of a union uniformly.
  ^-  tang
  =/  gen  (filler !>(*?(%a %b %c)))
  =/  seen  (tally ;;((list @) (draws 300 10 0v1 gen)))
  =/  each  |=(k=@ (within (~(gut by seen) k 0) 100 40))
  ;:  weld
    (expect-eq !>(`@ud`3) !>(~(wyt by seen)))
    (expect !>((levy `(list @)`~[%a %b %c] each)))
  ==
::
++  test-fill-unit
  ^-  tang
  =/  got  ;;((list (unit @ud)) (draws 100 10 0v1 (filler !>(*(unit @ud)))))
  ;:  weld
    (expect !>((lien got |=(u=(unit @ud) =(~ u)))))
    (expect !>((lien got |=(u=(unit @ud) ?=(^ u)))))
  ==
::
++  test-fill-constant-atom
  ^-  tang
  =/  got  (draws 50 10 0v1 (filler !>(%foo)))
  (expect !>((levy got |=(a=* =(a %foo)))))
::
++  test-fill-nested-cell
  ^-  tang
  =/  gen  (filler !>(*[@ud [@ud @ud]]))
  =/  got  ;;((list [@ud @ud @ud]) (draws 100 10 0v1 gen))
  =/  small
    |=  [a=@ud b=@ud c=@ud]
    &((lth a 10) (lth b 10) (lth c 10))
  (expect !>((levy got small)))
::
++  test-size-progression
  ::  Size starts at 1 and grows by 1 + 2/21 of itself per generated
  ::  sample, whatever the verdict: drops advance it as accepts do.
  ^-  tang
  =/  kept  (sizes 100 !>(|=(@ud &)))
  =/  dropped  (sizes 100 !>(|=(@ud %drop)))
  =/  picks  `(list @ud)`~[1 10 20 50 100]
  =/  got  (turn picks |=(i=@ud (snag (dec i) kept)))
  ;:  weld
    (expect-eq !>(`(list @ud)`~[1 10 33 586 55.946]) !>(got))
    (expect-eq !>(kept) !>(dropped))
  ==
--
