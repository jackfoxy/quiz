/+  engine=quiz-engine, gen=quiz-gen, fun=quiz-fun
|%
  ::  Map fusion: mapping f and then g equals mapping g after f in one
  ::  pass. f and g are generated tables, so the law is checked for many
  ::  functions, not one chosen by hand. The sample is typed `*`: a table
  ::  holds a list, and a recursive sample type would exceed sample-bytes.
  ::
::
+$  sample  [items=(list @ud) f=(fun:fun @ud @ud) g=(fun:fun @ud @ud)]
::
++  fate
  |=  raw=*
  =/  s  ;;(sample raw)
  =/  one  (to-gate:fun f.s)
  =/  two  (to-gate:fun g.s)
  =((turn (turn items.s one) two) (turn items.s (cork one two)))
::
++  norn
  =/  value  (range:gen 0 9)
  %^  trip:gen  (list-of:gen 0 20 value)
    (fun-of:fun value value 5)
  (fun-of:fun value value 5)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
