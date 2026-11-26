# Quiz workbench access audit

Audited 2026-11-25 against checkout `bfcfcb4` and the running disposable
fake ship. **Not all of Quiz's public functionality is accessible through
the urui workbench: several operations and request combinations have no UI
route.**

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
[suite/replay contracts](../../desk/doc/suites-and-replay.md).

| Capability | Workbench route | Finding |
| --- | --- | --- |
| Draft property execution | Editor → Run draft property | Available |
| Saved property execution | Open property → Saved property → Run | Available for files the UI can open |
| Saved suite execution | Open suite → Saved suite → Run | Available for files the UI can open; general Clay browsing is broken |
| Suite discovery and selected/all arms | Discover suite arms; Suite arms field | Available |
| All nine property arms | Editor: `fate`, `norn`, `alts`, `conf`, `cover`, `cover-table`, `confidence`, `within`, `expect` | Available through source |
| Supported Ford imports | Editor: `/-`, `/+`, `/=`, `/*` | Available through source against the selected context |
| Default and custom generators/shrinkers | Source imports and property arms | Available |
| Generator combinators, containers, size control, dependent and coordinated shrinking | `quiz-gen` imports | Available through source |
| Type-directed defaults | Omit `norn`/`alts`, or import `quiz-auto` | Available |
| Generated functions | `quiz-fun` imports | Available through source |
| Pure agent harness and simulated clock | `quiz-harness` and fixture imports | Available through source |
| Reports, notes, expected/actual, labels and tables | `quiz-prop` imports; result pane | Available |
| Coverage warning/check/confidence/table modes and expected failures | Property arms; result pane | Available |
| All engine configuration fields, including all 12 bounds | Edit `++conf` | Available through source |
| One-off overrides on an unchanged saved property | Run panel | Partial: four of nine configuration patch fields; seed also available |
| Ship-wide call/build/suite CPU limits | Settings | Available |
| Per-document limit and timeout policy | `++within` and `++conf` | Available through source |
| Preview count and independent verdict/alternate flags | Preview controls | Partial: three of four flag combinations |
| Desk and immutable numeric revision selection | Run panel and Clay source | Available, with the revision-selection race described below |
| Date and named-label revision selection | No control | Missing |
| Cancellation, rerun, exact property replay | Result buttons | Available; suite/preview replay is intentionally unsupported by the engine |
| History, status, counters, effective settings and source snapshot | History and result pane | Available |
| Counterexamples and bounded shrink trace | Result pane | Available |
| All outcome details and complete record export | Result pane | Partial |
| Delete one completed record; clear completed history | No control or HTTP operation | Missing; Gall only |
| Create/open/edit/save/copy/delete work files | Editor, file chooser, explorer context menu | Available; work-file deletion is distinct from run-history deletion |
| Bundled properties and suites | Examples explorer | Available: 35 properties and three suites |
| Indexed properties on other local Clay contexts | Clay source → Browse revision | Available |
| General Clay Hoon files and arbitrary external suites | Open → clay | Broken context handoff |
| Browser persistence, dirty protection, shortcuts, reference panes, Vim and Hoon mode | urui controls | Available; representative interaction coverage |
| Help | Help/Documentation | Fallback available; rendered `%docs` requires separate validation |

Library availability is established by the supported import path, source
contracts and representative bundled examples. This audit does not claim
that each individual helper received a new unit test.

## Confirmed gaps

### Completed-history maintenance

[`quiz-app`](../../desk/sur/quiz-app.hoon) defines `%delete` and `%clear`.
[`quiz-json`](../../desk/lib/quiz-json.hoon) has neither command, and
[`quiz-runs.js`](../../desk/web/quiz-runs.js) creates only Refresh, Cancel,
Rerun and Replay result actions. The browser guide test verifies HTTP
refusal. The missing work is authenticated HTTP routing plus visible
controls that preserve queued/active work.

### General Clay browsing

The Clay source index only discovers documents with the exact
`engine=quiz-engine` prelude import and a textual `++  fate` declaration.
Properties using a different alias and arbitrary suite cores need general
file browsing. After choosing and browsing a context, **Open → clay** still
sends `scope: ["clay"]`; the server requires `["clay", desk, revision]` and
returns `select a desk and revision`.

