# Quiz workbench access audit

Re-audited 2026-11-26 after units 22–33, on a fresh disposable fake ship
(`--loom 32`, `%zuse 408`, Vere 4.6) running this checkout. The first audit
(2026-11-25, checkout `bfcfcb4`) found five gaps. **All five are closed.
Every user-facing Quiz operation now has a workbench route.** What remains
without one are programming and operator interfaces, listed under
[remaining limits](#remaining-limits).

“Accessible” here means a visible control or the supported source editor.
Calling `window.quiz` from a browser console, sending an HTTP request, or
poking Gall does not count as a user-facing route. Source-level property
features need not have individual buttons: entering them in a document and
running that document is a valid workbench workflow.

## Capability inventory

The inventory covers the public contracts in [reference](../../desk/doc/reference.md),
[source format](../../desk/doc/source-format.md),
[agent API](../../desk/doc/agent-api.md),
[HTTP API](../../desk/doc/http-api.md), and
[suite/replay contracts](../../desk/doc/suites-and-replay.md). The last
column names the browser test that exercises the route; `doubles` is the
deterministic scenario suite in [run-scenarios.js](run-scenarios.js).

| Capability | Workbench route | Finding | Exercised by |
| --- | --- | --- | --- |
| Draft property execution | Editor → Run draft property | Available | `examples.spec.js`, `runs.spec.js` |
| Saved property execution | Open property → Saved property → Run | Available | `examples.spec.js` (every bundled property) |
| Saved suite execution | Open suite → Saved suite → Run | Available, including suites outside the index | `runs.spec.js`, `workbench.spec.js` |
| Suite discovery and selected/all arms | Discover suite arms; Suite arms field | Available | `runs.spec.js` |
| All nine property arms | Editor: `fate`, `norn`, `alts`, `conf`, `cover`, `cover-table`, `confidence`, `within`, `expect` | Available through source | `examples.spec.js` |
| Supported Ford imports | Editor: `/-`, `/+`, `/=`, `/*` | Available through source against the selected context | `examples.spec.js` |
| Generators, shrinkers, combinators, size control, dependent and coordinated shrinking | `quiz-gen` imports | Available through source | `examples.spec.js` |
| Type-directed defaults | Omit `norn`/`alts`, or import `quiz-auto` | Available | `examples.spec.js` (34) |
| Generated functions | `quiz-fun` imports | Available through source | `examples.spec.js` (23, 24) |
| Pure agent harness and simulated clock | `quiz-harness` and fixture imports | Available through source | `examples.spec.js` (25, 26, 32, 33) |
| Reports, notes, expected/actual, labels and tables | `quiz-prop` imports; result pane | Available | `examples.spec.js`, doubles |
| Coverage modes, observed vs established decisions, expected failures | Property arms; Coverage in the result pane | Available | `examples.spec.js` (12, 14, 28, 35), doubles |
| All engine configuration fields, including all 12 bounds | Edit `++conf` | Available through source | `examples.spec.js` |
| One-off overrides on an unchanged saved property | Run panel and More limits: all nine patch fields, seed | Available | `guide.spec.js`, `runs.spec.js`, `examples.spec.js` |
| Ship-wide call/build/suite CPU limits | Settings | Available | `workbench.spec.js`, `guide.spec.js` |
| Per-document limit and timeout policy | `++within` and `++conf` | Available through source | `examples.spec.js` (27, hanging specs) |
| Preview count, all four verdict/alternate combinations, preview summary | Preview controls; Preview summary | Available | `examples.spec.js`, `guide.spec.js`, doubles |
| Smallest passing example for each label | Find examples for each label | Available | `examples.spec.js`, doubles |
| Desk and numeric revision selection | Run panel, Clay source, Use latest revision | Available; the revision-selection race is fixed | `guide.spec.js`, doubles |
| Date and named-label revision selection | Pinned revision field | Available in the run panel; Clay source stays numeric | `guide.spec.js` |
| Cancellation, rerun, exact property replay | Result buttons | Available; suites, previews and example searches cannot exact-replay by design | `runs.spec.js` |
| Counterexample as a regression suite | Save as regression | Available for property runs with a counterexample | `runs.spec.js`, doubles |
| History, status, counters, effective settings and source snapshot | History and result pane | Available | `runs.spec.js` |
| Counterexamples and shrink trace, step by step | Result pane; Shrink trace | Available within `trace-steps` | `examples.spec.js`, doubles |
| All outcome details and complete record export | Record view, Download record, Copy sample noun; Error cause beside retained evidence | Available | `runs.spec.js` |
| Delete one completed record; clear completed history | Delete record; Clear completed history | Available; queued and active runs are kept | `guide.spec.js` |
| Create/open/edit/save/copy/delete work files | Editor, file chooser, explorer context menu | Available | `workbench.spec.js`, `guide.spec.js` |
| Bundled properties and suites | Examples explorer | Available: 41 properties and three suites | `examples.spec.js` |
| Indexed properties and suites on other local Clay contexts | Clay source → Browse revision | Available; any `quiz-engine` import face | `workbench.spec.js`, `guide.spec.js` |
| General Clay Hoon files and arbitrary external suites | Open → clay | Available at the context browsed in Clay source | `workbench.spec.js` |
| Browser persistence, dirty protection, shortcuts, reference panes, Vim and Hoon mode | urui controls | Available; representative interaction coverage | `workbench.spec.js`, `guide.spec.js`, shortcut checks |
| Help | Help/Documentation | Fallback available; rendered `%docs` needs a ship with `%docs` | `help.spec.js` |

Library availability is established by the supported import path, source
contracts and representative bundled examples. This audit does not claim
that each individual helper received a new unit test.

## Closed gaps

| Gap found at `bfcfcb4` | Closed by | Now |
| --- | --- | --- |
| Revision-selection race: an explorer refresh after Save As voided **Use latest revision**, inspection and discovery replies | Unit 22 | Each request has its own generation guard. The guide's "wait for refresh" workaround is gone. |
| No history deletion or clearing | Unit 23 | HTTP `delete` and `clear`; **Delete record** and **Clear completed history**. A queued or active run is refused with 409 `run-unfinished`. |
| **Open → clay** sent a bare `["clay"]` scope; the index needed the exact `engine=` face | Unit 24 | A quiz-owned transport sends the context browsed in Clay source; the index accepts any `quiz-engine` face and lists suites. No urui copy changed. |
| Five patch fields, the `(false, true)` preview and `da`/`tas` revisions unreachable | Unit 25 | **More limits** sets attempts, drops and duplicates budgets, on-timeout and every bound; four preview presets; dates and labels in the run panel. |
| Incomplete record inspection; a shrinker error hidden behind the earlier counterexample | Unit 26 | Record view (request, timestamps, snapshot), **Download record**, **Copy sample noun**; **Error cause** shown beside retained evidence. |

Units 27–33 added workbench routes for new capabilities in the same change:
preview summary (27), step-by-step shrink trace (28), labelled examples
(29–30), established coverage (31), and **Save as regression** (33). Unit 32
changed only documentation and examples.

## Remaining limits

- **Programming and operator interfaces.** Gall subscriptions and scries,
  desk installation, agent lifecycle, the standalone `+quiz` generator and
  Dojo `-test` have no workbench control. The browser polls history instead
  of subscribing.
- **Rendered Help.** Rendered `%docs` tabs need `%docs` installed. The test
  ship lacks it, so `help.spec.js` skips that test; fallback Help passes.
- **Clay source browsing is numeric.** Dates and labels apply to the run
  panel only. Choosing a desk without **Browse revision** does not change the
  context **Open → clay** uses.
- **Regressions save into `%quiz`.** A regression of a property pinned to
  another desk has to be copied into that desk's tests.
- **Replay** covers property runs only; suites, previews and example
  searches are refused by design.
- **The Open → clay chooser is flat** and lists every Hoon file of the
  chosen desk; `%base` is long.

## Validation evidence

| Fresh check | Result |
| --- | --- |
| `-test /=quiz=/tests ~` | 561 arms, `ok=%.y` |
| Workbench doubles | 5 scenarios passed |
| Complete repository Playwright suite | 72 passed, 1 skipped, 0 failed; 7.7 minutes (after the two fixes below) |
| Example counters against [examples.md](../../desk/doc/examples.md) | 40 of 40 recorded rows match (seed `0v123`, no overrides); 27 has no counters and passes in Playwright |
| urui copies against the pinned obelisk revision | Identical, except the two documented `chords.js` and `shortcut-conflicts.test.js` changes |
| `node --check`, `git diff --check`, desk symlinks, relative links | Clean |

The skipped Playwright test requires installed, rendered `%docs`. The main
suite executes all 41 property examples and three suites, including the
hanging-property examples in their separate timeout tests.

The fresh ship exposed two test defects in `guide.spec.js`, both fixed: the
clipboard permission was granted only to port 8092, and the date revision
was midnight UTC, before a desk created that day. An earlier full run lost
the serf in the `%discard` hanging spec despite `--loom 32` (Vere 4.6; see
[the browser-test README](README.md)); after a restart every test passed.

## Scope and reproduction

Run the commands in [the browser-test README](README.md) on a disposable
fake ship. Never use a production ship. Testing uses Chromium on Linux.
Other browsers, every Ace command, assistive technology, all possible
property programs and every internal engine/library arm are outside this
audit. The earlier [guide validation](cod-ug-validation.md) is kept as the
historical record of the first audit's evidence.
