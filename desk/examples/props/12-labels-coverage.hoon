/+  engine=quiz-engine, quiz, prop=quiz-prop
|%
  ::  Reversing a list twice gives it back. Each sample is classified by
  ::  length and tabulated, and ++cover requires short and long lists.
  ::
  ::  The run shows the distribution: the stock list norn makes lists close
  ::  to its xeb(size)-1 maximum, so short lists come only from the first
  ::  samples.
  ::
::
++  fate
  |=  items=*
  ^-  report:prop
  =/  items  ;;((list @ud) items)
  =/  size  (lent items)
  %^  classify:prop  =(0 size)  'empty'
  %^  classify:prop  &((gth size 0) (lte size 3))  'short'
  %^  classify:prop  (gth size 3)  'long'
  %^  tabulate:prop  'length'  ~[(scot %ud size)]
  (same:prop !>(items) !>((flop (flop items))))
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  (list @ud)
  (((list:norns:quiz @ud) (atom:norns:quiz @ud)) size rng)
::
++  cover  [%check ~[['short' 5] ['long' 50]]]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
