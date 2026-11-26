/=  threshold  /fixtures/quiz-replay/threshold
|%
  ::  Intentionally failing property for pinned-context replay verification.
  ::
++  fate
  |=  value=@ud
  (lte value ceiling:threshold)
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  (add 501 (rad:rng 64))
--
