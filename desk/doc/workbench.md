# Document workbench

Open `/apps/quiz/` after signing in to your ship. Use **+** for a new
property document. The Hoon editor provides syntax highlighting, search,
undo and redo; Settings also offers Vim keys.

**Settings** also holds **Quiz CPU time limits**, in seconds: **Property call**
(default 10), **Draft build** (30) and **Suite arm** (60). They are ship-wide,
stored by `%quiz`, and apply to every run from the next slice, build or arm.
Choose **Save limits** to apply them. A call that exceeds its limit ends the
run as **interrupted**.

**My documents** stores your Hoon and Markdown files under `/data/quiz` on
the installed desk. **Open**, **Save**, and **Save As** use the file chooser;
choose `hoon` or `md` when saving. Ctrl-S, Ctrl-Shift-S and Ctrl-O invoke
these actions. Closing or reopening an edited tab asks before discarding
changes. Leaving the page prompts when the browser permits it.

**Examples** contains passing property documents (`props`), intentional
failures (`failing`), and existing test suites (`examples`). Property documents
default to saved-property execution; suites default to saved-suite execution.
See the [example catalog](examples.md) for expected outcomes. **Documentation** contains
these reference files. Both are read-only. **Open editable copy** creates
an unsaved tab; save it in My documents to keep your version.

**Clay source** lists Hoon files on a local desk at an explicit revision.
Select a desk, enter a positive decimal revision, then choose **Browse
revision**. The revision is pinned: changing files does not change that
view. Select a file to read it or make an editable copy. An unavailable
revision reports an error. The Open chooser's `/clay` location requires a
context; use the Clay source view to choose that context.

Tabs, unsaved text, selections, pane layout and the last browsed Clay
context are saved in this browser's local storage. Clearing browser data
removes unsaved work. Saved files remain in Clay. A restored tab keeps its
buffer; explicitly reopening it reloads the saved file and protects dirty
edits with a confirmation.

Choose a source workflow in each tab's run controls:

- **Draft property** runs the current editor buffer. Imports use the selected
  desk and immutable revision.
- **Saved property** and **Saved suite** run the file at that desk/revision.
  Unsaved edits are excluded. Saving does not advance the selected revision;
  choose **Use latest revision** to run the newly saved version.
- Examples default to saved suites. Clay tabs use their displayed context.
  **Discover suite arms** lists available arms. Leave arms blank for all, or
  enter exact names separated by commas or whitespace.

Blank requested checks and seed follow the document's `conf`; absent settings
use engine defaults and a newly recorded seed. **Read document conf** previews
those settings. Overriding requested checks preserves every other document
budget. A seed uses Hoon `@uv` notation, for example `0v123`. Suite execution
has no controlled seed or property sample counters; those controls are disabled.

Results show only confirmed server status, effective configuration and seed,
counters, diagnostics, and original/shrunk counterexamples. Select a history
entry to inspect it. **Cancel selected run** requests cancellation at the next
server boundary. **Rerun request** submits the original request again (including
its pinned revision and any explicit seed); **Replay exact property** reuses
the captured source, effective configuration and seed. Suites cannot replay.

Each result includes its immutable source hash, context and expandable exact
source. **Source tab** returns to the associated document; edits mark its
results stale without changing their snapshots. Closed/unlinked tabs and
pruned records are labelled explicitly. Per-tab controls, run associations and
the selected result survive browser reload in local storage. The server owns
retained history; unfinished work is cancelled on agent reload.

Missing/deleted saved files, unavailable contexts and compile failures report
diagnostics. Empty history explains how to start. A connection failure keeps
last confirmed results and disables mutations until a successful refresh.
Requests are never retried automatically: a lost admission reply may still
have created a run, so inspect history before retrying. Polling continues after
reconnection. **Cancel** waits for the current Hoon call to return. A call
that never returns hits its CPU limit, or can be stopped with Ctrl-C in the
Vere terminal; the result shows **interrupted**, with the stage, any
counterexample found so far, and the suite arm. See
[aborted events](agent-api.md#aborted-events-and-interrupted).

Help includes a short offline summary. Install `%docs` for the full help
site and reference.
