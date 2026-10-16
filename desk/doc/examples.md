# Bundled examples

Open **Examples** in the workbench. `props` and `failing` contain read-only
property documents that default to **Saved property**. `examples` contains
the original read-only **Saved suite** files. **Open editable copy** makes a
draft you can change and save in My documents. For API callers, use the actual
Clay paths linked below, not the workbench's virtual root names.

Every property fixes seed `0v123` in its `conf`. Leave the panel overrides blank
to reproduce its configuration. The ordinary target is 20 accepted checks;
the duplicate example requests two and intentionally reaches its small budget.
The results below were checked through the browser/Gall application on
`%zuse 408`, engine `%quiz-engine-1`. They describe these exact sources and
settings, not universal outcomes of similar-looking properties.

| Document | Expected outcome | What it demonstrates |
| --- | --- | --- |
| [01-success](../examples/props/01-success.hoon) | Passed, 20 accepted | Increment then decrement on unsigned atoms |
| [02-boolean](../examples/failing/02-boolean.hoon) | Failed, false | Dividing by two and doubling loses an odd remainder |
| [03-crash](../examples/failing/03-crash.hoon) | Failed, crash at zero | Decrement is partial on unsigned atoms |
| [04-discards](../examples/props/04-discards.hoon) | Passed, 20 accepted with a discard | Reject zero before applying the partial identity |
| [05-duplicates](../examples/failing/05-duplicates.hoon) | Exhausted, duplicates | Constant seven yields 1 accepted + 3 duplicate = 4 attempted |
| [06-composed](../examples/props/06-composed.hoon) | Passed, 20 accepted | List/atom/cell norns; mapping an offset changes sum by length × offset |
| [07-positive](../examples/props/07-positive.hoon) | Passed, 20 accepted, no drops | Generate positive values directly |
| [08-seeded-threshold](../examples/failing/08-seeded-threshold.hoon) | Failed, false; 541 → 501 | Fixed-seed replay and default shrinking around 500 |
| [09-custom-alts](../examples/failing/09-custom-alts.hoon) | Failed, false; best sample 502 | A terminating shrinker preserving positive even inputs |

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

## Recorded property counters

Seed `0v123`, no UI overrides. Columns use the definitions in the reference.

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
