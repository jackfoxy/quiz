/+  engine=quiz-engine, quiz, prop=quiz-prop
|%
  ::  Every check passes, but the run is uncovered: the stock list norn
  ::  rarely makes an empty list once size has grown, so the required
  ::  share of empty lists is not reached.
  ::
::
++  fate
  |=  items=*
  ^-  report:prop
  =/  items  ;;((list @ud) items)
  %^  classify:prop  =(~ items)  'empty'
  (same:prop !>(items) !>((flop (flop items))))
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  (list @ud)
  (((list:norns:quiz @ud) (atom:norns:quiz @ud)) size rng)
::
++  cover  [%check ~[['empty' 10]]]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
