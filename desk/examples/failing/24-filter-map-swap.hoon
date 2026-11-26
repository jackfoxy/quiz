/+  engine=quiz-engine, gen=quiz-gen, fun=quiz-fun, prop=quiz-prop
|%
  ::  A false law: filtering after mapping equals mapping after filtering.
  ::  It fails when the test p judges an item and its image under f
  ::  differently. Both functions are generated tables and shrink like
  ::  data; the notes print the shrunk tables.
  ::
::
+$  sample  [items=(list @ud) f=(fun:fun @ud @ud) p=(fun:fun @ud ?)]
::
++  fate
  |=  raw=*
  =/  s  ;;(sample raw)
  =/  change  (to-gate:fun f.s)
  =/  test  (to-gate:fun p.s)
  =/  got  (skim (turn items.s change) test)
  =/  want  (turn (skim items.s test) change)
  =/  show  |=([name=tape f=vase] (crip "{name} = {(trip (fun-text:fun f))}"))
  %+  note:prop  (show "p" !>(p.s))
  %+  note:prop  (show "f" !>(f.s))
  (same:prop !>(want) !>(got))
::
++  norn
  =/  value  (range:gen 0 9)
  %^  trip:gen  (list-of:gen 0 10 value)
    (fun-of:fun value value 4)
  (fun-of:fun value (elements:gen ~[& |]) 4)
::
++  alts
  =/  flag  |=(b=? ^-((list ?) ?:(b ~ ~[&])))
  %+  alts-of:gen  sample
  %+  shrink-pair:gen  (shrink-list:gen shrink-atom:gen)
  %+  shrink-pair:gen  (shrink-fun:fun @ud shrink-atom:gen)
  (shrink-fun:fun @ud flag)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
