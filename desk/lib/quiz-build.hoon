/+  engine=quiz-engine
|%
  ::  Restricted Ford documents, pinned Clay reads, and checked engine parts.
  ::  Compilation/arm evaluation are virtualized. Callers apply the %jinx
  ::  CPU limit around draft, take-saved and compile.
  ::
+$  context  [our=ship desk=@tas revision=@ud]
::
+$  document-conf  [seed=(unit @uv) config=conf:engine]
::
+$  diagnostic
  [code=@tas path=path at=hair arm=(unit term) trace=tang clipped=?]
::
+$  dependency
  [face=(unit term) path=path mark=mark build=? at=hair]
::
+$  prepared
  [where=context path=path source=@t deps=(list dependency) code=hoon]
::
+$  product
  ::  `within` is the document's ++within; it lowers the call limit and is
  ::  never part of the replayable conf.
  $:  where=context
      settings=document-conf
      parts=parts:engine
      within=(unit @dr)
  ==
::
+$  result  $%([%ready product] [%invalid diagnostic])
::
+$  arm-name
  $?  %fate  %norn  %alts  %conf  %cover  %cover-table  %confidence
      %within  %expect
  ==
::
++  issue
  ::  Compiler traces include exact spans; at anchors the source/arm/import.
  |=  [code=@tas path=path at=hair arm=(unit term) trace=tang]
  ^-  diagnostic
  =/  fits  (fits:engine diagnostics-bytes.bounds:defaults:engine trace)
  [code path at arm ?:(fits trace ~) !fits]
::
++  safe-name
  ::  A desk name: a symbol of at most 64 bytes.
  |=  text=@t
  ^-  ?
  ?&  (lte (met 3 text) 64)
      !=(~ (rush text (full sym)))
  ==
::
++  safe-path
  ::  1 to 32 segments, each 1 to 64 bytes of a-z, 0-9 and -.
  |=  path=path
  ^-  ?
  ?&  !=(~ path)
      (lte (lent path) 32)
      %+  levy  path
      |=  part=@ta
      ?&  (gth (met 3 part) 0)
          (lte (met 3 part) 64)
          %+  levy  (trip part)
          |=  ch=@t
          ?|  &((gte ch 'a') (lte ch 'z'))
              &((gte ch '0') (lte ch '9'))
              =(ch '-')
          ==
      ==
  ==
::
++  validate
  ::  Call before any Clay read. Only explicit positive %ud cases are pinned.
  |=  [desk=@t revision=case path=path mark=mark source=@t]
  ^-  (unit diagnostic)
  ?.  (safe-name desk)  `(issue %desk path [1 1] ~ ~)
  ?.  ?=([%ud *] revision)  `(issue %case path [1 1] ~ ~)
  ?:  =(p.revision 0)  `(issue %case path [1 1] ~ ~)
  ?.  (safe-path path)  `(issue %path path [1 1] ~ ~)
  ?.  &(=(%hoon mark) =(%hoon (rear path)))
    `(issue %mark path [1 1] ~ ~)
  ?:  (gth (met 3 source) source-bytes.bounds:defaults:engine)
    `(issue %source-size path [1 1] ~ ~)
  ~
::
++  pin
  ::  Inspect known local desk metadata before issuing a revision read.
  |=  [our=ship desk=@t revision=case now=@da]
  ^-  (each context diagnostic)
  ?.  (safe-name desk)  [%.n (issue %desk / [1 1] ~ ~)]
  ?:  |(?=([%uv *] revision) =([%ud 0] revision))
    [%.n (issue %case / [1 1] ~ ~)]
  ?:  &(?=([%tas *] revision) !(safe-name p.revision))
    [%.n (issue %case / [1 1] ~ ~)]
  =/  desks  .^((set @tas) %cd [(scot %p our) %$ (scot %da now) ~])
  ?.  (~(has in desks) desk)
    =/  trace=tang  ~[[%leaf "desk %{(trip desk)} is unavailable on {<our>}"]]
    [%.n (issue %desk-unavailable / [1 1] ~ trace)]
  =/  latest=path  /(scot %p our)/[desk]/(scot %da now)
  =/  dom  .^(domo:clay %cv latest)
  =/  exists
    ?-  -.revision
      %ud  (~(has by hit.dom) p.revision)
      %tas  (~(has by lab.dom) p.revision)
      %da  (lte p.revision now)
    ==
  ?.  exists
    =/  trace=tang
      ~[[%leaf "revision {<revision>} is unavailable in %{(trip desk)}"]]
    [%.n (issue %revision-unavailable / [1 1] ~ trace)]
  =/  root=path  /(scot %p our)/[desk]/(scot revision)
  =/  cass  .^([@ud @da] %cw root)
  ?:  =(-.cass 0)
    [%.n (issue %revision-unavailable / [1 1] ~ ~)]
  [%.y [our `@tas`desk -.cass]]
