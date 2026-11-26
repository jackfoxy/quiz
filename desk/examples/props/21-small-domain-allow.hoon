/+  engine=quiz-engine, prop=quiz-prop
|%
  ::  De Morgan's law over two loobeans. Only four samples exist, so the
  ::  default %mug policy skips every repeat and exhausts its duplicates
  ::  budget. %allow evaluates repeats, as QuickCheck does, and the run
  ::  reaches 100 checks. The labels show all four cases were seen.
  ::
::
++  fate
  |=  [a=? b=?]
  =/  case=@t
    ?:  a  ?:(b 'both' 'a only')
    ?:(b 'b only' 'neither')
  (label:prop case =(!&(a b) |(!a !b)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(duplicates %allow)]
--
