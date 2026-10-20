---
name: quiz-dev
description: Change, test and debug the %quiz desk itself, including the app engine, document builder, suite runner, job queue, %quiz and %quiz-web Gall agents, HTTP API, urui workbench client and docs. Covers where a change belongs, which files are frozen or copied, the fake-ship edit/commit/-test loop, which test file covers which module, browser tests, and symptoms like failing -test arms, %invalid diagnostics, jobs stuck queued, HTTP 401/503/504, help not rendering, replay refusals and a hung ship. Use for any implementation, refactor, bug fix, test or doc-maintenance work in this repository, even a small one, before editing Hoon or JavaScript here.
---

# Quiz development and debugging

Read [AGENTS.md](../../../AGENTS.md) first. It has the ownership table, the
rules and the canonical [commands](../../../AGENTS.md#commands). This skill
says where changes go and how to find faults. It does not repeat the
commands.

## Where a change belongs

The layers are pure libraries wrapped by thin Gall and Eyre adapters. Put
logic in the lowest layer that can own it. Pure layers can be tested without
a bowl.

| Change | Edit | Tests |
| --- | --- | --- |
| Generation, classification, counters, shrinking, limits | `lib/quiz-engine.hoon` (bump `++version`) | `tests/lib/quiz-engine.hoon`, `tests/lib/quiz-shrink.hoon` |
| Document format, prelude, arm type checks, context pinning | `lib/quiz-build.hoon` | `tests/lib/quiz-build.hoon` (fixtures in `fixtures/quiz-build/`) |
| `test-*` discovery and arm execution | `lib/quiz-suite.hoon` | `tests/lib/quiz-suite.hoon` |
| Replay capture and validation | `lib/quiz-replay.hoon` | `tests/lib/quiz-replay.hoon` |
| Queue, admission, slices, cancellation, retention, reload | `lib/quiz-job.hoon` | `tests/app/quiz.hoon` |
| Clay requests, Behn ticks, facts, scries | `lib/quiz-agent.hoon` | `tests/app/quiz.hoon` |
| Public types or marks | `sur/quiz-app.hoon`, `mar/quiz/` | `tests/app/quiz.hoon` (state change: see AGENTS.md) |
| JSON shapes | `lib/quiz-json.hoon` | `tests/lib/quiz-json.hoon` |
| Routes, auth, pending API slot, assets | `lib/quiz-web-agent.hoon` | `tests/app/quiz-web.hoon` |
| Workbench config, stores, help fallback | `lib/quiz-web.hoon`, `lib/quiz-files.hoon` | `tests/app/quiz-web.hoon`, `tests/lib/quiz-files.hoon`, browser |
| Client behaviour | `web/quiz.js`, `web/quiz-runs.js` | `tests/browser/` doubles and Playwright |

Paths are under `desk/` unless they start with `tests/browser/`.

Do not edit these:

- **Frozen:** `lib/quiz.hoon`, `gen/quiz.hoon`, and the legacy tests. If the app
  needs different behaviour, implement it in the engine.
- **urui copies:** fix the problem upstream in urui and re-copy. A fix that is
  specific to quiz belongs in a quiz-owned file. For example, `quiz-files`
  works around a tomb-scry issue without touching `urui-files`.

## Loop

1. Edit in the repository.
2. Sync to the fake ship's mount and `|commit %quiz`.
3. Run the narrowest `-test` path, then `-test /=quiz=/tests ~` before you
   finish.
4. If you changed the client, the HTTP layer or the help: run the JS syntax
   checks and the browser suites in
   [tests/browser/README.md](../../../tests/browser/README.md).
5. Update the authoritative doc in the same change (see AGENTS.md).

Test idioms you will see here:

- **App tests** build a `bowl:gall` with `%*` and drive the agent
  door directly, or the pure `quiz-job` gates (`admit`, `activate`, `advance`).
  They also import `/app/quiz` to check the packaged export.
- **Engine tests** step `init:engine` to a terminal state in a bounded loop.
  A broken stop condition must fail the arm, not hang the suite.
- **Clay replies** in agent tests are hand-built `%writ` signs, mostly null
  riots that cover stale, late or failed builds. Successful pinned builds and
  real Clay behaviour need a check on the fake ship.

A ship-free runner exists in urui (`bin/hoon-test.js`, using `vere eval`). It
works for engine-only cores. It fails on anything that uses `quiz-build`,
because its embedded Hoon lacks `vi` (error `-find.vi`). Treat `-test` on
the fake ship as the real authority.

## Debugging by symptom

**`-test` fails before any arm runs: `clay: no files match /sur/...`.**
The mount is incomplete. Sync all of `desk/`, not just `lib/` and `tests/`.

**`%invalid` with a code.** Codes are listed in
[troubleshooting](../../../desk/doc/reference.md#troubleshooting).
A saved-file `%build` has no compiler trace, because Clay does not return
one. Run the same text as a draft to get the located tang. `%import-context`
or `%build-context` means a Clay reply didn't match the pinned
desk/revision/path. Check the request that `quiz-build` produced.

**Run stays `queued` or `building`.** Inspect the record:

```dojo
=qa -build-file /=quiz=/sur/quiz-app/hoon
.^(record:qa %gx /=quiz=/run/<id>/noun)
```

Exactly one job is active at a time, and every other job waits behind it.
Progress depends on a self-addressed Behn wake: `publish` arms the next wake
only when `timer` is empty. A runtime abort (`%jinx` timeout, Ctrl-C or loom
exhaustion) does not stall this. Vere turns the aborted event into an error
wake, `[%behn %wake [~ tang]]`, on the same tick wire, and `interrupt:quiz-job`
finishes the culprit job as `%interrupted`. If the queue does stop, look for
a crash in code outside any sandbox. Reloading the agent clears the timer
and cancels unfinished jobs with `%reload`; a recommit that rebuilds the
agent does this.

**The ship stops responding during a run.** Some call is running up to its
CPU limit (`call-time` 10 s, build 30 s, suite arm 1 min). Wait, or press
Ctrl-C in the Vere terminal: the terminal prints `recover: dig: alrm`,
`intr` or `meme`, and the run ends `%interrupted`. A Clay build of a saved
file or suite has no CPU limit; use Ctrl-C. Only run experiments on a
disposable ship.

**`%interrupted`.** `during` gives the stage. `arm` names the suite arm, and
`proof` holds the best counterexample committed before the abort. The
aborted slice's work is lost. To narrow a hang to one sample, rerun with the
same seed and `samples-per-slice` 1. The hung sample is number `attempted`+1;
its value is not recorded. A unit test can't
reproduce an abort: `%jinx` would abort the `-test` event itself. Test the
recovery path with a synthetic error wake, as `tests/app/quiz.hoon` does, and
check real aborts on the fake ship.

**`%exhausted` or `%limited` when you expected a pass.** This is usually
correct engine behaviour. Check the property with
[quiz-properties](../quiz-properties/SKILL.md) before you change the engine.

**Replay refused.** `%engine-version` means `++version` changed since the
record was made. This is intentional. `%source-hash` means the stored text
was altered. `%revision-unavailable` or `%desk-unavailable` means the pinned
context has gone. Replay never substitutes another context.

**HTTP.**

- 401: no session cookie, or the request came from a foreign ship. Asset
  routes are public; `/api` and `/files` are not.
- 503 `api-busy`: `%quiz-web` holds one pending mutation, discovery or conf
  request at a time.
- 504 `api-timeout`: that request did not finish within 30 s. A client that
  disconnects still holds the slot until the timeout. Admission may still
  have happened, so check `runs` before you resubmit.

Wire shapes: [http-api.md](../../../desk/doc/http-api.md).

**Help shows the fallback although `%docs` is installed, or rendered docs
appear after `%docs` was removed.** Eyre caches the `%docs` landing page.
Use the cleanup steps in the browser test README.

**Browser test failures.** Doubles use the compiled `/apps/quiz/app.js`, so
recommit before you run them. Playwright needs `QUIZ_URL` and `QUIZ_CODE`,
plus at least two desk revisions for the context test. Traces are written to
`test-results/`, which is ignored by Git.

**urui drift check reports a file.** Compare against the pinned revision, not
the urui working tree, which may have moved ahead. If upstream has a fix you
want, re-copy it and update the pin in AGENTS.md.

## Before you finish

- `-test /=quiz=/tests ~` reports `ok=%.y`. Also run the browser suites if
  you touched the client, HTTP or help.
- The frozen files and urui copies are unchanged: `git diff --stat` and the
  drift check.
- Any semantic change to the engine bumps `++version`. Recorded counters in
  `doc/examples.md` and the user's guide are re-measured.
- New Hoon follows `hoon-style-guide` and stays within 80 columns.
- `git diff --check` is clean.
