/+  engine=quiz-engine, gen=quiz-gen
|%
  ::  38-shrink-order's bug, with a pitfall in the shrinker: a line's
  ::  quantity and price only shrink together, halved or decremented as
  ::  one. The two fields are independent, since only the quantity decides
  ::  the bug, so every move that lowers the price lowers the quantity too.
  ::  Once the quantity reaches 4 nothing lighter fails, and the price is
  ::  left wherever it stood. The run ends at a larger order than 38's
  ::  ~[[4 1]]. Shrink fields together only when they are coupled, as in
  ::  29-bst-coordinated.
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
  (shrink-list:gen together)
::
++  together
  ::  The pitfall: both fields move at once.
  |=  =line
  ^-  (list ^line)
  ?:  |(=(0 qty.line) =(0 price.line))  ~
  :~  [(div qty.line 2) (div price.line 2)]
      [(dec qty.line) (dec price.line)]
  ==
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
