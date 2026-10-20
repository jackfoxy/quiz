# Quiz browser checks

Install with `npm ci` and `npx playwright install chromium`. Boot a disposable
fake ship, install the packaged `%quiz` and `%quiz-web`, and commit `desk/`
to its `%quiz` desk. Never run mutation checks on a production ship.

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
and restores a document, checks copies, pins/restores a Clay context, checks
help and Hoon tokenization. Temporary files are deleted in a `finally` block.
The ship needs at least two revisions. The context test uses its previous
revision; retain the packaged library there. No code is committed to Git.
Traces/screenshots are under ignored `test-results/`.

Quiz execution doubles also cover correlated IDs beyond JavaScript's exact
integer range, a concurrent producer, per-tab settings, full configuration
preservation, stale snapshots, cancellation/replay/rerun, unavailable suite
metrics, empty history, rejection, reload cancellation, interrupted runs
and network failures.
The Playwright run suite exercises document configuration, real draft failure
and shrinking, replay, rerun, session restoration, saved Clay suites,
cancellation, compilation diagnostics and disconnected progress. Server run
history is retained on the disposable ship for inspection.

Run/replay HTTP replies now carry their correlated decimal `id`; configuration
inspection uses `document-conf`. See `desk/doc/http-api.md` for both contracts.

`examples.spec.js` runs all nine property documents and the three existing
suites through the real UI, checks their expected outcomes and readonly roots,
and repeats the seeded threshold with exact replay. Each case writes a
`run.json` artifact under its test-results directory. No teaching failure is
included as a failing `-test` regression arm.

For rendered documentation verification, install a Markdown-capable `%docs`
on the disposable ship and run `QUIZ_DOCS=present` with `help.spec.js`.
It checks every TOC route, relative document/source links inside Help frames,
and restored tabs. With `%docs` absent, run the same file without that variable
to check fallback help. The workbench suite's fallback scenario also expects
`%docs` absent. These two states are tested separately, without mocking `%docs`.

When switching an existing disposable ship from installed to absent, `%docs`
can leave its landing page in Eyre's response cache after uninstall. Clear
that page and its binding before running the fallback checks:

```hoon
|uninstall %docs
|pass [%e %set-response '/docs' ~]
|pass [%e %set-response '/docs/' ~]
|pass [%e %disconnect ~ /docs]
```
