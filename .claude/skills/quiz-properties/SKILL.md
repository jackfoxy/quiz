---
name: quiz-properties
description: Write, review, run and interpret Quiz property tests for Hoon. Covers app property documents (++fate, ++norn, ++alts, ++conf), norn composition, domain-preserving shrinkers, %drop, choosing seeds and budgets, reading outcomes (passed, failed, exhausted, limited, error, invalid), replay, turning a counterexample into a regression test, and the frozen legacy check/check-verbose library. Use whenever someone wants to property-test Hoon code, write or debug a quiz fate or norn, explain a quiz result or counter, or choose between a property document, a test suite and the legacy library, even if they do not say "quiz".
---

# Quiz property authoring

Quiz checks a claim (the **fate**) against generated inputs and then
shrinks a failing input. It has two separate entry points with different
semantics. Pick the right one first:

| Goal | Use | Semantics |
| --- | --- | --- |
| Run in the workbench or `%quiz` agent with recorded seed, counters and replay | Property document (below) | App engine, `lib/quiz-engine.hoon` |
| Assert a property inside an ordinary `-test` suite | `~(check quiz seed runs)` from `/+ quiz` | Frozen legacy library |
| Run existing `test-*` arms through the app | Saved suite | Arm-level results only |

The legacy library counts drops toward `runs` and can return `%.y` after
duplicate exhaustion (`%tired`). The app never counts drops or duplicates
as accepted checks. Do not mix their numbers. See
[app vs legacy semantics](../../../desk/doc/reference.md#app-and-legacy-semantics-compared).

## Property document template

A document is one `.hoon` file whose product is a core. Only `++fate` is
required. Start from this and delete what you don't need:

```hoon
/+  engine=quiz-engine, quiz
|%
  ::  Increment then decrement is an identity on positive atoms.
  ::
::
++  fate
  ::  Zero is outside the domain; drop it rather than crash in dec.
  |=  value=@ud
  ^-  ?(? %drop)
  ?:  =(value 0)  %drop
  =(value +((dec value)))
::
++  norn
  ::  Generate the domain directly so drops stay rare.
  |=  [size=@ud rng=_og]
  ^-  @ud
  +((rad:rng size))
::
++  alts
  ::  Halve or decrement, never leaving the positive domain.
  |=  sample=vase
  ^-  (list vase)
  =/  value  !<(@ud sample)
  ?:  (lte value 1)  ~
  ~[sample(q (div value 2)) sample(q (dec value))]
::
++  conf
  =/  cfg  defaults:engine
  [[~ 0v123] cfg(requested 50)]
--
```

The builder type-checks every arm before anything runs. A mistake is an
`%invalid` outcome with a code and line, not a failing property.

- `fate`: a gate. Its sample type is the input domain. Its product must nest
  in `?(? %drop)`. `%.y` accepts, `%.n` is a counterexample, `%drop` rejects
  an input that is outside the domain. A crash or scry is a failure
  (`%crash`, `%scry`), not a drop.
- `norn`: `$-([@ud _og] sample-type)`. Returns the value, not a vase.
- `alts`: `$-(vase (list vase))`. Returns candidate smaller inputs.
- `conf`: `[seed=(unit @uv) config=conf:engine]`. Always edit a copy of
  `defaults:engine`. A partial record does not type-check, and a field above
  its ceiling is `%conf-range`. Besides the budgets it sets `size-start`
  (default 1), `size-max` (0 = uncapped), `duplicates` (`%mug`, `%exact` or
  `%allow`) and `on-timeout` (`%interrupt`, `%fail` or `%discard`), as in
  `cfg(size-max 30, duplicates %allow)`. Under `%fail` a hanging fate is a
  `timeout` failure, and under `%discard` it is dropped; each costs a full
  call limit, so use a short one. See
  [timeout policy](../../../desk/doc/reference.md#timeout-policy-on-timeout).

The prelude allows only `/-`, `/+`, `/=`, `/*`, in that order, all from the
selected desk at the pinned revision. Full rules:
[source-format.md](../../../desk/doc/source-format.md).

## Writing a good fate

- **Compare two computations.** Use a round trip, an algebraic law or a
  simple model. Comparing a value with itself proves nothing.
- **Guard partial functions.** `dec` crashes on zero. Either return `%drop`
  for out-of-domain inputs, or generate only valid inputs with a norn.
- **Prefer generation to filtering.** If most inputs drop, the run ends
  `%exhausted %drops` with few accepted checks. Write a norn that builds the
  domain directly. Compare `04-discards` with `07-positive` in
  [the examples](../../../desk/examples/props/).
- **Keep it pure.** Fates run with scries refused and must not poke agents.
  For stateful code, fold the implementation and a pure model over a
  generated command list from fresh state. Models:
  [10-queue-model](../../../desk/examples/props/10-queue-model.hoon), and
  [11-queue-model-bug](../../../desk/examples/failing/11-queue-model-bug.hoon)
  for a command precondition kept by both norn and alts.
- **Add fixed examples too.** A unit assertion for a known case catches
  regressions that random inputs might miss.

More techniques with worked examples:
[choosing useful properties](../../../desk/doc/users-guide.md#choosing-useful-properties).

## Reports, labels and coverage

A fate may return a report built with `/+  prop=quiz-prop` instead of a bare
verdict. Use it to make failures readable and to see what was tested:

```hoon
++  fate
  |=  items=*
  ^-  report:prop
  =/  items  ;;((list @ud) items)
  %^  classify:prop  =(~ items)  'empty'
  %+  note:prop  'double reversal should be the identity'
  (same:prop !>(items) !>((flop (flop items))))
++  cover  [%check ~[['empty' 5]]]
```

- `same` takes **vases**: `(same:prop !>(want) !>(got))`. The run shows
  both values rendered with their types. Without `!>` at the call site the
  types are lost.
- `classify`, `label`, `collect` and `tabulate` count over accepted samples.
  The run shows the distribution and the first example per label. Keep labels
  to ranges or cases. More than 100 distinct labels ends `limited %labels`.
- `++cover [%warn …]` reports shortfalls on a pass; `[%check …]` ends the run
  `uncovered`. It is a threshold at the final count, not a statistical test.
- `++expect %fail` marks a claim that should fail (`failed-as-expected`).
- `implies` with a trap guards partial code. `all` and `any` combine props, but
  every list element is already evaluated.

Models: [12-labels-coverage](../../../desk/examples/props/12-labels-coverage.hoon),
[13-expected-actual](../../../desk/examples/failing/13-expected-actual.hoon),
[14-coverage-shortfall](../../../desk/examples/failing/14-coverage-shortfall.hoon).
API: [reports, labels and coverage](../../../desk/doc/reference.md#reports-labels-and-coverage).

## Norns

Prefer `quiz-gen` (`/+ gen=quiz-gen`) for new documents. Its generators are
total (size 0 acts as 1), list lengths are uniform between bounds you choose,
and auras have real generators (`ship`, `date`, `real`, `cord`, `knot`,
`term`):

```hoon
++  norn
  ^-  $-([@ud _og] [(list @ud) @ud])
  (pair:gen (list-of:gen 0 20 (range:gen 0 99)) upto:gen)
```

- Generators in one list (`elements`, `one-of`, `frequency`) must share one
  type: cast each to `(norn:gen a)` first.
- `set-of`, `map-of` and `sorted` take element molds: `(set-of:gen @ud 5 g)`.
- Text is capped at 32 characters; engine size grows past 50,000 unless
  the conf sets `size-max`. `capped`, `resize`, `scale` and `sized` control
  size for one generator
  ([22-size-capped](../../../desk/examples/props/22-size-capped.hoon)).
- Spell sample types out (`ship=@p`, not `=ship`): a zuse mold carries its
  subject into the sample vase and hits `%sample-bytes`.
- Dependent inputs: `seeded`, then `regen` in the fate, with
  `shrink-seeded` ([20-dependent](../../../desk/examples/failing/20-dependent.hoon)).

API: [app generator library](../../../desk/doc/reference.md#app-generator-library-quiz-gen).

For a property over a function argument (`turn`, `skim`, folds), generate
the function with `quiz-fun` (`/+ fun=quiz-fun`): `(fun-of:fun keys vals n)`
gives a table, `(to-gate:fun f)` a gate for the fate, `(shrink-fun:fun @ud
shrink-atom:gen)` its shrinker, and `(fun-text:fun !>(f))` text for `note`.
Type the sample `*` and mold it. Model:
[24-filter-map-swap](../../../desk/examples/failing/24-filter-map-swap.hoon).

The legacy combinators are in `norns:quiz` (import `/+ quiz`): `atom`, `noun`,
`const`, `cell`, `freq`, `pick`, `list`. Signatures:
[norns and composition](../../../desk/doc/reference.md#norns-and-composition).
Things that go wrong:

- **Reusing an RNG core repeats the draw.** Thread the new core from
  `rads:rng`, or use `split-rng:quiz`, for each independent choice.
- **`atom` ignores the aura.** A random `@da` or `@rs` atom is usually not a
  meaningful date or float. Build those values yourself.
- **`const`, or a small domain, exhausts duplicates.** By default samples
  are deduplicated by `mug`, so a 4-value domain cannot give 20 accepted
  checks. It ends `%exhausted %duplicates`. Set `duplicates %allow` in the
  conf to evaluate repeats as QuickCheck does
  ([21-small-domain-allow](../../../desk/examples/props/21-small-domain-allow.hoon)),
  or lower `requested`, or widen the domain. `%exact` skips only equal
  nouns, so a mug collision no longer hides a distinct sample.
- **Recursive sample types can hit `%sample-bytes`.** The cap counts the
  vase's type as well as its value. For lists, declare the fate sample as `*`
  and validate it with `;;((list @ud) items)`, as
  [06-composed](../../../desk/examples/props/06-composed.hoon) does.
- **`freq` and `pick` need a nonempty list** with a positive total weight.
  Otherwise generation crashes with an `%error`.
- **`list` makes short lists.** At most `xeb(size)-1` elements: 15 by the
  100th sample, and usually close to the maximum. For longer or evenly
  spread lengths, draw a length with `rads:rng` in a custom norn, as
  [11-queue-model-bug](../../../desk/examples/failing/11-queue-model-bug.hoon)
  does. Measured shapes:
  [generator characteristics](../../../desk/doc/reference.md#measured-generator-characteristics).

## Alts and shrinking

The default shrinker halves and decrements atoms and recurses into cells. The
engine accepts a candidate only if its mug is new, its noun weight is strictly
smaller, and it fails with the **same category**. `%.y` and `%drop` candidates
are never accepted. The result is the smallest failure this shrinker found,
not necessarily the global minimum.

Write a custom `alts` when the default would leave the domain. Example: a
domain of positive even numbers, where halving gives odd values. Rules:

1. Return a short, finite list. An alts call that loops runs until its CPU
   limit, then the run ends `interrupted` with the best counterexample so far.
2. Make each candidate smaller, and return `~` at the floor.
3. Keep every candidate inside the domain the fate assumes.

Model: [09-custom-alts](../../../desk/examples/failing/09-custom-alts.hoon).

The default shrinker offers nothing for a typed list, and for a `*` sample
only the two subtrees of a cell; it never deletes one element. Use
`quiz-gen`:

```hoon
++  alts
  %+  alts-of:gen  ,[(list @ud) @ud]
  (shrink-pair:gen (shrink-list:gen shrink-atom:gen) shrink-atom:gen)
```

`shrink-list` deletes chunks, then shrinks one element; `shrink-keep` filters
candidates by a precondition; `shrink-via` shrinks through a representation.
**The comma matters:** `,[(list @ud) @ud]` is a mold, while `[(list @ud) @ud]`
is a cell of two gates. Models:
[19-queue-gen-lib](../../../desk/examples/failing/19-queue-gen-lib.hoon)
(library), [11-queue-model-bug](../../../desk/examples/failing/11-queue-model-bug.hoon)
(hand-written). Components shrink independently, so values that constrain
each other may stop high, as in
[17-bst-delete-bug](../../../desk/examples/failing/17-bst-delete-bug.hoon).

## Running

- **Workbench:** open the document, then choose **Draft property** (runs the
  unsaved buffer) or **Saved property** (runs the file at the selected Clay
  revision). Saving does not move that revision; choose **Use latest
  revision**. Blank panel fields mean the document's `conf` is used.
- **Dojo / Gall:** poke `%quiz-action` `[%run request]` and read
  `/x/run/<id>`. Exact nouns and examples:
  [agent-api.md](../../../desk/doc/agent-api.md).
- **HTTP:** [http-api.md](../../../desk/doc/http-api.md).
- **Inside a `-test` suite:** use the legacy library.
  `(expect !>((~(check quiz 0v123 20) !>(fate) ~ ~)))` passes custom norns or
  alts as `[~ gate]`.

## Reading a result

| Outcome | What to do |
| --- | --- |
| `passed` | `accepted` reached `requested`. This is evidence, not proof. Check that the inputs were interesting (the distribution, if the fate labels them): `requested 0` passes with no checks. `warnings` lists `%warn` coverage shortfalls. |
| `uncovered` | Every check passed, but a `%check` coverage row was short. Fix the generator so the case occurs. |
| `failed` | Read `why` (`%false` with notes and expected/actual if the fate gave them, `%crash` with trace, `%scry`, `%bad-product`), then the original and shrunk samples. The detail describes the shrunk sample. |
| `failed-as-expected` / `passed-unexpectedly` | The document has `++expect %fail`. The first is the intended result. |
| `exhausted` | A budget ran out first (`attempts`, `drops` or `duplicates`). `all-dropped` means no input was ever accepted. **Not a pass.** |
| `limited` | A named bound was hit. Simplify the data or alts, or lower the work. `%seen-bytes` means `%exact` kept too many sample bytes; cap the size or use `%mug`/`%allow`. |
| `error` | The norn, default generation or alts crashed. The stage says which. |
| `invalid` | Source, import, arm type, context or conf problem. Use the code and line. |
| `cancelled` | Cancelled by request, or by an agent reload. |
| `interrupted` | A call exceeded its CPU limit (**Settings**, default 10 s per call), was stopped with Ctrl-C, or exhausted memory. `during` gives the stage, `arm` the suite arm, and `proof` the best counterexample so far. Look for a loop or runaway allocation. |

Counter definitions:
[counters, status and outcomes](../../../desk/doc/reference.md#counters-status-and-outcomes).
Symptom table: [troubleshooting](../../../desk/doc/reference.md#troubleshooting).

## Reproduce, then regress

1. **Replay exact property** reruns the stored source, imports, revision,
   seed, config and engine version. A seed alone is not enough if any of
   those changed. **Rerun request** may choose new entropy.
2. Decide what the correct behaviour is.
3. Write the counterexample as an ordinary `test-*` arm with `expect-eq`.
   Keep the property beside it as a legacy `check` arm.
   Worked example: [user's guide step 6](../../../desk/doc/users-guide.md#6-replay-and-turn-evidence-into-a-regression).

Do not add intentionally failing examples under `desk/tests/`, because that
suite must pass. Teaching failures go in `desk/examples/failing/`.
