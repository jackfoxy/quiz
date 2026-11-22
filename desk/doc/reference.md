# Quiz reference

This desk targets `%zuse 408`. The application engine is `%quiz-engine-2`.
The frozen `lib/quiz.hoon` library and `gen/quiz.hoon` generator retain their
legacy behavior. Application property documents use `lib/quiz-engine.hoon`
through `%quiz`; they do not call the legacy check loop.

## Public contracts

### Fates and documents

A fate is a Hoon gate whose sample describes the input domain and whose product
is `?(? %drop)` or a `report` (see [reports and coverage](#reports-labels-and-coverage)).
`%.y` accepts the sample, `%.n` finds a counterexample, and
`%drop` rejects an input without checking the intended claim. A crash or scry
is a failure category, not a discard. A passed run establishes only the checks
performed, not a proof or coverage of every input.

An application document is a Hoon file producing a core:

| Arm | Contract |
| --- | --- |
| `++fate` | Required gate; sample may be any Hoon type; product must nest in `?(? %drop report:quiz-engine)` |
| `++norn` | Optional gate `$-([@ud _og] sample-type)` |
| `++alts` | Optional gate `$-(vase (list vase))` |
| `++conf` | Optional `[seed=(unit @uv) config=conf:quiz-engine]` |
| `++cover` | Optional `cover:quiz-engine`: `[mode=?(%warn %check) rows=(list [label=@t percent=@ud])]` |
| `++expect` | Optional `?(%pass %fail)`; default `%pass` |

The builder checks the arms before the run starts. Invalid source, imports,
arm types or settings produce `%invalid`, rather than an ordinary failing
property. Other arms may contain helpers. Missing `conf` means
`[~ defaults:quiz-engine]`; missing `norn` and `alts` select default generation
and shrinking. Start from the complete defaults when changing a setting, as
in [the success document](../examples/props/01-success.hoon).

A standalone gate is accepted by the legacy library, but is not an app
document. Existing `test-*` cores use the saved-suite workflow instead.

The [source-format contract](source-format.md) specifies the restricted Ford
prelude in detail. Supported groups, in order, are `/-`, `/+`, `/=`, `/*`;
raw imports permit `%hoon`, `%txt`, `%noun` only. Cross-desk imports and other
prelude runes are refused in the property document. Built dependencies use
ordinary Ford. Paths are 1–32 segments of 1–64 lowercase letters, digits or
hyphens, ending in `hoon`; desk names are Hoon symbols of at most 64 bytes.

### Legacy library signatures

Import `quiz` from `/lib/quiz/hoon`. Its door sample is
`[eny=@uv runs=@ud]`. Bunting the door supplies seed zero and runs zero;
`check-verbose` interprets runs zero as 100. An explicitly supplied seed is
deterministic for the same code and runtime.

The following types describe the exported arms, including the helper arms.
`sample`/`a`/`b` in polymorphic signatures mean the caller's chosen mold;
`|*`/`|$` arms are wet. `vase` is `[type noun]`, not just the input noun.

| Arm | Sample → product |
| --- | --- |
| `norn` | Wet type constructor: mold `sample` → `$-([@ud _og] sample)` |
| `check` | Wet gate: `[vax=vase norn=(unit (norn)) alts=(unit $-(vase (list vase)))]` → `?` |
| `check-verbose` | Same sample as `check` → `result` |
| `result` | `[defy=(unit vase) runs=@ drops=@]` |
| `run` | `[vax=vase sam=vase]` → raw fate product; crashes/scries become `%.n` |
| `fin` | `[defy=(unit vase) runs=@ drop=@]` → `result` |
| `sink` | `vase` → `(list vase)`; default shrink candidates |
| `quiz` | Helper door with sample `[size=@ud rng=_og]` |
| `fill:quiz` | `sax=vase` → `^+ sax`; default sample construction |
| `split-rng` | `[rng=_og]` → `^+ [og og]`, two deterministic RNG cores |

Pass a fate vase with `!>(fate-gate)`; pass `~` for an absent custom generator
or shrinker, and `[~ gate]` for a supplied one. Configure the library door
using `~(check quiz seed requested-runs)` or the corresponding
`check-verbose` arm. The [original tutorial](../tests/examples/01-quiz-tutorial.hoon)
contains executable calls with custom norns and alts.

`check` prints `[success-runs+N drops+M]` and, on failure, the resulting vase.
Its Boolean is true exactly when `defy` is null. `check-verbose` returns the
result directly, although its helpers can still print diagnostic output.
On failure, `defy` contains the final shrunk vase; the original sample is not
retained separately. `runs` counts earlier accepted **or dropped** distinct
samples, excluding the failing sample. On `%tired`, a null `defy` is returned
even though the requested number was not reached.

The `%say` generator has sample
`[[now=@da eny=@uvJ bec=beak] [vax=vase ~] [runs=@ud ~]]` and returns
`[%noun result=?]`. It forwards the generator environment's entropy to legacy
`check`, with no custom norn/alts. Its positional argument is the fate vase;
`runs` is an optional named argument. Omitting it uses the legacy 100-run
fallback. It is not the application's recorded-seed replay interface.

Source authority: [legacy library](../lib/quiz.hoon),
[generator](../gen/quiz.hoon), [compatibility tests](../tests/lib/quiz-legacy.hoon).

### Norns and composition

A norn receives `[size=@ud rng=_og]` and returns an input value. It must return
the fate's sample type, not a vase. A norn chooses data; the fate decides the
property. Structural type compatibility does not establish semantic validity:
positive integers, sorted lists, valid timestamps and consistent records need
appropriate generation and, where necessary, validation.

For new documents, prefer the [app generator library](#app-generator-library-quiz-gen),
whose generators are total and whose shrinkers fit the engine's rules. The
constructors below are under `norns:quiz` in the frozen legacy library and
can also be used by app documents:

| Arm | Construction and resulting type |
| --- | --- |
| `atom` | `(atom:norns:quiz a)` → `(norn:quiz a)`; the aura is ignored |
| `noun` | Already a `(norn:quiz *)`; no constructor argument |
| `const` | `((const:norns:quiz a) value)` → `(norn:quiz a)` |
| `cell` | `((cell:norns:quiz a b) left right)` → `(norn:quiz [a b])` |
| `freq` | `((freq:norns:quiz a) weighted)` where `weighted` is `(list (pair @ (norn:quiz a)))` |
| `pick` | `((pick:norns:quiz a) generators)` where `generators` is `(list (norn:quiz a))` |
| `list` | `((list:norns:quiz a) element-generator)` → `(norn:quiz (list a))` |

For `freq`, provide a nonempty list with positive total weight; individual
zero weights are never selected. `pick` needs a nonempty list and uses equal
weights. These constructors do not validate an empty/zero-total choice into
a friendly configuration error: generation can crash. `const` often exhausts
the app's duplicate budget when more than one accepted sample is requested.

`atom` chooses below the supplied size. It does not construct valid values
for every aura: a raw atom with a date or floating-point aura may be unsuitable
for the intended operations. `noun` recursively chooses atoms, repeated
subtrees or independent subtrees. `cell` splits the RNG for its children.
`list` halves its stopping parameter after each element; size 1 always makes
an empty list. Its distribution depends on size and is not a fixed geometric
`2^(-1-n)` distribution. It does not enumerate every list or semantic domain.

Use the [composed list/cell example](../examples/props/06-composed.hoon),
[positive custom norn](../examples/props/07-positive.hoon) and
[queue model](../examples/props/10-queue-model.hoon) as executable models.
The composed example uses a noun boundary for its list and validates it
inside the fate: a recursive sample type can retain a large compiler context,
and the sample-byte cap includes that type even when the value is small.
A custom norn must use the supplied RNG for repeatability. Repeated `rad:rng`
calls on the same unchanged core repeat a draw; thread the updated core from
`rads` or split it when making independent draws. Engine-supplied size starts
at 1. Calling sized generators directly with size zero is not supported by
these examples.

### Default generation, size and duplicates

The app reuses the frozen library's `fill`, `split-rng`, norns and default
`sink`, while owning execution and counters. `fill` handles `%noun`, atoms,
cells, faces, forks, hints and holds. Singleton atoms retain their value;
non-singleton atoms ignore aura. Fork alternatives are chosen from the type's
set. Holds are resolved through type operations. Other type forms warn and
return the supplied vase unchanged. This is heuristic generation, not a
promise that arbitrary gates, cores or semantic domains can be randomized.

Both runners grow size after each generated sample:

`next-size = size + 1 + floor(2 * size / 21)`

The legacy runner starts at 1 with no ceiling. The app starts at the conf's
`size-start` (default 1) and, when `size-max` is nonzero, holds size at
`size-max` from then on: `size = min(size-max, next-size)`. Under the
defaults size passes 50,000 by the 100th sample, so a cap mainly keeps
generated values small. Capped runs also reach a small domain's repeats
sooner, which the duplicates policy below decides what to do with.

Duplicate samples also grow size and advance the engine RNG. Attempt and
post-generation byte limits constrain the app run. They cannot prevent a
single large allocation or looping generator.

**Duplicates.** The legacy runner, and the app under its default policy
`%mug`, identify samples by `mug` of the sample **noun**, ignoring the vase's
type. A repeated mug is skipped without calling the fate. Distinct nouns can
collide, so `%mug` deduplication is approximate. The app's `duplicates` conf
field chooses the policy:

| Policy | A sample is skipped as a duplicate when | Notes |
| --- | --- | --- |
| `%mug` (default) | Its mug was seen before | Today's rule; a mug collision skips a distinct noun |
| `%exact` | An equal noun was seen before | Each evaluated noun is kept, charged at its `jam` bytes against `bounds.seen-bytes`; over it the run ends `%limited %seen-bytes` |
| `%allow` | Never | Every sample is evaluated and may be accepted, as in QuickCheck; `duplicate` stays 0 and `duplicates-max` is ignored |

Duplicate counts are cumulative for the run, not consecutive streaks; they do
not reset after an accepted sample. Under `%mug` and `%exact` a small finite
generator cannot satisfy a request larger than its available distinct samples;
use `%allow`, as in
[21-small-domain-allow](../examples/props/21-small-domain-allow.hoon).
Shrinking always uses a mug-based visited set as a loop guard, whatever the
policy; decreasing weight alone guarantees termination.

### Measured generator characteristics

[`tests/lib/quiz-norns.hoon`](../tests/lib/quiz-norns.hoon) and
[`tests/lib/quiz-sink.hoon`](../tests/lib/quiz-sink.hoon) pin these facts
with fixed seeds. They describe the frozen library; they are not guarantees
beyond it.

| Facet | Measured behaviour |
| --- | --- |
| Size by sample | 1, 10, 33, 586, 55,946 at samples 1, 10, 20, 50, 100 under the default conf; drops and duplicates advance it too; `size-max` holds it |
| `atom` | Uniform over `[0, size)`; both ends reached; size 0 crashes |
| `list` length | At most `xeb(size)-1`, so 0 at size 1 and 15 at sample 100; most draws are near that maximum and short lists are rare at large sizes; size 0 crashes |
| `noun` | Depth at most `xeb(size)-1`; leaves below size |
| `freq` and `pick` | Follow the weights; a zero weight is never chosen; an empty or all-zero list crashes |
| `cell` and `split-rng` | Children draw independently of each other and of the parent; split paths are prefix-free |
| `fill` on a union | Each branch is equally likely; `(unit a)` yields both `~` and values |
| Small domains | A `?` sample yields at most two accepted checks before duplicates exhaust the run, unless the app conf sets `duplicates %allow` |
| Default `sink` | An atom `n` gives `n/2` and `n-1`; a cell shrinks its children; a noun cell gives its two subtrees; every candidate weighs less than its parent |
| `sink` on lists and unions | Nothing: a list's type is a fork. Write `alts` for lists, as in [11-queue-model-bug](../examples/failing/11-queue-model-bug.hoon) |

### App and legacy semantics compared

| Behavior | Legacy library/generator | Application |
| --- | --- | --- |
| Target | `runs`: passes plus drops | `requested`: accepted `%.y` only |
| Zero target | Becomes 100 | Passes immediately with zero counters |
| Drops | Consume target budget | Consume drop and attempt budgets |
| Duplicate stop | 1,000 collisions, prints `%tired`, null `defy`; `check` returns true | `%exhausted %duplicates`, or never under `%allow` |
| Size | Starts at 1, uncapped | `size-start`, optional `size-max` |
| All evaluated inputs dropped | May report success | Never counts them as accepted; exhaustion flags `all-dropped` |
| Fate false/crash/scry | All become failure with no structured distinction | `%false`, `%crash`, `%scry` remain distinct |
| Unexpected fate product | Assertion failure in the legacy check loop | `%bad-product` classification; document builder normally rejects its type earlier |
| Generator/shrinker error | May escape the check loop | `%error` with stage and reason, or a diagnostic byte limit |
| Shrinking | Unbounded; false/crash categories interchangeable | Bounded, decreasing weight, same failure category |
| Failure evidence | Final shrunk vase only | Original and best shrunk sample, source/config/seed |
| Persistence | Caller-owned | Recorded history and exact property replay |

The frozen library has no application limits or cooperative cancellation.
Library users needing legacy behavior may continue to import it unchanged.
Do not interpret its `runs` field as the app's `accepted` or `attempted` count.

### App generator library (`quiz-gen`)

[`quiz-gen`](../lib/quiz-gen.hoon) (`/+ gen=quiz-gen`) provides generators,
typed shrinkers and an adaptor to `++alts`. Executable models:
[16-sorted-insert](../examples/props/16-sorted-insert.hoon) to
[20-dependent](../examples/failing/20-dependent.hoon).

Every generator is a norn, `$-([@ud _og] a)`, and is **total in size**: size 0
behaves as size 1. An empty choice crashes with a named `~|` message, which a
run reports as a generation `%error`. Generated text is at most `text-max`
(32) characters, because the engine's size grows past 50,000 by the 100th
sample unless the conf sets `size-max`.

| Generator | Produces |
| --- | --- |
| `(range low high)` | Uniform in `[low, high]`; crashes if `low > high` |
| `upto` | Uniform in `[0, size]` |
| `signed` | `@sd`, magnitude at most size, either sign |
| `ship` | `@p`: galaxy, star or planet, equally likely |
| `date` | `@da` within size seconds of `~2000.1.1`; no ambient time |
| `span` | `@dr`, whole seconds up to size |
| `real`, `real-single` | Finite `@rd`, `@rs` from random bits; never infinity or NaN |
| `cord`, `knot`, `term` | Printable `@t`; valid `@ta`; valid nonempty `@tas` |
| `(chars alphabet)` | A tape from the alphabet |
| `(elements items)`, `(one-of gens)`, `(frequency ~[[weight gen] …])` | Choice from a nonempty list; all generators must have one type |
| `(unit-of gen)` | `~` with chance 1/(size+2), otherwise a value |
| `(list-of low high gen)` | Length uniform in `[low, min(high, max(low, size))]`; elements from split streams |
| `(nonempty high gen)`, `(vector len gen)` | At least one element; exactly `len` |
| `(set-of mold high gen)`, `(map-of key-mold value-mold high key value)` | Up to `high` entries |
| `(sublist items)`, `(shuffle items)` | Order-preserving subset; uniform permutation |
| `(sorted mold low high gen order)` | A sorted `list-of` |
| `(pair a b)`, `(trip a b c)` | Components from split streams |
| `(cook gen fun)` | Mapped output |
| `(bind gen next)` | Dependent: `next` receives the first value and returns a generator |
| `(such-that gen pred tries)` | Retries with growing size; crashes after `tries` |
| `(seeded gen)`, `(regen make outer seed size)` | Dependent shrinking; see below |
| `(sized make)` | `make` receives the current size and returns the generator to run |
| `(resize n gen)` | `gen` at size `n`, whatever the run's size |
| `(scale fun gen)` | `gen` at size `(fun size)`, as in `(scale (curr div 10) gen)` |
| `(capped top gen)` | `gen` at `min(top, size)`; a per-generator `size-max` |

Shrinkers are typed gates from a value to candidates, simplest first. Except
for sets and maps, every candidate weighs strictly less than its input, so
the engine never discards one for lack of progress. Equal-weight candidates
such as permutations are never offered; this is where Quiz differs from
QuickCheck.

| Shrinker | Candidates, in order |
| --- | --- |
| `shrink-atom` | `0`, then `n-n/2`, `n-n/4`, …, `n-1` |
| `(shrink-toward floor)` | The same, never below `floor` |
| `(shrink-list item)` | Delete chunks of n, n/2, …, 1 elements, then shrink one element with `item` |
| `(shrink-pair a b)` | Shrink the left, then the right |
| `(shrink-unit item)` | `~`, then smaller inner values |
| `(shrink-set item)`, `(shrink-map key value)` | Through the element list; a rebalanced tree may not weigh less, and the engine discards such a candidate |
| `(shrink-via to from inner)` | Shrink through a representation |
| `(shrink-keep pred inner)` | Only candidates satisfying an invariant or precondition |
| `(shrink-seeded outer)` | A `seeded` sample: smaller outer values, then a halved size; the seed stays |
| `shrink-nothing` | No candidates |

`(alts-of mold shrinker)` turns a typed shrinker into a document's `++alts`.
It molds the sample's noun, so it works for samples typed `*`, and it keeps
the sample's vase type. Pass a mold: a tuple mold needs its comma, as in
`(alts-of ,[(list @ud) @ud] …)`. Written without the comma, `[(list @ud) @ud]`
is a cell of two gates.

Shrinkers combine independently. When values constrain each other, such as a
tree's keys and the key being deleted in
[17-bst-delete-bug](../examples/failing/17-bst-delete-bug.hoon), each can
shrink only while the failure survives, so the result may keep larger values
than a coordinated shrinker would.

**Dependent shrinking.** QuickCheck shrinks nested `forAll` inputs by
regenerating the inner value as the outer one shrinks. `seeded` gives a
sample `[value seed size]`; the fate calls `(regen make value seed size)` to
rebuild the dependent value, where `make` takes the outer value and returns a
generator. `shrink-seeded` shrinks only the outer value and size, so every
candidate rebuilds a consistent inner value. The inner value itself is not
shrunk directly.

**Wet-gate notes.** `set-of`, `map-of` and `sorted` take element molds because
`silt`, `malt` and `sort` cannot be type-checked over a wet element type.
Generators taking a literal list (`elements`, `one-of`, `frequency`,
`sublist`, `shuffle`) widen it with `homo`; every element must already share
one type, so cast generators to `(norn:gen a)` before listing them.

### Alts and shrinking

An alts gate takes a **vase** and returns a finite `(list vase)` of candidates.
Preserve the fate's input type and its semantic domain. The builder checks the
alts gate's declared product, but cannot prove every dynamically returned vase
is semantically valid for the fate. Terminate every alts invocation. Limiting
how many candidates the engine considers cannot stop one call that never
returns; that call hits the property call limit and the run ends
`%interrupted`.

The default `sink` tries halving and decrementing nonzero atoms, subtrees for
noun cells, and combinations of cell component candidates. It preserves
faces/hints while recursing. Singleton atoms do not shrink. Unhandled types,
including fork/hold wrappers at this stage, produce no candidates. List
shrinking is therefore not a general list-minimization algorithm.

The app accepts a candidate only when its mug is new (whatever the duplicates
policy), its noun weight strictly
decreases, and it reproduces the original failure **category**. Atom weight is
`value + 1`; cell weight is `1 + weight(head) + weight(tail)`. Equal-weight
permutations and growing candidates are skipped. Crash traces need not match:
preserving `%crash` does not prove the underlying crash cause stayed identical.
`%.y` and `%drop` candidates are never accepted as failures.

After accepting a candidate, the engine asks for alternatives of that new best
sample. When candidates end, the result is `%failed`; hitting a bound produces
`%limited`, and an alts error produces `%error`, retaining bounded evidence
when available. The best sample is not guaranteed globally minimal.

The [seeded threshold example](../examples/failing/08-seeded-threshold.hoon)
reaches 501 under the recorded seed/configuration. This is a verified example,
not a promise that every threshold property or shrinker always returns 501.
The [custom alts example](../examples/failing/09-custom-alts.hoon) preserves
positive even inputs and reaches 502, the smallest failure in that domain.
The [queue model bug](../examples/failing/11-queue-model-bug.hoon) shrinks a
command list: its alts deletes commands and shrinks pushed values, and keeps
only sequences that satisfy the pop precondition.

### Configuration and limits

`conf:quiz-engine` is:

```hoon
$:  requested=@ud  attempts-max=@ud  drops-max=@ud  duplicates-max=@ud
    size-start=@ud  size-max=@ud  duplicates=?(%mug %exact %allow)
    bounds=limits
==
```

The table gives engine defaults and maximum accepted configuration values.
`requested` defaults to 100 and can increase to `requested-max` (10,000).
`size-start` and `size-max` have no ceiling. All other numeric fields can be
lowered but not raised above their engine defaults.

| Field | Default | Unit / enforcement |
| --- | ---: | --- |
| `requested` | 100 | Accepted checks to complete |
| `attempts-max` | 10,000 | Generated samples, including duplicates and failures |
| `drops-max` | 1,000 | Fate `%drop` results |
| `duplicates-max` | 1,000 | Duplicate samples; ignored under `%allow` |
| `size-start` | 1 | First sample's size; at least 1 |
| `size-max` | 0 | Largest size; 0 means uncapped, otherwise at least `size-start` |
| `duplicates` | `%mug` | Duplicate policy: `%mug`, `%exact` or `%allow` |
| `bounds.source-bytes` | 262,144 | Source cord bytes; builder ceiling and effective replay capture check |
| `bounds.requested-max` | 10,000 | Ceiling for requested checks |
| `bounds.shrink-candidates` | 1,000 | Candidates considered, even if skipped |
| `bounds.shrink-depth` | 100 | Accepted shrink replacements |
| `bounds.sample-bytes` | 65,536 | Jammed sample vase bytes, including its type |
| `bounds.rendered-bytes` | 16,384 | Rendered sample cord bytes |
| `bounds.diagnostics-bytes` | 16,384 | Jammed engine failure/diagnostic noun bytes |
| `bounds.alts-bytes` | 262,144 | Jammed candidate-list bytes |
| `bounds.seen-bytes` | 4,194,304 | Jammed bytes of the samples `%exact` keeps |
| `bounds.retained-runs` | 100 | Completed records retained after this property finishes |
| `bounds.samples-per-slice` | 25 | Engine steps per scheduling slice, including shrink work |

Requested, attempt, drop, duplicate, shrink-candidate and shrink-depth limits
may be zero. Byte caps, retained-runs and samples-per-slice must be positive.
Requested-max may be zero when requested is also zero.
Requested must fit requested-max. Reaching the requested accepted
count wins over budgets reached on the same step. Otherwise, budget ties use
attempts, then drops, then duplicates. Shrink candidate limits precede depth
limits; an already known empty candidate list finishes normally first.

Additional fixed boundaries: queue length 100 waiting jobs; at most 100 explicit
suite arms; HTTP JSON bodies at most 524,288 bytes. The web adapter permits one
pending API mutation/discovery/configuration inspection at a time and times it
out after 30 seconds. The file wire permits one pending write and verifies it
with a 10-second timeout. These are request timers, not Hoon execution limits.
CPU time limits are ship-wide operational settings, not part of a document's
`conf`, so replay neither records nor restores them. Set them in the
workbench's **Settings** dialog, with the `%timeouts` action, or with the HTTP
`set-timeouts` operation. Each must be from 1 s to 1 hour.

| Limit | Default | Applies to |
| --- | ---: | --- |
| Property call (`call`) | 10 s | One fate, norn, alts or sample-rendering call |
| Draft build (`build`) | 30 s | Draft compilation and document arm checks, including conf inspection |
| Suite arm (`arm`) | 1 min | One suite arm's compile and run |

A change applies from the next slice, build or arm. It does not reach a call
that is already running.

Byte limits apply after generation, rendering or list construction as relevant;
`jam` also allocates. Build and suite diagnostics use the default diagnostic
cap; the configurable property cap applies inside the engine.

CPU limits are enforced by Vere's `%jinx` hint. A call that exceeds its limit,
a Ctrl-C in the Vere terminal, or loom exhaustion aborts the whole Gall event.
The run is then recorded as `%interrupted` (see below), and the queue
continues. Clay builds of saved files and suites have no CPU limit; interrupt
them with Ctrl-C. There is no per-run memory limit below the loom, and no
sandbox that isolates the ship from the code it runs. Use a disposable
development ship for examples and experimental properties.

### Reports, labels and coverage

A fate may return a report instead of a bare verdict:

```hoon
+$  report
  $:  %report
      ok=?(? %drop)
      =detail        ::  [notes=(list @t) compared=(unit [want=@t got=@t])]
      labels=(list @t)
      tables=(list [table=@t value=@t])
  ==
```

Build reports with [`quiz-prop`](../lib/quiz-prop.hoon) (`/+ prop=quiz-prop`).
Every combinator accepts a bare verdict or a report (`prop`) and returns a
report:

| Arm | Use | QuickCheck analogue |
| --- | --- | --- |
| `(same !>(want) !>(got))` | Passes when the nouns are equal; on failure records both, rendered with their types | `===` |
| `(note text p)` | Adds a line of explanation, shown if the property fails | `counterexample` |
| `(label text p)` | Labels the sample | `label` |
| `(classify cond text p)` | Labels the sample when `cond` holds | `classify` |
| `(collect !>(value) p)` | Labels the sample with the value's rendered text | `collect` |
| `(tabulate table values p)` | Counts each value under a named table | `tabulate` |
| `(implies pre \|.(p))` | `%drop` unless `pre`; the trap runs only when it holds | `==>` |
| `(all ~[p q …])` | Conjunction: the first failure's comparison, every note and tag | `conjoin` |
| `(any ~[p q …])` | Disjunction: passes if any part passes; otherwise fails or drops | `disjoin` |

`same` and `collect` take vases. A wet gate's formula is compiled once against
its formal sample, so `!>` inside one sees only `*`; the caller's `!>` keeps
the real type. Hoon is strict: every element of a list given to `all` or `any`
has already been evaluated. Guard partial computations with `implies`.

The engine molds a report under virtualization; a malformed one is a
`%bad-product` failure. A false report's `detail` becomes the failure:
`[%false detail]`. While shrinking, the failure is replaced by each accepted
candidate's failure, so the notes and comparison describe the shrunk sample.

Labels and table rows are counted over **accepted** samples only, a label once
per sample, a table value once per occurrence. The run keeps the first
accepted sample per label as that label's example. A label, table name or value
longer than 256 bytes, or more than 100 distinct labels or table rows, stops the
run as `%limited %labels`.

`++cover` lists required shares of accepted samples per label, in whole
percent, compared exactly at the end (`100 × hits ≥ percent × accepted`).
`%warn` reports shortfalls with `passed`; `%check` turns them into the outcome
`uncovered`. This is a plain threshold at the final count, not QuickCheck's
sequential statistical `checkCoverage`. With zero requested checks, every
positive requirement is short.

`++expect %fail` marks a property that should fail. A counterexample, after
shrinking, ends `failed-as-expected`; reaching the requested count ends
`passed-unexpectedly`. `error`, `limited` and `exhausted` outcomes are
unchanged.

### Counters, status and outcomes

Property progress has exactly these fields:

| Field | Meaning |
| --- | --- |
| `attempted` | Generated sample vases, including duplicates, capped samples and the failing sample; a generation failure before a sample is produced adds none |
| `accepted` | Unique evaluated samples returning `%.y` |
| `dropped` | Unique evaluated samples returning `%drop` |
| `duplicate` | Generated samples skipped as repeats under the duplicates policy: a seen mug (`%mug`), an equal seen noun (`%exact`), or none (`%allow`) |
| `shrink-tried` | Candidates considered, including repeated, nondecreasing or capped candidates |
| `shrink-steps` | Candidates accepted as a smaller failure of the original category |

Shrinking does not add property attempts, passes or drops. Requested is a
configuration field, not a measured counter. `all-dropped` is true on exhaustion
when accepted is zero and dropped is positive; zero evaluations do not qualify.

Run status is one of `queued`, `building`, `running`, `shrinking`, `cancelling`,
`done`. A quick run may skip visible intermediate updates. Terminal outcomes:

| Outcome | Meaning / payload |
| --- | --- |
| `passed` | Target accepted checks reached; no counterexample. Coverage `warnings` (empty unless `%warn` found a shortfall) and the first example per label |
| `uncovered` | Target reached, but a `%check` coverage row was short; `shortfalls` and examples |
| `passed-unexpectedly` | `++expect %fail`, but every requested check passed |
| `failed` | `why`, original sample, shrunk sample |
| `failed-as-expected` | `++expect %fail` and a counterexample was found; same payload as `failed` |
| `error` | Stage `norn`, `generate` or `alts`; failure reason; optional evidence |
| `limited` | Named bound and optional evidence |
| `exhausted` | Budget `attempts`, `drops` or `duplicates`, plus `all-dropped` |
| `invalid` | Located build/configuration diagnostic |
| `cancelled` | Reason `request` or `reload` |
| `interrupted` | The runtime aborted the run's event: a CPU limit, Ctrl-C or memory exhaustion. `during` (`building`, `running`, `shrinking`), optional best evidence, optional suite arm |
| `suite` | Aggregate status, arm counters and per-arm outcomes |

The durable Hoon [record](../sur/quiz-app.hoon) contains `id`, `request`, nullable
`snapshot` and `replay`, nullable effective `seed` and `config`, `engine-version`,
`status`, tagged `counts` (for properties, the counters plus the label and
table `distribution`), nullable `result`, and created/updated/finished times.
A snapshot contains context, path, exact source and its `shax` hash. A sample
contains noun `value` and rendered `text`; durable records do not retain vase
types. Invalid builds may have no effective settings or replay inputs.

The [JSON representation](http-api.md) uses `outcome` instead of Hoon `result`,
flattened `counts`, a separate `distribution`, a source `kind`, and
`sample-metrics`. Evidence uses `text`
and `noun-jam` (jammed noun rendered as `@uv`) instead of a raw JSON noun.
IDs/revisions are decimal strings; seeds/hashes use `@uv`; dates use `@da`.
Do not convert IDs to JavaScript numbers. Diagnostics have `code`, `path`,
`line`, `column`, nullable `arm`, rendered `trace` and `clipped`. An oversized
trace is omitted with the clipped flag, not silently reported as empty success.

### Suites

Saved suites build at a pinned Clay context using ordinary Ford. The runner
discovers `test-*` arms in descending name order as the Kelvin 408 `-test`
runner does. An empty selection means all; exact-name subsets are supported.
Unknown/duplicate selections, non-cores and cores without tests are refused.

Each arm must compile to a `tang`: empty means passed, nonempty means failed;
an execution crash/scry means crashed, and an invalid arm type means invalid.
The runner continues through remaining arms. Aggregate status is passed only
if all selected arms passed. Counters are `total`, `completed`, `passed`,
`failed`, `crashed`, `invalid`.

Only arm-level metrics are available. A suite has no controlled property seed,
accepted/dropped sample counts or structured property counterexamples. Console
output from a legacy check inside a test is not converted into sample metrics.
The app refuses scries during arms, whereas stock `-test` forwards them; not
every state-dependent suite is compatible. See [suite details](suites-and-replay.md).

The three existing example suites remain under `tests/examples`. Intentional
new teaching failures live under `examples/failing`, outside the regression
runner's default test directory. Run passing regression tests in Dojo with:

```hoon
-test /=quiz=/tests ~
```

### Clay context, seed and replay

A request chooses a local desk and `%ud`, `%da` or `%tas` case. The engine pins
it to a positive immutable revision when the queued job becomes active. Choose
an explicit `%ud` to make the context immutable at submission. Drafts use the
captured editor text; saved properties/suites use source at the pinned revision.
Imports resolve there too. There is no fallback to another desk or revision.

A request seed overrides document `conf`; its seed overrides entropy captured
on admission. Zero is a valid explicit seed. Blank UI inputs mean no override.
A configuration override replaces the **whole** record. The UI's requested-only
override first inspects document `conf` and changes just requested checks.

Replay records source text/hash, original path, ship/desk/revision, effective
seed/config and engine version. Exact replay validates them, rebuilds the
stored text using original imports, and restores effective inputs. It does
not reload changed current source, use new entropy or silently adopt a new
engine version. A missing/pruned run, absent replay inputs, incompatible engine,
missing revision or changed hash is reported. See [replay contract](suites-and-replay.md).
Same seed alone is insufficient if source, imports, config or engine changes.
Cross-Kelvin/compiler replay is not guaranteed by pinning the source revision.

Rerun submits the recorded request again. A request with no explicit seed may
choose new entropy unless the document fixes a seed. A date/label context can
resolve differently on a later rerun. The browser ordinarily submits explicit
numeric revisions. Suites can rerun, but cannot use property replay.

### Gall, HTTP and persistence

`%quiz` accepts local-ship `%quiz-action` pokes: `%run`, `%cancel`, `%delete`,
`%clear`, and `%timeouts` to set the CPU limits. Facts use `%quiz-update` on
`/runs`, `/run/<id>` or `/timeouts`. Scries are `/x/runs`, `/x/run/<id>`,
`/x/limits`, `/x/version`, `/x/timeouts`; Gall paths use dotted Hoon
`@ud` formatting where needed. Exact types, examples and authorization are in
[the agent API](agent-api.md).

`%quiz-web` serves public shell/assets at `/apps/quiz/`; `POST /api` and
`POST /files` require an authenticated local session. API operations are
`contexts`, `run`, `replay`, `cancel`, `runs`, `status`, `suite-arms`,
`document-conf`, `timeouts`, `set-timeouts`. Run/replay return 202 with the allocated decimal ID after
correlated admission; completion requires polling that record. Cancellation
returns admission acknowledgement, not immediate confirmation of termination.
There is no HTTP delete/clear operation or automatic mutation retry.
[HTTP fields/routes/errors](http-api.md) are the wire-format authority.

One job runs at a time with a FIFO queue. Property slices execute bounded
engine steps; suite slices execute one arm. A property slice also ends when it
first finds a counterexample. Cancellation takes effect at a boundary between
returning calls; queued work can cancel immediately. An event aborted by a CPU
limit, Ctrl-C or memory exhaustion finishes the job it was running as
`%interrupted` and is never retried
([details](agent-api.md#aborted-events-and-interrupted)). History
pruning removes oldest submitted completed records and preserves pending work.
The effective retention cap applies when its property finishes; suites/reload
use the default. IDs remain monotonic across delete/clear.

`on-save` persists `[%0 state-0]` with records, IDs and queue metadata. It omits
compiled gates, RNGs, timers and pending build replies. Agent reload preserves
completed records and cancels all unfinished jobs with reason `reload`; it
never resumes partially executed work. Web pending requests are transient.
Browser local storage separately retains editable buffers, controls, tab links,
selection and layout. Clearing it loses unsaved buffers, not server history.

### Workbench and shortcuts

Open **Examples** for passing properties (`props`), intentional failures
(`failing`) and existing suites (`examples`). Examples/docs/Clay files are
read-only; **Open editable copy** makes a writable unsaved tab. **My documents**
saves under `/data/quiz`. **Documentation** exposes this reference as source
text; installed `%docs` provides the rendered help-site mechanism.

**Draft property** runs the editor buffer. **Saved property/suite** excludes
unsaved edits and uses the chosen revision. Saving does not advance it; choose
**Use latest revision** when appropriate. **Read document conf** previews settings;
**Discover suite arms** lists names. Results show effective configuration/seed,
confirmed counters, diagnostics and both counterexamples. A changed source tab
marks its earlier result stale; its snapshot remains unchanged. History retains
source association and the selected result across browser reload.

**Run**, **Rerun request**, **Replay exact property** and **Cancel selected run**
follow server state. Network failure preserves last confirmed counters and
disables mutations until reconnection. A lost admission reply may still have
created a run: inspect history before retrying. The UI does not invent progress.

| Configured application binding | Action |
| --- | --- |
| F1 | Help |
| F2 | Settings |
| F5 | Run the selected property (outside the editor) |
| Ctrl-S / Command-S | Save active document |
| Ctrl-Shift-S / Command-Shift-S | Save As |
| Alt-O | Open document (outside the editor) |
| Alt-C | Copy document (outside the editor) |

Ace adds editing bindings such as undo/redo and search; Settings selects the
default or Vim keymap. Replay and cancel have no shortcut: they act on a
selected run. [Quiz keys](keyboard/quiz-keys.md) explains why Open is Alt-O.
The [workbench guide](workbench.md) describes editing and dirty protection.

### Troubleshooting

| Symptom | Check / response |
| --- | --- |
| `clay: no files match /sur/quiz-app/hoon` or `/sur/urui/hoon` | Copy **all** packaged `desk/` contents into the mounted desk, including `sur`, `app`, `web`, `doc`, fixtures and examples; then `\|commit %quiz` and rerun tests. Copying only lib/gen/tests is insufficient. |
| `%fate-missing`, `%fate-type`, `%norn-type`, `%alts-type` | Use a property core with the signatures above; choose suite mode for a test core. |
| `%source`, `%import`, `%build`, unavailable desk/revision | Check path and pinned context. For a saved compiler failure, an editable draft may expose a more precise compiler diagnostic. |
| `%conf-range` | Start with defaults, keep the full config, respect ceilings and positive bounds. |
| `%cover-type`, `%cover-range` | `++cover` must be `[?(%warn %check) (list [@t @ud])]`: at most 100 distinct, nonempty labels of at most 256 bytes, each percent at most 100. |
| `%expect-type` | `++expect` must be `%pass` or `%fail`. |
| `%uncovered` | Every check passed, but a required label was too rare. Inspect the distribution; change the generator, not the requirement, unless the requirement was wrong. |
| `%limited %labels` | A label was longer than 256 bytes, or a run produced more than 100 distinct labels or table rows. `collect` on a wide domain does this; label ranges instead. |
| `%limited %seen-bytes` | Under `duplicates %exact`, the samples kept for comparison passed `bounds.seen-bytes`. Use `%mug`, `%allow`, smaller samples (`size-max`), or fewer checks. |
| `%exhausted %duplicates` on a small domain | The generator has fewer distinct samples than `requested`. Set `duplicates %allow` to evaluate repeats. |
| `%exhausted` | Inspect drops/duplicates/attempts; improve generation or reduce the requested count for a finite domain. It is not a pass. |
| `%limited` | Inspect the named bound; simplify data/alts or lower requested work. Bounds cannot exceed engine ceilings. |
| Wrong source after Save | Saved execution still uses its selected revision; choose latest or draft execution. |
| Replay unavailable | Preserve the original record and its Clay revision; inspect the specific version/hash/context error. |
| HTTP 401 / disconnected | Sign in to this ship; refresh confirmed history before resubmitting an uncertain mutation. |
| HTTP 503 / 504 | Another request is pending or a response timed out; inspect history before retrying. |
| Cancellation cannot interrupt a call | Cooperative cancellation waits for the current call to return. Wait for its CPU limit, or press Ctrl-C in the Vere terminal; either way the run ends `%interrupted`. |
| `%interrupted` | A call exceeded its CPU limit (property call, draft build or suite arm), was stopped with Ctrl-C, or exhausted memory. Fix the non-terminating or oversized code. In **Settings**, lower a limit for faster detection, or raise it (up to 1 hour) for genuinely slow code. `during` and `arm` locate the stage. |
| HTTP 500 `crud!` | The ship aborted a configuration inspection or suite discovery event, usually a build that exceeded its CPU limit or memory. Run the document as a draft to see the result. |

## Internal implementation map

These details explain implementation and maintenance; they are not additional
user-facing wire contracts. Generated vases from the engine-owned maker are unboxed without re-molding
their shared type trees, then subjected to sample limits. Re-molding a large
recursive type can expand its shared representation before the byte check.
Direct callers of the low-level engine must supply
already checked parts/configuration and own scheduling and persistence.

| Module | Responsibility / key entry points |
| --- | --- |
| [quiz-engine](../lib/quiz-engine.hoon) | `init [seed config compiled]` → state; `step state` → state; `compiled=[fate=vase norn=(unit vase) alts=(unit vase) cover=(unit cover) expect=?(%pass %fail)]`; `judge` classifies reports; terminal states are stable |
| [quiz-prop](../lib/quiz-prop.hoon) | Report combinators for fates; no engine state |
| [quiz-gen](../lib/quiz-gen.hoon) | Total generators, size combinators, typed shrinkers and the `alts-of` adaptor; no engine state |
| [quiz-build](../lib/quiz-build.hoon) | `pin`, `prepare`/`prepare-file`, dependency requests, `draft`/`take-saved`, arm/config checks |
| [quiz-suite](../lib/quiz-suite.hoon) | `prepare-file`, `request`, `take-built`, one-arm `step` |
| [quiz-replay](../lib/quiz-replay.hoon) | Capture/validate stored inputs; `resolve` checks context before rebuilding |
| [quiz-job](../lib/quiz-job.hoon) | Pure admission, queue, slices, retention, save/load transformations |
| [quiz-agent](../lib/quiz-agent.hoon) | Gall bowl, Clay requests, Behn scheduling, facts/scries and local admission callbacks |
| [quiz-json](../lib/quiz-json.hoon) | JSON codecs; decimal string IDs; no vases on HTTP |
| [quiz-web-agent](../lib/quiz-web-agent.hoon) | Eyre authentication/routes, correlated admission, config inspection and file wire |
| [quiz-files](../lib/quiz-files.hoon) | Consumer virtual roots and pinned Clay reads |
| [quiz-web](../lib/quiz-web.hoon) | Compiled urui configuration, shell, help and assets |
| [quiz-runs.js](../web/quiz-runs.js), [quiz.js](../web/quiz.js) | Quiz controls/results and document integration; shared urui owns editor/file/dialog/session machinery |

Generation and fate/shrinker execution use virtualization with refused scries,
inside `sandbox:quiz-engine`, which adds the `%jinx` CPU limit.
Dependency builds use asynchronous Clay `%warp` requests (`%a` for builds, `%x`
for raw reads), because a failed build scry can escape Gall virtualization.
Each request is pinned; stale job wires are ignored. App-only `%quiz-submit`
and `%quiz-admitted` marks correlate HTTP tickets to allocated IDs without
changing the legacy action interface or durable schema.

For maintainers, changes to deterministic generation/evaluation/shrinking or
default semantics require an engine-version bump. Keep frozen legacy sources
and copied urui files unchanged. The [example catalog](examples.md) records
verified outcomes; regression and browser checks live under `desk/tests/` and
`tests/browser/` in the repository.
