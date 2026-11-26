/+  prop=quiz-prop, engine=quiz-engine, *test
|%
  ::  Property combinators: report shape, verdict mapping and tag merging.
  ::
::
++  test-lift
  ^-  tang
  ;:  weld
    (expect-eq !>(`report:engine`[%report & [~ ~] ~ ~]) !>((lift:prop &)))
    %+  expect-eq  !>(`report:engine`[%report %drop [~ ~] ~ ~])
    !>((lift:prop %drop))
  ==
::
++  test-same
  ::  Values render with their own types: a ship shows as a ship.
  ^-  tang
  =/  equal  (same:prop !>(3) !>(3))
  =/  ships  (same:prop !>(~zod) !>(~nec))
  ;:  weld
    (expect-eq !>(`?(? %drop)`&) !>(ok.equal))
    (expect-eq !>(`?(? %drop)`|) !>(ok.ships))
    %+  expect-eq  !>(`(unit [@t @t])``['~zod' '~nec'])
    !>(compared.detail.ships)
  ==
::
++  test-note-label-classify
  ^-  tang
  =/  r  (note:prop 'first' (note:prop 'zero' |))
  =/  tagged  (classify:prop & 'yes' (classify:prop | 'no' &))
  =/  shown  (collect:prop !>(`@ud`5) &)
  ;:  weld
    (expect-eq !>(`(list @t)`~['zero' 'first']) !>(notes.detail.r))
    (expect-eq !>(`?(? %drop)`|) !>(ok.r))
    (expect-eq !>(`(list @t)`~['yes']) !>(labels.tagged))
    (expect-eq !>(`(list @t)`~['5']) !>(labels.shown))
  ==
::
++  test-tabulate
  ^-  tang
  =/  r  (tabulate:prop 'kind' ~['a' 'b'] &)
  %+  expect-eq  !>(`(list [@t @t])`~[['kind' 'a'] ['kind' 'b']])
  !>(tables.r)
::
++  test-implies
  ::  A false precondition drops without running the guarded trap.
  ^-  tang
  ;:  weld
    (expect-eq !>(`prop:prop`%drop) !>((implies:prop | |.(!!))))
    (expect-eq !>(`prop:prop`|) !>((implies:prop & |.(|))))
  ==
::
++  test-all
  ^-  tang
  =/  passed  (all:prop ~[& (label:prop 'a' &)])
  =/  failed  (all:prop ~[(label:prop 'a' &) (same:prop !>(1) !>(2)) |])
  =/  dropped  (all:prop ~[& %drop])
  ;:  weld
    (expect-eq !>(`?(? %drop)`&) !>(ok.passed))
    (expect-eq !>(`(list @t)`~['a']) !>(labels.passed))
    (expect-eq !>(`?(? %drop)`|) !>(ok.failed))
    (expect-eq !>(`(list @t)`~['a']) !>(labels.failed))
    %+  expect-eq  !>(`(unit [@t @t])``['1' '2'])
    !>(compared.detail.failed)
    (expect-eq !>(`?(? %drop)`%drop) !>(ok.dropped))
  ==
::
++  test-any
  ^-  tang
  =/  passed  (any:prop ~[| &])
  =/  failed  (any:prop ~[(note:prop 'x' |) (note:prop 'y' %drop)])
  =/  dropped  (any:prop ~[%drop %drop])
  ;:  weld
    (expect-eq !>(`?(? %drop)`&) !>(ok.passed))
    (expect-eq !>(`?(? %drop)`|) !>(ok.failed))
    (expect-eq !>(`(list @t)`~['x' 'y']) !>(notes.detail.failed))
    (expect-eq !>(`?(? %drop)`%drop) !>(ok.dropped))
  ==
--
