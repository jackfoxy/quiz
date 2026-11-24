/+  gen=quiz-gen, engine=quiz-engine, *test
|%
  ::  The app generator and shrinker library. Distribution checks use fixed
  ::  seeds and wide tolerances, as in quiz-norns.
  ::
::
++  draws
  ::  N deterministic draws, each from its own split of the seed's stream.
  |=  [n=@ud size=@ud seed=@uv item=$-([@ud _og] *)]
  ^-  (list *)
  =/  rng  ~(. og seed)
  =|  out=(list *)
  |-
  ?:  =(0 n)  (flop out)
  =/  [here=_og next=_og]  (split:gen rng)
  $(n (dec n), rng next, out [(item size here) out])
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
++  small  (range:gen 0 9)
::
++  test-range
  ^-  tang
  =/  got  (silt ;;((list @ud) (draws 300 1.000 0v1 (range:gen 3 7))))
  ;:  weld
    (expect-eq !>((silt `(list @ud)`~[3 4 5 6 7])) !>(got))
    (expect-fail |.((range:gen 5 4)))
  ==
::
++  test-upto-and-size-zero
  ::  Size 0 is total: upto gives 0, list-of gives the empty list.
  ^-  tang
  =/  zero  (silt ;;((list @ud) (draws 50 0 0v1 upto:gen)))
  =/  ten  (silt ;;((list @ud) (draws 300 10 0v1 upto:gen)))
  =/  lists  ;;((list (list @ud)) (draws 50 0 0v1 (list-of:gen 0 9 small)))
  ;:  weld
    (expect-eq !>((silt `(list @ud)`~[0])) !>(zero))
    (expect-eq !>(`@ud`11) !>(~(wyt in ten)))
    (expect !>((levy lists |=(l=(list @ud) =(~ l)))))
  ==
::
++  test-signed
  ^-  tang
  =/  got  ;;((list @sd) (draws 300 10 0v1 signed:gen))
  =/  size  |=(a=@sd (lte (abs:si a) 10))
  ;:  weld
    (expect !>((levy got size)))
    (expect !>((lien got |=(a=@sd =(%.y (syn:si a))))))
    (expect !>((lien got |=(a=@sd =(%.n (syn:si a))))))
  ==
::
++  test-ship
  ::  Galaxies, stars and planets all occur.
  ^-  tang
  =/  got  ;;((list @p) (draws 300 10 0v1 ship:gen))
  =/  classes  (silt (turn got |=(p=@p (clan:title p))))
  ;:  weld
    (expect !>((levy got |=(p=@p (lth p (bex 32))))))
    %+  expect-eq  !>((silt `(list rank:title)`~[%czar %king %duke]))
    !>(classes)
  ==
::
++  test-date-and-span
  ^-  tang
  =/  dates  ;;((list @da) (draws 200 100 0v1 date:gen))
  =/  spans  ;;((list @dr) (draws 200 100 0v1 span:gen))
  =/  low  (sub ~2000.1.1 (mul ~s1 100))
  =/  high  (add ~2000.1.1 (mul ~s1 100))
  ;:  weld
    (expect !>((levy dates |=(d=@da &((gte d low) (lte d high))))))
    (expect !>((levy spans |=(d=@dr (lte d (mul ~s1 100))))))
  ==
::
++  test-reals-finite
  ::  No infinity or NaN: the exponent is never all ones.
  ^-  tang
  =/  doubles  ;;((list @rd) (draws 500 1 0v1 real:gen))
  =/  singles  ;;((list @rs) (draws 500 1 0v1 real-single:gen))
  ;:  weld
    (expect !>((levy doubles |=(r=@rd !=(0x7ff (cut 0 [52 11] r))))))
    (expect !>((levy singles |=(r=@rs !=(0xff (cut 0 [23 8] r))))))
  ==
::
++  test-text
  ::  Cords are printable; knots and terms pass +sane.
  ^-  tang
  =/  cords  ;;((list @t) (draws 200 12 0v1 cord:gen))
  =/  knots  ;;((list @ta) (draws 200 12 0v1 knot:gen))
  =/  terms  ;;((list @tas) (draws 200 12 0v1 term:gen))
  =/  long  ;;((list @t) (draws 50 10.000 0v1 cord:gen))
  =/  printable
    |=  c=@t
    (levy (trip c) |=(ch=@tD &((gte ch 32) (lte ch 126))))
  ;:  weld
    (expect !>((levy cords |=(c=@t (lte (met 3 c) 12)))))
    (expect !>((levy cords printable)))
    (expect !>((levy knots (sane %ta))))
    (expect !>((levy terms (sane %tas))))
    (expect !>((levy terms |=(t=@tas (gth (met 3 t) 0)))))
    (expect !>((levy long |=(c=@t (lte (met 3 c) text-max:gen)))))
  ==