::
++  import-rule
  ::  Zero or more `/rune body` lines, each followed by a gap.
  |*  [rune=rule body=rule]
  ;~  pose
    ;~(sfix (more gap ;~(pfix fas rune gap body)) gap)
    (easy ~)
  ==
::
++  taut-rule
  ::  One import: `*name` (no face), `face=name`, or `name` as its own face.
  ;~  pose
    (stag ~ ;~(pfix tar sym))
    ;~(plug (stag ~ sym) ;~(pfix tis sym))
    (cook |=(name=term [`name name]) sym)
  ==
::
++  header-rule
  ::  The prelude: /- then /+ then /= then /* lines, as dependencies
  ::  in that order.
  =/  sur
    %+  here
      |=  [loc=pint names=(list taut:clay)]
      ^-  (list dependency)
      %+  turn  names
      |=  [face=(unit term) name=term]
      [face /sur/[name]/hoon %hoon %.y p.loc]
    (most ;~(plug com gaw) taut-rule)
  =/  lib
    %+  here
      |=  [loc=pint names=(list taut:clay)]
      ^-  (list dependency)
      %+  turn  names
      |=  [face=(unit term) name=term]
      [face /lib/[name]/hoon %hoon %.y p.loc]
    (most ;~(plug com gaw) taut-rule)
  =/  raw
    %+  here
      |=  [loc=pint face=term path=path]
      ^-  dependency
      [`face (snoc path %hoon) %hoon %.y p.loc]
    ;~((glue gap) sym stap)
  =/  data
    %+  here
      |=  [loc=pint face=term mark=mark path=path]
      ^-  dependency
      [`face path mark %.n p.loc]
    ;~((glue gap) sym ;~(pfix cen sym) stap)
  %+  ifix  [gay gay]
  %+  cook
    |=  $:  a=(list (list dependency))  b=(list (list dependency))
            c=(list dependency)  d=(list dependency)
        ==
    ^-  (list dependency)
    =/  groups=(list (list dependency))  ~
    =.  groups  (weld a (weld b [c d ~]))
    (zing groups)
  ;~  plug
    (import-rule hep sur)
    (import-rule lus lib)
    (import-rule tis raw)
    (import-rule tar data)
  ==
::
++  prepare
  ::  Validate the path, parse the prelude, check each import's path and
  ::  mark, then parse the body. Reads nothing from Clay.
  |=  [where=context path=path source=@t]
  ^-  (each prepared diagnostic)
  =/  bad  (validate desk.where [%ud revision.where] path %hoon source)
  ?^  bad  [%.n u.bad]
  =/  header  (header-rule [1 1] (trip source))
  ?~  q.header  [%.n (issue %prelude path p.header ~ ~)]
  =/  deps  p.u.q.header
  =/  rest  q.u.q.header
  ?:  ?=([%'/' *] q.rest)
    =/  known  ?=([%'/' ?(%'-' %'+' %'=' %'*') *] q.rest)
    [%.n (issue ?:(known %prelude %unsupported-prelude) path p.rest ~ ~)]
  =/  invalid=(unit diagnostic)
    =/  todo  deps
    |-  ^-  (unit diagnostic)
    ?~  todo  ~
    =/  dep  i.todo
    ?.  (safe-path path.dep)
      `(issue %import-path path at.dep face.dep ~)
    ?.  &(?=(?(%hoon %txt %noun) mark.dep) =(mark.dep (rear path.dep)))
      `(issue %import-mark path at.dep face.dep ~)
    $(todo t.todo)
  ?^  invalid  [%.n u.invalid]
  =/  parsed  ((full (ifix [gay gay] tall:(vang & path))) rest)
  ?~  q.parsed  [%.n (issue %syntax path p.parsed ~ ~)]
  [%.y [where path source deps p.u.q.parsed]]
::
++  arm-at
  ::  Semantic errors anchor at the arm declaration; traces refine the span.
  |=  [source=@t name=term]
  ^-  hair
  =/  lines  (to-wain:format source)
  =/  row  1
  |-
  ?~  lines  [1 1]
  =/  found
    (;~(pfix gay (jest '++') gap sym) [row 1] (trip i.lines))
  ?:  ?&(?=(^ q.found) =(p.u.q.found name))  [row 1]
  $(lines t.lines, row +(row))
::
++  valid-config
  ::  Every budget and bound within the defaults' ceilings, every bound
  ::  positive, size-start at least 1, size-max 0 or at least size-start.
  |=  cfg=conf:engine
  ^-  ?
  =/  max  defaults:engine
  ?&  (lte requested.cfg requested-max.bounds.max)
      (lte requested.cfg requested-max.bounds.cfg)
      (lte attempts-max.cfg attempts-max.max)
      (lte drops-max.cfg drops-max.max)
      (lte duplicates-max.cfg duplicates-max.max)
      (gte size-start.cfg 1)
      |(=(0 size-max.cfg) (gte size-max.cfg size-start.cfg))
      (lte source-bytes.bounds.cfg source-bytes.bounds.max)
      (lte requested-max.bounds.cfg requested-max.bounds.max)
      (lte shrink-candidates.bounds.cfg shrink-candidates.bounds.max)
      (lte shrink-depth.bounds.cfg shrink-depth.bounds.max)
      (lte sample-bytes.bounds.cfg sample-bytes.bounds.max)
      (lte rendered-bytes.bounds.cfg rendered-bytes.bounds.max)
      (lte diagnostics-bytes.bounds.cfg diagnostics-bytes.bounds.max)
      (lte alts-bytes.bounds.cfg alts-bytes.bounds.max)
      (lte seen-bytes.bounds.cfg seen-bytes.bounds.max)
      (lte retained-runs.bounds.cfg retained-runs.bounds.max)
      (lte samples-per-slice.bounds.cfg samples-per-slice.bounds.max)
      (lte trace-steps.bounds.cfg trace-steps.bounds.max)
      (gth source-bytes.bounds.cfg 0)
      (gth sample-bytes.bounds.cfg 0)
      (gth rendered-bytes.bounds.cfg 0)
      (gth diagnostics-bytes.bounds.cfg 0)
      (gth alts-bytes.bounds.cfg 0)
      (gth seen-bytes.bounds.cfg 0)
      (gth retained-runs.bounds.cfg 0)
      (gth samples-per-slice.bounds.cfg 0)
  ==
::
++  valid-cover
  ::  At most label-max distinct, nonempty, bounded labels; whole percents.
  |=  =cover:engine
  ^-  ?
  =/  labels=(list @t)  (turn rows.cover head)
  ?&  (lte (lent rows.cover) label-max:engine)
      =((lent labels) ~(wyt in (silt labels)))
      %+  levy  rows.cover
      |=  [label=@t percent=@ud]
      ?&  (gth (met 3 label) 0)
          (lte (met 3 label) label-bytes:engine)
          (lte percent 100)
      ==
  ==
::
++  valid-tables
  ::  At most label-max distinct rows; nonempty, bounded names; whole
  ::  percents.
  |=  rows=(list table-row:engine)
  ^-  ?
  =/  keys=(list [@t @t])  (turn rows |=(r=table-row:engine [table.r value.r]))
  =/  name  |=(t=@t &((gth (met 3 t) 0) (lte (met 3 t) label-bytes:engine)))
  ?&  (lte (lent rows) label-max:engine)
      =((lent keys) ~(wyt in (silt keys)))
      %+  levy  rows
      |=  r=table-row:engine
      &((name table.r) (name value.r) (lte percent.r 100))
  ==
::
++  valid-confidence
  ::  Certainty 1 to 15 (wrong 1 in 10^k); tolerance 1 to 100 percent.
  |=  =confidence:engine
  ^-  ?
  ?&  (gte certainty.confidence 1)
      (lte certainty.confidence (lent z-table:engine))
      (gte tolerance.confidence 1)
      (lte tolerance.confidence 100)
  ==
::
++  inspect-gate
  ::  Infer the product without executing the gate on its bunt sample.
  |=  [gate=vase input=(unit type) output=type]
  ^-  ?
  ?.  =((sloe p.gate) ~[%$])  %.n
  =/  sample  (slot 6 gate)
  =/  actual  (slit p.gate ?~(input p.sample u.input))
  (~(nest ut output) | actual)
::
++  check-core
  ::  Check the compiled core's arms in order: fate, norn, alts, conf,
  ::  cover, cover-table, confidence, expect. Absent optional arms keep
  ::  defaults; the first bad arm is the diagnostic. The norn must produce
  ::  the fate's sample type. ++cover-table without ++cover uses %check;
  ::  ++confidence matters only to a %confident ++cover. ++within is a
  ::  call limit from within-min to within-max.
  |=  [doc=prepared core=vase]
  ^-  result
  =/  names  (sloe p.core)
  ?.  (~(has in (silt names)) %fate)
    [%invalid (issue %fate-missing path.doc [1 1] `%fate ~)]
  =/  parts=parts:engine  [*vase ~ ~ ~ %pass]
  =/  settings=document-conf  [~ defaults:engine]
  =/  wanted=(list arm-name)
    :~  %fate  %norn  %alts  %conf  %cover  %cover-table  %confidence
        %within  %expect
    ==
  =/  within=(unit @dr)  ~
  |-
  ?~  wanted
    ?:  (gth (met 3 source.doc) source-bytes.bounds.config.settings)
      [%invalid (issue %source-size path.doc [1 1] `%conf ~)]
    [%ready where.doc settings parts within]
  =/  arm  i.wanted
  =/  rest  t.wanted
  ?.  (~(has in (silt names)) arm)  $(wanted rest)
  =/  at  (arm-at source.doc arm)
  =/  got  (~(mule vi |) |.((slap core [%limb arm])))
  ?:  ?=(%.n -.got)
    [%invalid (issue %arm path.doc at `arm p.got)]
  =/  value  p.got
  ?:  ?=(%conf arm)
    ?.  (~(nest ut p:!>(*document-conf)) | p.value)
      [%invalid (issue %conf-type path.doc at `arm ~)]
    =/  settings  ;;(document-conf q.value)
    ?.  (valid-config config.settings)
      [%invalid (issue %conf-range path.doc at `arm ~)]
    $(wanted rest, settings settings)
  ?:  ?=(%cover arm)
    ?.  (~(nest ut p:!>(*cover:engine)) | p.value)
      [%invalid (issue %cover-type path.doc at `arm ~)]
    =/  cover  ;;(cover:engine q.value)
    ?.  (valid-cover cover)
      [%invalid (issue %cover-range path.doc at `arm ~)]
    =/  base=coverage:engine
      (fall cover.parts [cover ~ default-confidence:engine])
    $(wanted rest, parts parts(cover `base(cover cover)))
  ?:  ?=(%cover-table arm)
    ?.  (~(nest ut p:!>(*(list table-row:engine))) | p.value)
      [%invalid (issue %cover-table-type path.doc at `arm ~)]
    =/  rows  ;;((list table-row:engine) q.value)
    ?.  (valid-tables rows)
      [%invalid (issue %cover-table-range path.doc at `arm ~)]
    =/  base=coverage:engine
      (fall cover.parts [[%check ~] ~ default-confidence:engine])
    $(wanted rest, parts parts(cover `base(tables rows)))
  ?:  ?=(%confidence arm)
    ?.  (~(nest ut p:!>(*confidence:engine)) | p.value)
      [%invalid (issue %confidence-type path.doc at `arm ~)]
    =/  confidence  ;;(confidence:engine q.value)
    ?.  (valid-confidence confidence)
      [%invalid (issue %confidence-range path.doc at `arm ~)]
    ?~  cover.parts  $(wanted rest)
    $(wanted rest, parts parts(cover `u.cover.parts(confidence confidence)))
  ?:  ?=(%within arm)
    ?.  (~(nest ut p:!>(*@dr)) | p.value)
      [%invalid (issue %within-type path.doc at `arm ~)]
    =/  limit  ;;(@dr q.value)
    ?.  &((gte limit within-min:engine) (lte limit within-max:engine))
      [%invalid (issue %within-range path.doc at `arm ~)]
    $(wanted rest, within `limit)
  ?:  ?=(%expect arm)
    ?.  (~(nest ut p:!>(*expectation:engine)) | p.value)
      [%invalid (issue %expect-type path.doc at `arm ~)]
    $(wanted rest, parts parts(expect ;;(expectation:engine q.value)))
  =/  input=(unit type)
    ?-  arm
      %fate  ~
      %norn  `p:!>(*[@ud _og])
      %alts  `p:!>(*vase)
    ==
  =/  output=type
    ?-  arm
      %fate  p:!>(*?(? %drop report:engine))
      %norn  p:(slot 6 fate.parts)
      %alts  p:!>(*(list vase))
    ==
  =/  check  (mule |.((inspect-gate value input output)))
  ?:  |(?=(%.n -.check) =(p.check %.n))
    =/  code  ?-(arm %fate %fate-type, %norn %norn-type, %alts %alts-type)
    [%invalid (issue code path.doc at `arm ?:(?=(%.n -.check) p.check ~))]
  =.  parts
    ?-  arm
      %fate  parts(fate value)
      %norn  parts(norn `value)
      %alts  parts(alts `value)
    ==
  $(wanted rest)
::
++  compile
  ::  Dependencies are ordered exactly as Ford: each is pushed onto zuse.
  |=  [doc=prepared imports=(list vase)]
  ^-  result
  ?.  =((lent imports) (lent deps.doc))
    [%invalid (issue %imports path.doc [1 1] ~ ~)]
  =/  subject=vase  !>(..zuse)
  =/  deps  deps.doc
  |-
  ?~  deps
    =/  got  (~(mule vi |) |.((slap subject code.doc)))
    ?:  ?=(%.n -.got)
      [%invalid (issue %compile path.doc [1 1] ~ p.got)]
    (check-core doc p.got)
  ?>  ?=(^ imports)
  =/  dep  i.imports
  =?  p.dep  ?=(^ face.i.deps)  [%face u.face.i.deps p.dep]
  $(deps t.deps, imports t.imports, subject (slop dep subject))
::
++  draft-requests
  ::  Use asynchronous Clay reads: a failed %ca scry escapes Gall's mule.
  |=  doc=prepared
  ^-  (list [ship desk (unit rave:clay)])
  %+  turn  deps.doc
  |=  dep=dependency
  :*  our.where.doc  desk.where.doc
      `[%sing ?:(build.dep %a %x) [%ud revision.where.doc] path.dep]
  ==
::
++  draft
  ::  Replies must be in prelude order. Failed dependencies stay located.
  |=  [doc=prepared replies=(list riot:clay)]
  ^-  result
  ?.  =((lent replies) (lent deps.doc))
    [%invalid (issue %imports path.doc [1 1] ~ ~)]
  =/  deps  deps.doc
  =/  imports=(list vase)  ~
  |-
  ?~  deps  (compile doc (flop imports))
  ?>  ?=(^ replies)
  =/  dep  i.deps
  =/  reply  i.replies
  ?~  reply  [%invalid (issue %import path.doc at.dep face.dep ~)]
  ?.  ?&  =(?:(build.dep %a %x) p.p.u.reply)
          =([%ud revision.where.doc] q.p.u.reply)
          =(desk.where.doc r.p.u.reply)
          =(path.dep q.u.reply)
      ==
    [%invalid (issue %import-context path.doc at.dep face.dep ~)]
  ?.  =(?:(build.dep %vase mark.dep) p.r.u.reply)
    [%invalid (issue %import-mark path.doc at.dep face.dep ~)]
  =/  loaded
    %-  mule
    |.
    ?:  build.dep  !<(vase q.r.u.reply)
    ?-  mark.dep
      %hoon  !>(!<(@t q.r.u.reply))
      %txt   !>(!<(wain q.r.u.reply))
      %noun  q.r.u.reply
      *      !!
    ==
  ?:  ?=(%.n -.loaded)
    [%invalid (issue %import-type path.doc at.dep face.dep p.loaded)]
  $(deps t.deps, replies t.replies, imports [p.loaded imports])
::
++  prepare-file
  ::  Read the source at the same pinned revision used by saved-request.
  |=  [where=context path=path]
  ^-  (each prepared diagnostic)
  =/  bad  (validate desk.where [%ud revision.where] path %hoon '')
  ?^  bad  [%.n u.bad]
  =/  root=(list @ta)
    /(scot %p our.where)/[desk.where]/(scot %ud revision.where)
  ?.  .^(? %cu (weld root path))
    [%.n (issue %source path [1 1] ~ ~)]
  (prepare where path .^(@t %cx (weld root path)))
::
++  saved-request
  ::  The Gall adapter sends this as %c %warp, after prepare succeeds.
  |=  doc=prepared
  ^-  [ship desk (unit rave:clay)]
  [our.where.doc desk.where.doc `[%sing %a [%ud revision.where.doc] path.doc]]
::
++  take-saved
  ::  Clay failures carry no tang; draft compilation can refine the error.
  |=  [doc=prepared reply=riot:clay]
  ^-  result
  ?~  reply  [%invalid (issue %build path.doc [1 1] ~ ~)]
  ?.  ?&  =(%a p.p.u.reply)
          =([%ud revision.where.doc] q.p.u.reply)
          =(desk.where.doc r.p.u.reply)
          =(path.doc q.u.reply)
      ==
    [%invalid (issue %build-context path.doc [1 1] ~ ~)]
  ?.  =(%vase p.r.u.reply)
    [%invalid (issue %build-mark path.doc [1 1] ~ ~)]
  =/  decoded  (mule |.(!<(vase q.r.u.reply)))
  ?:  ?=(%.n -.decoded)
    [%invalid (issue %build-product path.doc [1 1] ~ p.decoded)]
  (check-core doc p.decoded)
--
