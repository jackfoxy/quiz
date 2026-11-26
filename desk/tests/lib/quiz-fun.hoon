/+  fun=quiz-fun, gen=quiz-gen, engine=quiz-engine, *test
|%
  ::  Generated functions: lookup, generation, rendering and shrinking.
  ::
::
++  table  `(fun:fun @ud @ud)`[~[[3 1] [5 2] [3 9]] 0]
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
++  test-apply
  ::  The first matching case wins; other keys get the default.
  ^-  tang
  ;:  weld
    (expect-eq !>(`@ud`1) !>((apply:fun table 3)))
    (expect-eq !>(`@ud`2) !>((apply:fun table 5)))
    (expect-eq !>(`@ud`0) !>((apply:fun table 7)))
    %+  expect-eq  !>(`(list @ud)`~[1 0 2])
    !>((turn ~[3 4 5] (to-gate:fun table)))
  ==
::
++  test-fun-text
  ^-  tang
  =/  flags  `(fun:fun @ud ?)`[~[[1 &]] |]
  ;:  weld
    %+  expect-eq  !>('{3 -> 1, 5 -> 2, 3 -> 9, _ -> 0}')
    !>((fun-text:fun !>(table)))
    (expect-eq !>('{1 -> %.y, _ -> %.n}') !>((fun-text:fun !>(flags))))
    %+  expect-eq  !>('{_ -> ~zod}')
    !>((fun-text:fun !>(`(fun:fun @ud @p)`[~ ~zod])))
  ==
::
++  test-fun-of-bounds
  ::  At most min(n, size) cases, keys and values from their generators.
  ^-  tang
  =/  make  (fun-of:fun (range:gen 0 9) (range:gen 10 19) 4)
  =/  big  ;;((list (fun:fun @ud @ud)) (draws 100 50 0v1 make))
  =/  small  ;;((list (fun:fun @ud @ud)) (draws 100 2 0v1 make))
  =/  zero  ;;((list (fun:fun @ud @ud)) (draws 20 0 0v1 make))
  =/  fits
    |=  f=(fun:fun @ud @ud)
    ?&  (gte else.f 10)
        (lte else.f 19)
        %+  levy  cases.f
        |=([k=@ud v=@ud] &((lte k 9) (gte v 10) (lte v 19)))
    ==
  =/  most
    |=  l=(list (fun:fun @ud @ud))
    ^-  @ud
    (roll (turn l |=(f=(fun:fun @ud @ud) (lent cases.f))) max)
  ;:  weld
    (expect !>((levy big fits)))
    (expect-eq !>(`@ud`4) !>((most big)))
    (expect-eq !>(`@ud`2) !>((most small)))
    (expect-eq !>(`@ud`0) !>((most zero)))
  ==
::
++  test-fun-on-total
  ^-  tang
  =/  make  (fun-on:fun ~[1 2 3] (range:gen 0 9))
  =/  got  ;;((list (fun:fun @ud @ud)) (draws 50 10 0v1 make))
  =/  keys  |=(f=(fun:fun @ud @ud) `(list @ud)`(turn cases.f head))
  (expect !>((levy got |=(f=(fun:fun @ud @ud) =(~[1 2 3] (keys f))))))
::
++  test-independence
  ::  Two keys agree about half the time when each value is a coin flip.
  ^-  tang
  =/  make  (fun-on:fun ~[0 1] (range:gen 0 1))
  =/  got  ;;((list (fun:fun @ud @ud)) (draws 400 10 0v1 make))
  =/  same
    %+  skim  got
    |=(f=(fun:fun @ud @ud) =((apply:fun f 0) (apply:fun f 1)))
  =/  n  (lent same)
  (expect !>(&((gte n 160) (lte n 240))))
::
++  test-determinism
  ^-  tang
  =/  make  (fun-of:fun (range:gen 0 9) (range:gen 0 9) 5)
  (expect-eq !>((draws 20 30 0v7 make)) !>((draws 20 30 0v7 make)))
::
++  test-shrink-order
  ::  The constant function, fewer cases, smaller values, smaller default.
  ^-  tang
  =/  f  `(fun:fun @ud @ud)`[~[[3 2] [5 1]] 2]
  =/  got  ((shrink-fun:fun @ud shrink-atom:gen) f)
  %+  expect-eq
    !>  ^-  (list (fun:fun @ud @ud))
        :~  [~ 2]
            [~[[5 1]] 2]
            [~[[3 2]] 2]
            [~[[3 0] [5 1]] 2]
            [~[[3 1] [5 1]] 2]
            [~[[3 2] [5 0]] 2]
            [~[[3 2] [5 1]] 0]
            [~[[3 2] [5 1]] 1]
        ==
  !>(got)
::
++  test-shrink-weight
  ::  Every candidate is lighter, and following the first candidate ends
  ::  at the constant zero function.
  ^-  tang
  =/  shrink  (shrink-fun:fun @ud shrink-atom:gen)
  =/  make  (fun-of:fun (range:gen 0 9) (range:gen 0 9) 6)
  =/  start  ;;((list (fun:fun @ud @ud)) (draws 30 20 0v3 make))
  =/  lighter
    %+  levy  start
    |=  f=(fun:fun @ud @ud)
    %+  levy  (shrink f)
    |=(c=(fun:fun @ud @ud) (lth (weight:engine c) (weight:engine f)))
  =/  last
    =/  f  `(fun:fun @ud @ud)`[~[[4 7] [1 3] [8 8]] 5]
    =/  left  100
    |-  ^-  (fun:fun @ud @ud)
    =/  next  (shrink f)
    ?~  next  f
    ?>  (gth left 0)
    $(f i.next, left (dec left))
  ;:  weld
    (expect !>(lighter))
    (expect-eq !>(`(fun:fun @ud @ud)`[~ 0]) !>(last))
  ==
::
++  test-alts-of
  ::  The adaptor keeps the sample's type on every candidate.
  ^-  tang
  =/  shrink  (shrink-fun:fun @ud shrink-atom:gen)
  =/  alts  (alts-of:gen (fun:fun @ud @ud) shrink)
  =/  sample  !>(`(fun:fun @ud @ud)`[~[[1 1]] 1])
  =/  got  (alts sample)
  ;:  weld
    (expect-eq !>(`@ud`3) !>((lent got)))
    (expect !>((levy got |=(v=vase =(p.v p.sample)))))
  ==
--