::
++  test-choice
  ^-  tang
  =/  picked  (tally ;;((list @) (draws 900 1 0v1 (elements:gen ~[1 2 3]))))
  =/  gens  ~[(range:gen 0 0) (range:gen 1 1)]
  =/  either  (silt ;;((list @ud) (draws 100 1 0v1 (one-of:gen gens))))
  =/  weighted  (frequency:gen ~[[1 (range:gen 0 0)] [3 (range:gen 1 1)]])
  =/  drawn  ;;((list @ud) (draws 1.000 1 0v1 weighted))
  =/  ones  (lent (skim drawn |=(a=@ud =(a 1))))
  =/  each  |=(k=@ (within (~(gut by picked) k 0) 300 60))
  ;:  weld
    (expect !>((levy `(list @)`~[1 2 3] each)))
    (expect-eq !>((silt `(list @ud)`~[0 1])) !>(either))
    (expect !>((within ones 750 75)))
    (expect-fail |.((elements:gen `(list @ud)`~)))
    (expect-fail |.((one-of:gen `(list (norn:gen @ud))`~)))
    (expect-fail |.((frequency:gen ~[[0 (range:gen 0 0)]])))
  ==
::
++  test-unit-of
  ^-  tang
  =/  got  ;;((list (unit @ud)) (draws 200 3 0v1 (unit-of:gen small)))
  ;:  weld
    (expect !>((lien got |=(u=(unit @ud) =(~ u)))))
    (expect !>((lien got |=(u=(unit @ud) ?=(^ u)))))
  ==
::
++  test-list-of-lengths
  ::  Lengths are uniform over [low, top]; both ends occur.
  ^-  tang
  =/  lists  (list-of:gen 2 5 small)
  =/  got  ;;((list (list @ud)) (draws 1.000 100 0v1 lists))
  =/  lengths  (tally (turn got |=(l=(list @ud) (lent l))))
  =/  each  |=(k=@ (within (~(gut by lengths) k 0) 250 60))
  =/  capped  ;;((list (list @ud)) (draws 200 3 0v1 (list-of:gen 0 50 small)))
  ;:  weld
    (expect-eq !>(`@ud`4) !>(~(wyt by lengths)))
    (expect !>((levy `(list @)`~[2 3 4 5] each)))
    (expect !>((levy capped |=(l=(list @ud) (lte (lent l) 3)))))
    (expect-fail |.((list-of:gen 5 4 small)))
  ==
::
++  test-fixed-lengths
  ^-  tang
  =/  vectors  ;;((list (list @ud)) (draws 50 9 0v1 (vector:gen 4 small)))
  =/  nonempty  ;;((list (list @ud)) (draws 50 0 0v1 (nonempty:gen 3 small)))
  ;:  weld
    (expect !>((levy vectors |=(l=(list @ud) =(4 (lent l))))))
    (expect !>((levy nonempty |=(l=(list @ud) =(1 (lent l))))))
  ==
::
++  test-containers
  ^-  tang
  =/  sets  ;;((list (set @ud)) (draws 50 9 0v1 (set-of:gen @ud 5 small)))
  =/  maps
    ;;((list (map @ud @ud)) (draws 50 9 0v1 (map-of:gen @ud @ud 5 small small)))
  ;:  weld
    (expect !>((levy sets |=(s=(set @ud) (lte ~(wyt in s) 5)))))
    (expect !>((levy maps |=(m=(map @ud @ud) (lte ~(wyt by m) 5)))))
  ==
::
++  test-reorder
  ::  Sublists keep order; shuffles are permutations; sorted is sorted.
  ^-  tang
  =/  items  `(list @ud)`~[1 2 3 4 5]
  =/  subs  ;;((list (list @ud)) (draws 100 1 0v1 (sublist:gen items)))
  =/  mixed  ;;((list (list @ud)) (draws 100 1 0v1 (shuffle:gen items)))
  =/  order  (sorted:gen @ud 0 20 small lte)
  =/  sorts  ;;((list (list @ud)) (draws 100 20 0v1 order))
  =/  in-order  |=(l=(list @ud) =(l (sort l lte)))
  ;:  weld
    (expect !>((levy subs in-order)))
    (expect !>((levy mixed |=(l=(list @ud) =(items (sort l lte))))))
    (expect !>((lien mixed |=(l=(list @ud) !=(items l)))))
    (expect !>((levy sorts in-order)))
  ==
