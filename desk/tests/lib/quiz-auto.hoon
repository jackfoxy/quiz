/+  auto=quiz-auto, legacy=quiz, engine=quiz-engine, *test
|%
  ::  Type-directed defaults. Parity arms pin that types legacy fill and
  ::  sink already handled are unchanged, draw for draw.
  ::
::
++  fills
  ::  N samples of a vase's type, sizes 1..n, each from its own stream.
  |=  [n=@ud seed=@uv sax=vase]
  ^-  (list vase)
  =/  rng  ~(. og seed)
  =|  out=(list vase)
  =/  size  1
  |-
  ?:  =(0 n)  (flop out)
  =/  [here=_og next=_og]  (split-rng:legacy rng)
  =/  made  (fill:auto size here sax)
  $(n (dec n), rng next, size +(size), out [made out])
::
++  legacy-fills
  |=  [n=@ud seed=@uv sax=vase]
  ^-  (list vase)
  =/  rng  ~(. og seed)
  =|  out=(list vase)
  =/  size  1
  |-
  ?:  =(0 n)  (flop out)
  =/  [here=_og next=_og]  (split-rng:legacy rng)
  =/  made  (~(fill quiz:legacy [size here]) sax)
  $(n (dec n), rng next, size +(size), out [made out])
::
++  plain
  ::  Types legacy fill and sink handle; quiz-auto must match them.
  ^-  (list vase)
  :~  !>(*@ud)
      !>(*?)
      !>(*[@ud @ud])
      !>(*?(%a %b %c))
      !>(*[a=? b=?])
      !>(*[a=@ud b=[c=? d=@ux]])
      !>(`*`0)
  ==
::
++  test-fill-parity
  ::  Same values and types as legacy fill, for 200 draws of each type.
  ^-  tang
  %-  expect
  !>  %+  levy  plain
      |=  sax=vase
      =((fills 200 0v7 sax) (legacy-fills 200 0v7 sax))
::
++  test-sink-parity
  ::  Same candidates as legacy sink on the same samples. Not `*`: legacy
  ::  fill types a noun sample so that legacy sink offers nothing, and
  ::  quiz-auto shrinks it.
  ^-  tang
  %-  expect
  !>  %+  levy  (snip plain)
      |=  sax=vase
      %+  levy  (fills 50 0v3 sax)
      |=(v=vase =((sink:auto v) (sink:legacy v)))
::
++  test-auras
  ::  Meaningful auras get valid values.
  ^-  tang
  =/  values
    |=  sax=vase
    ^-  (list *)
    (turn (fills 100 0v1 sax) tail)
  =/  cords  ;;((list @t) (values !>(*@t)))
  =/  terms  ;;((list @tas) (values !>(*@tas)))
  =/  knots  ;;((list @ta) (values !>(*@ta)))
  =/  reals  ;;((list @rd) (values !>(*@rd)))
  =/  ships  ;;((list @p) (values !>(*@p)))
  =/  chars  ;;((list @tD) (values !>(*@tD)))
  =/  printable
    |=  c=@t
    (levy (trip c) |=(ch=@tD &((gte ch 32) (lte ch 126))))
  ;:  weld
    (expect !>((levy cords printable)))
    (expect !>((levy terms |=(t=@tas &(!=(0 t) ((sane %tas) t))))))
    (expect !>((levy knots (sane %ta))))
    (expect !>((levy reals |=(r=@rd !=(0x7ff (cut 0 [52 11] r))))))
    (expect !>((levy ships |=(p=@p (lth p (bex 32))))))
    (expect !>((levy chars |=(c=@tD &((gte c 32) (lte c 126))))))
  ==
