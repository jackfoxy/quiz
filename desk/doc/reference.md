# Quiz reference

This desk targets `%zuse 408`. The application engine is `%quiz-engine-1`.
The `lib/quiz.hoon` library and `gen/quiz.hoon` generator check properties
inside ordinary code and `-test` suites. Application property documents use
`lib/quiz-engine.hoon` through `%quiz`; they do not call the library's check
loop.

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
| `++cover` | Optional `cover:quiz-engine`: `[mode=?(%warn %check %confident) rows=(list [label=@t percent=@ud])]` |
| `++cover-table` | Optional `(list table-row:quiz-engine)`: `[table=@t value=@t percent=@ud]` rows, each a required share of one table's entries |
| `++confidence` | Optional `confidence:quiz-engine`: `[certainty=@ud tolerance=@ud]`; used only by a `%confident` `++cover`; default `[9 90]` |
| `++expect` | Optional `?(%pass %fail)`; default `%pass` |

The builder checks the arms before the run starts. Invalid source, imports,
arm types or settings produce `%invalid`, rather than an ordinary failing
property. Other arms may contain helpers. Missing `conf` means
`[~ defaults:quiz-engine]`; missing `norn` and `alts` select default generation
and shrinking. Start from the complete defaults when changing a setting, as
in [the success document](../examples/props/01-success.hoon).

A standalone gate is accepted by the `quiz` library, but is not an app
document. Existing `test-*` cores use the saved-suite workflow instead.

The [source-format contract](source-format.md) specifies the restricted Ford
prelude in detail. Supported groups, in order, are `/-`, `/+`, `/=`, `/*`;
raw imports permit `%hoon`, `%txt`, `%noun` only. Cross-desk imports and other
prelude runes are refused in the property document. Built dependencies use
ordinary Ford. Paths are 1–32 segments of 1–64 lowercase letters, digits or
hyphens, ending in `hoon`; desk names are Hoon symbols of at most 64 bytes.

### Library signatures

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
`check-verbose` arm. The [tutorial suite](../tests/examples/01-quiz-tutorial.hoon)
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
`[%noun result=?]`. It forwards the generator environment's entropy to the
library's `check`, with no custom norn/alts. Its positional argument is the
fate vase; `runs` is an optional named argument. Omitting it uses the
library's 100-run fallback. It is not the application's recorded-seed replay interface.

Source authority: [quiz library](../lib/quiz.hoon),
[generator](../gen/quiz.hoon), [behaviour tests](../tests/lib/quiz-check.hoon).

### Norns and composition

A norn receives `[size=@ud rng=_og]` and returns an input value. It must return
the fate's sample type, not a vase. A norn chooses data; the fate decides the
property. Structural type compatibility does not establish semantic validity:
positive integers, sorted lists, valid timestamps and consistent records need
appropriate generation and, where necessary, validation.

