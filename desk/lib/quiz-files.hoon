/-  urui
/+  ufiles=urui-files, build=quiz-build
|%
  ::  urui's tomb probe uses the file's case as the outer scry date.
  ::  For a pinned numeric revision, keep that case on the inner beam
  ::  and use now for the outer tomb query. Shared urui stays unchanged.
  ::
++  handle
  |=  $:  policy=policy:ufiles
          bol=bowl:gall
          id=@ta
          req=inbound-request:eyre
          current=(unit pending:ufiles)
      ==
  ^-  outcome:ufiles
  =/  parsed  (parse-request:ufiles policy req)
  ?:  ?=(%.n -.parsed)
    [(refuse:ufiles id p.parsed) current]
  =/  op  p.parsed
  ?:  ?=(?(%save %delete) -.op)
    =/  where  (resolve:ufiles policy bol rel.op)
    ?:  ?=(%.n -.where)
      [(refuse:ufiles id p.where) current]
    ?.  write.p.where
      [(refuse:ufiles id read-only:ufiles) current]
    (handle:ufiles policy bol id req current)
  ?.  ?=([%load *] op)
    (handle:ufiles policy bol id req current)
  ?.  ?=([%clay *] rel.op)
    (handle:ufiles policy bol id req current)
  =/  where  (resolve:ufiles policy bol rel.op)
  ?:  ?=(%.n -.where)
    [(refuse:ufiles id p.where) current]
  =/  beam  (en-beam beak.p.where rel.p.where)
  =/  tomb  ~[(scot %p our.bol) %$ (scot %da now.bol) %tomb]
  ?.  .^(? %cx (weld tomb beam))
    [(refuse:ufiles id missing:ufiles) current]
  =/  text  (need (from-stored:ufiles %cord .^(* %cq beam)))
  :_  current
  %+  reply:ufiles  id
  %-  ok-json:ufiles
  :~  ['text' s+text]
      ['hash' s+(text-hash:ufiles text)]
      ['readonly' b+&]
  ==
::
  ::  Virtual workbench roots. Only work documents may be written.
  ::
++  locate
  |=  [bol=bowl:gall rel=path]
  ^-  (each location:ufiles failure:ufiles)
  =/  here=beak  [our.bol q.byk.bol [%da now.bol]]
  ?+  rel
    ::  Keep the Unit 8 relative Hoon wire as a writable alias.
    [%.y [here (weld /data/quiz rel) &]]
    [%work *]      [%.y [here (weld /data/quiz t.rel) &]]
    [%examples *]  [%.y [here (weld /tests/examples t.rel) |]]
    [%docs *]      [%.y [here (weld /doc t.rel) |]]
    [%clay *]
      ?.  ?=([%clay @ @ *] rel)
        [%.n (fail:ufiles %context 400 'select a desk and revision')]
      =/  desk  i.t.rel
      =/  revision  (rush i.t.t.rel dem)
      ?~  revision
        [%.n (fail:ufiles %context 400 'revision must be a decimal number')]
      =/  pinned  (pin:build our.bol desk [%ud u.revision] now.bol)
      ?:  ?=(%.n -.pinned)
        [%.n (fail:ufiles %context 404 code.p.pinned)]
      =/  ctx  p.pinned
      [%.y [[our.ctx desk.ctx [%ud revision.ctx]] t.t.t.rel |]]
  ==
--
