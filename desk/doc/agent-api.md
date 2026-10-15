# Quiz agent API

`%quiz` accepts local-ship clients only. Pokes and watches from another ship
are rejected. The engine and legacy library contracts are separate; see
[source format](source-format.md) and [suites and replay](suites-and-replay.md).

The authoritative types are in `sur/quiz-app.hoon`. `app/quiz.hoon` exports the
Gall interface from `lib/quiz-agent.hoon`; tests can exercise the latter's
transient state directly. `lib/quiz-job.hoon` owns the pure queue and lifecycle.

## Actions and requests

Poke `%quiz-action` with one of:

- `[%run request]`: enqueue, allocating the next positive `@ud` ID.
- `[%cancel id]`: cancel a queued job immediately, or request cancellation of
  active work at its next Behn boundary, including a pending Clay build.
- `[%delete id]`: delete a completed record. Missing and unfinished IDs are
  no-ops.
- `[%clear ~]`: delete completed records; preserve queued and active work.

The request fields, in order, are:

| Field | Type and meaning |
| --- | --- |
| `source` | `[%draft text=@t]`, `[%file path]`, or `[%suite path arms=(list term)]` |
| `desk` | Local Clay desk, `@tas` |
| `revision` | Clay `case`: positive `%ud`, `%da`, or `%tas` label |
| `config` | `(unit conf:quiz-engine)`; optional complete settings override |
| `seed` | `(unit @uv)`; optional seed override, including zero |
| `replay-of` | `(unit @ud)`; replay an existing property's captured inputs |

Absent overrides use the document's `conf`, then engine defaults. Entropy is
captured on admission; a document seed takes precedence over that entropy.
The effective settings and seed are recorded after compilation. A supplied
config replaces the whole config; clients changing one field should copy the
current settings and edit that field. Suites expose neither a controlled seed
nor property counters: their record's `seed` and `config` are absent.

When `replay-of` is present, its stored source, path, context, seed, and settings
replace the other request fields. Missing/pruned records and records without
property replay inputs are rejected. Replay still checks local ship, engine
version, source hash, and context availability before execution.

Source and context are pinned when the queued job becomes active. For a date
or label request, the recorded immutable revision is the authority. A saved
file changed while waiting may therefore use the newer content if the chosen
case resolves to it. Use an explicit `%ud` revision to select immutable input
before enqueueing. Missing sources or unavailable contexts yield `%invalid`.
A source snapshot is retained before property parsing, so syntax errors still
refer to the captured text. If the source/context cannot be read, it is absent.

## Reads and updates

Subscribe using `%quiz-update` facts:

- `/runs` initially sends `[%runs ids]`, newest ID first. It subsequently
  sends list changes, `[%run record]` progress, and `[%deleted id]`.
- `/run/<id>` initially sends `[%run record]` and then progress snapshots.
  Unknown IDs are rejected. Deletion/pruning sends `[%deleted id]` followed
  by a kick. Completion keeps the subscription open.

IDs in paths use canonical `(scot %ud id)`, including dots for thousands.
Snapshots are current state; they are not a lossless log of every internal
engine step. A no-import draft can move from queued directly to running in
one event. Progress facts precede outgoing build requests.

Scries return `%noun` cages:

| Agent path | Product |
| --- | --- |
| `/x/run/<id>` | `record:quiz-app`; known path with absent ID returns no value |
| `/x/runs` | Newest-first `(list @ud)` of retained and pending IDs |
| `/x/limits` | `defaults:quiz-engine`, including bounds |
| `/x/version` | Engine semantics version (`%quiz-engine-1`) |

The Dojo `%gx` syntax adds a terminal mark; Gall strips it before `on-peek`:

```hoon
=qa -build-file /=quiz=/sur/quiz-app/hoon
.^((list @ud) %gx /=quiz=/runs/noun)
.^(@tas %gx /=quiz=/version/noun)
.^(record:qa %gx /=quiz=/run/1/noun)
```

```hoon
:quiz &quiz-action [%run [%draft '|%  ++  fate  |=(@ud &)  --'] %quiz [%ud 1] ~ ~ ~]
:quiz &quiz-action [%cancel 1]
:quiz &quiz-action [%run [%draft ''] %quiz [%ud 1] ~ ~ `1]
```

Replace revision `1` with an available revision. An empty suite arm list runs
all discovered arms. Numeric filenames need cord path components, for example
`~[%tests %examples '02-boxcar' %hoon]`.

## Scheduling, bounds, and persistence

There is one active job and a FIFO queue of at most 100 waiting jobs. Property
slices perform at most `samples-per-slice` engine steps (default 25); shrinking
steps use the same budget. Suites run one arm per slice. A self-addressed Behn
wake yields between slices, with a nominal 10 ms delay. Tokens are monotonic
and saved; duplicate, late, wrong-kind, and pre-reload replies are ignored.
Cancellation of active work first publishes `%cancelling`; the next slice
publishes `%done` with `[%cancelled %request]`, without another evaluation.

The default retained completed-record cap is 100. A property's effective
`retained-runs` can lower the cap when that property completes. Pruning removes
the oldest submitted completed records, never queued/active work. Suites use
the default cap. Reload applies the default cap after cancelling interruptions.
Deleting/clearing does not reset IDs or tokens. Admission rejects oversized
drafts, invalid overrides/paths/names, more than 100 explicit suite arm names,
and a full queue; these pokes are nacked and allocate no ID. Build/type/context
failures after admission are recorded as `%invalid` runs.

`on-save` emits `[%0 state-0]`: IDs, tokens, requests, source/replay snapshots,
settings, timestamps, progress, and durable outcomes. It excludes pending Clay
replies, compiled gates, suite cores, RNGs, and timer state. Counterexamples
contain only their noun values and bounded rendered text, without vase types.
`on-load` preserves completed records and marks every interrupted queued,
building, running, shrinking, or cancelling record `%cancelled` with reason
`%reload`. It never resumes old execution or substitutes new replay inputs.

The limits are cooperative and checked between calls. A non-returning property,
compiler, generator, shrinker, or suite arm can still block the ship; size caps
apply after allocation. There is no hard execution or memory isolation.
