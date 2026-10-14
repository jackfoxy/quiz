/+  engine=quiz-engine
|%
  ::  Restricted Ford documents, pinned Clay reads, and checked engine parts.
  ::  Compilation/arm evaluation are virtualized; individual calls may hang.
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
+$  product  [where=context settings=document-conf parts=parts:engine]
::
+$  result  $%([%ready product] [%invalid diagnostic])
::
++  issue
  ::  Compiler traces include exact spans; at anchors the source/arm/import.
  |=  [code=@tas path=path at=hair arm=(unit term) trace=tang]
  ^-  diagnostic
  =/  fits  (fits:engine diagnostics-bytes.bounds:defaults:engine trace)
  [code path at arm ?:(fits trace ~) !fits]
::
++  safe-name
  |=  text=@t
  ^-  ?
  ?&  (lte (met 3 text) 64)
      !=(~ (rush text (full sym)))
  ==
::
++  safe-path
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
  ?.  (~(has in desks) desk)  [%.n (issue %context / [1 1] ~ ~)]
  =/  latest=path  /(scot %p our)/[desk]/(scot %da now)
  =/  dom  .^(domo:clay %cv latest)
  =/  exists
    ?-  -.revision
      %ud  (~(has by hit.dom) p.revision)
      %tas  (~(has by lab.dom) p.revision)
      %da  (lte p.revision now)
    ==
  ?.  exists  [%.n (issue %context / [1 1] ~ ~)]
  =/  root=path  /(scot %p our)/[desk]/(scot revision)
  =/  cass  .^([@ud @da] %cw root)
  ?:  =(-.cass 0)  [%.n (issue %context / [1 1] ~ ~)]
  [%.y [our `@tas`desk -.cass]]
::
++  import-rule
  |*  [rune=rule body=rule]
  ;~  pose
    ;~(sfix (more gap ;~(pfix fas rune gap body)) gap)
    (easy ~)
  ==
::
++  taut-rule
  ;~  pose
    (stag ~ ;~(pfix tar sym))
    ;~(plug (stag ~ sym) ;~(pfix tis sym))
    (cook |=(name=term [`name name]) sym)
  ==
::
++  header-rule
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
  |=  cfg=conf:engine
  ^-  ?
  =/  max  defaults:engine
  ?&  (lte requested.cfg requested-max.bounds.max)
      (lte requested.cfg requested-max.bounds.cfg)
      (lte attempts-max.cfg attempts-max.max)
      (lte drops-max.cfg drops-max.max)
      (lte duplicates-max.cfg duplicates-max.max)
      (lte source-bytes.bounds.cfg source-bytes.bounds.max)
      (lte requested-max.bounds.cfg requested-max.bounds.max)
      (lte shrink-candidates.bounds.cfg shrink-candidates.bounds.max)
      (lte shrink-depth.bounds.cfg shrink-depth.bounds.max)
      (lte sample-bytes.bounds.cfg sample-bytes.bounds.max)
      (lte rendered-bytes.bounds.cfg rendered-bytes.bounds.max)
      (lte diagnostics-bytes.bounds.cfg diagnostics-bytes.bounds.max)
      (lte alts-bytes.bounds.cfg alts-bytes.bounds.max)
      (lte retained-runs.bounds.cfg retained-runs.bounds.max)
      (lte samples-per-slice.bounds.cfg samples-per-slice.bounds.max)
      (gth source-bytes.bounds.cfg 0)
      (gth sample-bytes.bounds.cfg 0)
      (gth rendered-bytes.bounds.cfg 0)
      (gth diagnostics-bytes.bounds.cfg 0)
      (gth alts-bytes.bounds.cfg 0)
      (gth retained-runs.bounds.cfg 0)
      (gth samples-per-slice.bounds.cfg 0)
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
  |=  [doc=prepared core=vase]
  ^-  result
  =/  names  (sloe p.core)
  ?.  (~(has in (silt names)) %fate)
    [%invalid (issue %fate-missing path.doc [1 1] `%fate ~)]
  =/  parts=parts:engine  [*vase ~ ~]
  =/  settings=document-conf  [~ defaults:engine]
  =/  wanted=(list ?(%fate %norn %alts %conf))
    ~[%fate %norn %alts %conf]
  |-
  ?~  wanted
    ?:  (gth (met 3 source.doc) source-bytes.bounds.config.settings)
      [%invalid (issue %source-size path.doc [1 1] `%conf ~)]
    [%ready where.doc settings parts]
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
  =/  input=(unit type)
    ?-  arm
      %fate  ~
      %norn  `p:!>(*[@ud _og])
      %alts  `p:!>(*vase)
    ==
  =/  output=type
    ?-  arm
      %fate  p:!>(*?(? %drop))
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
