/+  quiz, *test
/=  quiz-gen  /gen/quiz
::  Pins legacy behavior, including successful exhaustion and lost categories.
|%
::
++  sized
  |=  [size=@ud rng=_og]
  ^-  @ud
  size
::
++  no-alts
  |=  sam=vase
  ^-  (list vase)
  ~
::
++  test-result-shape
  ^-  tang
  =/  got  (~(check-verbose quiz 0v1 3) !>(|=(@ud &)) `sized ~)
  (expect-eq !>(`result:quiz`[~ 3 0]) !>(got))
::
++  test-zero-means-hundred
  ^-  tang
  =/  got  (~(check-verbose quiz 0v1 0) !>(|=(@ud &)) `sized ~)
  (expect-eq !>(`result:quiz`[~ 100 0]) !>(got))
::
++  test-all-dropped
  ^-  tang
  =/  fate  !>(|=(@ud %drop))
  =/  got  (~(check-verbose quiz 0v1 5) fate `sized ~)
  ;:  weld
    (expect-eq !>(`result:quiz`[~ 5 5]) !>(got))
    (expect !>((~(check quiz 0v1 5) fate `sized ~)))
  ==
::
++  test-failure-counts
  ^-  tang
  =/  fate  !>(|=(a=@ud ?:((lth a 3) %drop %.n)))
  =/  got  (~(check-verbose quiz 0v1 5) fate `sized `no-alts)
  =/  sam  (slot 6 fate)
  (expect-eq !>(`result:quiz`[`sam(q 3) 2 2]) !>(got))
::
++  test-tired-success
  ^-  tang
  =/  give  ((const:norns:quiz @ud) 7)
  =/  fate  !>(|=(@ud &))
  =/  got  (~(check-verbose quiz 0v1 2) fate `give ~)
  ;:  weld
    (expect-eq !>(`result:quiz`[~ 1 0]) !>(got))
    (expect !>((~(check quiz 0v1 2) fate `give ~)))
  ==
::
++  test-hash-dedupe
  ^-  tang
  ::  Distinct atoms with the same mug: the second fate must never run.
  =/  give
    |=  [size=@ud rng=_og]
    ^-  @ud
    ?:(=(size 1) 28.731 188.973)
  =/  fate  !>(|=(a=@ud =(a 28.731)))
  =/  got  (~(check-verbose quiz 0v1 2) fate `give `no-alts)
  ;:  weld
    (expect !>(?!(=(28.731 188.973))))
    (expect-eq !>((mug 28.731)) !>((mug 188.973)))
    (expect-eq !>(`result:quiz`[~ 1 0]) !>(got))
  ==
::
++  test-fixed-entropy
  ^-  tang
  =/  give  |=([size=@ud rng=_og] (rad:rng 65.536))
  =/  fate  !>(|=(@ud |))
  =/  first  (~(check-verbose quiz 0v1a 10) fate `give `no-alts)
  =/  again  (~(check-verbose quiz 0v1a 10) fate `give `no-alts)
  =/  other  (~(check-verbose quiz 0v1b 10) fate `give `no-alts)
  ;:  weld
    (expect-eq !>(first) !>(again))
    (expect !>(?!(=(defy.first defy.other))))
  ==
::
++  test-crash-is-false
  ^-  tang
  =/  fate  !>(|=(@ud ^-(? !!)))
  =/  sam  (slot 6 fate)
  =/  give  ((const:norns:quiz @ud) 7)
  =/  got  (~(check-verbose quiz 0v1 1) fate `give `no-alts)
  ;:  weld
    (expect-eq !>(%.n) !>((run:quiz fate sam)))
    (expect-eq !>(`result:quiz`[`sam(q 7) 0 0]) !>(got))
  ==
::
++  test-scry-is-false
  ^-  tang
  =/  fate  !>(|=(@ud .^(? %cz /quiz-legacy-missing)))
  =/  sam  (slot 6 fate)
  =/  give  ((const:norns:quiz @ud) 7)
  =/  got  (~(check-verbose quiz 0v1 1) fate `give `no-alts)
  ;:  weld
    (expect-eq !>(%.n) !>((run:quiz fate sam)))
    (expect-eq !>(`result:quiz`[`sam(q 7) 0 0]) !>(got))
  ==
::
++  test-bad-product-crashes
  ^-  tang
  %-  expect-fail
  |.  (~(check-verbose quiz 0v1 1) !>(|=(@ud 42)) `sized ~)
::
++  test-default-shrink
  ^-  tang
  =/  fate  !>(|=(a=@ud (lte a 500)))
  =/  give  ((const:norns:quiz @ud) 1.024)
  =/  got  (~(check-verbose quiz 0v1 1) fate `give ~)
  =/  sam  (slot 6 fate)
  (expect-eq !>(`result:quiz`[`sam(q 501) 0 0]) !>(got))
::
++  test-shrink-loses-crash-category
  ^-  tang
  =/  fate  !>(|=(a=@ud ^-(? ?:(=(a 1) !! =(a 0)))))
  =/  give  ((const:norns:quiz @ud) 2)
  =/  got  (~(check-verbose quiz 0v1 1) fate `give ~)
  =/  sam  (slot 6 fate)
  (expect-eq !>(`result:quiz`[`sam(q 1) 0 0]) !>(got))
