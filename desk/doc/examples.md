# Bundled examples

Open **Examples** in the workbench. `props` and `failing` contain read-only
property documents that default to **Saved property**. `examples` contains
the original read-only **Saved suite** files. **Open editable copy** makes a
draft you can change and save in My documents. For API callers, use the actual
Clay paths linked below, not the workbench's virtual root names.

Every property fixes seed `0v123` in its `conf`. Leave the panel overrides blank
to reproduce its configuration. The ordinary target is 20 accepted checks;
the duplicate example requests two and intentionally reaches its small budget,
and the queue models, coverage, generator-library, size and function
examples request 100.
The results below were checked through the browser/Gall application on
`%zuse 408`, engine `%quiz-engine-13`. They describe these exact sources and
settings, not universal outcomes of similar-looking properties.

| Document | Expected outcome | What it demonstrates |
| --- | --- | --- |
| [01-success](../examples/props/01-success.hoon) | Passed, 20 accepted | Increment then decrement on unsigned atoms |
| [02-boolean](../examples/failing/02-boolean.hoon) | Failed, false | Dividing by two and doubling loses an odd remainder |
| [03-crash](../examples/failing/03-crash.hoon) | Failed, crash at zero | Decrement is partial on unsigned atoms |
| [04-discards](../examples/props/04-discards.hoon) | Passed, 20 accepted with a discard | Reject zero before applying the partial identity |
| [05-duplicates](../examples/failing/05-duplicates.hoon) | Exhausted, duplicates | Constant seven yields 1 accepted + 3 duplicate = 4 attempted; passes with **Repeated samples** set to evaluate every sample |
| [06-composed](../examples/props/06-composed.hoon) | Passed, 20 accepted | List/atom/cell norns; mapping an offset changes sum by length × offset |
| [07-positive](../examples/props/07-positive.hoon) | Passed, 20 accepted, no drops | Generate positive values directly |
| [08-seeded-threshold](../examples/failing/08-seeded-threshold.hoon) | Failed, false; 541 → 501 | Fixed-seed replay and default shrinking around 500 |
| [09-custom-alts](../examples/failing/09-custom-alts.hoon) | Failed, false; best sample 502 | A terminating shrinker preserving positive even inputs |
| [10-queue-model](../examples/props/10-queue-model.hoon) | Passed, 100 accepted | Model-based test: a two-list queue against a list model over generated command sequences |
| [11-queue-model-bug](../examples/failing/11-queue-model-bug.hoon) | Failed, false; 12 commands → 3 | A pop precondition kept by both the norn and a sequence shrinker |
| [12-labels-coverage](../examples/props/12-labels-coverage.hoon) | Passed, 100 accepted; coverage met | `classify`, `tabulate` and `++cover`; the run shows the label distribution |
| [13-expected-actual](../examples/failing/13-expected-actual.hoon) | Failed, false; expected 1, actual 0 | `same` and `note`: a failure that explains itself |
| [14-coverage-shortfall](../examples/failing/14-coverage-shortfall.hoon) | Uncovered; empty 1% of 10% | Every check passes, but the generator misses a required case |
| [15-expect-failure](../examples/props/15-expect-failure.hoon) | Failed as expected; 11 → 10 | `++expect %fail` for a claim known to be false |
| [16-sorted-insert](../examples/props/16-sorted-insert.hoon) | Passed, 100 accepted; every position covered | `sorted` and `pair` generators; labels where the value lands |
| [17-bst-delete-bug](../examples/failing/17-bst-delete-bug.hoon) | Failed, false; 9 keys → 3 | A search tree against a sorted-set model; `shrink-pair` of `shrink-list` |
| [18-parse-print](../examples/props/18-parse-print.hoon) | Passed, 100 accepted | Aura generators (`upto`, `ship`, `knot`) in `scot`/`slav` round trips |
| [19-queue-gen-lib](../examples/failing/19-queue-gen-lib.hoon) | Failed, false; 4 commands → 3 | Example 11 rebuilt from `list-of`, `cook`, `shrink-keep` and `shrink-list` |
| [20-dependent](../examples/failing/20-dependent.hoon) | Failed, false; one-element list | `seeded`, `regen` and `shrink-seeded`: dependent shrinking |
| [21-small-domain-allow](../examples/props/21-small-domain-allow.hoon) | Passed, 100 accepted from four samples | `duplicates %allow` evaluates repeats of a small domain |
| [22-size-capped](../examples/props/22-size-capped.hoon) | Passed, 100 accepted; size held at 30 | `size-max` keeps size-driven lists short; `sized` and `vector` |
| [23-map-fusion](../examples/props/23-map-fusion.hoon) | Passed, 100 accepted | Generated functions: two `turn`s equal one over `cork` |
| [25-counter-agent](../examples/props/25-counter-agent.hoon) | Passed, 100 accepted; 5 duplicates | Pure agent harness: model-based pokes against a counter agent's door |
| [27-timeout-fail](../examples/props/27-timeout-fail.hoon) | Failed, timeout; shrinks to `n=11` | `on-timeout %fail`: a fate that never returns is a `%timeout` failure, shrunk to the smallest hanging input. `++within ~s0..8000` lowers its call limit to 0.5 s, since each hanging candidate costs it; no Settings change is needed |
| [28-confident-coverage](../examples/props/28-confident-coverage.hoon) | Passed, 800 accepted; heads 377 | `++cover [%confident …]`: undecided at 100, 200 and 400 checks, covered at 800 by the Wilson lower bound |
| [29-bst-coordinated](../examples/failing/29-bst-coordinated.hoon) | Failed, false; `[~[1 0 2] 1]` | 17's tree with `shrink-equal` through `shrink-via`: the deleted key and its copy in the tree shrink together |
| [30-dependent-inner](../examples/failing/30-dependent-inner.hoon) | Failed, false; bound 1, pinned `~[90]` | `dependent`, which bundles `seeded` and `shrink-seeded` with an inner shrinker: once the bound is minimal, the regenerated list itself shrinks and is pinned |
| [31-float-associativity](../examples/failing/31-float-associativity.hoon) | Failed, false; `[a=.~-1.2 b=.~-1 c=.~1]` | Sized `real` and `shrink-real`: float addition is not associative; the shrunk triple has short decimals |
| [32-expiry-agent](../examples/props/32-expiry-agent.hoon) | Passed, 100 accepted; 15 duplicates | Simulated behn clock: puts with a time to live and waits against an expiring key store |
| [33-expiry-agent-bug](../examples/failing/33-expiry-agent-bug.hoon) | Failed, false; two puts of `%a` and a wait | A re-put that does not `%rest` its old timer; the old wake deletes the new value early |
| [34-typed-defaults](../examples/failing/34-typed-defaults.hoon) | Failed, false; `[name='' tags=~[%a %a %a]]` | No norn or alts: `quiz-auto` fills printable text and a list of terms from the sample's type and shrinks the list |
| [35-cover-table](../examples/props/35-cover-table.hoon) | Passed, 100 accepted; 64 duplicates | `++cover-table`: each list's least element is tabulated, and three values must each be 5% of the table's entries |
| [26-counter-agent-bug](../examples/failing/26-counter-agent-bug.hoon) | Failed, false; `[%add 11]` | A lost update in the agent; shrinks to one add of eleven. Expected 11, actual 0 |
| [24-filter-map-swap](../examples/failing/24-filter-map-swap.hoon) | Failed, false; `p = {8 -> %.y, _ -> %.n}` | A false law over generated functions; the tables shrink and print |

