/+  build=quiz-build, engine=quiz-engine
|%
  ::  Durable property inputs contain no compiled cores or live RNG state.
  ::  Resolve the recorded context before sending any dependency requests.
  ::
+$  record
  $:  where=context:build
      path=path
      source=@t
      source-hash=@uv
      seed=@uv
      config=conf:engine
      engine-version=@tas
  ==
::
++  capture
  ::  Store the resolved seed and effective config, including panel overrides.
  |=  [doc=prepared:build seed=@uv config=conf:engine]
  ^-  (each record diagnostic:build)
  =/  saved=record
    :*  where.doc  path.doc  source.doc  (shax source.doc)
        seed  config  version:engine
    ==
  =/  checked  (prepare saved)
  ?:  ?=(%.n -.checked)  [%.n p.checked]
  [%.y saved]
::
++  prepare
  ::  Validate persisted inputs without reading Clay or selecting new entropy.
  |=  saved=record
  ^-  (each prepared:build diagnostic:build)
  ?.  =(engine-version.saved version:engine)
    [%.n (issue:build %engine-version path.saved [1 1] ~ ~)]
  ?.  =(source-hash.saved (shax source.saved))
    [%.n (issue:build %source-hash path.saved [1 1] ~ ~)]
  ?.  (valid-config:build config.saved)
    [%.n (issue:build %conf-range path.saved [1 1] `%conf ~)]
  ?:  (gth (met 3 source.saved) source-bytes.bounds.config.saved)
    [%.n (issue:build %source-size path.saved [1 1] ~ ~)]
  (prepare:build where.saved path.saved source.saved)
::
++  resolve
  ::  No substitution of the latest revision or a different ship is allowed.
  |=  [our=ship now=@da saved=record]
  ^-  (each prepared:build diagnostic:build)
  =/  parsed  (prepare saved)
  ?:  ?=(%.n -.parsed)  parsed
  ?.  =(our our.where.saved)
    [%.n (issue:build %ship-unavailable path.saved [1 1] ~ ~)]
  =/  pinned
    (pin:build our desk.where.saved [%ud revision.where.saved] now)
  ?:  ?=(%.n -.pinned)  [%.n p.pinned(path path.saved)]
  [%.y p.parsed]
::
++  start
  ::  Use replies from draft-requests on the resolved prepared document.
  ::  Stored settings override document defaults exactly, including the seed.
  |=  [saved=record replies=(list riot:clay)]
  ^-  (each state:engine diagnostic:build)
  =/  parsed  (prepare saved)
  ?:  ?=(%.n -.parsed)  [%.n p.parsed]
  =/  built  (draft:build p.parsed replies)
  ?:  ?=(%invalid -.built)  [%.n +.built]
  [%.y (init:engine seed.saved config.saved parts.built)]
--
