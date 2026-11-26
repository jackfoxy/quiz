# Document workbench

Open `/apps/quiz/` after signing in to your ship. Use **+** for a new
property document. The Hoon editor provides syntax highlighting, search,
undo and redo; Settings also offers Vim keys.

**Settings** also holds **Quiz CPU time limits**, in seconds: **Property call**
(default 10), **Draft build** (30) and **Suite arm** (60). They are ship-wide,
stored by `%quiz`, and apply to every run from the next slice, build or arm.
They save when the Settings dialog closes. A call that exceeds its limit ends the
run as **interrupted**. A property document's `++within` can lower its own
property call limit below the Settings value, never raise it.

**My documents** stores your Hoon and Markdown files under `/data/quiz` on
the installed desk. **Open**, **Save**, and **Save As** use the file chooser;
choose `hoon` or `md` when saving. Ctrl-S, Ctrl-Shift-S and Alt-O invoke
these actions. Closing or reopening an edited tab asks before discarding
changes. Leaving the page prompts when the browser permits it.

**Examples** contains passing property documents (`props`), intentional
failures (`failing`), and existing test suites (`examples`). Property documents
default to saved-property execution; suites default to saved-suite execution.
See the [example catalog](examples.md) for expected outcomes. **Documentation** contains
these reference files. Both are read-only. **Open editable copy** creates
an unsaved tab; save it in My documents to keep your version.

**Clay source** lists the property documents and suites on a local desk at
an explicit revision. A property document imports `quiz-engine` on a `/+`
prelude line, under any face, and declares a `++  fate` arm at the start of a
line; otherwise a file with a `++  test-` arm at the start of a line is listed
as a suite. Select a desk, enter a positive decimal revision, then choose
**Browse revision**. The revision is pinned: changing files does not change
that view. Select a file to read it or make an editable copy. An unavailable
revision reports an error. The Open chooser's `clay` location lists every
Hoon file at the context last browsed in Clay source, so browse there first
to choose the desk and revision. A Clay tab runs as a saved suite when it has
a `++  test-` arm and no `++  fate`, and as a saved property otherwise.

Tabs, unsaved text, selections, pane layout and the last browsed Clay
context are saved in this browser's local storage. Clearing browser data
removes unsaved work. Saved files remain in Clay. A restored tab keeps its
buffer; explicitly reopening it reloads the saved file and protects dirty
edits with a confirmation.

Choose a source workflow in each tab's run controls:

- **Draft property** runs the current editor buffer. Imports use the selected
  desk and immutable revision.
- **Saved property** and **Saved suite** run the file at that desk/revision.
  **Pinned revision** takes a number, a date (`~2026.11.25`, or with
  `..12.00.00`) or a label; a date or label resolves to the numeric revision
  current when the run is built, which the result shows as its context
  beside the requested revision. An unknown label ends the run `invalid`
  with `revision-unavailable`.
  Unsaved edits are excluded. Saving does not advance the selected revision;
  choose **Use latest revision** to run the newly saved version.
- Examples default to saved suites. Clay tabs use their displayed context.
  **Discover suite arms** lists available arms. Leave arms blank for all, or
  enter exact names separated by commas or whitespace.

