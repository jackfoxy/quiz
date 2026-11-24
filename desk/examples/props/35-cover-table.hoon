/+  engine=quiz-engine, gen=quiz-gen, prop=quiz-prop
|%
  ::  Table coverage. Sorting is idempotent; each sample's list is
  ::  tabulated by its smallest element, a digit from 0 to 9. ++cover-table
  ::  requires each of three values to be at least 5 percent of that
  ::  table's entries, the way QuickCheck's coverTable does: the share is
  ::  of the table's entries, not of the samples, and an empty list adds
  ::  no entry.
  ::
::
++  fate
  |=  items=*
  ^-  report:prop
  =/  items  ;;((list @ud) items)
  =/  sorted  (sort items lte)
  =/  least=(list @t)  ?~(sorted ~ ~[(scot %ud i.sorted)])
  %^  tabulate:prop  'least'  least
  (same:prop !>(sorted) !>((sort sorted lte)))
::
++  norn  (list-of:gen 0 4 (range:gen 0 9))
::
++  cover-table  ~[['least' '0' 5] ['least' '1' 5] ['least' '5' 5]]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
