/+  engine=quiz-engine
|%
  ::  A deliberately false claim, marked with ++expect %fail. Finding and
  ::  shrinking a counterexample is the expected result; a run that passed
  ::  every check would be reported as passed-unexpectedly. A shrink that
  ::  hits a budget still ends %limited, as for any property.
  ::
::
++  fate
  |=  value=@ud
  (lth value 10)
::
++  expect  %fail
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 100)]
--