Blank requested checks, seed, first and largest sample size, and **Repeated
samples** follow the document's `conf`; absent settings use engine defaults and
a newly recorded seed. **Read document conf** previews those settings.
Overriding any of these fields preserves every other document budget. A seed
uses Hoon `@uv` notation, for example `0v123`. A largest size of 0 removes the
cap. **Repeated samples** chooses the
[duplicates policy](reference.md#default-generation-size-and-duplicates):
skip a repeated mug, skip only an equal sample, or evaluate every sample.
**More limits** folds away the other configuration fields: the attempts,
drops and duplicates budgets, **On timeout**, and each of the twelve bounds.
Blank keeps the document's value. A bounds override sends a complete
`bounds`, so setting any bound reads the document's conf once (one build) to
fill the others; the other fields need no build. Suite execution has no
controlled seed or property sample counters; those controls are disabled.

**Find examples for each label**, beside **Preview samples**, runs a
[labelled-example search](reference.md#labelled-examples) over **Find
examples over passing samples** passes (blank means 100; at most the
conf's `requested-max`). The result lists each label's smallest example,
its weight, shrink steps, candidates tried and how its shrink ended
(smallest found, shrink limit reached, or not shrunk because a failure ended
the search). It also lists `++cover` labels no passing sample carried, and
says which budget ended generation early. A failure that ended the search
appears as an ordinary counterexample. Searches cannot be replayed.

**Preview samples** shows what the generator makes before a run, as
QuickCheck's `sample` does. It makes up to **Preview samples** (1–1000,
blank = 20) samples with the run's seed, sizes and generator, so each row is
the sample a run would make at that position; the first 100 are listed. A
**Generator summary** above the rows covers every sample: size and jammed
byte length (minimum, median, maximum, and bytes in power-of-two buckets),
repeats a run would skip, and, with verdicts, each verdict's and label's
share. It notes when half or more of the samples were discarded or repeat. **Preview shows** chooses how much
else to show: the default, *Samples, verdicts and shrink candidates*, also
runs the fate on each sample and shows its verdict and labels, then the first
sample's shrink candidates, each marked lighter or not; *Samples and
verdicts* leaves out the candidates; *Samples and shrink candidates* runs no
fate but shows the candidates; *Samples only* runs no fate. The result
is a table of Size, Sample, Verdict, Labels and Repeat ("skipped by a run"
where the duplicate policy would skip it), followed by **First sample's
shrink candidates**. Requested checks are ignored; suites cannot be
previewed. A preview is kept in history like a run; it cannot be replayed,
and **Rerun request** previews again. See the
[reference](reference.md#generator-preview).

Results show only confirmed server status, effective configuration and seed,
counters, diagnostics, and original/shrunk counterexamples. A property run
also shows **Call limit: N ms per call**, the limit its last slice ran under. Under the
counterexample, a collapsed **Shrink trace** shows the retained trace as
steps: one alts call on the best sample, its weight and candidate count, and
each candidate tried, with its weight, outcome (still fails, passed, dropped,
other failure, not lighter, seen), the reason in words and its rendered text
where the engine computed one. A rejected heavier candidate names the
strict-weight rule. The view opens on the last step, which says why
shrinking stopped; **First**, **Previous**, **Next** and **Last** move
between steps, and **Accepted path only** lists each accepted candidate with
the weight it replaced. Select a history
entry to inspect it. **Cancel selected run** requests cancellation at the next
server boundary. **Rerun request** submits the original request again (including
its pinned revision and any explicit seed); **Replay exact property** reuses
the captured source, effective configuration and seed. Suites cannot replay.
An error after a counterexample, such as a crashing shrinker, shows its
**Error cause** above the retained counterexamples and their failure. The
**Record** disclosure shows the submitted request, created, updated and
finished times, and each counterexample's jammed noun (`@uv`); **Download
record** saves the whole record as JSON (the HTTP `status` reply) and **Copy
sample noun** copies the shrunk sample's jam.
**Delete record** removes the selected completed run and **Clear completed
history** removes every completed run; both ask for confirmation in the page.
Queued and active runs are never deleted. Tabs forget deleted runs, and a
replay whose original is gone says so.

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
reconnection. History refreshes every second while a run is unfinished and
every 30 seconds once all are done; **Refresh history** shows runs started
elsewhere at once. A hidden page does not poll and refreshes when shown. **Cancel** waits for the current Hoon call to return. A call
that never returns hits its CPU limit, or can be stopped with Ctrl-C in the
Vere terminal; the result shows **interrupted**, with the stage, any
counterexample found so far, and the suite arm. See
[aborted events](agent-api.md#aborted-events-and-interrupted).

Help includes a short offline summary. Install `%docs` for the full help
site and reference.
