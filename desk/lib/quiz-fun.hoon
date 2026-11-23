/+  gen=quiz-gen
|%
  ::  Generated functions for higher-order properties.
  ::
  ::  A function is a finite table plus a default, as QuickCheck's Fun is:
  ::  plain data, so it replays exactly, renders, and shrinks. ++apply looks
  ::  a key up with =, first match winning, and falls back to `else`. Use
  ::  ++to-gate inside the fate to get a gate for turn, skim and the like.
  ::
  ::  A table contains a list, so a sample type holding one is recursive:
  ::  type the fate's sample `*` and mold it, as the examples do.
  ::
  ::  Usage:
  ::    /+  gen=quiz-gen, fun=quiz-fun
  ::    ++  norn  (fun-of:fun (range:gen 0 9) (range:gen 0 9) 5)
  ::    ++  alts
  ::      (alts-of:gen (fun:fun @ud @ud) (shrink-fun:fun @ud shrink-atom:gen))
  ::
++  fun  |$  [a b]  [cases=(list [key=a val=b]) else=b]
::
::  +|  Use
::
++  apply
  ::  The value of the first case whose key equals `key`, else the default.
  |*  [f=[cases=(list [* *]) else=*] key=*]
  =/  cases  cases.f
  |-  ^+  else.f
  ?~  cases  else.f
  ?:  =(-.i.cases key)  +.i.cases
  $(cases t.cases)
::
++  to-gate
  ::  The table as a gate, for turn, skim, cork and the like.
  |*  f=[cases=(list [* *]) else=*]
  |=  key=*
  (apply f key)
::
++  fun-text
  ::  Render a table as {k -> v, ..., _ -> d}. Pass a vase so keys and
  ::  values render with their own types: (fun-text !>(f)).
  |=  f=vase
  ^-  @t
  =/  show
    |=  v=vase
    ^-  tape
    ::  Faces would print as key=3; show the bare value.
    |-
    ?:  ?=([%face *] p.v)  $(p.v q.p.v)
    ~(ram re (sell v))
  =/  cases  (slot 2 f)
  =|  out=tape
  |-
  ?@  q.cases
    (crip "\{{out}_ -> {(show (slot 3 f))}}")
  =/  one  (slot 2 cases)
  =/  row  "{(show (slot 2 one))} -> {(show (slot 3 one))}, "
  $(cases (slot 3 cases), out (weld out row))
::
::  +|  Generators
::
++  fun-of
  ::  Up to min(n, size) cases, each key and value from its own stream,
  ::  then a default. A repeated key is shadowed by its first case, and
  ::  shrinking drops it.
  |*  [keys=$-([@ud _og] *) vals=$-([@ud _og] *) n=@ud]
  |=  [size=@ud rng=_og]
  =/  [one=_og two=_og]  (split:gen rng)
  =/  cases  ((list-of:gen 0 n (pair:gen keys vals)) size one)
  [cases=cases else=(vals size two)]
::
++  fun-on
  ::  A total table over a finite domain, one case per element in order,
  ::  each value from its own stream.
  |*  [domain=(list) vals=$-([@ud _og] *)]
  |=  [size=@ud rng=_og]
  =/  [one=_og two=_og]  (split:gen rng)
  =/  keys  (homo domain)
  =/  out  *(list [_(snag 0 keys) _(vals size one)])
  |-
  ?~  keys  [cases=(flop out) else=(vals size two)]
  =/  [here=_og next=_og]  (split:gen one)
  $(keys t.keys, one next, out [[i.keys (vals size here)] out])
::
::  +|  Shrinking
::
++  shrink-fun
  ::  Keys never change, since that would change which inputs a case
  ::  covers. Candidates, simplest first: the constant function, fewer
  ::  cases (by shrink-list), smaller case values, then a smaller default.
  ::  Every candidate weighs less than the table.
  |*  [key=mold item=$-(* (list))]
  |=  f=(fun key _+<.item)
  =/  keep  |=(k=key `(list key)`~)
  =/  tables=(list _cases.f)
    ((shrink-list:gen (shrink-pair:gen keep item)) cases.f)
  =/  smaller=(list _f)  (turn tables |=(c=_cases.f f(cases c)))
  =/  defaults=(list _f)  (turn (item else.f) |=(e=_else.f f(else e)))
  (weld smaller defaults)
--
