# Quiz user's guide

Quiz checks a claim against generated inputs, then tries to simplify a failing
input. A passing run is evidence about the inputs checked, not a proof. This
walkthrough uses the shipped examples, seed `0v123`, and blank panel overrides.
The displayed results below were recorded on `%zuse 408`, `%quiz-engine-2`.
The [reference](reference.md) defines the exact contracts and limits.

## 1. Install, open and run an example

Use a development ship running `%zuse 408`. In Dojo, create a new desk and mount
it (skip creation if you already have this desk):

```dojo
|new-desk %quiz
|mount %quiz
```

From the repository root, copy **all** of `desk/` into the ship's mounted
`quiz/` directory. Replace `/path/to/pier` with your pier's host path:

```sh
cp -RL desk/. /path/to/pier/quiz/
```

Back in Dojo:

```dojo
|commit %quiz
|install our %quiz
```

Sign in to that ship's web interface and open `/apps/quiz/`. Both `%quiz` and
`%quiz-web` must be running. There is no separate front-end build. See the
[README](https://github.com/jackfoxy/quiz#installation) for library-only use.

Open **Examples → props → 01-success**, leave overrides blank, and choose
**Run saved property**. Recorded result: **passed**, attempted **34**, accepted
**20**, duplicate **14**. Duplicates do not count toward the accepted target.
A small sample space can exhaust a run: **failing → 05-duplicates** records
**exhausted / duplicates**, attempted **4**, accepted **1**, duplicate **3**.
Exhaustion is not a pass. Set **Repeated samples** to **Evaluate every
sample** and rerun: repeats are now evaluated, as in QuickCheck, and the run
passes with attempted **2**, accepted **2**, duplicate **0**. [All example results](examples.md).

Help uses a Markdown-capable `%docs` app when installed. Its TOC opens rendered
pages in remembered explorer tabs; otherwise Help shows the short local guide.
**Documentation** always opens the shipped Markdown as read-only editor text.

## 2. Find the zero bug and choose the domain

Create a document with **+**, paste this complete document and choose
**Draft property → Run draft property**. It is also shipped as
**Examples → failing → 03-crash**:

```hoon
/+  engine=quiz-engine
|%
  ::  Deliberately partial: decrementing zero crashes before comparison.
  ::
::
++  fate
  |=  value=@ud
  =(value +((dec value)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

The claim increments after decrementing. Unsigned zero cannot be decremented.
Recorded result: **failed / crash**, attempted **1**, accepted **0**; original
and shrunk counterexample **value=0**. Open the result's diagnostics and both
counterexamples. A crash is separate from a Boolean `%.n` failure; neither
is a discard.

If the intended law applies only to positive inputs, guard before the unsafe
operation. `%drop` means this input is outside the property domain:

```hoon
/+  engine=quiz-engine
|%
  ::  Exclude zero from the partial decrement/increment identity.
  ::
::
++  fate
  |=  value=@ud
  ?:  =(value 0)  %drop
  =(value +((dec value)))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

Recorded result: **passed**, attempted **35**, accepted **20**, dropped **1**,
duplicate **14**. The guard runs before `dec`; the discarded zero is not a
successful check. If zero is part of your required domain, fix the function
instead of discarding its bug.

Generate positive values directly when filtering wastes attempts:

```hoon
/+  engine=quiz-engine
|%
  ::  Generate the positive domain directly instead of discarding zero.
  ::
::
++  fate
  |=  value=@ud
  =(value +((dec value)))
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  +((rad:rng size))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

Recorded result: **passed**, attempted **32**, accepted **20**, dropped **0**,
duplicate **12**. Here the norn returns `1 + rad(size)`. It consumes the RNG
provided by the engine, so the run can be reproduced.

This translation of conditional properties and constructive generation is
informed by [FsCheck Properties](https://fscheck.github.io/FsCheck/Properties.html).
Quiz's `%drop` and norns are Hoon contracts, not FsCheck operators.

## 3. Save, reopen, edit and run a Clay suite

Open an example and choose **Open editable copy**. Save it as `guide-positive`
with mark `hoon`; its virtual location is `work/guide-positive/hoon`, physically
`/data/quiz/guide-positive/hoon` on the selected application desk. Close the tab
and reopen it through **My documents** or **Open**. A dirty tab asks before
changes are discarded; unsaved tabs are also remembered in this browser.

Add a comment without saving and run **Draft property**. The result snapshot
must contain that comment. **Saved property** runs the saved source at the
selected revision instead. After saving, choose **Use latest revision** to
advance the context explicitly. Wait for the selected revision to update before
running. Saving alone does not change that selection.
A changed tab marks its earlier result stale; the recorded snapshot stays fixed.

Open **Examples → examples → 02-boxcar**. It defaults to **Saved suite**.
Choose **Discover suite arms**, leave the selection empty for all arms, and run.
Recorded result: **suite / passed**, **3** total, **3** completed, **3** passed.
Alternatively, choose a local desk and numeric revision in **Clay source**,
then open a Hoon test core with **Open** under `/clay`; Clay source itself
lists only property documents. Select **Saved suite** for your test core.

A suite reports arm results. Legacy checks inside an arm do not expose their
sample seed, drops or counterexamples as application property metrics.
[Editing details](workbench.md), [suite details](suites-and-replay.md).

## 4. Generate meaningful structured inputs

This complete document composes atom, list and cell norns. Adding an offset to
every list element should increase its sum by length times the offset:

```hoon
/+  engine=quiz-engine, quiz
|%
  ::  Adding an offset to each list element changes its sum by length*offset.
  ::
::
++  fate
  ::  Keep the vase type small; validate the generated list inside the gate.
  |=  [items=* offset=@ud]
  ^-  ?
  =/  items  ;;((list @ud) items)
  =/  shifted  (turn items |=(value=@ud (add value offset)))
  =/  expected  (add (roll items add) (mul (lent items) offset))
  =(expected (roll shifted add))
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  [(list @ud) @ud]
  =/  atoms=(norn:quiz @ud)  (atom:norns:quiz @ud)
  =/  lists=(norn:quiz (list @ud))  ((list:norns:quiz @ud) atoms)
  =/  pair  ((cell:norns:quiz (list @ud) @ud) lists atoms)
  (pair size rng)
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

Recorded result: **passed**, attempted **20**, accepted **20**, dropped **0**,
duplicate **0**. The norn constructs a typed list; the fate validates its noun
boundary with `;;`. This keeps the sample vase small: recursive types can retain
large compiler contexts and hit the byte cap even for short values.

The [app generator library](reference.md#app-generator-library-quiz-gen) does
the same with total generators, list lengths you choose, and a list shrinker:

```hoon
/+  gen=quiz-gen
::  …
++  norn
  ^-  $-([@ud _og] [(list @ud) @ud])
  (pair:gen (list-of:gen 0 20 upto:gen) upto:gen)
::
++  alts
  %+  alts-of:gen  ,[(list @ud) @ud]
  (shrink-pair:gen (shrink-list:gen shrink-atom:gen) shrink-atom:gen)
```

The legacy `list` norn gives at most `xeb(size)-1` elements; `list-of` gives a
length uniform in its bounds. `shrink-list` deletes chunks of elements before
shrinking single values, which the legacy default shrinker cannot do. Note the
comma in `,[(list @ud) @ud]`: `alts-of` needs a mold.

Structural types alone do not express sortedness, positivity, valid dates or
relationships between fields. Choose a generator for that semantic domain and
keep the shrinker in the same domain. Bounded recursive generation should reduce
its size at every recursive step. Reusing an unchanged RNG repeats a draw;
thread or split it for independent choices. These design ideas are informed by
[FsCheck Test Data](https://fscheck.github.io/FsCheck/TestData.html).

Inspect the distribution, not just the green result. Aggregate accepted and
drop counts cannot establish coverage. Return a report from the fate with
[`quiz-prop`](reference.md#reports-labels-and-coverage), label each sample's
case, and require the cases you care about with `++cover`:

```hoon
/+  prop=quiz-prop
|%
++  fate
  |=  items=(list @ud)
  ^-  report:prop
  %^  classify:prop  =(~ items)  'empty'
  %^  classify:prop  ?=([* ~] items)  'singleton'
  (same:prop !>(items) !>((flop (flop items))))
++  cover  [%check ~[['empty' 5] ['singleton' 5]]]
--
```

The run shows each label's count and share of accepted samples, plus the first
example per label. Under `%check`, a run whose samples were too rarely empty
ends `uncovered` even though every check passed. Open **props →
12-labels-coverage** and **failing → 14-coverage-shortfall** for both
outcomes. `%warn` and `%check` are a threshold at the requested count. With
`%confident`, as in **props → 28-confident-coverage**, the run keeps testing
until a Wilson bound decides each row.
These ideas follow [FsCheck observation guidance](https://fscheck.github.io/FsCheck/Properties.html#Observing-Test-Case-Distribution)
and QuickCheck's `classify` and `cover`.

## 5. Observe shrinking and preserve constraints

Paste this document, or open **failing → 08-seeded-threshold**:

```hoon
/+  engine=quiz-engine
|%
  ::  Seed 0v123 produces 541; default shrinking reaches 501 in this example.
  ::
::
++  fate
  |=  value=@ud
  (lte value 500)
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  (add 501 (rad:rng 64))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

Recorded result: **failed / false**, attempted **1**, accepted **0**; original
**value=541**, shrunk **value=501**, shrink tried **82**, shrink steps **40**.
The law is intentionally false above 500. The engine tests smaller alternatives;
it accepts only a new, lower-weight sample with the same failure category.
This example reaches 501; there is no universal smallest-counterexample promise.

For positive even inputs, preserve that constraint while shrinking:

```hoon
/+  engine=quiz-engine
|%
  ::  Shrink even positive inputs by two; never leave that semantic domain.
  ::
::
++  fate
  |=  value=@ud
  ?>  &(=(0 (mod value 2)) (gth value 0))
  (lte value 500)
::
++  norn
  |=  [size=@ud rng=_og]
  ^-  @ud
  (mul 2 (add 251 (rad:rng 32)))
::
++  alts
  |=  sample=vase
  ^-  (list vase)
  =/  value  !<(@ud sample)
  ?:  (lte value 2)  ~
  ~[sample(q (sub value 2))]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

Recorded result: **failed / false**, original **value=510**, shrunk **value=502**,
shrink tried **5**, shrink steps **4**. Each alts call returns at most one
candidate, decreases it by two, and stops at two. The candidate 500 passes and
is rejected as a counterexample. The assertion in `fate` checks that the even,
positive domain is preserved. Default shrinking could leave that domain.

A finite candidate list and a decreasing measure make this shrinker terminate.
An alts call that loops is stopped by its CPU limit (**Settings → Property
call**, default 10 s), and the run
ends **interrupted**, keeping the best counterexample found so far. Domain-aware generation and
shrinking are paired design responsibilities. [FsCheck Test Data](https://fscheck.github.io/FsCheck/TestData.html).

## 6. Replay and turn evidence into a regression

Select the threshold result and choose **Replay exact property**. Recorded
replay: **value=541 → value=501**, the same **82** candidates and **40** accepted
shrinks. It keeps the source hash, original path and pinned revision, effective
seed/configuration and engine version. Save these with a bug report. The seed
alone is insufficient if imports, source or settings change.

**Rerun request** resubmits the earlier request; it can choose new entropy when
no explicit/document seed is fixed. Exact replay refuses missing revisions or
incompatible versions instead of silently choosing a different context.
[Replay contract](suites-and-replay.md). FsCheck also supports reproducible runs;
its replay representation is different. [FsCheck Running Tests](https://fscheck.github.io/FsCheck/RunningTests.html).

For a real bug, decide the intended behavior before making a regression. Suppose
we now require a saturating predecessor: zero stays zero, positive inputs lose
one. Keep the zero counterexample as an ordinary assertion, and complement it
with a randomized law. Save this complete test core as `guide-regression/hoon`:

```hoon
/+  *test, quiz
|%
  ::  Saturating predecessor, with a saved zero regression and a property.
  ::
::
++  predecessor
  |=  value=@ud
  ?:(=(value 0) 0 (dec value))
::
++  test-zero
  (expect-eq !>(0) !>((predecessor 0)))
::
++  test-one
  (expect-eq !>(0) !>((predecessor 1)))
::
++  test-successor
  =/  fate  |=(value=@ud =(value (predecessor +(value))))
  (expect !>((~(check quiz 0v123 20) !>(fate) ~ ~)))
--
```

This is a suite, not a property document: select **Saved suite**, choose latest
revision after saving, discover the three arms and run. Recorded result:
**suite / passed**, **3** total/completed/passed. The unit assertion covers the
known zero bug even if a later generator misses it.

## 7. Run suites in Dojo and the UI

For the saved regression above, run in Dojo:

```dojo
-test /=quiz=/data/quiz/guide-regression ~
```

Recorded output includes:

```text
OK      /data/quiz/guide-regression/test-zero
OK      /data/quiz/guide-regression/test-successor
OK      /data/quiz/guide-regression/test-one
ok=%.y
```

The shipped tutorial, boxcar and Euler suites can be run together:

```dojo
-test /=quiz=/tests/examples ~
```

Recorded result: **19 passing arms**, `ok=%.y`. To run all packaged regressions:

```dojo
-test /=quiz=/tests ~
```

Recorded result: **251 passing arms**, `ok=%.y`. Intentional teaching failures
are under `/examples/failing`, outside `/tests`. In the UI, open each suite,
use **Discover suite arms**, and run all or an exact-name subset. Stock `-test`
can forward scries; the app's suite runner refuses them. Stateful suites may
therefore behave differently. Keep unit tests and property tests together:
known cases lock in decisions, generated inputs look for omissions.

## Choosing useful properties

The following are Quiz applications of general property-testing techniques;
**conceptual** rows describe future tests to write, not additional APIs.

| Technique | Working example or conceptual exercise |
| --- | --- |
| Invariant | Boxcar `test-boxcar-sanity` checks its result is in the allowed range; the other two arms supply stronger meaning. |
| Round trip | Tutorial `test-jam-cue` checks decoding an encoded noun. A broken pair can share a bug, so add known encodings or an independent model. |
| Algebraic law | Tutorial `test-add-sub`, reverse-concatenation checks in `test-flop-2`, and the composed offset/sum document compare equivalent computations. |
| Idempotence | **Conceptual:** normalizing an already normalized record should leave it unchanged. Add expected examples; a function returning a constant can satisfy this law. |
| Simple model | `10-queue-model` compares a two-list queue with a plain list model after each command. Keep model logic independent from the optimized implementation. |
| Avoid tautologies | The offset/sum example compares two computations. Comparing a value only with itself cannot find a bug; don't use that as a real specification. |
| Avoid vacuity | `04-discards` still requires 20 accepted inputs; `05-duplicates` explicitly exhausts. An always-dropping generator establishes nothing. |
| Boundaries | The regression above checks zero and one explicitly; boxcar checks four/five. `16-sorted-insert` labels where an inserted value lands (empty, front, middle, end) and requires each with `++cover`. |
| Data structures | `17-bst-delete-bug` checks a binary search tree against a sorted-set model and shrinks a failing deletion to three keys. |
| Round trip | `18-parse-print` prints and parses decimal numbers, ships and knots made by aura generators. |
| Filtering | Compare `04-discards` with `07-positive`: construct the domain directly when most inputs would be dropped. |
| Distribution | `12-labels-coverage` labels each list by length and requires short and long lists with `++cover`; `14-coverage-shortfall` shows a requirement the generator misses. Know the stock norns' shape first: a `list` norn has at most `xeb(size)-1` elements. See [measured generator characteristics](reference.md#measured-generator-characteristics). |
| Readable failures | `13-expected-actual` uses `same` and `note`, so the run shows the expected and actual values, not just `false`. |
| Repeatability | Threshold replay records effective inputs and both counterexamples. Preserve the Clay revision too. |
| Domain-preserving shrink | `09-custom-alts` keeps positive even values and terminates; `11-queue-model-bug` keeps a pop precondition while shrinking a command list; `19-queue-gen-lib` does the same with `quiz-gen`'s `shrink-keep` and `shrink-list`. |
| Dependent inputs | `20-dependent` regenerates an index from a seed as its list shrinks, so no candidate indexes past the end. `30-dependent-inner` also shrinks the dependent value itself, pinned in the sample. |
| Related values | `29-bst-coordinated` shrinks equal keys together with `shrink-equal`, so a key that must stay in the tree shrinks with its copy. |
| Small domains | `21-small-domain-allow` checks De Morgan's law over two loobeans. Only four samples exist; `duplicates %allow` evaluates repeats, so 100 checks pass and the labels show every case. |
| Agent model | `25-counter-agent` runs generated pokes against a counter agent's door and compares its state with a model. `26-counter-agent-bug` finds a lost update, an add above ten the agent drops, and shrinks to a single `[%add 11]`. The harness is pure: real effects are out of scope ([limitations](limitations.md)). |
| Hanging code | `27-timeout-fail` gives a fate that never returns for inputs above ten. `on-timeout %fail` reports each hang as a `timeout` failure and shrinks to `n=11`. The browser test also checks `%discard`, which drops hanging samples and carries on. Use a short call limit. See [timeout policy](reference.md#timeout-policy-on-timeout). |
| Higher-order functions | `23-map-fusion` and `24-filter-map-swap` generate the function arguments themselves with `quiz-fun`. |
| Size control | `22-size-capped` checks a quadratic sort against `sort` on lists as long as the size. `size-max 30` keeps the lists short; `quiz-gen`'s `capped`, `resize` and `scale` do the same for one generator. |

These are design suggestions, informed by FsCheck's
[Properties](https://fscheck.github.io/FsCheck/Properties.html),
[Test Data](https://fscheck.github.io/FsCheck/TestData.html),
[Running Tests](https://fscheck.github.io/FsCheck/RunningTests.html), and
[Tips and Tricks](https://fscheck.github.io/FsCheck/TipsAndTricks.html).

**Command-sequence testing:** generate a finite list of commands and an
initial pure state; fold both the implementation and a simple model over it,
checking each returned value and state. Every sample starts from fresh state.
[10-queue-model](../examples/props/10-queue-model.hoon) is the plain form.
[11-queue-model-bug](../examples/failing/11-queue-model-bug.hoon) adds a
precondition: its norn generates only valid sequences, and its `alts` deletes
commands and shrinks values but keeps only valid candidates. The default
shrinker cannot delete a command from a list. See the
[queue examples](examples.md#model-based-queue-examples). This is an ordinary
fate; Quiz has no dedicated state-machine, external-system driver, parallel or
asynchronous property API.

**Testing higher-order code:** generate the function argument too.
[`quiz-fun`](reference.md#generated-functions-quiz-fun) makes functions as
small tables, such as `{8 -> %.y, _ -> %.n}`, that shrink like data.
[23-map-fusion](../examples/props/23-map-fusion.hoon) checks that two `turn`s
equal one `turn` over `cork` for generated `f` and `g`.
[24-filter-map-swap](../examples/failing/24-filter-map-swap.hoon) refutes
"filter after map equals map after filter": its notes print the shrunk
tables, `f = {_ -> 0}` and `p = {8 -> %.y, _ -> %.n}`, with item `~[8]`.

Labels, classify, collect, tabulate, threshold coverage, expected failure and
conjunction/disjunction are available through
[`quiz-prop`](reference.md#reports-labels-and-coverage). Other FsCheck
facilities are **unsupported**: `Arbitrary` registration, automatic .NET
derivation/reflection, generated functions beyond finite tables, coverage
certainty other than QuickCheck's default, expected-exception combinators, nested quantification inside
a fate, xUnit/NUnit adapters and `IRunner` callbacks. Do not paste FsCheck
API examples into Hoon. The [reference](reference.md) is the Quiz API authority.

## Corrections to the original blog

The blog remains historical source material. Current legacy output uses
`success-runs`/`drops` and a vase, not the old illustrated tags. Legacy runs
include drops and may return success after duplicate exhaustion; app accepted
counts do neither. The bunted library has deterministic seed zero, while app
entropy is recorded unless overridden. List lengths are not distributed by the
blog's claimed fixed geometric formula. Shrinking to 501 is an observed example,
not a guarantee; valid semantic domains need deliberate norns and alts.
