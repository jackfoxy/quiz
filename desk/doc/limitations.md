# Quiz limitations

This page collects the known boundaries and operational caveats of Quiz. It is
an index, not a replacement for the linked contracts; follow each link for the
authoritative behavior and recovery guidance.

## Execution and containment

- **A passing property is evidence, not proof.** Quiz reports `%passed` after
  the requested number of accepted checks. It does not establish that the
  property holds for every input. See
  [counters, status and outcomes](reference.md#counters-status-and-outcomes).
- **A timeout policy costs a full call limit per hanging sample.** Under
  `on-timeout %fail` or `%discard`, every hanging sample or candidate waits
  the whole call limit (default 10 s) before it is handled, and a shrink can
  hang many times. Give such a document a short `++within`, or set a short
  call limit in **Settings**. Each abort also costs its recovery (the error
  wake and the next tick), so a lower limit helps a long hang more than many
  short ones: example 27 took 33.6 s under a 0.5 s `++within`, about what it
  took under a 2 s Settings limit.
  The policy covers the fate only; generation, norn, alts and rendering still
  interrupt the run.
- **A preview judges in the same step and ignores the timeout policy.** With
  verdicts, a [generator preview](reference.md#generator-preview) runs the
  fate in the step that makes the sample. A fate that exceeds the call limit
  interrupts the preview, whatever `on-timeout` says. A preview makes at most
  100 samples, shows at most 20 shrink candidates, and cannot be replayed.
- **CPU limits stop a stuck call, but block the ship until they fire.** Each
  fate, norn, alts or rendering call has a `%jinx` CPU limit (default 10 s).
  Draft compilation defaults to 30 s and a suite arm to 1 minute. All three
  are ship-wide and set in **Settings** (1 s to 1 hour). A document's
  `++within` (10 ms to 1 hour) can lower its own property call limit, never
  raise it. Until a limit fires, the ship processes nothing else.
  Clay builds of saved files and suites have no CPU limit. See
  [configuration and limits](reference.md#configuration-and-limits).
- **An aborted run keeps only committed progress.** A CPU limit, Ctrl-C or
  memory exhaustion aborts the whole Gall event, and the run is recorded as
  `%interrupted`. Work done in the aborted slice is lost: counters and evidence
  are those of the last completed slice. A counterexample is committed as soon
  as it is found, but which sample made a fate hang is not reported. The cause
  (timeout, Ctrl-C or memory) is not reported either. See
  [aborted events](agent-api.md#aborted-events-and-interrupted).
- **There is no memory isolation or sandbox.** Byte caps are checked after
  allocation. A computation can use the whole loom before it is aborted, and
  code you run is not isolated from the ship. Run experimental properties on a
  disposable ship.
- **Cancellation is not preemption.** Active cancellation takes effect only at
  a boundary between returning calls. Queued work can cancel immediately. See
  [Gall, HTTP and persistence](reference.md#gall-http-and-persistence).

## Properties and suites

- **Draft imports use a restricted prelude.** Draft documents support `/-`,
  `/+`, `/=` and `/*` in order, with limited raw marks. Other Ford forms and
  cross-desk imports are refused. Saved Clay files and their dependencies use
  ordinary Ford. See the
  [restricted Ford prelude](source-format.md#restricted-ford-prelude).
- **A zero requested count passes without checking an input.** Zero is a valid
  configuration value, and the requested accepted count has already been
  reached at startup. Use a positive value for meaningful evidence. See
  [configuration and limits](reference.md#configuration-and-limits) and
  [counters, status and outcomes](reference.md#counters-status-and-outcomes).
- **Suites cannot use property replay.** Suites can rerun, but replay is
  limited to property records with captured source, context, seed and
  configuration. See
  [Clay context, seed and replay](reference.md#clay-context-seed-and-replay).
- **The `quiz` library's generators are narrow and partial.** Its `list` norn
  yields at most `xeb(size)-1` elements, usually close to that, so short
  lists are rare late in a run. `atom`, `list` and `noun` crash at size 0,
  and `freq` or `pick` crash on an empty or all-zero list. The library's
  `sink` offers nothing for lists or unions, and it treats a float
  as a raw atom, so a negative double can shrink to NaN. The app's defaults
  come from `quiz-auto` instead, which shrinks containers, unions and floats
  by type. Prefer the
  [app generator library](reference.md#app-generator-library-quiz-gen),
  whose generators are total and whose `shrink-list` handles lists.
- **Type-directed defaults are heuristic.** Without `++norn` and `++alts`,
  `quiz-auto` reads the sample's type: meaningful auras get valid values, and
  lists, units, sets and maps are recognized by shape. It cannot know a
  semantic domain (sorted lists, positive numbers, consistent records), it
  holds at most 20 elements per container, and it finds a union's branch by
  checking only atoms and the first few cell heads. Write a norn and alts
  for anything more specific. See
  [type-directed defaults](reference.md#type-directed-defaults-quiz-auto).
- **Duplicates are skipped by mug unless you choose otherwise.** Under the
  default `%mug` policy a small domain such as `?` exhausts before a larger
  request, and a mug collision skips a distinct noun. Set `duplicates %allow`
  to evaluate repeats, or `%exact` to skip only equal nouns; `%exact` keeps
  every evaluated sample, bounded by `seen-bytes`.
- **Size grows fast unless capped.** The default size passes 50,000 by the
  100th sample. Set `size-max`, or use `quiz-gen`'s `capped`, for generators
  whose output grows with size.
  See [measured generator characteristics](reference.md#measured-generator-characteristics).
- **Shrinkers combine independently unless told otherwise.** `quiz-gen`
  shrinks each component on its own. Values that constrain each other may stop
  high; `shrink-equal` coordinates equal values, but there is no general
  search over joint changes such as shifting every key by the same amount.
- **Agent harness is pure.** `quiz-harness` drives a Gall agent's door with
  generated events. Behn timers are simulated by `run-clock`, and `%agent`
  and `%arvo` signs can be generated, but nothing else answers the agent:
  threads, Khan and other agents' replies exist only as the signs a
  property generates. Real effects would
  break determinism, exact replay and the `%jinx` containment model. A scry
  made by the agent under test is refused, so the sample ends `%scry`; test
  such arms with the scry results supplied in the handler, or refactor them.
  The CPU limit covers the whole fate, so long event lists need a lower
  `requested`.
- **Generated functions are finite tables.** `quiz-fun` makes a table
  plus a default, which cannot express every gate. Keys never shrink, so a
  counterexample keeps the inputs its cases name. A gate supplied by the
  code under test is never randomized.
- **Spell out sample types.** A fate sample typed with a mold that carries a
  large subject, such as zuse's `ship`, or with a recursive type, such as
  `(list @ud)`, makes every sample vase exceed the sample-byte limit. Use the
  aura (`@p`) or a `*` sample molded in the fate.
- **Statistical coverage is bounded.** `%warn` and `%check` compare each
  label's share at the requested count. `%confident` keeps testing until
  Wilson bounds decide, as QuickCheck's `checkCoverage` does, but stops at
  `requested-max` (10,000) or a budget, where the plain threshold decides.
  `++confidence` sets certainty from 1 in 10 to 1 in 10^15 (powers of ten
  only) and tolerance in whole percent. See
  [reports, labels and coverage](reference.md#reports-labels-and-coverage).
- **Labels are bounded and not shrunk per class.** At most 100 distinct labels
  and 100 table rows of at most 256 bytes; the run otherwise ends
  `%limited %labels`. Each label keeps its first passing example, unshrunk.
- **`same` and `collect` need `!>` at the call site.** A wet gate cannot render
  its argument with the caller's type, so these combinators take vases.
- **Pinned source does not freeze the compiler.** Replay validates the engine
  version and pinned Clay source, but source pinning alone does not guarantee
  identical behavior across Kelvin or compiler changes. See
  [property replay](suites-and-replay.md#property-replay).

## Scheduling and persistence

- **Only one job runs at a time.** Other admitted jobs wait in a FIFO queue of
  at most 100 entries. Property slices and suite arms yield only after their
  current call returns. See
  [scheduling, bounds and persistence](agent-api.md#scheduling-bounds-and-persistence).
- **No state migrations yet.** An upgrade that changes the saved state's
  shape is refused with `%load-failed`. Run `|nuke %quiz`, which deletes run
  history, then commit again. Migrations are planned.
- **Reload cancels unfinished work.** Completed records survive, but queued,
  building, running, shrinking and cancelling jobs become `%cancelled` with
  reason `%reload`; execution is never resumed. See
  [scheduling, bounds and persistence](agent-api.md#scheduling-bounds-and-persistence).
- **Retention is shared.** When a property finishes, its effective
  `retained-runs` can lower the cap applied to the complete run history and
  prune the oldest completed records, not only that property's records. See
  [scheduling, bounds and persistence](agent-api.md#scheduling-bounds-and-persistence).
- **An interrupted build has no source snapshot.** When the aborted event was
  starting a job, recording its snapshot rolls back too. The run's `request`
  still holds the draft text or path. See
  [aborted events](agent-api.md#aborted-events-and-interrupted).

## HTTP and workbench

- **The web adapter serializes mutations.** Only one API mutation, discovery
  or configuration inspection may await a reply. Another receives 503. A
  disconnected request retains that slot until a reply or the 30-second
  timeout; admission may already have happened, so inspect history before
  retrying. See [suite arm discovery](http-api.md#suite-arm-discovery).
- **An aborted inspection answers 500.** If configuration inspection or suite
  discovery is aborted by a CPU limit, Ctrl-C or memory exhaustion, Eyre
  replies 500 `crud!` with no structured diagnostic. Run the document as a
  draft to see the result. See
  [inspect document configuration](http-api.md#inspect-document-configuration).
- **HTTP acknowledgement is not completion.** Run and replay return after
  correlated admission, and cancellation returns after acknowledgement. Poll
  the run record for its confirmed terminal state. There is no automatic
  mutation retry. See [run and replay](http-api.md#run-and-replay) and
  [history, status and cancellation](http-api.md#history-status-cancellation-and-deletion).
- **The file wire serializes writes.** Only one save or delete may be pending;
  verification times out after 10 seconds. See the
  [file wire](http-api.md#file-wire).
- **Full rendered Help depends on `%docs`.** Without a Markdown-capable
  `%docs` app, the workbench provides only its built-in fallback summary. See
  the [document workbench](workbench.md).