::
++  test-shrink-skips-drop
  ^-  tang
  =/  fate  !>(|=(a=@ud ?:(=(a 1) %drop =(a 0))))
  =/  give  ((const:norns:quiz @ud) 2)
  =/  got  (~(check-verbose quiz 0v1 1) fate `give ~)
  =/  sam  (slot 6 fate)
  (expect-eq !>(`result:quiz`[`sam(q 2) 0 0]) !>(got))
::
++  test-sink-atoms
  ^-  tang
  ;:  weld
    (expect-eq !>(~[!>(`@ud`4) !>(`@ud`8)]) !>((sink:quiz !>(`@ud`9))))
    (expect-eq !>(*(list vase)) !>((sink:quiz !>(`@ud`0))))
    (expect-eq !>(*(list vase)) !>((sink:quiz !>(%fixed))))
  ==
::
++  test-sink-cell-order
  ^-  tang
  =/  sam  !>([`@ud`4 `@ud`2])
  =/  want=(list vase)
    :~  sam(q [2 1])  sam(q [2 1])  sam(q [3 1])
        sam(q [3 1])  sam(q [4 1])  sam(q [4 1])
    ==
  (expect-eq !>(want) !>((sink:quiz sam)))
::
++  test-norn-composition
  ^-  tang
  =/  rng  ~(. og 42)
  =/  seven  ((const:norns:quiz @ud) 7)
  =/  nine  ((const:norns:quiz @ud) 9)
  =/  pair  ((cell:norns:quiz @ud @ud) seven nine)
  =/  weighted  ((freq:norns:quiz @ud) ~[[0 seven] [1 nine]])
  =/  pick-one  ((pick:norns:quiz @ud) ~[seven])
  =/  items  ((list:norns:quiz @ud) seven)
  ;:  weld
    (expect-eq !>(`@ud`7) !>((seven 0 rng)))
    (expect-eq !>([`@ud`7 `@ud`9]) !>((pair 10 rng)))
    (expect-eq !>(`@ud`9) !>((weighted 10 rng)))
    (expect-eq !>(`@ud`7) !>((pick-one 10 rng)))
    (expect-eq !>(*(list @ud)) !>((items 1 rng)))
  ==
::
++  test-generator
  ^-  tang
  ::  Call the actual %say gate with fixed context, including default runs.
  =/  context  [~2000.1.1 `@uvJ`42 `beak`[~zod %quiz da+~2000.1.1]]
  =/  yes  !>(|=(@ud &))
  =/  no  !>(|=(@ud |))
  =/  zero  !>(|=(a=@ud =(a 0)))
  ;:  weld
    (expect-eq !>(%say) !>(-.quiz-gen))
    (expect-eq !>([%noun %.y]) !>((+.quiz-gen context [zero ~] [1 ~])))
    (expect-eq !>([%noun %.n]) !>((+.quiz-gen context [zero ~] [0 ~])))
    (expect-eq !>([%noun %.y]) !>((+.quiz-gen context [yes ~] [3 ~])))
    (expect-eq !>([%noun %.n]) !>((+.quiz-gen context [no ~] [3 ~])))
    (expect-eq !>([%noun %.y]) !>((+.quiz-gen context [yes ~] [0 ~])))
  ==
--
