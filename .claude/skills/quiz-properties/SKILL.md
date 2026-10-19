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
  its ceiling is `%conf-range`.

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
  generated command list from fresh state.
- **Add fixed examples too.** A unit assertion for a known case catches
  regressions that random inputs might miss.

More techniques with worked examples:
[choosing useful properties](../../../desk/doc/users-guide.md#choosing-useful-properties).

## Norns

Combinators are in `norns:quiz` (import `/+ quiz`): `atom`, `noun`, `const`,
`cell`, `freq`, `pick`, `list`. Signatures:
[norns and composition](../../../desk/doc/reference.md#norns-and-composition).
Things that go wrong:

- **Reusing an RNG core repeats the draw.** Thread the new core from
  `rads:rng`, or use `split-rng:quiz`, for each independent choice.
- **`atom` ignores the aura.** A random `@da` or `@rs` atom is usually not a
  meaningful date or float. Build those values yourself.
- **`const`, or a small domain, exhausts duplicates.** Samples are
  deduplicated by `mug`, so a 4-value domain cannot give 20 accepted checks.
  It ends `%exhausted %duplicates`. Lower `requested`, or widen the domain.
- **Recursive sample types can hit `%sample-bytes`.** The cap counts the
  vase's type as well as its value. For lists, declare the fate sample as `*`
  and validate it with `;;((list @ud) items)`, as
  [06-composed](../../../desk/examples/props/06-composed.hoon) does.
- **`freq` and `pick` need a nonempty list** with a positive total weight.
  Otherwise generation crashes with an `%error`.

## Alts and shrinking

The default shrinker halves and decrements atoms and recurses into cells. The
engine accepts a candidate only if its mug is new, its noun weight is strictly
smaller, and it fails with the **same category**. `%.y` and `%drop` candidates
are never accepted. The result is the smallest failure this shrinker found,
not necessarily the global minimum.

Write a custom `alts` when the default would leave the domain. Example: a
domain of positive even numbers, where halving gives odd values. Rules:

1. Return a short, finite list. The engine cannot interrupt a looping alts.
2. Make each candidate smaller, and return `~` at the floor.
3. Keep every candidate inside the domain the fate assumes.

Model: [09-custom-alts](../../../desk/examples/failing/09-custom-alts.hoon).

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
| `passed` | `accepted` reached `requested`. This is evidence, not proof. Check that the inputs were interesting: `requested 0` passes with no checks. |
| `failed` | Read `why` (`%false`, `%crash` with trace, `%scry`, `%bad-product`), then the original and shrunk samples. |
| `exhausted` | A budget ran out first (`attempts`, `drops` or `duplicates`). `all-dropped` means no input was ever accepted. **Not a pass.** |
| `limited` | A named bound was hit. Simplify the data or alts, or lower the work. |
| `error` | The norn, default generation or alts crashed. The stage says which. |
| `invalid` | Source, import, arm type, context or conf problem. Use the code and line. |
| `cancelled` | Cancelled by request, or by an agent reload. |

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
