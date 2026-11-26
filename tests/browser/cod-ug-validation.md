# Validation of the Quiz user's guide

Checked on 2026-11-24 against checkout `7210f00b8ef76c86c61a526b72344474dbc1cc45`,
engine `%quiz-engine-13`, on an existing disposable fake `~zod` with `%zuse
408`, Vere 4.6 and a 4 GB loom. The companion is `cod-ug.md`. It and the
`cod-ug-evidence/` files named below were kept outside the repository.

**Result: Quiz's complete public functionality is not accessible through
the urui workbench.** Its property-authoring and execution features are
accessible, including all nine property arms, library imports, previews,
shrinking, reports, coverage, functions and pure agent testing. Saved suites
are accessible for files the UI can open. There are confirmed gaps in
history maintenance, general Clay browsing, advanced request options and
full-record access. The guide identifies them rather than implying complete
UI parity with the HTTP or Gall APIs.

## What was checked

The inventory starts with the public contracts in `desk/doc/reference/engine-and-library.md`,
`source-format.md`, `agent-api.md`, `http-api.md`, `suites-and-replay.md` and
`workbench.md`. Each capability was traced to the run panel, result renderer,
explorer, Settings, file wire or source editor. The inspection includes the
actual Hoon/JavaScript implementation, not only documentation claims.

The guide follows Obelisk's progression from a small example through richer
operations, then appendices. It includes 19 lessons, all 35 bundled property
documents, all three bundled suites, and a complete map of property arms and
public library families. New snippets and substantive editing exercises
were checked through the real workbench on the fake ship.

No application implementation, frozen file or urui copy was edited. The
pre-existing changes to `desk/doc/reference/workbench.md`, `tests/browser/README.md`
and `tests/browser/guide.spec.js` were preserved. Existing tests were used;
additional guide tests live with the evidence rather than modifying the
repository. Test-created regression files were removed.

## Fresh test results

| Check | Result | Evidence |
| --- | --- | --- |
| Existing Playwright suite | 60 passed, 1 skipped, 0 failed; 7.5 minutes | browser.log, JSON report (`cod-ug-evidence/browser-results.json`) |
| Additional guide checks | 14 distinct checks passed: 11 initially, 2 on targeted recheck, 1 after waiting for explorer refresh | initial log (`cod-ug-evidence/lessons.log`), targeted recheck (`cod-ug-evidence/lessons-recheck.log`), saved-suite check (`cod-ug-evidence/suite-settled.log`) |
| Workbench doubles using freshly fetched deployed bundle | 5 scenarios passed | doubles.log |
| Shortcut conflict checks | 9 passed | shortcuts.log |
| Mounted deployment vs checkout | All 134 Hoon/JavaScript files identical | source-comparison.json |
| Served client vs checkout | Compiled bundle embeds the current `quiz.js` and `quiz-runs.js` texts | Checked directly after fetching the public bundle |
| Fresh example snapshots vs checkout | All 37 saved source snapshots match, ignoring trailing whitespace | example-checks.json |
| Guide references and code formatting | Local reference targets resolve; fenced Hoon lines fit 80 columns | document-checks.json |
| Repository hygiene | `git diff --check` passes; no desk symlinks | Checked after validation |

The skipped test is installed, rendered `%docs` Help. The fake ship has no
`%docs`; its fallback Help tests passed. Unit 12 contains historical rendered
Help evidence, but it is not counted as a fresh test here.

The 37 saved example records cover 34 properties and three suites. Property
27 is exercised separately by the timeout test, which verifies a failure
shrinking to `n=11` and a 500 ms call limit; it took approximately 31 seconds.
Thus all 35 properties execute in the browser suite even though there are
37 ordinary example `run.json` artifacts rather than 38.

The first additional-test run found two test-harness issues: its expected
file-location text omitted `Read-only:`, and its string replacement changed
a comment instead of the timeout configuration. Both were corrected and
passed targeted rechecks. The saved-suite test exposed an actual revision-
selection race during the explorer refresh after saving. Focused rechecks
and event call stacks isolated it; the guide documents the recovery below.

## Feature-to-evidence map