The [workbench documentation](../../desk/doc/workbench.md) says selecting a
context first is sufficient. The implementation does not fulfill that
claim. Opening a path programmatically in a test does not demonstrate that
a user can reach it through the chooser. The repair must respect the
repository's urui ownership rule.

### Request options

The Run panel sets `requested`, `size-start`, `size-max`, and `duplicates`.
It cannot override `attempts-max`, `drops-max`, `duplicates-max`, `bounds`,
or `on-timeout` for an unchanged saved property. Editing `++conf` provides
the engine functionality but changes the source being tested.

Preview presets cover `(verdicts, alts)` values `(true, true)`,
`(true, false)`, and `(false, false)`. The API's `(false, true)` combination
cannot be selected. Date (`da`) and named-label (`tas`) revision selectors
are also absent; `requestFor` always constructs a numeric `ud` revision.

### Complete result inspection

The full record includes submitted request data, timestamps and jammed
sample nouns that the pane does not expose completely. There is no result
download control; document Copy copies source text.

In `renderDetail`, an outcome with retained evidence renders `proof.why`;
the top-level `outcome.why` is rendered only in the `else` branch. A
shrinker error can therefore hide its own cause behind the earlier
counterexample. This finding is established by source inspection; the
fresh browser run does not deliberately induce that error.

### Revision-selection race

The earlier [guide validation](cod-ug-validation.md) reproduced a successful
**Use latest revision** reply being ignored during explorer refresh after
Save As. Explorer change events invalidate the same inspection generation
used by `latest()`. The current client still contains that path.

Until repaired, wait for explorer refresh to finish, select the latest
revision, and verify the visible `Selected` confirmation. The earlier
reproduction is historical evidence; this audit does not count it as a new
reproduction. Configuration inspection and suite discovery use the same
generation guard, but those variants have not been separately reproduced.

## Validation evidence

| Fresh check | Result |
| --- | --- |
| Complete repository Playwright suite | 60 passed, 1 skipped, 0 failed; 7.5 minutes |
| Visible explorer and Clay chooser checks | 2 passed: all 38 bundled files open by clicking; the missing Clay context is reproduced |
| Additional preview, size/repeat and Markdown-file checks | 3 passed: samples-only/verdict-only previews, exact-repeat and size overrides, visible Markdown save/open/delete |
| Workbench doubles using the fetched deployed bundle | 5 scenarios passed |
| Shortcut policy/conflict checks | 9 passed |
| Report links, whitespace and desk symlinks | Links resolve; `git diff --check` passes; no desk symlinks |

The skipped test requires installed, rendered `%docs`. The fake ship does
not have it; fallback Help passes. The main suite executes all 35 property
examples and three suites, including the hanging-property example in its
separate timeout test. The additional navigation check clicks every
bundled explorer row, avoiding the programmatic-open shortcut used by some
execution tests.

The supplemental checks are temporary audit tests derived from the earlier
guide checks, plus a new visible Markdown save/open/delete exercise. They
do not modify the committed test suite or application. Test-created work
files are cleaned up; run history remains on the disposable ship.

The served bundle contains the checkout's exact `quiz.js` and
`quiz-runs.js` texts. The mounted engine is not byte-identical to this
checkout: four implementation files differ in comments or the rename of
the `legacy=quiz` import face to `quiz`; test files also changed. These
differences were inspected. Live results describe the installed engine
`%quiz-engine-13`, while the capability inventory also inspects current
checkout sources. No fresh deployment or full Hoon regression run is
claimed.

## Scope and reproduction

Run the commands in [the browser-test README](README.md) on a disposable
fake ship. Never use a production ship. The committed
[`guide.spec.js`](guide.spec.js) includes checks for the history and budget
gaps. To reproduce the Clay failure manually, browse a valid revision in
Clay source, open the file chooser, and select its clay location.

Gall subscriptions/scries, desk installation, agent lifecycle, the
standalone `+quiz` generator and recursive Dojo `-test` are programming or
operator interfaces. The workbench provides neither a Dojo terminal nor
direct controls for those interfaces. Library code can be called from
editable properties or suites where its types and sandbox allow it.

Testing uses Chromium on Linux. Other browsers, every Ace command,
assistive technology, all possible property programs and every internal
engine/library arm are outside this audit. No application implementation,
frozen library or urui copy was changed.
