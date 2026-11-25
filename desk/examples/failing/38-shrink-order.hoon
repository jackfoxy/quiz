/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  An order total against a model. The bug: a bulk line, of four or
  ::  more, is charged for one item fewer. Any order with one bulk line of
  ::  a priced item fails.
  ::
  ::  The shrinker works deliberately: shrink-list first deletes lines,
  ::  the largest cuts first, then shrinks one line's fields, and
  ::  shrink-pair moves the quantity and the price one at a time. The
  ::  price can fall to 1 while the quantity stays at 4, so the run ends
  ::  at the smallest failing order, ~[[4 1]]. Compare
  ::  39-shrink-together.
  ::
::
+$  line  [qty=@ud price=@ud]
::
++  total
  ::  Bug: a bulk line gets an item free.
  |=  lines=(list line)
  ^-  @ud
  %+  roll  lines
  |=  [=line sum=@ud]
  =/  charged  ?:((gte qty.line 4) (dec qty.line) qty.line)
  (add sum (mul charged price.line))
::
++  model
  |=  lines=(list line)
  ^-  @ud
  (roll lines |=([=line sum=@ud] (add sum (mul qty.line price.line))))
::
++  fate
  |=  lines=*
  ^-  ?
  =/  lines  ;;((list line) lines)
  =((model lines) (total lines))
::
++  norn
  ^-  $-([@ud _og] (list line))
  (list-of:gen 3 10 (pair:gen (range:gen 0 9) (range:gen 0 50)))
::
++  alts
  %+  alts-of:gen  ,(list line)
  (shrink-list:gen (shrink-pair:gen shrink-atom:gen shrink-atom:gen))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