::
++  test-composition
  ^-  tang
  =/  pairs  ;;((list [@ud @ud]) (draws 200 1 0v1 (pair:gen small small)))
  =/  same  (lent (skim pairs |=([a=@ud b=@ud] =(a b))))
  =/  doubled  ;;((list @ud) (draws 50 1 0v1 (cook:gen small (cury mul 2))))
  =/  below
    (bind:gen (range:gen 1 9) |=(n=@ud (range:gen 0 (dec n))))
  =/  dependent  ;;((list @ud) (draws 200 1 0v1 below))
  ;:  weld
    (expect !>((lth same 40)))
    (expect !>((levy doubled |=(a=@ud =(0 (mod a 2))))))
    (expect !>((levy dependent |=(a=@ud (lth a 9)))))
  ==
::
++  test-such-that
  ^-  tang
  =/  even  (such-that:gen small |=(a=@ud =(0 (mod a 2))) 50)
  =/  never  (such-that:gen small |=(a=@ud |) 5)
  ;:  weld
    =/  got  ;;((list @ud) (draws 50 1 0v1 even))
    (expect !>((levy got |=(a=@ud =(0 (mod a 2))))))
    (expect-fail |.((never 1 ~(. og 0v1))))
  ==
::
++  test-seeded
  ::  The dependent value is a function of the outer value and seed.
  ^-  tang
  ::  A pinned dependent value is used as is.
  =/  sample
    ;;([@ud @uv @ud (unit @ud)] ((seeded:gen small) 10 ~(. og 0v1)))
  =/  [outer=@ud seed=@uv size=@ud pin=(unit @ud)]  sample
  =/  make  |=(n=@ud (range:gen 0 n))
  =/  a  (regen:gen make outer seed size pin)
  =/  b  (regen:gen make outer seed size pin)
  ;:  weld
    (expect-eq !>(~) !>(pin))
    (expect-eq !>(a) !>(b))
    (expect !>((lte a outer)))
    (expect-eq !>(7) !>((regen:gen make outer seed size `7)))
  ==
::
++  test-size-combinators
  ::  upto draws from [0, size], so its largest draw shows the size used.
  ^-  tang
  =/  top  |=(v=(list *) (roll ;;((list @ud) v) max))
  =/  fixed  (resize:gen 3 upto:gen)
  =/  tenth  (scale:gen (curr div 10) upto:gen)
  =/  held  (capped:gen 5 upto:gen)
  =/  exact  (sized:gen |=(n=@ud (range:gen n n)))
  ;:  weld
    (expect-eq !>(`@ud`3) !>((top (draws 200 1.000 0v1 fixed))))
    (expect-eq !>(`@ud`10) !>((top (draws 300 100 0v1 tenth))))
    (expect-eq !>(`@ud`5) !>((top (draws 200 1.000 0v1 held))))
    (expect-eq !>(`@ud`2) !>((top (draws 200 2 0v1 held))))
    (expect-eq !>(`(list @ud)`~[7 7 7]) !>((draws 3 7 0v1 exact)))
  ==
::
++  test-determinism
  ^-  tang
  =/  lists  (list-of:gen 0 20 small)
  ;:  weld
    (expect-eq !>((draws 20 50 0v1 lists)) !>((draws 20 50 0v1 lists)))
    (expect !>(!=((draws 20 50 0v1 lists) (draws 20 50 0v2 lists))))
  ==
::
++  test-shrink-atom
  ^-  tang
  ;:  weld
    (expect-eq !>(`(list @)`~[0 5 8 9]) !>((shrink-atom:gen 10)))
    (expect-eq !>(`(list @)`~) !>((shrink-atom:gen 0)))
    (expect-eq !>(`(list @)`~[3 7 9]) !>(((shrink-toward:gen 3) 10)))
    (expect-eq !>(`(list @)`~) !>(((shrink-toward:gen 3) 3)))
  ==
::
++  test-shrink-list-order
  ::  Chunk deletions largest first, then one element at a time.
  ^-  tang
  =/  got  ((shrink-list:gen shrink-atom:gen) `(list @ud)`~[1 2 3])
  =/  want=(list (list @))
    :~  ~  ~[2 3]  ~[1 3]  ~[1 2]
        ~[0 2 3]  ~[1 0 3]  ~[1 1 3]  ~[1 2 0]  ~[1 2 2]
    ==
  (expect-eq !>(`(list *)`want) !>(`(list *)`got))
::
++  test-shrink-weight
  ::  Dogfood: the engine checks that every list candidate is lighter.
  ^-  tang
  =/  fate
    !>  |=  items=*
        =/  items  ;;((list @ud) items)
        =/  parent  (weight:engine items)
        %+  levy  ((shrink-list:gen shrink-atom:gen) items)
        |=(c=* (lth (weight:engine c) parent))
  =/  norn  !>((list-of:gen 0 12 (range:gen 0 1.000)))
  =/  cfg  defaults:engine
  =/  s  (init:engine 0v1 cfg(requested 50) [fate `norn ~ ~ %pass])
  =/  left  500
  =/  done
    |-  ^-  state:engine
    ?:  !=(~ result.s)  s
    ?>  (gth left 0)
    $(s (step:engine s), left (dec left))
  (expect !>(?=([~ %passed ~] result.done)))
::
++  test-shrink-terminates
  ::  The whole candidate graph below a small list is finite.
  ^-  tang
  =/  shrink  (shrink-list:gen shrink-atom:gen)
  =/  seen=(set *)
    =|  seen=(set *)
    =/  todo=(list *)  ~[~[3 2 1]]
    |-  ^-  (set *)
    ?~  todo  seen
    ?:  (~(has in seen) i.todo)  $(todo t.todo)
    ?>  (lte ~(wyt in seen) 500)
    =/  more=(list *)  (weld (shrink ;;((list @ud) i.todo)) t.todo)
    $(seen (~(put in seen) i.todo), todo more)
  (expect !>((~(has in seen) ~)))
::
++  test-shrink-combinators
  ^-  tang
  =/  pairs  ((shrink-pair:gen shrink-atom:gen shrink-atom:gen) [2 1])
  =/  units  ((shrink-unit:gen shrink-atom:gen) `2)
  =/  evens
    ((shrink-keep:gen |=(a=@ =(0 (mod a 2))) shrink-atom:gen) 10)
  =/  via
    ((shrink-via:gen |=(a=@ (div a 10)) (cury mul 10) shrink-atom:gen) 40)
  =/  make  |=(n=@ud (range:gen 0 n))
  =/  shrink  (shrink-seeded:gen shrink-atom:gen make shrink-atom:gen)
  =/  seeded  (shrink [2 0v9 8 `5])
  =/  equal  ((shrink-equal:gen shrink-atom:gen) ~[4 1 4])
  =/  then  ((shrink-then:gen shrink-atom:gen |=(a=@ ~[a])) 2)
  ;:  weld
    (expect-eq !>(`(list *)`~[[0 1] [1 1] [2 0]]) !>(`(list *)`pairs))
    (expect-eq !>(`(list *)`~[~ [~ 0] [~ 1]]) !>(`(list *)`units))
    (expect-eq !>(`(list *)`~[0 8]) !>(`(list *)`evens))
    (expect-eq !>(`(list *)`~[0 20 30]) !>(`(list *)`via))
    %+  expect-eq
      !>  ^-  (list *)
          :~  [0 0v9 8 ~]  [1 0v9 8 ~]  [2 0v9 4 ~]
              [2 0v0 8 `0]  [2 0v0 8 `3]  [2 0v0 8 `4]
          ==
    !>(`(list *)`seeded)
    %+  expect-eq
      !>(`(list *)`~[~[0 1 0] ~[2 1 2] ~[3 1 3] ~[4 0 4]])
    !>(`(list *)`equal)
    (expect-eq !>(`(list *)`~[0 1 2]) !>(`(list *)`then))
    (expect-eq !>(`(list *)`~) !>(`(list *)`(shrink-nothing:gen 5)))
  ==
::
++  test-alts-of
  ::  The adaptor keeps the sample's type and molds its noun.
  ^-  tang
  =/  alts  (alts-of:gen (list @ud) (shrink-list:gen shrink-atom:gen))
  =/  sample  !>(`*`~[1 2])
  =/  got  (alts sample)
  ;:  weld
    (expect !>((levy got |=(v=vase =(p.v p.sample)))))
    %+  expect-eq  !>(`(list *)`~[~ ~[2] ~[1] ~[0 2] ~[1 0] ~[1 1]])
    !>((turn got tail))
  ==
--
