# Quiz browser checks

See the [workbench access audit](workbench-access-audit.md) for the public
capability inventory, validation results, and confirmed gaps in UI access.

Install with `npm ci` and `npx playwright install chromium`. Boot a disposable
fake ship, install the packaged `%quiz` and `%quiz-web`, and commit `desk/`
to its `%quiz` desk. Never run mutation checks on a production ship.

Boot it with a 4 GB loom (`<vere> zod --loom 32`). The hanging-sample specs
abort events with `%jinx`. On Vere 4.6 each abort is followed by a `meme`,
and with the default 2 GB loom the serf died on every `%discard` run once
the engine also carried `quiz-auto`; with `--loom 32` it passes.

```
QUIZ_URL=http://127.0.0.1:18881 npm run test:doubles
QUIZ_URL=http://127.0.0.1:18881 QUIZ_CODE=<fake-ship-code> npm run test:browser
```

Doubles fetch the compiled public `/apps/quiz/app.js`; alternatively set
`QUIZ_BUNDLE` to a saved bundle. Each scenario boots in its own process.
Consumer setup adds Quiz DOM nodes and an in-memory files/API transport;
`doubles/` remains an unchanged copy of the pinned urui harness. Scenarios
cover open/edit/save, dirty protection, read-only copies, session restoration
and invalid application context. They do not substitute for real DOM/Ace tests.

Playwright logs in, creates uniquely named temporary files, saves/reopens
and restores a document, checks copies, pins/restores a Clay context, indexes
a property with a non-default engine face and a suite, opens and runs an
arbitrary suite through Open → clay, checks
help and Hoon tokenization. Temporary files are deleted in a `finally` block.
The ship needs at least two revisions. The context test uses its previous
revision; retain the packaged library there. No code is committed to Git.
Traces/screenshots are under ignored `test-results/`.

Quiz execution doubles also cover correlated IDs beyond JavaScript's exact
integer range, a concurrent producer, per-tab settings, full configuration
preservation, stale snapshots, replies to Use latest revision, configuration
inspection and suite discovery that arrive after an explorer change,
cancellation/replay/rerun, delete and clear with in-page confirmation,
unavailable suite
metrics, empty history, rejection, reload cancellation, interrupted runs,
generator previews (the request's mode, the rows and candidates, the count
bound, no replay, alternates without verdicts), an error cause beside retained
evidence with the record view, More limits overrides (a bound
completed from the document conf with one build), date and label revisions,
and network failures.
The Playwright run suite exercises document configuration, real draft failure
and shrinking, replay, rerun, session restoration, saved Clay suites,
cancellation, compilation diagnostics, disconnected progress, and a shrinker
error shown with its cause beside the evidence, whose record downloads as
the `status` reply and whose shrunk noun copies. Server run
history is retained on the disposable ship for inspection.

Run/replay HTTP replies now carry their correlated decimal `id`; configuration
inspection uses `document-conf`. See `desk/doc/http-api.md` for both contracts.

`examples.spec.js` runs all thirty-five property documents and the three existing
suites through the real UI, checks their expected outcomes and readonly roots,
and repeats the seeded threshold with exact replay. It also previews
`08-seeded-threshold` (five rows, verdicts, shrink candidates, replay
disabled). Each case writes a
`run.json` artifact under its test-results directory. No teaching failure is
included as a failing `-test` regression arm.

For rendered documentation verification, install a Markdown-capable `%docs`
on the disposable ship and run `QUIZ_DOCS=present` with `help.spec.js`.
It checks every TOC route, relative document/source links inside Help frames,
and restored tabs. With `%docs` absent, run the same file without that variable
to check fallback help. The workbench suite's fallback scenario also expects
`%docs` absent. These two states are tested separately, without mocking `%docs`.

`guide.spec.js` checks the workbench paths the users guide teaches and no
other spec reaches: F1 and F2, Alt-C (copies to the clipboard), Alt-O, Ctrl-S
and Ctrl-Shift-S, F5, Add Ref, Use latest revision with Clay source browsing,
the Vim setting, run-history deletion (Delete record, Clear completed history,
404/409 refusals, an unfinished run surviving Clear), and the run panel's
More limits (budgets, on-timeout and a bound reaching the effective
configuration), the alternates-only preview, and date and label revisions.

When switching an existing disposable ship from installed to absent, `%docs`
can leave its landing page in Eyre's response cache after uninstall. Clear
that page and its binding before running the fallback checks:

```hoon
|uninstall %docs
|pass [%e %set-response '/docs' ~]
|pass [%e %set-response '/docs/' ~]
|pass [%e %disconnect ~ /docs]
```
