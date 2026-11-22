/+  quiz, engine=quiz-engine, *test
|%
  ::  Characterization of the frozen default shrinker, used when a document
  ::  has no alts. Engine shrinking budgets are in quiz-shrink.
  ::
::
++  test-sink-atom
  ^-  tang
  ;:  weld
    (expect-eq !>(`(list *)`~[5 9]) !>((turn (sink:quiz !>(10)) tail)))
    (expect-eq !>(`(list *)`~) !>((turn (sink:quiz !>(0)) tail)))
  ==
::
++  test-sink-weight-decreases
  ::  Every default candidate weighs less than its parent and keeps a type
  ::  that nests in the parent's, so the engine's weight filter never has
  ::  to discard one.
  ^-  tang
  =/  samples=(list vase)
    :~  !>(1.000)
        !>([3 4])
        !>(`[a=@ud b=@ud]`[6 7])
        !>(`*`[[2 3] 4])
        !>(`[@ud [@ud @ud]]`[8 [5 1]])
    ==
  =/  sound
    |=  parent=vase
    ^-  ?
    %+  levy  (sink:quiz parent)
    |=  child=vase
    ?&  (lth (weight:engine q.child) (weight:engine q.parent))
        (~(nest ut p.parent) | p.child)
    ==
  =/  bad=(list vase)  (skip samples sound)
  (expect-eq !>(`(list *)`~) !>((turn bad tail)))
::
++  test-sink-termination
  ::  Following the first candidate halves every leaf at once and reaches
  ::  all zeros in ten steps.
  ^-  tang
  =/  steps
    =/  sam  !>(`[@ud @ud @ud]`[1.000 500 250])
    =/  n  0
    |-  ^-  @ud
    =/  next  (sink:quiz sam)
    ?~  next  n
    ?>  (lth n 100)
    $(sam i.next, n +(n))
  (expect-eq !>(`@ud`10) !>(steps))
::
++  test-sink-search-terminates
  ::  The whole candidate graph below a small triple is finite and reaches
  ::  zero. Weight decrease is what guarantees it.
  ^-  tang
  =/  seen=(set *)
    =|  seen=(set *)
    =/  todo=(list vase)  ~[!>(`[@ud @ud @ud]`[6 3 2])]
    |-  ^-  (set *)
    ?~  todo  seen
    ?:  (~(has in seen) q.i.todo)  $(todo t.todo)
    ?>  (lte ~(wyt in seen) 84)
    =/  more=(list vase)  (weld (sink:quiz i.todo) t.todo)
    $(seen (~(put in seen) q.i.todo), todo more)
  ;:  weld
    (expect !>((lte ~(wyt in seen) 84)))
    (expect !>((~(has in seen) [0 0 0])))
  ==
::
++  test-sink-list
  ::  A list's type is a fork; the default shrinker offers nothing for it.
  ::  Lists need custom alts.
  ^-  tang
  =/  items  !>(`(list @ud)`~[1 2 3])
  (expect-eq !>(`(list *)`~) !>((turn (sink:quiz items) tail)))
::
++  test-sink-constant
  ^-  tang
  ;:  weld
    (expect-eq !>(`(list *)`~) !>((turn (sink:quiz !>(%foo)) tail)))
    (expect-eq !>(`(list *)`~) !>((turn (sink:quiz !>(`?`&)) tail)))
  ==
--
