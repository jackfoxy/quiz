# Quiz user's guide

Quiz tests claims about Hoon programs by generating inputs. When a claim
fails, it searches for a smaller input that still fails. You use the urui
workbench to write the claim, inspect its inputs, run it, study the failure,
and replay the experiment.

This guide follows the example-led progression of [Obelisk's user's
guide][obelisk-guide]: start with a small working document, change one thing
at a time, and introduce more powerful operations when the example needs
them. You will grow a collection under `guide/` in **My documents**. Later
chapters use the bundled examples to test collections, dependent inputs,
generated functions and Gall agent doors.

The guide describes Quiz at commit `7210f00`, engine `%quiz-engine-1`,
targeting `%zuse 408`. It assumes you can read simple Hoon gates. The
[reference][reference] supplies exact library signatures.

**Workbench coverage.** All property-document features can be authored in
its editor; property and saved-suite workflows, request options, history
deletion, Clay browsing and record export have workbench controls.
[Appendix C](#appendix-c-workbench-access-and-validation) records the
remaining boundaries, such as operator tasks that belong in Dojo.

## Contents

1. [Open the workbench](#1-open-the-workbench)
2. [Write and run a property](#2-write-and-run-a-property)
3. [Save a document and pin its source](#3-save-a-document-and-pin-its-source)
4. [Distinguish false, crash and discard](#4-distinguish-false-crash-and-discard)
5. [Choose inputs and preview them](#5-choose-inputs-and-preview-them)
6. [Control size, repeats and budgets](#6-control-size-repeats-and-budgets)
7. [Shrink within the intended domain](#7-shrink-within-the-intended-domain)
8. [Replay a failure and keep a regression](#8-replay-a-failure-and-keep-a-regression)
9. [Explain failures with reports](#9-explain-failures-with-reports)
10. [Measure and require coverage](#10-measure-and-require-coverage)
11. [Generate structured data](#11-generate-structured-data)
12. [Test a model and shrink command sequences](#12-test-a-model-and-shrink-command-sequences)
13. [Keep related inputs consistent](#13-keep-related-inputs-consistent)
14. [Generate functions](#14-generate-functions)
15. [Test agent doors and simulated time](#15-test-agent-doors-and-simulated-time)
16. [Set time limits and manage jobs](#16-set-time-limits-and-manage-jobs)
17. [Run saved suites](#17-run-saved-suites)
18. [Use other Clay contexts and imports](#18-use-other-clay-contexts-and-imports)
19. [Arrange the workbench and find help](#19-arrange-the-workbench-and-find-help)

- [Choosing useful properties](#choosing-useful-properties)

## 1. Open the workbench

Use a disposable development ship with Quiz installed and both `%quiz` and
`%quiz-web` running. Sign in to the ship, then open its **Quiz** tile or visit
`/apps/quiz/`. Installation is an operator task outside the workbench; follow
the repository's [installation instructions][installation] if needed.

The explorer has four views:

| View | What you keep or find there |
| --- | --- |
| **My documents** | Your saved Hoon properties, suites and Markdown notes |
| **Examples** | Read-only `props`, intentionally `failing` properties, and `examples` containing existing suites |
| **Documentation** | Shipped Markdown documentation as read-only text |
| **Clay source** | Indexed properties and suites on a selected desk at a pinned revision |

The document editor holds your source. The run controls below it choose what
to execute. **Run results** holds server-confirmed history and the selected
run's evidence. Each document tab has its own run settings.

Three words recur throughout Quiz:

| Word | Job |
| --- | --- |
| **Fate** | Tests the claim on one input |
| **Norn** | Generates an input from a size and random-number generator |
| **Alts** | Proposes simpler inputs after a failure |

You need only a fate to begin. Quiz supplies a norn and alts from the fate's
sample type when you omit them. A passing run supplies evidence for the
inputs checked; it is not a proof of the claim.

## 2. Write and run a property

Click **+** on the document tab strip. Replace the editor contents with this
complete property:

```hoon
|%
::
++  fate
  |=  n=@ud
  ^-  ?
  =(n (add 0 n))
--
```

`n=@ud` describes an unsigned-integer input. The fate returns a loobean:
`%.y` when adding zero leaves the input unchanged, `%.n` otherwise.

1. Leave **Source to run** on **Draft property (editor buffer)**.
2. Enter `20` in **Requested checks** and `0v123` in **Seed**.
3. Click **Run draft property**. Select its row in the result history if
   another row is selected.
4. Wait for **passed**. Expand **Confirmed counters** and check that
   `accepted` is 20. Expand **Exact source snapshot** to see what actually ran.

Now change `(add 0 n)` to `(add 1 n)` and run again. The claim is false for
every unsigned integer. Look for **failed**, failure category **false**, and
the **Original counterexample** and **Shrunk counterexample**. Zero suffices
to disprove it.

Select the earlier passing history row. Its source still contains `add 0`.
Editing a tab does not rewrite a completed experiment; the stale-source
notice tells you that the editor and this run differ.

Restore `add 0`. The lesson is the complete testing loop: state a claim, run
it, inspect the evidence, change the claim, and compare experiments.

## 3. Save a document and pin its source

Choose **Save As**, enter `guide/identity`, and select format `hoon`. The
document appears under **My documents** and is stored in the app desk's
Clay namespace as `/data/quiz/guide/identity/hoon`. Nested names use
lowercase letters, digits and hyphens, with `/` between directories.

A saved document and an editor buffer are different run sources:

| Source to run | What runs |
| --- | --- |
| **Draft property (editor buffer)** | The complete current buffer, including unsaved edits |
| **Saved property (selected revision)** | The saved file at the selected desk and immutable revision |
| **Saved suite (selected revision)** | A saved `test-*` core at that revision; introduced in chapter 17 |

Click **Use latest revision** and wait for **Pinned revision** to fill.
Choose **Saved property**, then **Run saved property**. Now change `add 0`
to `add 1` without saving:

1. Run as a **Draft property**: it fails.
2. Run as a **Saved property**: the pinned version still passes.
3. **Save**, then **Use latest revision**, then run saved: it now fails.

**Use latest revision** confirms with “Selected %quiz revision N”. Saving
does not advance the selected revision. This protects reproducibility but
also explains why a saved run can seem to ignore your fix.

Restore `add 0`, save, and advance the revision again. Keep this document for
later experiments. To keep a bundled example, use **Open editable copy** and
then **Save As**; the original is read-only.

Browser storage restores tabs, unsaved text, selections, layout and run
associations. Clay keeps explicitly saved documents. Save work you want to
keep beyond this browser's local storage. Closing or reopening a dirty tab
asks before discarding edits.

## 4. Distinguish false, crash and discard

Open **Examples**. Expand the named folder and click a file. For bundled
examples throughout this guide, clear count, seed and size overrides, and
set **Repeated samples** to **Document conf**. Then **Run saved property**.
Each example supplies a fixed `0v123` seed and its own configuration.

Run these four in order:

| Example | Observation with its bundled settings | Meaning |
| --- | --- | --- |
| `props/01-success` | 34 attempted, 20 accepted, 14 duplicates | Increment then decrement returns the original input |
| `failing/02-boolean` | False; original 3, shrunk 1 | Integer division by two loses an odd remainder |
| `failing/03-crash` | Crash at zero; no accepted checks | Decrementing zero is undefined |
| `props/04-discards` | 35 attempted, 20 accepted, 1 dropped, 14 duplicates | A guard excludes zero before calling decrement |

A false result says the computation returned a counterexample. A crash says
the computation did not produce a normal verdict. A discard says the input
was outside the domain the property intended to test.

Open `04-discards` and find its guard:

```hoon
?:  =(value 0)  %drop
```

This is a fragment inside the fate, before the decrement. `%drop` earns no
accepted check. An always-dropping property cannot meet a positive target.
If zero belongs to the intended domain, discarding it would conceal the bug;
the correct response is to fix the implementation or revise the specification.

Read the counters this way:

| Counter | What it measures |
| --- | --- |
| `attempted` | Generated samples, including repeats, drops and the failing sample |
| `accepted` | Evaluations that pass; repeated values count too under `%allow` |
| `dropped` | Evaluations rejected by the fate, including handled `%discard` timeouts |
| `duplicate` | Samples skipped under the selected repeat policy |
| `size` | The size the next generated sample will use |
| `shrink-tried` | Candidates considered after a failure |
| `shrink-steps` | Smaller failures accepted as replacements |

## 5. Choose inputs and preview them

Run `props/07-positive`. It tests the decrement/increment law while
generating positive numbers directly. It reaches 20 accepted checks with no
drops. Its norn takes `[size=@ud rng=_og]` and returns an `@ud`; adding one
to a draw below size makes zero impossible.

Use a guard to express a necessary precondition. Use a suitable generator
when ordinary inputs would mostly be discarded. A generator's type alone
does not establish semantic requirements such as positivity or sorted order.

Now open `failing/08-seeded-threshold` and choose **Open editable copy**.
Save it as `guide/threshold`. Its complete source is:

```hoon
/+  engine=quiz-engine
|%
  ::  Seed 0v123 produces 541; default shrinking reaches 501 in this example.
  ::
::
++  fate
  |=  value=@ud
  ^-  ?
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

The norn generates 501 through 564. The fate claims that each is at most
500, so the experiment is deliberately false. The generator uses the
supplied RNG; the document fixes its seed and requests 20 successes.

Before running:

1. Choose **Draft property** and click **Read document conf**. This compiles
   and reads the document's settings without creating a run; panel overrides
   are not applied to this inspection.
2. Enter `5` in **Preview samples**.
3. Leave **Preview shows** on **Samples, verdicts and shrink candidates**,
   then click **Preview samples**.
4. The first sample is 541. Read the size, verdict, labels and repeat marker.
   Below the table are the first sample's proposed shrink candidates.
5. Change **Preview shows** to **Samples only** and preview again. Verdicts
   are absent because the fate was not called. **Samples and verdicts**
   evaluates the fate but omits candidate generation.

Preview creates its own history record. It accepts 1–1000 samples, lists
the first 100, defaults to 20, and ignores requested checks and attempt/drop/duplicate budgets. It
shows at most 20 candidates for the first sample; it does not search for a
minimal failure. A repeat marker indicates what a normal run would skip.

**Samples and shrink candidates** shows candidates without running the fate.
A verdict preview of a hanging fate interrupts regardless of
the normal run's timeout policy. Use **Samples only** to inspect that norn.

### Inspect the generator before trusting a pass

A pass says only that the samples tried did not fail. If the generator makes
few interesting samples, or the fate discards most of them, a pass tests
little. QuickCheck's documentation recommends sampling and classifying a
generator before relying on it
([Arbitrary](https://hackage.haskell.org/package/QuickCheck/docs/Test-QuickCheck-Arbitrary.html));
Preview's **Generator summary** does both over up to 1,000 samples.

1. Run `props/36-weak-generator`. It checks example 16's insert law but
   generates arbitrary lists and drops every unsorted one. It **passes**:
   100 accepted from 324 attempts, with 215 dropped.
2. Set **Preview shows** to **Samples and verdicts**, **Preview samples** to
   `200`, and click **Preview samples**. The summary says 66% of samples
   were discarded, and the Labels table shows 1 `long` sample (a list of
   three or more) among 200. The run's own distribution agrees: 94 `short`,
   6 `long`. The law held, but almost only on lists of length 0–2.
3. Open `props/37-insert-generated`, which generates sorted lists directly
   with `sorted:gen`, and preview it the same way. Nothing is discarded and
   119 of 200 samples are `long`; its run accepts 100 from 101 attempts with
   61 `long`, and its `++cover` requires at least half.

Read a summary before trusting a pass:

- **Discards.** A high `drop` share means the fate filters what the
  generator should have produced. Generate valid inputs instead, as 37
  does; a filter also risks `exhausted` when the drops budget runs out.
- **Sizes and bytes.** If the median sample is tiny, larger cases are
  rare; raise `size-max` or change the generator's length or magnitude.
- **Repeats.** Many repeats mean the domain is small for the requested
  checks; see [chapter 6](#6-control-size-repeats-and-budgets).
- **Labels.** A label you care about that is rare in the preview is rare
  in the run. Require it with `++cover` once the generator is right.

## 6. Control size, repeats and budgets

Run `failing/05-duplicates` with its bundled settings. Its norn always
returns seven, but the target is two accepted checks. It ends **exhausted**:
four attempts produced one acceptance and three duplicates.

Change **Repeated samples** to **Evaluate every sample** and run again.
Both requested evaluations now pass. The three choices are:

| Workbench choice | Configuration | Tradeoff |
| --- | --- | --- |
| **Skip a repeated mug** | `%mug` | Compact hash tracking; a collision can skip a distinct noun |
| **Skip only an equal sample** | `%exact` | Full noun equality; retained samples consume the `seen-bytes` budget |
| **Evaluate every sample** | `%allow` | Repeated values are evaluated and may count toward the target |

Open `props/21-small-domain-allow`: two booleans have only four possible
pairs. It evaluates repeats and reaches 100 checks. Its labels show which
pairs occurred. A hundred evaluations need not mean a hundred distinct inputs.

Next preview `props/22-size-capped`. Its generated list is as long as the
size. Set **First sample size** to `3`, **Largest sample size** to `5`, and
preview several rows. The lists grow to five elements and stop growing.
Zero in the largest-size field means no cap; blank follows the document.

Size is an argument to the generator, not a universal list length. The
default schedule starts at 1 and repeatedly adds `1 + floor(2*size/21)`;
duplicates and drops advance it too. It passes 50,000 by sample 100 when
uncapped. A size cap makes expensive size-driven generators manageable.

### Set a budget in the document

The panel overrides requested checks, seed, first/largest size and repeat
policy; **More limits** overrides the other budgets, **On timeout** and each
bound for one run without editing the source. To keep a setting with the
document, put it in the editor's `++conf`. For example, replace `guide/threshold`'s `conf` arm with this
fragment, keeping its import and the closing `--`:

```hoon
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20, shrink-candidates.bounds 1)]
```

Run the draft. It ends **limited**, identifying `shrink-candidates`, and
retains the counterexample it has found. Restore the original arm and run
again to allow normal shrinking. **Effective configuration** in the result
shows the merged settings actually used.

| Setting | Default | Use |
| --- | ---: | --- |
| `requested` | 100 | Successful evaluations wanted; ceiling 10,000 |
| `attempts-max` | 10,000 | Total generated samples allowed |
| `drops-max` | 1,000 | Discards allowed |
| `duplicates-max` | 1,000 | Skipped repeats allowed; ignored with `%allow` |
| `shrink-candidates.bounds` | 1,000 | Candidates considered |
| `shrink-depth.bounds` | 100 | Accepted shrink replacements |
| `trace-steps.bounds` | 100 | Latest trace rows retained; zero disables tracing |
| `retained-runs.bounds` | 100 | Completed history retained after this property finishes |
| `samples-per-slice.bounds` | 1,000 | Ceiling on work per scheduling slice |

The remaining bounds limit source, sample, rendered, diagnostic, alternatives
and exact-repeat storage bytes, plus the requested-check ceiling. See
[configuration and limits][configuration] for every field and unit. Lower
budgets from `defaults:engine`; do not construct an incomplete configuration.
Byte, retention and slice bounds must be positive. A zero requested count
passes immediately without testing an input.

Clear panel overrides to return to document settings. A blank seed uses the
document seed, or a newly chosen seed that Quiz records. `0v0` is an explicit
seed, not a request for fresh entropy.

## 7. Shrink within the intended domain

Run the restored `guide/threshold` draft. Its original counterexample is
541 and its shrunk counterexample is 501. In this example Quiz considered
82 candidates and accepted 40 replacements.

Expand **Shrink trace**. Each step is one call of the shrinker on the best
sample so far, and the candidates tried against it. The engine accepts a
candidate only when it has a new mug, a weight strictly below the best
weight and the same failure category: the strict-weight rule. Passing or
dropped candidates cannot replace a failure. Equal-weight rearrangements are
rejected even if they would look simpler to a person. Candidates are tried
in the order the shrinker gives them; the first accepted one becomes the
best sample, and the rest of that list is never tried.

The trace opens on its last step, which says why shrinking stopped there.
**First**, **Previous**, **Next** and **Last** move between steps, and
**Accepted path only** lists just the replacements, from the original down
to the shrunk sample.

| Outcome | Interpretation |
| --- | --- |
| still fails | This lighter failure replaced the previous best (`accepted`) |
| passed, dropped | The candidate did not reproduce the failure |
| not lighter, seen | It failed the strict-weight rule or the visited-mug guard |
| other failure | It failed for a different category |
| still fails (timeout) | A hanging candidate became the best under `%fail` timeout handling |

Only the configured tail of the trace is kept. The shrunk sample is the best
this bounded search found, not a promise of a global minimum. Two crashes
can share a category while having different underlying causes.

Now run `failing/09-custom-alts`. Its domain is positive even integers. The
original 510 shrinks to 502. Open its source and find the custom alts:

```hoon
::
++  alts
  |=  sample=vase
  ^-  (list vase)
  =/  value  !<(@ud sample)
  ?:  (lte value 2)  ~
  ~[sample(q (sub value 2))]
```

Each call offers at most one smaller positive even value. At 502, candidate
500 passes, so 502 remains the failure. The generator chooses the domain;
the shrinker must preserve it. Quiz's type checks cannot infer that an even
number was intended rather than any `@ud`.

For a typed shrinker, `(alts-of:gen mold shrinker)` supplies the required
vase interface. Chapter 12 uses this to shrink command lists.

### Deliberate shrink order

Because the first accepted candidate wins, a shrinker's order decides the
path, and its moves decide where the path can end. QuickCheck's advice for
[`shrink`](https://hackage.haskell.org/package/QuickCheck/docs/Test-QuickCheck-Arbitrary.html#v:shrink)
holds here too: offer the largest structural cuts first, then shrink the
parts one at a time.

Run `failing/38-shrink-order`. An order is a list of `[qty price]` lines;
the bug charges a bulk line, of four or more, for one item fewer. The
original order is `lines=[[4 13] [0 33] [0 18] 0]`. Its shrinker is
`(shrink-list:gen (shrink-pair:gen shrink-atom:gen shrink-atom:gen))`:
delete lines, the largest chunks first, then shrink one line, its quantity
and its price separately. Open **Shrink trace** and choose **First**. Steps
1 and 2 delete the two irrelevant lines; steps 3 to 6 lower the price, 13 →
7 → 4 → 2 → 1, while the quantity stays at 4 because 3 passes. The last
step finds nothing lighter that fails: `lines=[[4 1] 0]`, after 35
candidates in 6 accepted steps.

Now run `failing/39-shrink-together`. The bug, generator and seed are the
same, but each line's fields only move together: both halved, or both
decremented. The same deletions happen, then step 3 offers `[2 6]` and
`[3 12]`, both of which pass because the quantity fell below 4. Shrinking
stops at `lines=[[4 13] 0]`, after 9 candidates in 2 accepted steps. The
price never shrank, because no move lowered it alone.

Quantity and price are independent, so they must shrink independently.
Shrink fields together only when they are coupled, as the deleted key and
its copy in the tree are in `failing/29-bst-coordinated` (chapter 13). If a
shrunk counterexample still holds values that look irrelevant, open the last
step: when every candidate also changed something that matters, the
shrinker needs a move that changes one part alone.

## 8. Replay a failure and keep a regression

Select the completed threshold failure and choose **Replay exact property**.
The new result names its **Replay of** ID. Compare seed, configuration,
source hash, pinned revision, counters and both counterexamples.

Replay keeps the exact source and dependency context, not just the seed.
An edited or closed source tab does not change the replay. A missing/pruned
record, unavailable pinned revision or incompatible engine version can
prevent it. Pinning source does not freeze the compiler across runtime upgrades.

**Rerun request** is different: it resubmits the original request. A fixed
request or document seed repeats; absent both, another seed can be chosen.
To run the newest buffer, return with **Source tab** and use the tab's Run
button. Previews and suites support rerun, not exact property replay.

### Make a regression suite

A replay record is retained history. A saved regression states what the
program should do after you decide the correct behavior. Suppose the crash
at zero from chapter 4 led you to require a saturating predecessor: zero
stays zero and positive inputs lose one.

Create a new document containing this complete suite:

```hoon
/+  *test
|%
::
++  predecessor
  |=  value=@ud
  ^-  @ud
  ?:(=(value 0) 0 (dec value))
::
++  test-zero
  ^-  tang
  (expect-eq !>(0) !>((predecessor 0)))
::
++  test-one
  ^-  tang
  (expect-eq !>(0) !>((predecessor 1)))
--
```

Save as `guide/regression`. Select **Saved suite**, choose **Use latest
revision**, click **Discover suite arms**, leave **Suite arms** blank, and
**Run saved suite**. Both arms should pass. Chapter 17 explains suite results
and adds the bundled example suites to this workflow.

### Mark an intentionally false property

Run `props/15-expect-failure`. Its `++expect %fail` makes the known false
claim finish **failed-as-expected**, shrinking to 10. Open an editable copy,
replace `(lth value 10)` with `=(value value)` and run the draft. It ends
**passed-unexpectedly**: the anticipated counterexample disappeared.

This is useful for teaching a false law or checking that a bug demonstration
still finds its bug. It does not convert budget exhaustion, engine errors or
limits into success.

## 9. Explain failures with reports

Return to halving and doubling. Open `failing/13-expected-actual`, run it,
and inspect **Notes**, **Expected** and **Actual**. The shrunk value is one;
the expected result is one and the actual result is zero.

The complete document is:

```hoon
/+  engine=quiz-engine, prop=quiz-prop
|%
  ::  Halving then doubling loses an odd remainder. The report shows the
  ::  expected and actual values, rendered with their types, and a note.
  ::
::
++  fate
  |=  value=@ud
  ^-  report:prop
  %+  note:prop  'halving then doubling should give the value back'
  (same:prop !>(value) !>((mul 2 (div value 2))))
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 20)]
--
```

`same:prop` compares the nouns and records typed renderings on a mismatch.
`note:prop` explains the claim. Pass vases using `!>` at the call site so
rendering keeps the original types. As shrinking succeeds, the explanation
is updated to describe the shrunk input.

Make an editable copy, change the comparison's actual computation to
`value`, and run the draft: it passes. Restore the original computation to
recover the useful failure. This deliberately tautological edit checks that
you understand the comparison; it is not a meaningful production property.

The report combinators are available by importing `/+  prop=quiz-prop`:

| Combinator | When to use it |
| --- | --- |
| `same`, `note` | Show expected/actual values and explanatory text |
| `label`, `classify` | Tag every result, or only results satisfying a condition |
| `collect` | Tag by the typed rendering of a value, passed with `!>` |
| `tabulate` | Add values to a named frequency table |
| `implies` | Drop an input unless a precondition holds; delay the protected computation with `\|.` |
| `all`, `any` | Combine claims as a conjunction or disjunction |

Hoon evaluates arguments eagerly. All computations in the list given to
`all` or `any` have already happened. Use `implies` with a delayed trap to
guard a decrement, division, index lookup or other partial computation.

## 10. Measure and require coverage

Run `props/12-labels-coverage`. The law passes, but also inspect
**Distribution**, its length table and **First example per label**. The
recorded run has 100 accepted lists: one empty, 15 short and 84 long.
Each label counts once per accepted sample. Its retained example is the
first passing sample with that label, not a minimized representative.

Now run `failing/14-coverage-shortfall`. Every evaluated claim passes, yet
the outcome is **uncovered**. Empty lists appeared in only 1% of accepted
samples; `++cover` required 10%.

1. Open an editable copy of 14.
2. Change `%check` in `++cover` to `%warn`.
3. Run the draft. The result passes with **Coverage warnings**.
4. Restore `%check`. Before weakening a real requirement, decide whether
   the generator should produce more empty lists instead.

### Require table entries

Run `props/35-cover-table`. Sorting is idempotent. Each nonempty sample
contributes its smallest digit to the `least` table. The empty sample
contributes nothing, so this run has 99 table entries from 100 accepted
samples. Its requirement is:

```hoon
::
++  cover-table  ~[['least' '0' 5] ['least' '1' 5] ['least' '5' 5]]
```

Each named digit must occupy at least 5% of that table's entries. Label
coverage divides by accepted samples; table coverage divides by entries in
the named table. One sample can contribute several entries.

Make an editable copy and raise the requirement for `'5'` to 100. Run the
draft and read the resulting table shortfall. Restore five afterward.

### Ask for statistical coverage

Run `props/28-confident-coverage`. Its fair-coin property requires at least
40% heads with `++cover [%confident ...]`. It evaluates repeats because the
domain has only two inputs. With the bundled seed it continues past 100,
200 and 400 checks, and passes at 800 accepted flips with 377 heads.

Quiz uses Wilson bounds at successively doubled targets. Optional
`++confidence` sets `[certainty tolerance]`, default `[9 90]`: certainty is
the exponent in a power of ten, and tolerance is a percentage of the
required share. To exercise the arm, add this before the final `--` in an
editable copy and run the draft:

```hoon
::
++  confidence  [9 90]
```

The explicit defaults preserve the experiment's settings. Other supported
values are certainty 1–15 and tolerance 1–100. If bounds stay undecided until
the configured maximum or a budget after the requested target, ordinary
percentage thresholds decide. Do not treat every `%confident` completion
as a promise that its confidence test reached a decision.

### Understand coverage through examples

A label count says how often a case occurred, not what the case looked like.
**Find examples for each label** answers the second question, as
QuickCheck's
[`labelledExamples`](https://hackage.haskell.org/package/QuickCheck/docs/Test-QuickCheck.html#v:labelledExamples)
does. It generates and judges samples as a run does until the given number
pass (blank means 100), then shrinks each label's first sample to the
smallest one that still passes and still carries that label.

1. Open `props/10-queue-model` and click **Find examples for each label**.
   The queue labels a pop on an empty queue `empty-pop`, and a pop that has
   to refill the front list from the back `refill`. The table shows the
   smallest of each, with tags rendered as numbers (`%pop` is 7.368.560,
   `%push` 1.752.397.168):

   | Label | Smallest example | Reads as |
   | --- | --- | --- |
   | `empty-pop` | `cmds=[[7.368.560 0] 0]` | pop |
   | `refill` | `cmds=[[1.752.397.168 0] [7.368.560 0] 0]` | push 0, pop |

   `refill` is the case the two-list design exists for. A run that never
   carried it would pass without testing the reversal.
2. Open `props/16-sorted-insert` and search again. Each insert position
   shrinks to its smallest witness: `empty` `[~ 0]`, `front`
   `[~[0] 0]`, `end` `[~[0] 1]`, and `middle` `[~[0 1] 1]`, the shortest
   list with a strictly inner position.
3. Open `props/32-expiry-agent` and search again. `expired` shrinks to a put
   of `%a` for one second followed by a one-second wait, and `repeated-key`
   to two puts of `%a`. Those are the two stories example 33's bug needs, so
   the passing run did exercise them.

The search needs a shrinker that can move within the domain. These three
documents have an `++alts`. A `*` sample with none, such as `12-labels-coverage`,
barely shrinks: the default shrinker's candidates leave the list type, the
fate crashes on them, and the search rejects them. A `++cover` label that no
passing sample carried is listed under **++cover labels no passing sample
carried**. A generated sample that fails ends the search; it appears as an
ordinary counterexample below the labels found so far. Each label's shrink
has its own shrink budgets; **shrink limit reached** marks one that ran out.

## 11. Generate structured data

Open, preview, then run the following examples. Read the fate first: what
would count as a counterexample? Then read the norn: can it generate one?

| Example | Exercise |
| --- | --- |
| `props/06-composed` | Follow a list and offset through two equivalent sum computations. Its `quiz` library list/cell norns illustrate composition. |
| `props/16-sorted-insert` | Inspect the sorted-list generator and insertion-position labels. Check that empty, front, middle and end cases all meet coverage. |
| `props/18-parse-print` | Follow decimal, ship and knot values through print/parse round trips. Inspect the aura-specific generators. |
| `failing/34-typed-defaults` | Find the missing norn and alts: defaults use the sample type. Read the shrunk `[name='' tags=~[%a %a %a]]`. |
| `failing/31-float-associativity` | Inspect the finite float generator and the shrunk triple. Floating-point rounding invalidates mathematical associativity. |

For new custom generators, import `/+  gen=quiz-gen`. Choose a construction
that makes valid inputs directly: `range` for bounded integers, `sorted` for
ordered lists, `pair` or `trip` for independent components. `cook` transforms
generated data; `bind` chooses a later generator from an earlier draw.

Use `sized` to inspect the current size, `resize` to replace it, `scale` to
transform it, and `capped` to limit one component. These generators handle
size zero as size one, although the workbench's starting-size field begins
at one. Empty choices and exhausted `such-that` retries are generation
errors, not successful tests.

If you write RNG operations yourself, split or thread the supplied RNG.
Calling `rad` twice on the same unchanged RNG core repeats a draw. Ambient
time or entropy would destroy replayability.

Defaults are useful but heuristic. `quiz-auto` recognizes meaningful auras,
lists, units, sets, maps and unions; generated containers hold at most 20
elements. It cannot infer that a list is sorted or that two fields agree.
An explicit norn and domain-preserving alts are the tools for those rules.
See [Appendix B](#appendix-b-property-and-library-map) for the library map.

## 12. Test a model and shrink command sequences

Run `props/10-queue-model`. It generates commands against a two-list queue
and a simple list model, comparing replies and contents after every command.
Each sample starts with fresh state. The model should be easier to trust
than the implementation it checks.

Now run `failing/11-queue-model-bug`. A pop wrongly returns the newest item.
The original twelve-command sequence shrinks to two different pushes and
one pop, equivalent to:

```text
push 0
push 1
pop       expected 0, got 1
```

The sample is represented as a noun, so the result may print command tags
as numbers. Read the source's command mold to interpret them.

Pop on an empty queue is invalid in this version. Its norn creates only
valid sequences; its alts deletes commands and shrinks values while keeping
that precondition. Removing the first push indiscriminately could produce
a different failure, a crash, instead of the queue-order bug.

Open and run `failing/19-queue-gen-lib`. It rebuilds this approach with
`list-of`, `cook`, `shrink-list` and `shrink-keep`. Follow the composition:
generate commands, repair or constrain them, then filter shrink candidates
through the same validity condition. `alts-of` adapts the typed shrinker.

Use **Open editable copy** to experiment with these constructions and
**Preview samples** to inspect their initial candidates before running.
Command-sequence testing is an ordinary fate over data; Quiz has no separate
parallel or asynchronous state-machine runner.

## 13. Keep related inputs consistent

### Coordinate values that must stay equal

Run `failing/17-bst-delete-bug`. Deleting a search-tree root loses the right
subtree. A sorted-set model reveals the bug. Independent shrinking stops
with keys `[12 0 13]`, deleting 12.

Run `failing/29-bst-coordinated`. It tests the same bug but adds
`shrink-equal` through `shrink-via` and `shrink-then`. Every copy of a key
changes together; now the counterexample reaches `[1 0 2]`, deleting 1.
Compare the alts definitions in the two tabs. A better shrinker improved
the explanation without changing the law being tested.

### Regenerate a dependent input

Run `failing/20-dependent`. The index is generated from the list's length,
so shrinking the list independently would risk indexing beyond its end.
`seeded` stores an outer value, seed, size and optional pinned inner value;
`regen` consistently rebuilds the dependent value when the outer one changes.

Then run `failing/30-dependent-inner`. Its `dependent` helper bundles the
sample mold, norn, shrinker, alts and a `both` accessor. After shrinking the
outer bound, it shrinks and pins the inner list itself. Inspect the final
bound of one and pinned list containing 90.

Independent `pair` generation is appropriate for unrelated values. Use
`bind` for dependent draws, and `seeded`/`dependent` when their relationship
must survive shrinking too. These examples are the templates to copy into
**My documents** for such properties.

## 14. Generate functions

Run `props/23-map-fusion`. It checks that mapping with `f` and then `g`
equals one map with their composition. Both functions are generated inputs.

Quiz's `quiz-fun` represents a function as a finite table of key/value cases
plus a default. Data can be printed, shrunk and replayed; an arbitrary
compiled gate cannot be generated this way. `to-gate` lets a generated table
act as a Hoon gate in operations such as `turn` and `skim`.

Run `failing/24-filter-map-swap`. The claim that filtering and mapping can
always be swapped is false. Inspect the shrunk notes:

```text
items: [8]
f:     {_ -> 0}
p:     {8 -> %.y, _ -> %.n}
```

Filtering first keeps 8, then mapping gives `[0]`. Mapping first gives `[0]`,
which the predicate rejects. This small example explains why the law fails.

Use `fun-of` for generated cases or `fun-on` for a complete finite domain.
`apply` looks up a value; `fun-text` prints a table for a note. `shrink-fun`
removes cases and simplifies outputs/defaults while preserving keys.
Open an editable copy of 24 and inspect its norn and alts together before
changing the generated function domains.

## 15. Test agent doors and simulated time

### Compare an agent with a model

Run `props/25-counter-agent`, then `failing/26-counter-agent-bug`. A pure
driver feeds generated events to a counter agent's door and compares its
saved state with a model. The bug drops additions above ten; shrinking
leaves one `[%add 11]`, expected 11 and actual zero.

Read the imports and driver call. `/+  h=quiz-harness` supplies the harness;
an explicit `/=` import supplies the fixture driver. For each event the
driver rebuilds the door from saved state, invokes an arm, and saves again.
The model and agent start fresh for each generated sample.

The harness accepts poke, watch, leave, peek, agent-sign and Arvo-sign
events. `bowl-at` constructs the input bowl from explicit values. `run`
folds events through the driver. Inspect emitted cards with `cards-of`,
`facts-on`, `pokes-to` and `watches-to` when replies matter as much as state.

This tests an agent's logic without installing or poking that agent on the
ship. Scries are refused; other agents and services reply only when your
generated events provide the signs.

### Advance a simulated clock

Run `props/32-expiry-agent`, then `failing/33-expiry-agent-bug`. The buggy
store replaces a key but fails to cancel its previous expiry timer. The
shrunk story is:

```text
put key a, expiring in one second
replace key a, expiring in two seconds
wait one simulated second
```

The old timer deletes the replacement too soon. `run-clock` tracks Behn
wait/rest cards and feeds due wakes back to the driver in time order; equal
due times retain registration order. Inspect its remaining timers and
final simulated time. No wall-clock sleep or real Behn timer is required.

To adapt this example, copy its property, supply your door/driver on the
dependency desk, define events and an independent model, then preview and
run from the workbench. Creating those dependency files outside
`/data/quiz` remains a desk-development task.

## 16. Set time limits and manage jobs

Open **Settings** with `F2`. Under **Quiz CPU time limits**, inspect:

| Setting | Default | Limits |
| --- | ---: | --- |
| **Property call** | 10 seconds | Each norn, fate, alts and sample-rendering call |
| **Draft build** | 30 seconds | Draft compilation and document-arm checks |
| **Suite arm** | 60 seconds | Compilation/execution of one suite arm |

Settings accept whole seconds from 1 to 3600 and save when the dialog
closes. They are ship-wide, not per-tab, and apply at the next relevant
slice, build or arm. Saved-file and suite Clay builds are outside these
CPU limits.

### Treat a hanging fate as a finding

On the disposable ship, run `props/27-timeout-fail`. Its fate hangs above
ten. `++within ~s0..8000` lowers this document's call limit to half a second,
and `on-timeout %fail` makes the hang a shrinkable timeout failure.
Expect **failed**, **timeout**, **500 ms per call**, and shrunk `n=11`.
The complete run takes longer than half a second because several candidates
hang and each abort has recovery overhead.

| `on-timeout` in `++conf` | Fate timeout during a normal run |
| --- | --- |
| `%interrupt` | Ends the run as interrupted; default |
| `%fail` | Records a timeout failure and tries to shrink it |
| `%discard` | Counts the input as dropped and continues within budgets |

For a short second experiment, make an editable copy of 27, replace
`on-timeout %fail` with `on-timeout %discard`, and lower `attempts-max` to
15 in the same configuration update. Run the draft and inspect drops and
the terminal budget result. Restore the original settings afterward.

These policies cover fate timeouts. A hanging norn, alts or rendering call
still interrupts. `++within` accepts 10 milliseconds to one hour and can
only lower the ship-wide call limit. Replay carries the arm in its source,
but does not restore ship-wide CPU settings or guarantee timing outcomes.

### Follow, cancel and recover jobs

Only one job executes at a time; up to 100 others may wait in the FIFO queue.
Select a history row to follow **queued**, **building**, **running** or
**shrinking**. **Cancel selected run** removes queued work or requests active
cancellation at the next scheduling boundary. It cannot preempt a call
currently blocking the ship.

To practice cancellation, use a cheap passing draft, set **Requested checks**
to `10000`, and click Run, then **Cancel selected run** while it is active.
If it finishes first, that completed run is unchanged; cancellation is a
no-op for completed IDs. Avoid a hanging call merely to make cancellation
easier to see.

| Terminal result | Next action |
| --- | --- |
| **exhausted** | Read the attempts, drops or duplicates budget; inspect the generator and repeat policy |
| **limited** | Read the named bound and any retained counterexample; simplify data or adjust a lowered budget within its ceiling |
| **invalid** | Read the diagnostic code, path, arm and location; fix syntax, types, imports, context or settings |
| **error** | Read the generator/shrinker stage; repair the helper, not the claimed law |
| **interrupted** | Read the stage and suite arm, if present; only previously committed evidence survives |
| **cancelled** | Read `request` or `reload`; submit a new job when appropriate |

A CPU abort, terminal Ctrl-C or memory exhaustion can interrupt a job. The
ordinary interrupted outcome does not distinguish those causes. Byte caps
apply after allocation; there is no memory isolation. Reloading `%quiz`
cancels unfinished jobs and preserves completed records.

If the connection fails, the pane retains last confirmed results and
disables mutations. After reconnecting, **Refresh history** before retrying
a submission: its reply may have been lost after admission. Quiz does not
automatically retry mutations. Active history polls about every second,
idle history every 30 seconds; a hidden page refreshes when visible again.

History normally retains the newest 100 completed records. Lowering a
property's `retained-runs` affects shared history when it finishes.
**Delete record** removes the selected completed run, and **Clear completed
history** removes every completed run; each asks you to confirm, and neither
touches queued or active work. Deleting a work file does not delete its run
records, and closing a tab does neither.

## 17. Run saved suites

Open **Examples → examples → 02-boxcar**. **Saved suite** is selected
automatically. Click **Discover suite arms**; discovery lists test names
without executing them.

1. Enter `test-boxcar-4-5` in **Suite arms** and **Run saved suite**.
2. Check that one arm completed and passed.
3. Clear **Suite arms** and run again. All three arms pass.
4. For a subset, enter exact names separated by commas or spaces. Execution
   uses descending name order, regardless of selection order.

Run `examples/01-quiz-tutorial` (12 passing arms) and `examples/03-euler`
(four passing arms). Together with boxcar these are the 19 bundled example
arms. Inspect the tutorial source for the `quiz` library's `check`, custom
norns and alts embedded in ordinary test arms.

A suite is a saved Hoon core whose `test-*` arms produce `tang`:

| Arm result | Meaning |
| --- | --- |
| **passed** | Empty diagnostic list |
| **failed** | Nonempty diagnostic list, displayed with the arm |
| **crashed** | Execution crashed or attempted a refused scry |
| **invalid** | The arm could not compile with a `tang` product |

An unsuccessful returning arm does not stop later arms. The overall suite
passes only if every selected arm passes. A runtime abort interrupts the
suite and identifies the active arm when available.

The workbench reports suite arm counts, not property sample counts hidden
inside library calls. Seed and exact property replay are unavailable for
suites; use **Rerun request**. A suite requiring live scries can work with
Dojo's `-test` yet fail under the app runner's refusing scry gate.

To extend your `guide/regression`, edit it, **Save**, **Use latest revision**,
discover, and run again. There is no draft-suite mode. A suite copied into
**My documents** works directly; choosing an arbitrary suite elsewhere on
a desk is affected by the Clay browsing gap in the next chapter.

## 18. Use other Clay contexts and imports

Each property runs with a dependency/source desk and a pinned revision.
The draft buffer supplies the main text; imports still come from that desk
and revision. A saved run reads both the file and imports there.

To browse indexed properties and suites:

1. Open **Clay source** and select a desk.
2. Enter an available positive decimal **Revision**.
3. Click **Browse revision** and select a listed file. Suites are marked
   “(suite)”.
4. Inspect its read-only source and pinned context, or use **Open editable
   copy** to experiment with a draft.

The index is textual: a property imports `quiz-engine` on a `/+` prelude line,
under any face, and has a top-level `++  fate`; a suite has a top-level
`++  test-` arm. A valid minimal property without the engine import is absent.

Any other Hoon file at that context opens through **Open** (Alt-O): choose
the `clay` location, which lists every Hoon file at the desk and revision last
browsed in **Clay source**. A file with `++  test-` arms and no `++  fate`
opens ready to run as a saved suite, so external suites run from the
workbench.

### Import dependencies

Property documents accept these prelude groups, in order:

| Form | Source |
| --- | --- |
| `/-  types` | `/sur/types/hoon` |
| `/+  gen=quiz-gen, prop=quiz-prop` | Aliased libraries under `/lib` |
| `/=  drive  /fixtures/quiz-harness/drive` | A Hoon dependency at an explicit path |
| `/*  text  %txt  /fixtures/quiz-build/note/txt` | Raw native-mark data |

Raw marks are `%hoon`, `%txt` and `%noun`, with matching suffixes. Groups
may repeat in their supported order. Cross-desk imports and other Ford
prelude runes are unsupported in the submitted property document.
Dependencies and saved suites use ordinary Ford compilation.

Choose **Dependency / source desk** and **Pinned revision** before running
an imported property. **Use latest revision** resolves an available current
revision; typing a numeric revision keeps a historical context. The API
also accepts date and label selectors; the workbench supplies numeric ones.

For an import error, try the same text as a draft to obtain a more precise
diagnostic than a failed saved Clay build. Do not silently switch revisions
while investigating a reproducibility problem.

## 19. Arrange the workbench and find help

Use **Open** to reopen a saved file, **Save** to update it and **Save As** to
keep another version. Markdown is available as `md` for your notes; Hoon
files are the runnable sources. **Copy** copies the active document text to
the clipboard. It does not create a tab or export the selected run.

**Add Ref** opens a reference panel that follows the document while you
edit. Drag tabs to reorder them and use **×** to close one. File-row **…**
menus offer actions including deletion of writable work files, with
confirmation. Read-only examples and documentation cannot be overwritten.
If a save reports a conflict, preserve your buffer and compare it with the
other saved version before overwriting.

**Settings** offers system/light/dark theme, Ace/Vim keybindings and
columns/rows layout. Drag pane dividers, or focus one and use arrow keys.
Dialogs can be dragged by their headers; double-click the header to recenter.

| Shortcut | Action |
| --- | --- |
| `F1` | Help, including from the editor |
| `F2` | Settings, including from the editor |
| `Ctrl-S` | Save |
| `Ctrl-Shift-S` | Save As |
| `F5` | Run the selected source workflow, outside the editor |
| `Alt-O` | Open, outside the editor |
| `Alt-C` | Copy document, outside the editor |
| `Esc` | Close the top dialog |
| `Enter` / `Space` on a file row | Open |
| `Alt-Enter` / `Shift-F10` on a file row | Row actions |
| `Delete` on a writable file row | Request deletion, with confirmation |

Use Command in place of Ctrl on macOS. Rerun, replay and cancel have buttons
but no configured shortcuts. The editor retains its normal search,
undo/redo, selection and editing commands; see [keyboard help][keys].

**Documentation** always offers shipped source text. **Help** uses rendered
documentation when a Markdown-capable `%docs` is installed, with a built-in
summary as fallback. Installation of `%docs` is outside Quiz's workbench.

## Choosing useful properties

Use this table when deciding what to test. Open the named documents under
**Examples**; the tutorial and boxcar suites are in its `examples` folder.
**Conceptual** rows are exercises to write, not additional Quiz APIs.

| Technique | Working example or conceptual exercise |
| --- | --- |
| Invariant | Boxcar `test-boxcar-sanity` checks its result is in the allowed range; the other two arms supply stronger meaning. |
| Round trip | Tutorial `test-jam-cue` checks decoding an encoded noun; `18-parse-print` covers decimals, ships and knots. A broken pair can share a bug, so add known encodings or an independent model. |
| Algebraic law | Tutorial `test-add-sub`, reverse-concatenation checks in `test-flop-2`, and the composed offset/sum document compare equivalent computations. |
| Idempotence | **Conceptual:** normalizing an already normalized record should leave it unchanged. Add expected examples; a function returning a constant can satisfy this law. |
| Simple model | `10-queue-model` compares a two-list queue with a plain list model after each command. Keep model logic independent from the optimized implementation. |
| Avoid tautologies | The offset/sum example compares two computations. Comparing a value only with itself cannot find a bug; don't use that as a real specification. |
| Avoid vacuity | `04-discards` still requires 20 accepted inputs; `05-duplicates` explicitly exhausts. An always-dropping generator establishes nothing. |
| Boundaries | The regression in [chapter 8](#8-replay-a-failure-and-keep-a-regression) checks zero and one explicitly; boxcar checks four/five. `16-sorted-insert` labels where an inserted value lands (empty, front, middle, end) and requires each with `++cover`. |
| Data structures | `17-bst-delete-bug` checks a binary search tree against a sorted-set model and shrinks a failing deletion to three keys. |
| Filtering | Compare `04-discards` with `07-positive`: construct the domain directly when most inputs would be dropped. |
| Generator preview | **Preview samples** on `08-seeded-threshold` lists its first samples, sizes and verdicts, and the default shrinker's candidates for the first one. Preview creates its own history record without running the normal accepted-check loop. |
| Distribution | `12-labels-coverage` labels each list by length and requires short and long lists with `++cover`; `14-coverage-shortfall` shows a requirement the generator misses; `35-cover-table` requires shares of a tabulated value with `++cover-table`. Know the generator's shape: the library's `list` norn has at most `xeb(size)-1` elements. See [measured generator characteristics][generator-characteristics]. |
| Readable failures | `13-expected-actual` uses `same` and `note`, so the run shows the expected and actual values, not just `false`. |
| Repeatability | Threshold replay records effective inputs and both counterexamples. Preserve the Clay revision too. |
| Domain-preserving shrink | `09-custom-alts` keeps positive even values and terminates; `11-queue-model-bug` keeps a pop precondition while shrinking a command list; `19-queue-gen-lib` does the same with `quiz-gen`'s `shrink-keep` and `shrink-list`. |
| Dependent inputs | `20-dependent` regenerates an index from a seed as its list shrinks, so no candidate indexes past the end. `30-dependent-inner` also shrinks the dependent value itself, pinned in the sample, and builds its arms with the `dependent` helper. |
| Floats | `31-float-associativity` shows that float addition is not associative. The sized `real` starts with exact small values; `shrink-real` keeps every candidate finite and ends at short decimals. The app's default shrinker uses `shrink-real` too; only the `quiz` library treats a float as a raw atom ([limitations][limitations]). |
| Defaults from types | `34-typed-defaults` has no norn or alts: its text, list of terms and their shrinking come from the sample's type through `quiz-auto`. |
| Related values | `29-bst-coordinated` shrinks equal keys together with `shrink-equal`, so a key that must stay in the tree shrinks with its copy. |
| Small domains | `21-small-domain-allow` checks De Morgan's law over two loobeans. Only four samples exist; `duplicates %allow` evaluates repeats, so 100 checks pass and the labels show every case. |
| Agent model | `25-counter-agent` runs generated pokes against a counter agent's door and compares its state with a model. `26-counter-agent-bug` finds a lost update, an add above ten the agent drops, and shrinks to a single `[%add 11]`. `32-expiry-agent` and `33-expiry-agent-bug` add a simulated clock with `run-clock`: generated waits fire the agent's behn timers, and 33 finds an old timer deleting a re-put key early. The harness is pure: real effects are out of scope ([limitations][limitations]). |
| Hanging code | `27-timeout-fail` gives a fate that never returns for inputs above ten. `on-timeout %fail` reports each hang as a `timeout` failure and shrinks to `n=11`. The browser test also checks `%discard`, which drops hanging samples and carries on. Use a short call limit: the example's `++within ~s0..8000` lowers its own limit to half a second without changing Settings. See [timeout policy][timeout-policy]. |
| Higher-order functions | `23-map-fusion` and `24-filter-map-swap` generate the function arguments themselves with `quiz-fun`. |
| Size control | `22-size-capped` checks a quadratic sort against `sort` on lists as long as the size. `size-max 30` keeps the lists short; `quiz-gen`'s `capped`, `resize` and `scale` do the same for one generator. |

These are design suggestions, informed by FsCheck's
[Properties](https://fscheck.github.io/FsCheck/Properties.html),
[Test Data](https://fscheck.github.io/FsCheck/TestData.html),
[Running Tests](https://fscheck.github.io/FsCheck/RunningTests.html), and
[Tips and Tricks](https://fscheck.github.io/FsCheck/TipsAndTricks.html).

These cross-references explain general techniques. Use the Quiz
[reference][reference] for Hoon contracts; FsCheck APIs are not Quiz APIs.

## Appendix A. Every bundled example

All property examples fix seed `0v123`. Leave panel overrides blank to use
their settings. A file under `props` can deliberately produce a failure:
27 demonstrates a timeout, and 15 expects a false claim to fail.

| Open under Examples | Expected outcome | Chapter |
| --- | --- | --- |
| `props/01-success` | Passed, 20 accepted | 4 |
| `failing/02-boolean` | Failed, false | 4 |
| `failing/03-crash` | Failed, crash at zero | 4 |
| `props/04-discards` | Passed, 20 accepted with a discard | 4 |
| `failing/05-duplicates` | Exhausted, duplicates | 6 |
| `props/06-composed` | Passed, 20 accepted | 11 |
| `props/07-positive` | Passed, 20 accepted, no drops | 5 |
| `failing/08-seeded-threshold` | Failed, false; 541 → 501 | 5 |
| `failing/09-custom-alts` | Failed, false; best sample 502 | 7 |
| `props/10-queue-model` | Passed, 100 accepted | 12 |
| `failing/11-queue-model-bug` | Failed, false; 12 commands → 3 | 12 |
| `props/12-labels-coverage` | Passed, 100 accepted; coverage met | 10 |
| `failing/13-expected-actual` | Failed, false; expected 1, actual 0 | 9 |
| `failing/14-coverage-shortfall` | Uncovered; empty 1% of 10% | 10 |
| `props/15-expect-failure` | Failed as expected; 11 → 10 | 8 |
| `props/16-sorted-insert` | Passed, 100 accepted; every position covered | 11 |
| `failing/17-bst-delete-bug` | Failed, false; 9 keys → 3 | 13 |
| `props/18-parse-print` | Passed, 100 accepted | 11 |
| `failing/19-queue-gen-lib` | Failed, false; 4 commands → 3 | 12 |
| `failing/20-dependent` | Failed, false; one-element list | 13 |
| `props/21-small-domain-allow` | Passed, 100 accepted from four samples | 6 |
| `props/22-size-capped` | Passed, 100 accepted; size held at 30 | 6 |
| `props/23-map-fusion` | Passed, 100 accepted | 14 |
| `failing/24-filter-map-swap` | Failed, false; `p = {8 -> %.y, _ -> %.n}` | 14 |
| `props/25-counter-agent` | Passed, 100 accepted; 5 duplicates | 15 |
| `failing/26-counter-agent-bug` | Failed, false; `[%add 11]` | 15 |
| `props/27-timeout-fail` | Failed, timeout; shrinks to `n=11` | 16 |
| `props/28-confident-coverage` | Passed, 800 accepted; heads 377 | 10 |
| `failing/29-bst-coordinated` | Failed, false; `[~[1 0 2] 1]` | 13 |
| `failing/30-dependent-inner` | Failed, false; bound 1, pinned `~[90]` | 13 |
| `failing/31-float-associativity` | Failed, false; `[a=.~-1.2 b=.~-1 c=.~1]` | 11 |
| `props/32-expiry-agent` | Passed, 100 accepted; 15 duplicates | 15 |
| `failing/33-expiry-agent-bug` | Failed, false; two puts of `%a` and a wait | 15 |
| `failing/34-typed-defaults` | Failed, false; `[name='' tags=~[%a %a %a]]` | 11 |
| `props/35-cover-table` | Passed, 100 accepted; 64 duplicates | 10 |
| `props/36-weak-generator` | Passed, 100 accepted; 215 dropped | 5 |
| `props/37-insert-generated` | Passed, 100 accepted; 61 long | 5 |
| `failing/38-shrink-order` | Failed, false; 3 lines → `[[4 1] 0]` | 7 |
| `failing/39-shrink-together` | Failed, false; 3 lines → `[[4 13] 0]` | 7 |
| `examples/01-quiz-tutorial` | Suite passes, 12 arms | 17 |
| `examples/02-boxcar` | Suite passes, 3 arms | 17 |
| `examples/03-euler` | Suite passes, 4 arms | 17 |

## Appendix B. Property and library map

Every document arm can be written in the workbench editor. Only `fate` is
required; helpers can be additional arms. This table connects the complete
property interface to the lessons:

| Arm | Lesson |
| --- | --- |
| `fate` | 2–4: pass, false, crash, discard; 9: reports |
| `norn` | 5 and 11: generated inputs |
| `alts` | 7, 12 and 13: custom and composed shrinking |
| `conf` | 5–6 and 16: seed, budgets, sizes, repeats and timeout policy |
| `cover` | 10: warn, check and confident coverage |
| `cover-table` | 10: shares within tables |
| `confidence` | 10: confidence parameters |
| `within` | 16: per-document call limit |
| `expect` | 8: expected failure |

The libraries below are editor imports, not separate tool panels. Their
full contracts are in the [reference][reference].

| Library | Public facilities and where to start |
| --- | --- |
| `quiz-prop` | `same`, `note`, `label`, `classify`, `collect`, `tabulate`, `implies`, `all`, `any`; chapters 9–10 |
| `quiz-gen`: scalar data | `range`, `upto`, `signed`, `ship`, `date`, `span`, `real`, `real-single`, `real-bits`, `real-single-bits`, `cord`, `knot`, `term`, `chars`; chapters 5 and 11 |
| `quiz-gen`: choices/containers | `elements`, `one-of`, `frequency`, `unit-of`, `list-of`, `nonempty`, `vector`, `set-of`, `map-of`, `sublist`, `shuffle`, `sorted`, `pair`, `trip`; chapters 11–12 |
| `quiz-gen`: transformation/size | `cook`, `bind`, `such-that`, `sized`, `resize`, `scale`, `capped`; chapters 6 and 11 |
| `quiz-gen`: shrinkers | `shrink-atom`, `shrink-toward`, `shrink-real`, `shrink-real-single`, `shrink-list`, `shrink-pair`, `shrink-unit`, `shrink-set`, `shrink-map`, `shrink-via`, `shrink-keep`, `shrink-equal`, `shrink-then`, `shrink-nothing`, `alts-of`; chapters 7 and 12–13 |
| `quiz-gen`: dependency | `seeded`, `regen`, `shrink-seeded`, `dependent`; chapter 13 |
| `quiz-auto` | Implicit type-directed generation/shrinking; `fill`, `sink`, `smaller` when extending defaults; chapter 11 |
| `quiz-fun` | `fun`, `apply`, `to-gate`, `fun-of`, `fun-on`, `shrink-fun`, `fun-text`; chapter 14 |
| `quiz-harness` | Events, `bowl-at`, `run`, `run-clock`, `cards-of`, `facts-on`, `pokes-to`, `watches-to`; chapter 15 |
| `quiz` library | `check`, `check-verbose`, norns and vase-based alts inside saved suites; chapter 17 and the tutorial suite |

The `quiz` library has different counting and stopping semantics.
Drops count toward its run target, zero requests mean 100, and duplicate
exhaustion can return success. The application uses accepted checks and
explicit exhaustion. Prefer app property documents for the workbench's
structured evidence; use the library inside `-test` suites. The standalone
Dojo `+quiz` generator and recursive `-test` command are native entry points,
not commands available from the workbench.

## Appendix C. Workbench access and validation

“Accessible” here means reachable with visible workbench controls or by
authoring Hoon in its editor. Browser-console calls and direct HTTP/Gall
requests do not count as UI access. Low-level engine/build/job functions are
implementation interfaces, not additional workbench operations.

| Feature | Workbench route | Assessment |
| --- | --- | --- |
| New/open/save/save-as/delete work documents; copies and reference panels | Editor, explorer and dialogs | Available |
| Draft and saved properties; all nine property arms | Editor and Run controls | Available |
| Generator/shrinker/report/function/harness libraries | Editor imports, preview and run | Available; libraries have no dedicated GUI editors |
| Counts, seed, sizes and repeat-policy overrides | Run-panel fields | Available |
| Other budgets, bounds and timeout policy | More limits; or `++conf` | Available |
| Sample/verdict/candidate previews | Four Preview presets | Available |
| Diagnosis, counterexamples, coverage and shrink trace | Selected history result | Available with bounded retained evidence |
| Exact property replay; request rerun | Result buttons | Available; suites/previews cannot exact-replay by design |
| Saved-suite discovery and named/all arms | Run controls | Available for openable saved suites |
| CPU limits and document call limit | Settings and `++within` | Available |
| Queue observation, cancellation and history refresh | Result controls | Available; cancellation waits for a scheduling boundary |
| Browse indexed properties and suites at numeric revisions | Clay source | Available |
| Advance a saved tab's revision | Use latest revision | Available |
| General Clay-file chooser, including unindexed external suites | Open → clay | Available at the context browsed in Clay source |
| Date/label revision selection | Pinned revision | Available; Clay source browsing stays numeric |
| Delete one completed run or clear completed history | Delete record; Clear completed history | Available; queued and active runs are kept |
| Full machine-readable record and sample noun export | Record: Download record, Copy sample noun | Available |
| Secondary shrinker error alongside retained failure | Error cause above the retained evidence | Available |
| Live Gall subscriptions | Browser polls history | Programmatic interface only |
| Install/update desk, agent lifecycle and recursive `-test` | No workbench control | Operator/Dojo workflow |
| Rendered Help | Help, with `%docs` installed | Available conditionally; fallback summary otherwise |

The claim that **all Quiz functionality is accessible through the urui
workbench is false for this revision**. The tutorial covers the accessible
property and suite workflows and identifies the remaining interface gaps.
No application code was changed to hide or repair those gaps.

The companion [validation record](cod-ug-validation.md) gives the fresh
test results, source comparisons, test-to-feature mapping and remaining
validation limits. It distinguishes actual fake-ship execution from source
inspection and recorded evidence.

## Sources

The implementation and public contracts take precedence over this guide.
It draws on the [workbench documentation][workbench], [source format][source-format],
[reference][reference], [example catalog][examples], [suite/replay
contract][suites], [HTTP API][http-api], [Gall API][agent-api],
[limitations][limitations], local verification records,
and the examples themselves. It borrows its progressive teaching structure
from [Obelisk's guide][obelisk-guide], not Obelisk's commands or UI behavior.

[obelisk-guide]: ../../../../../../mnt/mars/gitrepos/obelisk/desk/doc/usr/users-guide.md
[installation]: ../../../../../../mnt/mars/gitrepos/quiz/README.md#installation
[reference]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/reference.md
[configuration]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/reference.md#configuration-and-limits
[workbench]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/workbench.md
[source-format]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/source-format.md
[examples]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/examples.md
[suites]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/suites-and-replay.md
[http-api]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/http-api.md
[agent-api]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/agent-api.md
[limitations]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/limitations.md
[keys]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/keyboard/quiz-keys.md

[generator-characteristics]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/reference.md#measured-generator-characteristics
[timeout-policy]: ../../../../../../mnt/mars/gitrepos/quiz/desk/doc/reference.md#timeout-policy-on-timeout
