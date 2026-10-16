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