| Feature | Workbench route | Evidence |
| --- | --- | --- |
| Open every bundled file through the explorer | Examples → folder → file | Additional test clicks all 38 visible file rows and checks read-only location, run mode and enabled Run |
| Ordinary properties: pass, false, crash, drop and exhaustion | Run saved property | `examples.spec.js`, examples 01–09 |
| Draft authoring and source snapshots | Editor → Run draft property | `runs.spec.js`; guide starter and its false edit |
| Document configuration and panel overrides | Read document conf, requested/seed/size/repeat fields | `runs.spec.js`; duplicates override test; additional exact-repeat and size-override test |
| Sample, verdict and candidate previews | Preview shows → Preview samples | Existing full preview test; additional samples-only and verdict-only tests |
| Explicit norn and alts; domain-preserving shrinking | Editor source and selected result | Examples 07–11, 19; guide threshold and bounded-shrink exercises |
| Original/shrunk evidence and trace | Selected history row | `examples.spec.js`, including queue trace, threshold and domain-specific counterexamples |
| Replay, rerun, stale source, source-tab navigation and restoration | Result buttons and reload | `runs.spec.js`; threshold exact replay in `examples.spec.js` |
| Notes and typed expected/actual output | Result pane | Examples 13, 24, 26; complete report snippet exercised as a draft |
| Labels, collection tables and first examples | Distribution/table output | Examples 12, 16, 21 and 35 |
| Coverage failure and warnings | `++cover`, run result | Example 14; additional `%warn` edit |
| Confidence and table requirements | `++cover`, `++confidence`, `++cover-table` | Examples 28 and 35; explicit `[9 90]` confidence and deliberate table-shortfall edits |
| Expected failure and unexpected pass | `++expect` | Example 15; repaired claim produces `passed-unexpectedly` |
| Structured generators, type defaults and float shrinking | Editor imports, preview/run | Examples 06, 16, 18, 22, 31 and 34 |
| Model/command-sequence testing | Editor imports, saved property run | Examples 10, 11, 17 and 19 |
| Coordinated and dependent shrinking | Editor imports, shrink evidence | Examples 20, 29 and 30 |
| Generated finite functions | Editor imports and notes | Examples 23 and 24 |
| Agent doors and simulated clock | Editor imports and model comparisons | Examples 25, 26, 32 and 33 |
| Per-document call limit and timeout policy | `++within`, `++conf`, result Call limit | Existing timeout `%fail` and `%discard` tests; additional bounded-discard exercise |
| Ship-wide CPU limits | Settings | `workbench.spec.js` changes/restores limits and interrupts a looping run |
| Suite discovery, exact names and all arms | Discover suite arms → Run saved suite | Existing suite tests; guide's saved two-arm regression suite |
| Cancellation and diagnostics | Result controls | `runs.spec.js`; disconnected/reload/interrupted doubles |
| Browsed desk/revision | Clay source | `guide.spec.js`; additional real-server general-chooser failure reproduction |
| Save/open/copy, editable copies, dirty protection, persistence | Editor and file dialogs | `workbench.spec.js`, `guide.spec.js`, doubles |
| F1/F2/F5, save/open/copy shortcuts, reference panel, Vim setting | Keyboard, Add Ref, Settings | Existing `guide.spec.js` and shortcut conflict tests |
| Fallback help and Hoon tokenization | Help, Documentation and editor | `help.spec.js`, `workbench.spec.js` |

Library access means a property can import and invoke the library through
the editor. It does not mean every scalar generator or helper has a dedicated
button, or that this documentation task re-executed every library unit test.
The existing examples exercise the major families; the reference and source
establish the remaining callable signatures.

## Confirmed access gaps

### 1. Completed-history deletion and clearing are Gall-only

`quiz-app`/`quiz-agent` support `%delete` and `%clear`. The JSON decoder does
not expose either operation, and the client has no corresponding control.
The existing guide spec sends both HTTP operations and verifies refusal.
Deleting a work file and cancelling a job are different operations.

To achieve UI parity, add authenticated HTTP routing and visible controls
for deleting one completed result or clearing completed history, preserving
queued and active work. This task documents the gap; it does not implement it.

### 2. The general Clay chooser loses its context

After selecting a context in **Clay source** and browsing a revision,
**Open → clay** sends `{"op":"browse","scope":["clay"]}`. The server's
`locate` in `desk/lib/quiz-files.hoon` requires a desk and decimal revision
after `clay`; it returns `select a desk and revision`.

