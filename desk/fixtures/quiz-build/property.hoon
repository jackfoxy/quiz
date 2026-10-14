/-  d=docket
/+  engine=quiz-engine
/=  helper  /fixtures/quiz-build/helper
/*  source  %hoon  /fixtures/quiz-build/helper/hoon
/*  note  %txt  /fixtures/quiz-build/note/txt
|%
::
++  fate
  |=  value=@ud
  ?&  (lte value ceiling:helper)
      !=(~ note)
      !=('' source)
  ==
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  size
::
++  alts
  |=  sample=vase
  ^-  (list vase)
  ~
::
++  conf
  ^-  document-conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 3)]
::
+$  document-conf  [seed=(unit @uv) config=conf:engine]
--
