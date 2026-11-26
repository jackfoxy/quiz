/-  urui
/+  ufiles=urui-files, build=quiz-build
|%
::
++  handle
  ::  urui's tomb probe uses the file's case as the outer scry date.
  ::  For a pinned numeric revision, keep that case on the inner beam
  ::  and use now for the outer tomb query. Shared urui stays unchanged.
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
++  properties
  ::  Hoon files on `desk` at `revision` that are property documents (the
  ::  prelude imports quiz-engine, under any face, and `++  fate` is
  ::  declared) or suites (a `++  test-` arm), as workbench paths under
  ::  /clay with their role. The Clay source view lists these; Open lists
  ::  every Hoon file at the same context.
  |=  [bol=bowl:gall desk=@tas revision=@ud]
  ^-  (each (list [path role]) failure:ufiles)
  ::  a-co, not scot: +locate parses the revision with +dem, so no dots.
  =/  scope=path  /clay/[desk]/(crip (a-co:co revision))
  =/  where  (locate bol scope)
  ?:  ?=(%.n -.where)  where
  =/  tomb  ~[(scot %p our.bol) %$ (scot %da now.bol) %tomb]
  =/  found
    %-  mule
    |.
    %+  murn  (browse-paths:ufiles p.where)
    |=  sub=path
    ^-  (unit [path role])
    ?~  sub  ~
    ?.  =(%hoon (rear sub))  ~
    =/  beam  (en-beam beak.p.where (weld rel.p.where sub))
    ?.  .^(? %cx (weld tomb beam))  ~
    =/  text  (from-stored:ufiles %cord .^(* %cq beam))
    ?~  text  ~
    =/  role  (role-of u.text)
    ?~(role ~ `[(weld scope sub) u.role])
  ?:  ?=(%.n -.found)
    [%.n (fail-with:ufiles %internal 500 'clay browse failed' p.found)]
  [%.y p.found]
::
+$  role  ?(%property %suite)
::
++  role-of
  ::  A property document, else a suite, else neither.
  |=  text=@t
  ^-  (unit role)
  ?:  &((imports-engine text) (has-arm '++  fate' text))  `%property
  ?:  (has-arm '++  test-' text)  `%suite
  ~
::
++  imports-engine
  ::  Whether the prelude imports /lib/quiz-engine under any face. Only
  ::  whole lines within the first prelude-bytes are parsed.
  |=  text=@t
  ^-  ?
  =/  lines=wain  (to-wain:format (end [3 prelude-bytes] text))
  =?  lines  (gth (met 3 text) prelude-bytes)  (snip lines)
  =/  parsed  (header-rule:build [1 1] (trip (of-wain:format lines)))
  ?~  q.parsed  |
  %+  lien  p.u.q.parsed
  |=  dep=dependency:build
  =(/lib/quiz-engine/hoon path.dep)
::
++  has-arm
  ::  Whether a line at column 0 is `++  fate` alone or before a space
  ::  (`head` is `'++  fate'`), or starts with `head` when that ends in a
  ::  hyphen (`'++  test-'`). Textual; the build still type-checks.
  |=  [head=@t text=@t]
  ^-  ?
  =/  size  (met 3 head)
  =/  prefix  =('-' (cut 3 [(dec size) 1] head))
  %+  lien  (to-wain:format text)
  |=  line=@t
  ?:  prefix  =(head (end [3 size] line))
  |(=(head line) =((cat 3 head ' ') (end [3 +(size)] line)))
::
++  prelude-bytes
  ::  Far longer than any real prelude; no need to read a whole file.
  4.096
::
++  locate
  ::  Virtual workbench roots. Only work documents may be written.
  |=  [bol=bowl:gall rel=path]
  ^-  (each location:ufiles failure:ufiles)
  =/  here=beak  [our.bol q.byk.bol [%da now.bol]]
  ?+  rel
    ::  A bare relative path is a writable work path.
    [%.y [here (weld /data/quiz rel) &]]
    [%work *]      [%.y [here (weld /data/quiz t.rel) &]]
    [%examples *]  [%.y [here (weld /tests/examples t.rel) |]]
    [%props *]     [%.y [here (weld /examples/props t.rel) |]]
    [%failing *]   [%.y [here (weld /examples/failing t.rel) |]]
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
