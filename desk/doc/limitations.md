# Quiz limitations

This page collects the known boundaries and operational caveats of Quiz. It is
an index, not a replacement for the linked contracts; follow each link for the
authoritative behavior and recovery guidance.

## Execution and containment

- **A passing property is evidence, not proof.** Quiz reports `%passed` after
  the requested number of accepted checks. It does not establish that the
  property holds for every input. See
  [counters, status and outcomes](reference.md#counters-status-and-outcomes).
- **CPU limits stop a stuck call, but block the ship until they fire.** Each
  fate, norn, alts or rendering call has a `%jinx` CPU limit (default 10 s).
  Draft compilation defaults to 30 s and a suite arm to 1 minute. All three
  are ship-wide and set in **Settings** (1 s to 1 hour). Until a limit fires,
  the ship processes nothing else.
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
  [history, status and cancellation](http-api.md#history-status-and-cancellation).
- **The file wire serializes writes.** Only one save or delete may be pending;
  verification times out after 10 seconds. See the
  [file wire](http-api.md#file-wire).
- **Full rendered Help depends on `%docs`.** Without a Markdown-capable
  `%docs` app, the workbench provides only its built-in fallback summary. See
  the [document workbench](workbench.md).