For new documents, prefer the [app generator library](#app-generator-library-quiz-gen),
whose generators are total and whose shrinkers fit the engine's rules. The
constructors below are under `norns:quiz` in the `quiz` library and can
also be used by app documents:

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

Without `++norn` the app fills the sample with
[`quiz-auto`](#type-directed-defaults-quiz-auto)'s `fill`; without `++alts`
it shrinks with `quiz-auto`'s `sink`. Both follow the `quiz` library's rules
and add type-directed cases. `fill` handles `%noun`, atoms, cells, faces,
forks, hints and holds, and draws from the RNG exactly as the library's `fill`
does. Singleton atoms retain their value. A non-singleton atom gets a valid
value for an aura with a meaning, and otherwise the library's uniform draw below
size. Fork alternatives are chosen from the type's set. Holds are expanded
through type operations, and lists, units, sets and maps are recognized and
built as containers. Other type forms, such as cores, return the supplied
vase unchanged. This is heuristic generation, not a promise that arbitrary
gates, cores or semantic domains can be randomized. The library's runner
uses its own `fill` and `sink`.

Both runners grow size after each generated sample:

`next-size = size + 1 + floor(2 * size / 21)`

The library's runner starts at 1 with no ceiling. The app starts at the conf's
`size-start` (default 1) and, when `size-max` is nonzero, holds size at
`size-max` from then on: `size = min(size-max, next-size)`. Under the
defaults size passes 50,000 by the 100th sample, so a cap mainly keeps
generated values small. Capped runs also reach a small domain's repeats
sooner, which the duplicates policy below decides what to do with.

Duplicate samples also grow size and advance the engine RNG. Attempt and
post-generation byte limits constrain the app run. They cannot prevent a
single large allocation or looping generator.

**Duplicates.** The library's runner, and the app under its default policy
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
with fixed seeds. They describe the `quiz` library; they are not guarantees
beyond it. The app's default differs for meaningful auras, containers and
unions: see [type-directed defaults](#type-directed-defaults-quiz-auto).

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
| `sink` on lists and unions | Nothing: a list's type is a fork. The app's `quiz-auto` default shrinks both; with the `quiz` library, write `alts` for lists, as in [11-queue-model-bug](../examples/failing/11-queue-model-bug.hoon) |

### Library and app semantics compared

| Behavior | `quiz` library/generator | Application |
| --- | --- | --- |
| Target | `runs`: passes plus drops | `requested`: accepted `%.y` only |
| Zero target | Becomes 100 | Passes immediately with zero counters |
| Drops | Consume target budget | Consume drop and attempt budgets |
| Duplicate stop | 1,000 collisions, prints `%tired`, null `defy`; `check` returns true | `%exhausted %duplicates`, or never under `%allow` |
| Size | Starts at 1, uncapped | `size-start`, optional `size-max` |
| All evaluated inputs dropped | May report success | Never counts them as accepted; exhaustion flags `all-dropped` |
| Fate false/crash/scry | All become failure with no structured distinction | `%false`, `%crash`, `%scry` remain distinct |
| Unexpected fate product | Assertion failure in the library's check loop | `%bad-product` classification; document builder normally rejects its type earlier |
| Generator/shrinker error | May escape the check loop | `%error` with stage and reason, or a diagnostic byte limit |
| Default generation | Library `fill`: auras ignored, containers filled as plain unions | `quiz-auto`'s `fill`: the same draws for plain types; valid values for meaningful auras; lists, units, sets and maps as containers |
| Default shrinking | Library `sink`: atoms and cells only; nothing for lists, unions or holds; floats as raw atoms | `quiz-auto`'s `sink`: the same for plain atoms and cells; text, ships, signed numbers and floats by meaning; containers, unions and holds by type |
| Shrinking | Unbounded; false/crash categories interchangeable | Bounded, decreasing weight, same failure category |
| Failure evidence | Final shrunk vase only | Original and best shrunk sample, source/config/seed |
| Persistence | Caller-owned | Recorded history and exact property replay |

The `quiz` library has no application limits or cooperative cancellation.
Do not interpret its `runs` field as the app's `accepted` or `attempted` count.

### App generator library (`quiz-gen`)

[`quiz-gen`](../lib/quiz-gen.hoon) (`/+ gen=quiz-gen`) provides generators,
typed shrinkers and an adaptor to `++alts`. Executable models:
[16-sorted-insert](../examples/props/16-sorted-insert.hoon) to
[20-dependent](../examples/failing/20-dependent.hoon), and
[31-float-associativity](../examples/failing/31-float-associativity.hoon)
for floats.

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
| `real`, `real-single` | Sized `@rd`, `@rs`: a whole number or a fraction `a/b`, equally likely, either sign, with `\|a\|` and `b` at most size (capped at 2^53 and 2^24), rounded to nearest; never infinity or NaN |
| `real-bits`, `real-single-bits` | Any finite `@rd`, `@rs` from random bits; size is ignored, so most values are near 1e±300 (1e±38); never infinity or NaN |
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
| `(seeded gen)`, `(regen make outer seed size pin)` | Dependent shrinking; see below |
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
| `shrink-real` | `.~0`, the absolute value of a negative, up to 54 smaller whole magnitudes (as `shrink-atom`, sign kept), then the shortest decimal form cut toward zero to 0, 1, …, 6 places, so `1.25` offers `1` and `1.2`. Only finite, strictly lighter candidates, each once; infinity and NaN give `~[.~0]`, zero gives `~` |
| `shrink-real-single` | `shrink-real` through doubles, each candidate rounded to the nearest single and kept only if lighter |
| `(shrink-list item)` | Delete chunks of n, n/2, …, 1 elements, then shrink one element with `item` |
| `(shrink-pair a b)` | Shrink the left, then the right |
| `(shrink-unit item)` | `~`, then smaller inner values |
| `(shrink-set item)`, `(shrink-map key value)` | Through the element list; a rebalanced tree may not weigh less, and the engine discards such a candidate |
| `(shrink-via to from inner)` | Shrink through a representation |
| `(shrink-keep pred inner)` | Only candidates satisfying an invariant or precondition |
| `(shrink-equal item)` | Coordinated: for each distinct element, every copy replaced by each of its candidates |
| `(shrink-then a b)` | `a`'s candidates, then `b`'s, for one value |
| `(shrink-seeded outer make inner)` | A `seeded` sample: smaller outer values, then a halved size, both unpinned; then the dependent value shrunk by `inner` and pinned |
| `(dependent outer-mold inner-mold outer outer-shrink make inner-shrink)` | A `seeded` document's parts in one core: `sample` (the fate's sample mold), `norn`, `shrink`, `alts` and `both` (a sample to `[outer dependent]`) |
| `shrink-nothing` | No candidates |

`(alts-of mold shrinker)` turns a typed shrinker into a document's `++alts`.
It molds the sample's noun, so it works for samples typed `*`, and it keeps
the sample's vase type. Pass a mold: a tuple mold needs its comma, as in
`(alts-of ,[(list @ud) @ud] …)`. Written without the comma, `[(list @ud) @ud]`
is a cell of two gates.

Shrinkers combine independently. When values constrain each other, such as a
tree's keys and the key being deleted in
[17-bst-delete-bug](../examples/failing/17-bst-delete-bug.hoon), each can
shrink only while the failure survives, so the result may keep larger values.
`shrink-equal` coordinates them: viewed through `shrink-via` as one list, every
copy of a value shrinks at once, and `shrink-then` adds those candidates after
the independent ones. [29-bst-coordinated](../examples/failing/29-bst-coordinated.hoon)
reaches `[~[1 0 2] 1]` where 17 stops at `[~[12 0 13] 12]`.

**Dependent shrinking.** QuickCheck shrinks nested `forAll` inputs by
regenerating the inner value as the outer one shrinks, then shrinking the inner
value with the outer one fixed. `seeded` gives a sample `[value seed size pin]`
with `pin` empty; the fate calls `(regen make value seed size pin)`, where
`make` takes the outer value and returns a generator. `regen` returns the
pinned value when there is one, and otherwise rebuilds it from the seed. Type
`pin` in the fate's sample as a unit of the dependent value's type.
`(shrink-seeded outer make inner)` first shrinks the outer value and halves the
size, each unpinned so the dependent value is rebuilt consistently. Then it
shrinks the current dependent value with `inner` and pins each candidate.
Pinning clears the seed, which a pinned value does not need: the unpinned
sample does not hold its dependent value, so only dropping the seed lets a
pinned candidate weigh less. Later outer shrinks rebuild from seed 0.
[20-dependent](../examples/failing/20-dependent.hoon) spells these parts out.

`dependent` bundles them. Give it molds for the outer and dependent values,
the outer generator and shrinker, `make`, and the dependent shrinker; write
the document's arms from its core:

```hoon
++  dep
  %:  dependent:gen  @ud  (list @ud)
    (range:gen 1 20)  (shrink-toward:gen 1)  values
    (shrink-list:gen shrink-atom:gen)
  ==
++  norn  norn:dep
++  alts  alts:dep
++  fate
  |=  raw=sample:dep
  =/  [bound=@ud items=(list @ud)]  (both:dep raw)
  (levy items (curr lth 90))
```

The molds type the sample, as for `set-of`, so it renders without the
shrinkers' faces: `raw=[value=1 seed=0v0 size=0 pin=[~ ~[90]]]`.
[30-dependent-inner](../examples/failing/30-dependent-inner.hoon) is this
document.

### Type-directed defaults (`quiz-auto`)

[`quiz-auto`](../lib/quiz-auto.hoon) (`/+ auto=quiz-auto`) is the app's
default generator and shrinker: the engine uses `fill` when a document has no
`++norn` and `sink` when it has no `++alts`. Both read the fate's sample type.
Executable model:
[34-typed-defaults](../examples/failing/34-typed-defaults.hoon).

**Plain types are unchanged.** For `@ud` and other atoms without a meaningful
aura, loobeans, cells, faces, hints, plain unions and `*`, `fill` draws from
the RNG exactly as the `quiz` library's `fill` does (a `*` sample is filled
by that `fill` itself), and `sink` offers the library `sink`'s candidates.
[`tests/lib/quiz-auto.hoon`](../tests/lib/quiz-auto.hoon) pins this parity.

**Auras with a meaning** get valid values from `quiz-gen` and shrink by that
meaning:

| Aura | `fill` | `sink` |
| --- | --- | --- |
| `@t`, `@ta`, `@tas` | `cord`, `knot`, `term` | Delete characters, then turn a character above `a` into `a`; `@ta` and `@tas` stay valid, `@tas` nonempty |
| `@tD` | A printable character | Toward `a` |
| `@p` | `ship` | `shrink-atom`, toward `~zod` |
| `@da`, `@dr` | `date`, `span` | As the library: `n/2`, `n-1` |
| `@s`, `@sd` | `signed` | Smaller magnitudes with the same sign |
| `@rd`, `@rs` | Sized `real`, `real-single` | `shrink-real`, `shrink-real-single`; never NaN |

**Containers** are recognized from the type, not by molding: a hold is
expanded, and its expansion is compared with each shape.

| Shape | Recognized as | `fill` | `sink` |
| --- | --- | --- | --- |
| List | A fork of `~` and `[i=a t=…]` whose `t` is the same hold | `list-of`, 0 to `container-max` (20) elements | `shrink-list`, each element by its type |
| Unit | A fork of `~` and `[~ u=a]` | `unit-of` | `~`, then smaller inner values |
| Set | A fork of `~` and `[n=a l=… r=…]` with equal `l` and `r` | Up to 20 elements | Through the element list, rebuilt with `silt` |
| Map | A set whose `n` is `[p=k q=v]` | Up to 20 entries; duplicate keys collapse | Through the entry list, keys then values, rebuilt with `malt` |

A set of pairs has a map's type, so it is generated as a map, which is still
a valid set.

**Unions** shrink within the branch the value is in. The branch is found by
checking atoms, constants and cell heads a few levels deep; deeper parts are
assumed to fit. A hold is expanded and shrunk as its expansion. A `*` sample
shrinks to its subtrees and smaller atoms; the library's `sink` gives it
nothing, because the library's `fill` types its noun so that `sink` does not
match it.

Every candidate keeps the sample's type, and the engine's usual rules apply:
only a lighter candidate with the same failure category is accepted.

| Arm | Meaning |
| --- | --- |
| `(fill size rng sample)` | A sample of the vase's type |
| `sink` | `vase` → `(list vase)`; usable directly as `++alts` |
| `(smaller type noun)` | The candidate nouns behind `sink` |
| `(shape-of hold expansion)`, `expand` | Container recognition |
| `container-max` | Most elements a default container holds (20) |

A document can add its own candidates to the defaults:

```hoon
/+  auto=quiz-auto
++  alts  |=(v=vase (weld (sink:auto v) (custom v)))
```

### Generated functions (`quiz-fun`)

[`quiz-fun`](../lib/quiz-fun.hoon) (`/+ fun=quiz-fun`) generates functions
for higher-order properties. As in QuickCheck's `Fun`, a function is a
finite table plus a default:

```hoon
(fun:fun a b)  ::  [cases=(list [key=a val=b]) else=b]
```

A table is plain data: it replays exactly, renders, and shrinks. `apply`
returns the value of the first case whose key equals the input, else the
default. Executable models:
[23-map-fusion](../examples/props/23-map-fusion.hoon) and
[24-filter-map-swap](../examples/failing/24-filter-map-swap.hoon).

| Arm | Meaning |
| --- | --- |
| `(apply f key)` | Look a key up |
| `(to-gate f)` | The table as a gate, for `turn`, `skim`, `cork` and the like |
| `(fun-of keys vals n)` | Up to `min(n, size)` cases from the key and value generators, then a default; a repeated key is shadowed by its first case |
| `(fun-on domain vals)` | A total table over a finite domain, one case per element, in order |
| `(shrink-fun key-mold value-shrinker)` | The constant function `[~ else]`, then fewer cases (as `shrink-list`), smaller case values, then a smaller default. Keys never change. Every candidate weighs less |
| `(fun-text !>(f))` | `'{3 -> 1, 5 -> 2, _ -> 0}'`, for `note`; pass a vase so values render with their types |

A table holds a list, so a sample type containing one is recursive: type the
fate's sample `*` and mold it with `;;`, as both examples do. Each value is
drawn from its own stream, so different keys get independent values; this is
QuickCheck's `coarbitrary` in table form. Tables cannot express every gate:
they are finitely supported, and a gate the property did not generate is
never randomized.

### Agent harness (`quiz-harness`)

[`quiz-harness`](../lib/quiz-harness.hoon) (`/+ h=quiz-harness`) drives a Gall
agent's door through model-based properties. It is pure: a property never
performs a real effect, a scry made by the agent is refused, and replay stays
exact. The bowl comes from the sample, never from the clock.

| Arm | Meaning |
| --- | --- |
| `event` | `[%poke mark vase]`, `[%watch path]`, `[%leave path]`, `[%peek path]`, `[%agent wire sign]` (a `sign:agent:gall` for `on-agent`), `[%arvo wire sign-arvo]` (for `on-arvo`) or `[%wait span]` (advances `run-clock`'s clock) |
| `timer` | `[due=@da =wire]`, a pending behn timer |
| `(bowl-at our src now eny dap)` | A bowl with the fields a door reads; `now` and `eny` come from the sample |
| `(run start handle events)` | Fold events through `handle`, a gate from the event and the saved state to cards and the next saved state. Returns `[%& cards state]`, or `[%| tang]` when a step crashes |
| `(run-clock start now handle events)` | As `run`, with a simulated clock starting at `now`; `handle` also receives the time, `$-([event @da *] [(list card) *])`. Returns `[%& cards state now timers]` (a `clocked`), or `[%| tang]` |
| `(cards-of cards tag)` | Cards with that head tag, such as `%give` or `%pass` |
| `(facts-on cards path)` | `%give %fact` cards published on exactly `path` |
| `(pokes-to cards dock)` | `%pass … %agent` `%poke` cards sent to `[ship agent]` |
| `(watches-to cards dock)` | `%pass … %agent` `%watch` cards sent to `[ship agent]` |

`handle` rebuilds the door for each event: `on-load` the saved vase, run the
event arm, then `on-save`. That is how Gall reloads state, so each sample
starts fresh and needs no cleanup. A door arm that crashes ends its run as
`[%| tang]` rather than a property crash. Wrap a door in a fixture file and
import it with `/=  drive  /fixtures/...`; see
[counter](../fixtures/quiz-harness/counter.hoon) and
[drive](../fixtures/quiz-harness/drive.hoon). Executable models:
[25-counter-agent](../examples/props/25-counter-agent.hoon) and
[26-counter-agent-bug](../examples/failing/26-counter-agent-bug.hoon).

**Simulated clock.** `run-clock` keeps the behn timers a step sets with
`[%pass wire %arvo %b %wait due]` cards; a `%rest` card cancels the first
pending timer with that wire and time. `[%wait d]` advances the clock by `d`,
first delivering every timer due by then as `[%arvo wire %behn %wake ~]`, with
`now` at its due time: earliest first, equal times in the order set. A timer
set while a wait is delivering wakes fires within that wait when it falls due.
The result's `timers` are those still pending, in the order set. No real time
passes and no timer reaches Behn. The
[expiry](../fixtures/quiz-harness/expiry.hoon) fixture, a gate over `fixed`
returning the door, and its
[drive-expiry](../fixtures/quiz-harness/drive-expiry.hoon) driver are the
executable models
[32-expiry-agent](../examples/props/32-expiry-agent.hoon) and
[33-expiry-agent-bug](../examples/failing/33-expiry-agent-bug.hoon).

A `fate` reads its saved state with `;;(vase state)`, and `!<` works on that
vase afterwards. Read the sample as a noun with `;;`, not `!<`, where the
sample is typed `*`: `!<` checks the vase's type.

**Save the state as a noun when its type is large.** `;;(vase st)` molds the
vase's type too. That is cheap for the counter's `@ud`, but a map's type
carries its whole compile-time subject, and molding it took minutes. The
expiry driver therefore saves `q` of `on-save`, rebuilds the vase for
`on-load` as `[p:!>(*store) st]`, and its fates read the store with
`;;(store:drive state)`.

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

The app's default is `quiz-auto`'s `sink`
([type-directed defaults](#type-directed-defaults-quiz-auto)). For plain
atoms and cells it matches the library's `sink`: halving and decrementing
nonzero atoms, subtrees for noun cells, and combinations of cell component
candidates, preserving faces and hints. Singleton atoms do not shrink. It
also shrinks text, ships, signed numbers and floats by their meaning, lists,
units, sets and maps as containers, a union within the branch its value is
in, and holds by expanding them.

The `quiz` library's `sink`, used by its runner, produces no
candidates for forks and holds, so it does not shrink lists or unions. It
treats a float as an atom, halving and decrementing the bit pattern: a
negative double can reach NaN (`-0` minus one is all ones) or a huge positive
value.

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

**Shrink trace.** Evidence carries a `trace` of the last `trace-steps` shrink
steps (default 100; 0 turns it off), newest first in Hoon and oldest first in
JSON. It answers "why did shrinking stop here?":

| Row | Recorded when |
| --- | --- |
| `[%alts best count]` | Alts was asked for candidates of the best sample, of weight `best`; it gave `count` |
| `[%candidate weight why text]` | One candidate was considered; `why` is below |

| `why` | Meaning | Weight | Text |
| --- | --- | --- | --- |
| `%accepted` | Replaced the best sample | yes | yes |
| `%timeout` | Hung and was accepted under `on-timeout %fail` | yes | yes |
| `%passed` | The fate passed | yes | yes |
| `%dropped` | The fate dropped it, or it hung under `%discard` | yes | yes |
| `%other-failure` | It failed in another category, including a hang when the failure is not a timeout | yes | yes |
| `%heavier` | Not lighter than the best sample | yes | no |
| `%visited` | Its mug was seen before | no | no |

Text is at most 160 bytes, cut with `...`. A rejected candidate is rendered
only for the trace; if rendering fails, the row has no text. Tracing never
changes a run's result or counters (pinned on examples 09, 11, 17 and 29),
but each rendered rejected candidate is one more sandboxed call under the
property call limit.

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
    bounds=limits  on-timeout=?(%interrupt %fail %discard)
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
| `on-timeout` | `%interrupt` | What a sample whose fate exceeds the call limit does: `%interrupt` ends the run; `%fail` shrinks it as a `%timeout` failure; `%discard` drops it and continues |
| `bounds.source-bytes` | 262,144 | Source cord bytes; builder ceiling and effective replay capture check |
| `bounds.requested-max` | 10,000 | Ceiling for requested checks |
| `bounds.shrink-candidates` | 1,000 | Candidates considered, even if skipped |
| `bounds.shrink-depth` | 100 | Accepted shrink replacements |
| `bounds.sample-bytes` | 65,536 | Jammed sample value bytes; the type, shared by every sample, is not counted |
| `bounds.rendered-bytes` | 16,384 | Rendered cord bytes of a kept sample: failure evidence, accepted shrinks, each label's first example, and samples stored under a split timeout policy |
| `bounds.diagnostics-bytes` | 16,384 | Jammed engine failure/diagnostic noun bytes |
| `bounds.alts-bytes` | 262,144 | Jammed bytes of one alts call's candidate values; types are not counted |
| `bounds.seen-bytes` | 4,194,304 | Jammed bytes of the samples `%exact` keeps |
| `bounds.retained-runs` | 100 | Completed records retained after this property finishes |
| `bounds.samples-per-slice` | 1,000 | Ceiling on engine steps per scheduling slice, including shrink work; slices start at 8 and adapt (see the agent API) |
| `bounds.trace-steps` | 100 | Shrink steps kept in the evidence's trace, newest; 0 turns tracing off |

Requested, attempt, drop, duplicate, shrink-candidate, shrink-depth and
trace-steps limits may be zero. Byte caps, retained-runs and samples-per-slice must be positive.
Requested-max may be zero when requested is also zero.
Requested must fit requested-max. Reaching the requested accepted
count wins over budgets reached on the same step. Otherwise, budget ties use
attempts, then drops, then duplicates. Shrink candidate limits precede depth
limits; an already known empty candidate list finishes normally first.

Additional fixed boundaries: queue length 100 waiting jobs; at most 100 explicit
suite arms; at most 100 samples (`preview-max`) and 20 shrink candidates
(`candidate-max`) per [generator preview](#generator-preview); HTTP JSON bodies at most 524,288 bytes. The web adapter permits one
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

A property document can lower its own call limit with the optional arm
`++within`, an `@dr` from 10 ms to 1 hour. Each slice runs its calls under the
lower of `++within` and the ship-wide `call` limit, so `++within` never raises
the ship's limit, and a Settings change still applies. It is not part of the
replayable `conf`: replay rebuilds the source, so the arm carries over. It
does not apply to draft builds or suites. A run's record keeps the limit its
last slice ran under as `call` (JSON `call-ms`, whole milliseconds).
Vere 4.6 honours sub-second limits: a looping Dojo expression under a 50 ms
limit aborted after 0.1–0.4 s including Dojo overhead, under 500 ms after
1.2 s, and under 2 s after 2.4 s.

Byte limits apply after generation, rendering or list construction as relevant;
`jam` also allocates. Only kept samples are rendered, each once, so a passing
sample with no new label renders nothing and cannot hit `rendered-bytes`.
Shrink candidates are weighed under the call limit before they are judged. Build and suite diagnostics use the default diagnostic
cap; the configurable property cap applies inside the engine.

CPU limits are enforced by Vere's `%jinx` hint. A call that exceeds its limit,
a Ctrl-C in the Vere terminal, or loom exhaustion aborts the whole Gall event.
The run is then recorded as `%interrupted` (see below), unless its
[timeout policy](#timeout-policy-on-timeout) handles a fate's timeout, and the
queue continues. Clay builds of saved files and suites have no CPU limit; interrupt
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
`uncovered`. Both are a plain threshold at the requested count. With zero
requested checks, every positive requirement is short.

`%confident` follows QuickCheck's `checkCoverage`. The run does not stop at
`requested`: at `requested`, then each doubling (200, 400, ... from 100) it
computes each row's Wilson score interval at certainty 1 in 10^9
(z ≈ 6.109). A row whose upper bound is below its share ends the run
`uncovered`; once every row's lower bound reaches 0.9 of its share the run
`passed`. Otherwise testing goes on. At `requested-max`, or when a budget ends
the run after `requested` was met, the plain threshold decides instead, as
under `%check`; such a run is never `exhausted`.

`++cover-table` follows QuickCheck's `coverTable`. Each row
`[table value percent]` requires `value` to be at least `percent` of the
entries `tabulate` made in `table`, not of the accepted samples, so a sample
that tabulates nothing adds nothing. It uses `++cover`'s mode, or `%check`
when the document has no `++cover`. A table with no entries is short for any
positive row under the plain threshold; under `%confident` such a row stays
undecided until entries appear or the plain threshold decides.

`++confidence [certainty tolerance]` sets `%confident`'s parameters, as
QuickCheck's `checkCoverageWith` does. `certainty` *k*, from 1 to 15, means a
decision is wrong at most 1 in 10^k; z is taken from a table of
`-inv_cdf(10^-k / 2)` (k = 9 gives 6.1094). `tolerance`, from 1 to 100,
is the percent of its share a row's lower bound must reach. The default
`[9 90]` is the behaviour described above. Without a `%confident` `++cover`
the arm is checked and then ignored.
[35-cover-table](../examples/props/35-cover-table.hoon) is an executable
model of `++cover-table`.

A shortfall is `[label want got table]`. For a label row `table` is `~`; for a
table row `label` is the value and `table` is the table's name. `got` is the
floored observed percentage: of accepted samples for a label, of the table's
entries for a table row.

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
| `uncovered` | Target reached, but a `%check` coverage row was short, or a `%confident` row's upper bound fell below its share; `shortfalls` and examples |
| `passed-unexpectedly` | `++expect %fail`, but every requested check passed |
| `failed` | `why`, original sample, shrunk sample, shrink trace |
| `failed-as-expected` | `++expect %fail` and a counterexample was found; same payload as `failed` |
| `error` | Stage `norn`, `generate` or `alts`; failure reason; optional evidence |
| `limited` | Named bound and optional evidence |
| `exhausted` | Budget `attempts`, `drops` or `duplicates`, plus `all-dropped` |
| `invalid` | Located build/configuration diagnostic |
| `cancelled` | Reason `request` or `reload` |
| `interrupted` | The runtime aborted the run's event: a CPU limit, Ctrl-C or memory exhaustion. `during` (`building`, `running`, `shrinking`), optional best evidence, optional suite arm. Under `on-timeout %fail` or `%discard` a fate's CPU limit does not interrupt the run; see the timeout policy below |
| `suite` | Aggregate status, arm counters and per-arm outcomes |
| `preview` | A [generator preview](#generator-preview)'s `rows` and `candidates` |

The durable Hoon [record](../sur/quiz-app.hoon) contains `id`, `request`, nullable
`snapshot` and `replay`, nullable effective `seed` and `config`, `engine-version`,
`status`, tagged `counts` (for properties, the counters plus the label and
table `distribution`), nullable `result`, created/updated/finished times, and
nullable `call`, the call limit the property's last slice ran under.
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

### Generator preview

A request whose `mode` is `[%preview count verdicts alts]` previews the
generator, as QuickCheck's `sample` does, instead of running the property. It
is an ordinary queued job and record: it runs in slices, can be cancelled or
`interrupted`, and its history row's kind is `preview`.

- It makes `count` samples, at most `preview-max` (100), with the run's RNG
  split, size schedule and `++norn` or [type-directed fill](#type-directed-defaults-quiz-auto).
  Sample *i* is therefore sample *i* of a run with the same seed and conf, up
  to the run's first skipped repeat.
- A repeat is flagged, not skipped: `repeat` says the conf's duplicate policy
  would skip it.
- With `verdicts`, the fate runs on each sample, in the same step, and the
  row records the verdict kind (`pass`, `drop`, `false`, `crash`, `scry`,
  `bad-product`) and the report's labels. A fate that exceeds the call limit
  interrupts the preview, whatever `on-timeout` says.
- With `alts`, after the last sample, one alts call on the first sample
  (`++alts`, or `quiz-auto`'s `sink`) shows up to `candidate-max` (20)
  candidates, each rendered, weighed and marked lighter or not. A candidate
  that cannot be shown has no weight and is not lighter.
- There are no budgets: `requested` and the attempt, drop and duplicate
  budgets are ignored, and nothing is shrunk. Sample-bytes and rendered-bytes
  limits and norn, generation or alts errors end a preview `limited` or
  `error`, as they end a run.

A row is `[size value text repeat verdict labels]`; a candidate is
`[value text weight lighter]`. The workbench's **Preview samples** button
shows both. Previews cannot be replayed.

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
output from a library check inside a test is not converted into sample metrics.
The app refuses scries during arms, whereas stock `-test` forwards them; not
every state-dependent suite is compatible. See [suite details](suites-and-replay.md).

The three example suites live under `tests/examples`. Intentional
teaching failures live under `examples/failing`, outside the regression
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
`/runs`, `/run/<id>` or `/timeouts`. Scries are `/x/runs`, `/x/summaries`, `/x/run/<id>`,
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

### Timeout policy (`on-timeout`)

By default a fate that exceeds the call limit aborts the whole run as
`%interrupted`, and the hanging sample is not recorded. The document can
choose instead with `conf.on-timeout`:

- `%fail`: the hanging sample is a failure, `[%timeout ~]`, and shrinking
  starts from it. A hanging candidate is accepted only while the failure is
  still a timeout. A candidate that hangs for a different failure is skipped.
  The result is `failed` with a `%timeout` cause, and its JSON kind is
  `timeout`.
- `%discard`: the hanging sample is counted as dropped, and the run goes on.
  A discarded shrink candidate is skipped.

Under either policy each sample is evaluated on its own tick, one kind of
work per tick, so an aborted tick has exactly one culprit: the sample stored
for it. Generation, alts and rendering still interrupt the run. A sample
stored on the last permitted attempt is still evaluated before any budget
ends the run, so the outcome and counters match `%interrupt` when nothing
hangs.

The runtime does not report why it aborted a tick, and its error wake carries
the aborted event's own `now`. `%quiz` judges the abort on the following wake:
it applies the policy only when the span from the aborted tick's due time to
that wake is at least the call limit. CPU time never exceeds wall time, so a
shorter abort was Ctrl-C or loom exhaustion, and the run ends `%interrupted`.
Other events queued before the aborted tick lengthen the span, so a Ctrl-C
close to the limit may be taken as a timeout. A Ctrl-C pressed after the call
limit has elapsed cannot be told apart from a timeout and is handled by the
policy. Each timed-out
sample or candidate costs a full call limit (10 s by default), so give such a
document a short `++within`, or set a short call limit in **Settings**. Each
abort also costs its recovery (the error wake and the next tick), so a lower
limit mainly helps fates that hang for long, not runs with many aborts:
[27-timeout-fail](../examples/props/27-timeout-fail.hoon) under a 0.5 s
`++within` took 33.6 s, about what it took under a 2 s Settings limit. Timing is not reproducible bit
for bit, so replay of a timeout run reproduces its policy and evidence, not
its wall-clock time. A timed-out sample has no separate counter: it appears
as `dropped` under `%discard`, and as the failure under `%fail`.

### Troubleshooting

| Symptom | Check / response |
| --- | --- |
| `clay: no files match /sur/quiz-app/hoon` or `/sur/urui/hoon` | Copy **all** packaged `desk/` contents into the mounted desk, including `sur`, `app`, `web`, `doc`, fixtures and examples; then `\|commit %quiz` and rerun tests. Copying only lib/gen/tests is insufficient. |
| `%fate-missing`, `%fate-type`, `%norn-type`, `%alts-type` | Use a property core with the signatures above; choose suite mode for a test core. |
| `%source`, `%import`, `%build`, unavailable desk/revision | Check path and pinned context. For a saved compiler failure, an editable draft may expose a more precise compiler diagnostic. |
| `%conf-range` | Start with defaults, keep the full config, respect ceilings and positive bounds. A request `config` patch is checked after it is merged. |
| `%cover-type`, `%cover-range` | `++cover` must be `[?(%warn %check %confident) (list [@t @ud])]`: at most 100 distinct, nonempty labels of at most 256 bytes, each percent at most 100. |
| `%cover-table-type`, `%cover-table-range` | `++cover-table` must be `(list [@t @t @ud])`: at most 100 distinct `[table value]` rows, each name nonempty and at most 256 bytes, each percent at most 100. |
| `%confidence-type`, `%confidence-range` | `++confidence` must be `[@ud @ud]`: certainty 1 to 15, tolerance 1 to 100. |
| `%within-type`, `%within-range` | `++within` must be an `@dr` from 10 ms (`(div ~s1 100)`) to `~h1`. |
| `%expect-type` | `++expect` must be `%pass` or `%fail`. |
| `%uncovered` | Every check passed, but a required label or table value was too rare. Inspect the distribution; change the generator, not the requirement, unless the requirement was wrong. |
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
| [quiz-engine](../lib/quiz-engine.hoon) | `init [seed config compiled]` → state; `previewing [state count verdicts alts]` → a preview state; `step state` → state (`preview-step`/`preview-end` while previewing); `compiled=[fate=vase norn=(unit vase) alts=(unit vase) cover=(unit coverage) expect=?(%pass %fail)]`, where `coverage` is `[cover tables confidence]`; `judge` classifies reports; terminal states are stable |
| [quiz-prop](../lib/quiz-prop.hoon) | Report combinators for fates; no engine state |
| [quiz-harness](../lib/quiz-harness.hoon) | Pure agent harness: `event`, `bowl-at`, `run`, `cards-of`, `facts-on`; fixtures in `fixtures/quiz-harness/` |
| [quiz-fun](../lib/quiz-fun.hoon) | Generated functions as tables: `fun`, `apply`, `to-gate`, `fun-of`, `fun-on`, `shrink-fun`, `fun-text`; no engine state |
| [quiz-gen](../lib/quiz-gen.hoon) | Total generators, size combinators, typed shrinkers and the `alts-of` adaptor; no engine state |
| [quiz-auto](../lib/quiz-auto.hoon) | Type-directed default `fill` and `sink` used by the engine without `++norn`/`++alts`; `smaller`, `shape-of`, `expand`; the library's RNG use for plain types |
| [quiz-build](../lib/quiz-build.hoon) | `pin`, `prepare`/`prepare-file`, dependency requests, `draft`/`take-saved`, arm/config checks |
| [quiz-suite](../lib/quiz-suite.hoon) | `prepare-file`, `request`, `take-built`, one-arm `step` |
| [quiz-replay](../lib/quiz-replay.hoon) | Capture/validate stored inputs; `refuse` checks a record without parsing; `resolve` checks context before rebuilding |
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
changing the `%quiz-action` interface or durable schema.

For maintainers, after release, changes to deterministic
generation/evaluation/shrinking or default semantics require an
engine-version bump; before release the version stays `%quiz-engine-1`.
Keep the `quiz` library, its generator and copied urui files unchanged. The [example catalog](examples.md) records
verified outcomes; regression and browser checks live under `desk/tests/` and
`tests/browser/` in the repository.