The composed example's list is generated as `(list @ud)` but enters its fate
through a noun boundary and is checked there. Recursive vase types can include
large compiler contexts; they count toward the sample-byte limit even for a
small value. This boundary keeps the type small without trusting malformed
list inputs inside the property.

The custom alts returns at most one candidate, decrementing by two until two.
Every call terminates, each candidate stays positive and even, and accepted
candidates strictly reduce the engine's noun weight. A passing candidate is
rejected, so the final false sample is 502, rather than 501. This illustrates
why preserving the domain matters; it does not establish a general globally
minimal shrinker.

Select the seeded threshold's result and use **Replay exact property**. The
replay should retain its seed, effective config, source hash and revision and
reproduce both counterexamples and all counters. Editing the source tab marks
the earlier result stale; replay still uses its recorded snapshot. See
[replay semantics](reference.md#clay-context-seed-and-replay).

## Model-based queue examples

Both documents generate a list of `%push`, `%pop` and `%size` commands and
fold a two-list queue and a plain list model over it from fresh state. After
every command the fate compares the replies and the full contents. The sample
is typed `*` for the reason above, so command tags render as numbers:
`%push` 1.752.397.168, `%pop` 7.368.560, `%size` 1.702.521.203.

In `10-queue-model`, pop on an empty queue replies `~`, so every sequence is
valid. Its norn composes `freq`, `const`, `atom` and `list`. The stock list
norn yields at most `xeb(size)-1` commands, 15 by the 100th sample; that is
enough to reach the reversal. Fed a queue that forgets to reverse, this norn
fails at sample 28. The default shrinker stops at
`~[[%push 52] [%push 18] [%pop ~] [%pop ~]]`: it offers only the two subtrees
of a noun, and a strict sublist is not one of them.

In `11-queue-model-bug`, pop on an empty queue crashes, which gives the
sequence a precondition. The norn draws a pop only while the model holds an
item. The alts deletes one command, then halves or zeroes one pushed value,
and keeps only candidates that satisfy the precondition. The fate also
`%drop`s an invalid sequence, for replays and hand-written inputs. The
12-command counterexample shrinks to
`~[[%push 0] [%push 1] [%pop ~]]`: two different values, then one pop that
returns the newer. The engine already rejects a candidate that fails in
another category, such as a crash; filtering avoids spending the candidate
budget on them.

## Reports and coverage examples

`12-labels-coverage` labels each list `empty`, `short` (1–3 elements) or
`long`, tabulates its length, and checks a double reversal with `same`. Its
`++cover` requires 5% short and 50% long lists, under `%check`. The recorded
distribution is empty 1, short 15, long 84: the stock list norn makes lists
near its `xeb(size)-1` maximum, so short and empty lists come from the first
samples only.

`14-coverage-shortfall` uses the same generator and requires 10% empty lists.
Every check passes, but only 1% of samples were empty, so the run ends
`uncovered` with the shortfall `empty: 1% of accepted samples, required 10%`.
The fix belongs in the generator, not the requirement.

`35-cover-table` sorts a list of up to four digits and tabulates its least
element under `least`. `++cover-table` requires `0`, `1` and `5` each to be
at least 5% of that table's entries, as QuickCheck's `coverTable` does: the
share is of the 99 entries, since the one empty list tabulates nothing, not of
the 100 accepted samples. With no `++cover` the rows use `%check`; all are
met. A short row would read `least = 5: …% of the table's entries`.

`13-expected-actual` reports `same` on the value and its halved-and-doubled
form, with a note. The shrunk failure shows expected `1`, actual `0`; the
note and comparison follow the shrunk sample, not the original 3.

`15-expect-failure` claims every value is below 10 and marks the document
`++expect %fail`. The engine finds 11, shrinks it to 10, and reports
`failed-as-expected`.

## Generator library examples

Examples 16 to 20 and 29 to 31 use [`quiz-gen`](reference.md#app-generator-library-quiz-gen).

`16-sorted-insert` generates a sorted list and a value, inserts the value,
and checks the result with `same` under `all`. It labels where the value
landed: empty 3, front 18, middle 65, end 14, all above the `++cover`
minimums.

`17-bst-delete-bug` builds a binary search tree from a key list and deletes a
key; the bug drops the right subtree when the deleted node has two children.
The original nine keys shrink to `~[12 0 13]` with 12 deleted: a root with two
children. The values stay at 12 and 13 because the keys and the deleted key
shrink independently, and shrinking any one of them alone would stop the
failure. A coordinated shrinker could reach `~[1 0 2]`.

`18-parse-print` checks `slav` after `scot` for `@ud`, `@p` and `@ta` values from
aura generators. Its fate spells the sample out as `@p`; the zuse mold `ship`
would make each sample vase exceed the sample-byte limit.

`19-queue-gen-lib` is example 11 written with library parts: the norn draws
up to 40 commands and removes forbidden pops (`cook` with a repair gate); the
alts is `shrink-list` over a command shrinker, filtered by `shrink-keep`. It
reaches 11's minimum, `~[[%push 0] [%push 1] [%pop ~]]`.

`20-dependent` stores a list with a seed and regenerates an index into it in
the fate. The false claim is that the chosen element is never the last. The
list shrinks from `~[19]` to `~[0]` and the size to 0; each candidate's index
is rebuilt for its own list, so no candidate indexes past the end.

`29-bst-coordinated` is 17's search tree with a coordinated shrinker. The
deleted key is also in the tree, so shrinking either copy alone loses the
failure, and 17 stops at `[~[12 0 13] 12]`. Viewing the sample as one list,
the deleted key first, `shrink-equal` replaces every copy of a value at once
and reaches `[~[1 0 2] 1]`: delete the root of a three-key tree.

`30-dependent-inner` regenerates a list of at most `bound` values from the
seed; the false claim is that every value is below 90. It builds its norn,
alts and sample mold with `dependent`; 20 writes the same parts out by hand.
`shrink-seeded` lowers the bound to 1, rebuilding the list each time, then
shrinks the list itself and pins it: the run ends at
`raw=[value=1 seed=0v0 size=0 pin=[~ ~[90]]]`, with the seed cleared.

`31-float-associativity` claims `(a + b) + c` equals `a + (b + c)` for three
doubles from the sized `real`. Small whole numbers and fractions add exactly,
so five samples pass; the sixth, `[a=.~-1.2 b=.~-2 c=.~6]`, rounds
differently in the two orders. `shrink-real` moves each value toward zero, a
whole number and fewer decimal places, and the run ends at
`[a=.~-1.2 b=.~-1 c=.~1]`. The default shrinker
`quiz-auto`, the app's default without `++alts`, also uses `shrink-real`;
the legacy library's shrinker would treat each double as a raw atom; see
[limitations](limitations.md).

`21-small-domain-allow` checks De Morgan's law for a `[? ?]` sample. Under
the default `%mug` policy the run could accept at most four checks before
duplicates exhausted it. Its `conf` sets `duplicates %allow`, so every
repeat is evaluated: 100 checks pass with no duplicates, labelled both 28,
a only 21, b only 28, neither 23.

`22-size-capped` compares an insertion sort with `sort`. Its norn,
`(sized:gen |=(n=@ud (vector:gen n upto:gen)))`, makes a list as long as the
size. Its `conf` sets `size-max 30`, so the size climbs 1, 2, 3, … and then
stays at 30; uncapped it would pass 60,000 by the hundredth sample. Its fate
takes a `*` sample and molds it, because a `(list @ud)` sample type would
exceed the sample-byte limit.

`25-counter-agent` and `26-counter-agent-bug` drive the agent in
[`fixtures/quiz-harness/counter.hoon`](../fixtures/quiz-harness/counter.hoon)
through [`quiz-harness`](reference.md#agent-harness-quiz-harness). The agent
keeps a count and ignores an add above ten. The first property generates adds
of 0 to 9 and resets, so model and agent agree; the second generates adds of
up to 99, and the lost update shows as a mismatch. Its alts is `shrink-list`
over each operation, with each amount shrunk toward zero.

`32-expiry-agent` and `33-expiry-agent-bug` drive the expiring key store in
[`fixtures/quiz-harness/expiry.hoon`](../fixtures/quiz-harness/expiry.hoon)
through `run-clock`, the harness's simulated clock. A put stores a value and
sets a behn timer for its time to live; the wake deletes the key. The model
keeps each key until its latest put expires. Generated waits fire the timers
that fall due, so no real time passes. With its fix, a second put of a key
`%rest`s the first put's timer and 32 passes. Without it, in 33, the older
wake deletes the newer value early: the run ends at
`~[[%put %a 0 ~s1] [%put %a 0 ~s2] [%wait ~s1]]`, expected `{%a}`, actual
`{}`. Its alts is `shrink-list` over each operation, then, through
`shrink-then`, every key renamed to `%a` at once: the failure needs two puts
of one key, so moving one copy alone would lose it.

`34-typed-defaults` has no `++norn` and no `++alts`. Its sample is
`[name=@t tags=(list @tas)]`, and the false claim is that a record never has
more than two tags. [`quiz-auto`](reference.md#type-directed-defaults-quiz-auto)
reads the type: the name is printable text and the tags a list of valid
terms, up to 20. Two samples pass and the third fails. The default shrinker
recognizes the list, deletes tags, empties the name and lowers each term
toward `%a`, ending at `[name='' tags=~[%a %a %a]]`.

`23-map-fusion` and `24-filter-map-swap` generate their function arguments
with `quiz-fun` and take `*` samples molded to
`[items=(list @ud) f=(fun @ud @ud) …]`. In 24 the law "filter after map
equals map after filter" fails on the eighth sample. Shrinking with
`shrink-list` and `shrink-fun` ends at items `~[8]`, `f = {_ -> 0}` and
`p = {8 -> %.y, _ -> %.n}`. Mapping first turns 8 into 0, which `p` rejects;
filtering first keeps 8 and maps it, so expected `~[0]`, actual `~`. The item
stays 8 because keys never shrink: 8 is the key `p`'s case names.

## Recorded property counters

Seed `0v123`, no UI overrides. Columns use the definitions in the reference.
[`tests/lib/quiz-examples.hoon`](../tests/lib/quiz-examples.hoon) pins the
queue, report, coverage, generator-library, size and function rows in
`-test`.

| Document | Attempted | Accepted | Dropped | Duplicate | Shrink tried | Shrink steps | Original → shrunk |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 01-success | 34 | 20 | 0 | 14 | 0 | 0 | — |
| 02-boolean | 5 | 2 | 0 | 2 | 3 | 1 | value=3 → value=1 |
| 03-crash | 1 | 0 | 0 | 0 | 0 | 0 | value=0 → value=0 |
| 04-discards | 35 | 20 | 1 | 14 | 0 | 0 | — |
| 05-duplicates | 4 | 1 | 0 | 3 | 0 | 0 | — |
| 06-composed | 20 | 20 | 0 | 0 | 0 | 0 | — |
| 07-positive | 32 | 20 | 0 | 12 | 0 | 0 | — |
| 08-seeded-threshold | 1 | 0 | 0 | 0 | 82 | 40 | value=541 → value=501 |
| 09-custom-alts | 1 | 0 | 0 | 0 | 5 | 4 | value=510 → value=502 |
| 10-queue-model | 107 | 100 | 0 | 7 | 0 | 0 | — |
| 11-queue-model-bug | 14 | 11 | 0 | 2 | 68 | 20 | 12 commands → `[[1.752.397.168 0] [1.752.397.168 1] [7.368.560 0] 0]` |
| 12-labels-coverage | 104 | 100 | 0 | 4 | 0 | 0 | — |
| 13-expected-actual | 5 | 2 | 0 | 2 | 3 | 1 | value=3 → value=1 |
| 14-coverage-shortfall | 104 | 100 | 0 | 4 | 0 | 0 | — |
| 15-expect-failure | 13 | 6 | 0 | 6 | 4 | 1 | value=11 → value=10 |
| 16-sorted-insert | 100 | 100 | 0 | 0 | 0 | 0 | — |
| 17-bst-delete-bug | 18 | 17 | 0 | 0 | 60 | 6 | 9 keys, delete 12 → `[~[12 0 13] 12]` |
| 18-parse-print | 100 | 100 | 0 | 0 | 0 | 0 | — |
| 19-queue-gen-lib | 4 | 3 | 0 | 0 | 46 | 7 | 4 commands → `[[1.752.397.168 0] [1.752.397.168 1] [7.368.560 0] 0]` |
| 20-dependent | 1 | 0 | 0 | 0 | 5 | 2 | `[~[19] seed 1 ~]` → `[~[0] seed 0 ~]` |
| 21-small-domain-allow | 100 | 100 | 0 | 0 | 0 | 0 | — |
| 22-size-capped | 100 | 100 | 0 | 0 | 0 | 0 | — |
| 23-map-fusion | 100 | 100 | 0 | 0 | 0 | 0 | — |
| 24-filter-map-swap | 8 | 7 | 0 | 0 | 37 | 5 | 3 items → `~[8]`, `f = {_ -> 0}`, `p = {8 -> %.y, _ -> %.n}` |
| 25-counter-agent | 105 | 100 | 0 | 5 | 0 | 0 | — |
| 26-counter-agent-bug | 2 | 1 | 0 | 0 | 21 | 4 | `[%add 11]` (expected 11, actual 0) |
| 27-timeout-fail | — | — | — | — | — | — | `n=11` under its 0.5 s `++within`, in 33.6 s; run in the browser, not pinned in `-test` (a hanging fate would abort the test event) |
| 28-confident-coverage | 800 | 800 | 0 | 0 | 0 | 0 | — |
| 29-bst-coordinated | 18 | 17 | 0 | 0 | 146 | 14 | 9 keys, delete 12 → `[~[1 0 2] 1]` |
| 30-dependent-inner | 3 | 2 | 0 | 0 | 24 | 5 | `[8 seed 3 ~]` → `[1 0v0 0 [~ ~[90]]]` |
| 31-float-associativity | 6 | 5 | 0 | 0 | 33 | 4 | `[a=.~-1.2 b=.~-2 c=.~6]` → `[a=.~-1.2 b=.~-1 c=.~1]` |
| 32-expiry-agent | 115 | 100 | 0 | 15 | 0 | 0 | — |
| 33-expiry-agent-bug | 9 | 6 | 0 | 2 | 56 | 7 | `~[[%put %a 0 ~s1] [%put %a 0 ~s2] [%wait ~s1]]` (expected `{%a}`, actual `{}`) |
| 34-typed-defaults | 3 | 2 | 0 | 0 | 44 | 8 | `[name='-]' tags=~[%vby %m0g6 %q7qa]]` → `[name='' tags=~[%a %a %a]]` |
| 35-cover-table | 164 | 100 | 0 | 64 | 0 | 0 | — |

## Existing suites

| Suite | Recorded arm result | Notes |
| --- | --- | --- |
| [Quiz tutorial](../tests/examples/01-quiz-tutorial.hoon) | 12/12 passed | Legacy fates, norns, drops, shrinking and round trips |
| [Boxcar](../tests/examples/02-boxcar.hoon) | 3/3 passed | Property/unit checks for a small range predicate |
| [Euler](../tests/examples/03-euler.hoon) | 4/4 passed | Prime-number examples and ordinary assertions |

Across these three files, all 19 test arms pass in the app and under `-test`.
They report arm counters, not property sample metrics; seeds, drops and
structured counterexamples inside their legacy checks are unavailable to the
suite UI. The tutorial's deliberate counterexamples are asserted as expected
failures inside passing test arms.

```hoon
-test /=quiz=/tests/examples ~
```

The new intentional failures are outside `desk/tests/`. Running the complete
regression suite therefore remains a passing check. The executable browser
matrix is `tests/browser/examples.spec.js`; its `run.json` artifacts retain
full source hashes, effective configurations, counters and outcomes for each
example and the threshold replay. See the [reference](reference.md) for exact
contracts, limits and legacy/app differences.