The additional browser test reproduced this against the real server. The
exact request is retained in the lesson artifacts. Indexed properties
still open correctly, as do bundled suites and saved work files. General
unindexed files and arbitrary external suites lack a usable chooser path.
The documentation statement that selecting a context first is sufficient
does not match the client behavior.

A repair belongs in the shared file-chooser/context integration and must
respect the repository's urui ownership rule.

### 3. Some per-request options have no panel controls

The UI provides count, seed, first/largest size and repeat-policy overrides.
It does not provide per-request attempts/drop/duplicate budgets, bounds or
timeout policy. Those features remain accessible by editing `++conf`, but
an unchanged saved property cannot receive such a one-off UI override.

The HTTP API also accepts independent preview `verdicts` and `alts` flags;
the panel supplies three presets and omits candidates without verdicts.
HTTP/Gall support date/label revision selectors; the UI accepts a positive
numeric revision. These are confirmed by the request builders/decoders.

### 4. The result pane is not a complete record/export interface

HTTP status and Gall reads include timestamps, submitted request fields and
jammed sample nouns that are not all rendered in the pane. There is no result
download control; **Copy** copies the source document.

When an error has retained failure evidence, `renderDetail` renders the
evidence's `why` and only uses the top-level error `why` in the `else`
branch. Thus the stage and retained failure are visible while the separate
shrinker error cause can be missing. Both remain in the full record.
This finding is from renderer/codec inspection, not a newly induced crash.

Gall subscriptions are likewise a programmatic interface; the browser polls
history. Installation, agent lifecycle, standalone `+quiz` and
recursive Dojo `-test` are operator/programming entry points, not UI features.

### 5. Explorer refresh can invalidate revision selection after saving

During the new saved-suite exercise, **Use latest revision** received HTTP
200 with the new desk revision but left the old revision selected and gave
no “Selected” confirmation. Waiting only for Save As to close did not avoid
the problem.

Captured change-event call stacks show the refreshed explorer's HTML
`details` toggle events calling urui's generic `changed()`. Quiz's
`onChange` calls `runner.changed()`, which calls `clearInspection()` and
increments the inspection generation. `latest()` then discards its
successful response as obsolete. The same generation mechanism is used for
configuration inspection and suite discovery, although those variants were
not separately reproduced.

The guide says to let the explorer finish refreshing before selecting the
latest revision, wait for its confirmation, and retry the selection if the
confirmation never appears. The final regression-suite check waits for the
explorer's busy state to clear before using the visible controls. This is
a UI timing defect, not a compile failure in the guide's suite. A code fix
would need to distinguish document/context changes from unrelated explorer
state changes when invalidating inspections.

## Limits of this validation

- Chromium on this Linux environment was exercised. macOS Command mappings,
  other browsers and assistive-technology behavior were not separately tested.
- Theme/layout choices, dialog dragging, all individual Ace commands and
  polling intervals were checked against shipped configuration/source; this
  run did not add exhaustive interaction tests for each one.
- Real rendered `%docs` Help was skipped, as described above.
- The pure agent harness was exercised by its shipped examples. Real external
  effects, live scries, threads and other-agent integration are not provided
  by those tests or by the deterministic harness.
- No new full Hoon `-test` run or fresh desk installation was necessary for
  this documentation-only change. The existing installed fake ship's matching
  implementation executed the browser tests and guide snippets.
- Fresh pass/fail results are evidence for these inputs and settings, not a
  proof of the engine or of every possible property.

## Reproduce the checks

Use a disposable fake ship with this desk installed; never a live ship.
Follow `tests/browser/README.md` for setup. From the Quiz checkout, with the
fake-ship URL and login code supplied in environment variables:

```sh
npm run test:browser
npm run test:doubles
npm run test:shortcuts
npx playwright test --config <guide-directory>/cod-ug-evidence/lessons.config.cjs
```

Set `QUIZ_URL` and `QUIZ_CODE` for the first two browser commands and the
additional lesson tests. The lesson configuration resolves Playwright and
sources from the current checkout; optionally set `QUIZ_REPO` to that
checkout. The evidence includes its test source (`cod-ug-evidence/lessons.spec.cjs`),
configuration (`cod-ug-evidence/lessons.config.cjs`) and extracted
guide snippets (`cod-ug-evidence/snippets.json`). It contains no login code or
browser traces. Existing `guide.spec.js` currently hardcodes its clipboard
permission origin to port 8092; adjust that test's origin if validating on
another port.
