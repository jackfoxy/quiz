/+  engine=quiz-engine
|%
  ::  Property combinators for app fates.
  ::
  ::  A fate may return a bare verdict (%.y, %.n or %drop) or a report built
  ::  here. Reports explain failures (notes, expected and actual text) and
  ::  classify passing samples (labels and table rows) for the run's
  ::  distribution and a document's ++cover requirements.
  ::
  ::  Hoon is strict: every prop in a list has already been evaluated. Use
  ::  ++implies with a trap to guard a partial computation.
  ::
  ::  ++same and ++collect take vases. A wet gate's formula is compiled once
  ::  against its formal sample, so !> inside one would see only `*`; the
  ::  caller's !> keeps the real type for rendering.
  ::
  ::  Usage:
  ::    /+  prop=quiz-prop
  ::    ++  fate
  ::      |=  items=(list @ud)
  ::      %+  classify:prop  =(~ items)  'empty'
  ::      (same:prop !>((lent items)) !>((lent (flop items))))
  ::
+$  verdict  verdict-product:engine
+$  report  report:engine
+$  prop  $@(verdict report)
::
++  lift
  ::  Normalize a bare verdict to a report.
  |=  p=prop
  ^-  report
  ?@  p  [%report p [~ ~] ~ ~]
  p
::
++  render
  ::  The text a run shows for a typed value.
  |=  value=vase
  ^-  @t
  (crip ~(ram re (sell value)))
::
++  same
  ::  Passes when the values are equal; on failure shows both, each rendered
  ::  with its own type.
  |=  [want=vase got=vase]
  ^-  report
  ?:  =(q.want q.got)  (lift &)
  [%report | [~ `[(render want) (render got)]] ~ ~]
::
++  note
  ::  Attach a line of explanation, shown if the property fails.
  |=  [text=@t p=prop]
  ^-  report
  =/  r  (lift p)
  r(notes.detail (snoc notes.detail.r text))
::
++  label
  ::  Label the sample; a passing run counts samples per label.
  |=  [text=@t p=prop]
  ^-  report
  =/  r  (lift p)
  r(labels [text labels.r])
::
++  classify
  ::  Label the sample only when the condition holds.
  |=  [c=? text=@t p=prop]
  ^-  report
  ?.(c (lift p) (label text p))
::
++  collect
  ::  Label the sample with a value's rendered text.
  |=  [value=vase p=prop]
  ^-  report
  (label (render value) p)
::
++  tabulate
  ::  Count each value under a named table, many per sample.
  |=  [table=@t values=(list @t) p=prop]
  ^-  report
  =/  r  (lift p)
  =/  rows=(list [table=@t value=@t])
    (turn values (lead table))
  r(tables (weld rows tables.r))
::
++  implies
  ::  Drop the sample unless the precondition holds; the trap runs only then.
  |=  [pre=? p=(trap prop)]
  ^-  prop
  ?.(pre %drop $:p)
::
++  merge
  ::  The tags and notes of every report, in order.
  |=  rs=(list report)
  ^-  [notes=(list @t) labels=(list @t) tables=(list [table=@t value=@t])]
  =/  notes=(list @t)  (zing (turn rs |=(r=report notes.detail.r)))
  =/  labels=(list @t)  (zing (turn rs |=(r=report labels.r)))
  =/  tables=(list [table=@t value=@t])
    (zing (turn rs |=(r=report tables.r)))
  [notes labels tables]
::
++  all
  ::  Conjunction. Fails with the first failure's comparison; any drop with
  ::  no failure drops. Tags and notes of every part are kept.
  |=  ps=(list prop)
  ^-  report
  =/  rs=(list report)  (turn ps lift)
  =/  m  (merge rs)
  =/  bad  (skim rs |=(r=report =(| ok.r)))
  ?^  bad
    [%report | [notes.m compared.detail.i.bad] labels.m tables.m]
  =/  ok=verdict  ?:((lien rs |=(r=report =(%drop ok.r))) %drop &)
  [%report ok [notes.m ~] labels.m tables.m]
::
++  any
  ::  Disjunction. Passes if any part passes; fails, with every part's notes
  ::  and the first comparison, only when some part failed and none passed.
  |=  ps=(list prop)
  ^-  report
  =/  rs=(list report)  (turn ps lift)
  =/  m  (merge rs)
  ?:  (lien rs |=(r=report =(& ok.r)))
    [%report & [~ ~] labels.m tables.m]
  =/  bad  (skim rs |=(r=report =(| ok.r)))
  ?~  bad  [%report %drop [notes.m ~] labels.m tables.m]
  [%report | [notes.m compared.detail.i.bad] labels.m tables.m]
--
