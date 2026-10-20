# Suites and property replay

## Clay suites

`lib/quiz-suite.hoon` runs existing Clay test files. It uses the same superficial
`test-*` arm discovery, descending name order, and `tang` return contract as the
Kelvin 408 `-test` runner. It does not interpret a test core as a property gate.

1. Resolve a local desk/case with `pin:quiz-build`.
2. `prepare-file:suite [where path selected]` reads and validates the source at
   that revision. `prepare:suite [where path source selected]` is the pure
   counterpart for callers that already loaded the exact source. The file uses
   ordinary Ford; the property document's restricted prelude does not apply.
3. Send `request:suite doc` as a Gall `%c %warp` request. Pass its `riot:clay`
   reply to `take-built:suite [doc reply]`.
4. A `%ready` result contains state with `available` and `remaining` arm names.
   Call `step:suite` once per scheduling slice. A completed state is unchanged
   by subsequent steps. `result` becomes non-null when all selected arms finish.

`selected=~` selects all test arms. A nonempty list selects exact arm names;
unknown or duplicate names are invalid. Selection order does not change execution
order. Discovery never calls a test. Non-core files report `%suite-not-core`;
cores without `test-*` arms report `%suite-no-tests`. Build, mark, path, source
size, and mismatched reply errors are also explicit `%invalid` diagnostics.

Each arm is compiled against `tang` before execution:

| Arm status | Meaning |
| --- | --- |
| `%passed` | Returned an empty tang |
| `%failed` | Returned a nonempty tang |
| `%crashed` | Execution crashed or attempted a scry |
| `%invalid` | The arm could not be compiled with a tang product |

The runner keeps going after an unsuccessful arm. The aggregate status is
`%passed` only when every selected arm passed; otherwise it is `%failed`.
The result contains `counts=[total completed passed failed crashed invalid]`,
ordered `arms`, and `sample-metrics=%unavailable`. Each arm contains
`[name status trace clipped]`; traces above the engine's default diagnostic byte
cap are omitted with `clipped=%.y`, without changing the arm's status.

Only arm counts are measured. Legacy sample attempts, accepted checks, drops,
duplicates, shrink counts, seeds, and counterexamples are unavailable through
this interface. Printed `~&` output is not parsed into invented metrics. A test
may perform many legacy property checks inside one arm.

The app runner refuses scries during arm execution. The stock `-test` runner
forwards them; tests that require live scries are therefore not compatible with
this app runner. Unlike `-test`'s eager arm compilation, a bad arm type becomes
an individual `%invalid` result, allowing other selected arms to run. The three
bundled example suites have the same 19 passing arm outcomes in both runners:

```hoon
-test /=quiz=/tests/examples ~
```

Each arm's compile and run has the ship-wide suite arm CPU limit (default
1 minute, set in **Settings**). An arm
that exceeds it, is stopped with Ctrl-C, or exhausts memory ends the suite as
`%interrupted` with `arm` naming it. Earlier arms' counts are kept; their
individual results are not. The Clay build of the suite file has no CPU limit,
but can be interrupted. Scheduling one arm per slice also gives a cancellation
boundary between returning arms.

## Property replay

`lib/quiz-replay.hoon` records property inputs separately from compiled state.
Its `record` contains:

| Field | Recorded value |
| --- | --- |
| `where` | Local ship, desk, positive immutable `%ud` revision |
| `path` | Original document path, including `/hoon` |
| `source`, `source-hash` | Exact text and its `shax` digest |
| `seed` | Resolved `@uv` seed, including an explicit zero |
| `config` | Effective engine config after all overrides |
| `engine-version` | `version:quiz-engine`, currently `%quiz-engine-2` |

`capture:replay [doc seed config]` validates and creates a record. Call it with
the source and effective settings used by the original run. It stores no vases,
compiled cores, or live RNG state; ordinary jam/cue persistence preserves it.

To replay:

1. `resolve:replay [our now record]` checks the engine version, source hash,
   configuration, source size, ship, desk, and recorded revision. `our` and `now`
   come from the Gall bowl. It returns the prepared **stored text**, not the
   current contents of the file. A deleted or edited current file does not
   replace the stored text.
2. Send `draft-requests:quiz-build` for that prepared document and gather replies
   in prelude order. Every import request uses the original revision.
3. `start:replay [record replies]` rebuilds, checks types, and initializes the
   engine using the recorded seed and effective config. Call `step:quiz-engine`
   normally to reproduce the original and shrunk counterexamples and counters.

`prepare:replay` and `start:replay` are pure validation/build helpers. The caller
must successfully `resolve` before running a stored record, even when there are
no imports. No fallback to latest revision, new entropy, or document defaults
is performed. Replays do not depend on a stored compiled vase.

Unavailable contexts distinguish `%ship-unavailable`, `%desk-unavailable`, and
`%revision-unavailable`. The latter two include descriptive tang where available.
`%engine-version` rejects an incompatible engine; `%source-hash` rejects changed
text whose digest was not updated. Invalid configuration, size, source, or
failed imports retain the builder's specific diagnostic. Source hashing detects
accidental source changes; it is not authentication of the whole record.

Engine maintainers must bump `version:quiz-engine` whenever deterministic
sampling, evaluation, shrinking, or default semantics change. Older versions
are rejected rather than silently replayed with new semantics. Pinning imports
does not by itself freeze a future kernel/compiler; cross-Kelvin replay is not
claimed. This desk currently targets `%zuse 408`.

The [replay fixture](../fixtures/quiz-replay/property.hoon) intentionally fails
against its imported threshold and is kept outside the passing test directory.
Opaque legacy suites can be rerun at their saved Clay context, but this property
replay API does not invent seed control or sample-level replay for suite arms.
