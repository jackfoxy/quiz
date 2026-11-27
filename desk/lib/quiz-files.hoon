/-  urui
/+  ufiles=urui-files, build=quiz-build
|%
::
++  handle
  ::  urui's file wire over Clay, as +locate maps it: only property
  ::  documents, suites and quiz suites (+role-of) are opened or saved.
  ::
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
    ?:  &(?=(%save -.op) ?=(~ (role-of text.op)))
      [(refuse:ufiles id unindexed) current]
    (handle:ufiles policy bol id req current)
  ?.  ?=([%load *] op)
    (handle:ufiles policy bol id req current)
  =/  where  (resolve:ufiles policy bol rel.op)
  ?:  ?=(%.n -.where)
    [(refuse:ufiles id p.where) current]
  =/  beam  (en-beam beak.p.where rel.p.where)
  =/  tomb  ~[(scot %p our.bol) %$ (scot %da now.bol) %tomb]
  ?.  .^(? %cx (weld tomb beam))
    [(refuse:ufiles id missing:ufiles) current]
  =/  text  (need (from-stored:ufiles %cord .^(* %cq beam)))
  ?~  (role-of text)
    [(refuse:ufiles id unindexed) current]
  :_  current
  %+  reply:ufiles  id
  %-  ok-json:ufiles
  :~  ['text' s+text]
      ['hash' s+(text-hash:ufiles text)]
      ['readonly' b+!write.p.where]
  ==
::
++  unindexed
  ::  The refusal for a file that is not a property document or suite.
  ^-  failure:ufiles
  %^  fail:ufiles  %unindexed  400
  'only property documents, suites and quiz suites can be opened or saved'
::
++  properties
  ::  Hoon files on `desk` at `revision` that are property documents,
  ::  suites or quiz suites (see +role-of), as workbench paths under /clay
  ::  with their role. The Clay source view lists these; Open lists every
  ::  Hoon file at the same context.
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
+$  role  ?(%property %suite %quiz-suite)
::
++  quiz-libs
  ::  Libraries whose import, beside /lib/test, makes a quiz suite.
  ^-  (list path)
  ~[/lib/quiz/hoon /lib/quiz-auto/hoon /lib/quiz-engine/hoon]
::
++  role-of
  ::  A property document, else a suite, else neither. Both are read from
  ::  the prelude's imports: a property imports quiz-engine and declares
  ::  `++  fate`; a suite imports /lib/test and has a `++  test-` arm, and
  ::  is a quiz suite when it also imports a quiz library.
  |=  text=@t
  ^-  (unit role)
  =/  libs=(set path)  (silt (imports text))
  ?:  &((~(has in libs) /lib/quiz-engine/hoon) (has-arm '++  fate' text))
    `%property
  ?.  &((~(has in libs) /lib/test/hoon) (has-arm '++  test-' text))
    ~
  ?.  (lien quiz-libs ~(has in libs))  `%suite
  `%quiz-suite
::
++  imports
  ::  The libraries the prelude imports, under any face. Only whole lines
  ::  within the first prelude-bytes are parsed.
  |=  text=@t
  ^-  (list path)
  =/  lines=wain  (to-wain:format (end [3 prelude-bytes] text))
  =?  lines  (gth (met 3 text) prelude-bytes)  (snip lines)
  =/  parsed  (header-rule:build [1 1] (trip (of-wain:format lines)))
  ?~  q.parsed  ~
  (turn p.u.q.parsed |=(dep=dependency:build path.dep))
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
  ::  Every workbench path is /clay/<desk>/<case>/<path>. At `now` it is
  ::  the desk's current files, writable; at a revision number it is
  ::  pinned and read-only.
  |=  [bol=bowl:gall rel=path]
  ^-  (each location:ufiles failure:ufiles)
  ?.  ?=([%clay @ @ *] rel)
    [%.n (fail:ufiles %context 400 'select a desk and revision')]
  =/  desk  i.t.rel
  ?:  =(%now i.t.t.rel)
    =/  pinned  (pin:build our.bol desk [%da now.bol] now.bol)
    ?:  ?=(%.n -.pinned)
      [%.n (fail:ufiles %context 404 code.p.pinned)]
    [%.y [[our.bol desk.p.pinned [%da now.bol]] t.t.t.rel &]]
  =/  revision  (rush i.t.t.rel dem)
  ?~  revision
    [%.n (fail:ufiles %context 400 'revision must be now or a decimal number')]
  =/  pinned  (pin:build our.bol desk [%ud u.revision] now.bol)
  ?:  ?=(%.n -.pinned)
    [%.n (fail:ufiles %context 404 code.p.pinned)]
  =/  ctx  p.pinned
  [%.y [[our.ctx desk.ctx [%ud revision.ctx]] t.t.t.rel |]]
--