::
++  test-shapes
  ::  Containers are recognized by type; a union and a plain cell are not.
  ^-  tang
  =/  kind
    ::  Through holds, as fill does: a set is a hold of a tree's hold.
    |=  sax=vase
    ^-  (unit @tas)
    =/  t  p.sax
    |-
    ?.  ?=([%hold *] t)  ~
    =/  open  (expand:auto t)
    =/  found  (shape-of:auto t open)
    ?^  found  `-.u.found
    $(t open)
  ;:  weld
    (expect-eq !>(`%list) !>((kind !>(*(list @ud)))))
    (expect-eq !>(`%set) !>((kind !>(*(set @t)))))
    (expect-eq !>(`%map) !>((kind !>(*(map @t (list @ud))))))
    (expect-eq !>(`%unit) !>((kind !>(*(unit @da)))))
    (expect-eq !>(`%list) !>((kind !>(*(list (list @t))))))
    (expect-eq !>(~) !>((kind !>(*(pair @ud @t)))))
  ==
::
++  test-container-values
  ::  Filled containers mold as their types and stay within the maximum.
  ^-  tang
  =/  values
    |=  sax=vase
    ^-  (list *)
    (turn (fills 60 0v2 sax) tail)
  =/  lists  ;;((list (list @ud)) (values !>(*(list @ud))))
  =/  sets  ;;((list (set @t)) (values !>(*(set @t))))
  =/  maps  ;;((list (map @tas (list @ud))) (values !>(*(map @tas (list @ud)))))
  =/  units  ;;((list (unit @da)) (values !>(*(unit @da))))
  =/  tapes  ;;((list tape) (values !>(*tape)))
  =/  top  container-max:auto
  ;:  weld
    (expect !>((levy lists |=(l=(list @ud) (lte (lent l) top)))))
    (expect !>((lien lists |=(l=(list @ud) (gth (lent l) 2)))))
    (expect !>((levy sets |=(s=(set @t) (lte ~(wyt in s) top)))))
    (expect !>((lien maps |=(m=(map @tas (list @ud)) (gth ~(wyt by m) 1)))))
    (expect !>((lien units |=(u=(unit @da) =(~ u)))))
    (expect !>((lien units |=(u=(unit @da) ?=(^ u)))))
    (expect !>((lien tapes |=(t=tape (gth (lent t) 0)))))
  ==
::
++  test-sink-lighter-and-typed
  ::  Every default candidate weighs less and still molds as its type.
  ^-  tang
  =/  check
    |*  [sax=vase kind=mold]
    %+  levy  (fills 15 0v5 sax)
    |=  v=vase
    =/  parent  (weight:engine q.v)
    %+  levy  (sink:auto v)
    |=  c=vase
    ?&  (lth (weight:engine q.c) parent)
        =(p.c p.v)
        =(q.c ;;(kind q.c))
    ==
  ;:  weld
    (expect !>((check !>(*[name=@t tags=(list @tas)]) ,[@t (list @tas)])))
    (expect !>((check !>(*(map @tas @ud)) (map @tas @ud))))
    (expect !>((check !>(*(set @ud)) (set @ud))))
    (expect !>((check !>(*(unit @rd)) (unit @rd))))
    (expect !>((check !>(*@sd) @sd)))
  ==
::
++  test-sink-examples
  ::  Lists shrink by deletion first; a union shrinks inside its branch;
  ::  -0 shrinks to 0, never to NaN.
  ^-  tang
  =/  values  |=(l=(list vase) (turn l tail))
  =/  items  !>(`(list @ud)`~[4 1])
  =/  union  !>(`$%([%a x=@ud] [%b y=@t])`[%a 10])
  ;:  weld
    %+  expect-eq  !>(`(list *)`~[~ ~[1] ~[4] ~[2 1] ~[3 1] ~[4 0] ~[4 0]])
    !>((values (sink:auto items)))
    (expect-eq !>(`(list *)`~[[%a 5] [%a 9]]) !>((values (sink:auto union))))
    (expect-eq !>(`(list *)`~[.~0]) !>((values (sink:auto !>(.~-0)))))
    %+  expect-eq  !>(`(list *)`~['' 'b' 'a' 'aa'])
    !>((values (sink:auto !>('ab'))))
  ==
--
