# Document workbench

Open `/apps/quiz/` after signing in to your ship. Use **+** for a new
property document. The Hoon editor provides syntax highlighting, search,
undo and redo; Settings also offers Vim keys.

**My documents** stores your Hoon and Markdown files under `/data/quiz` on
the installed desk. **Open**, **Save**, and **Save As** use the file chooser;
choose `hoon` or `md` when saving. Ctrl-S, Ctrl-Shift-S and Ctrl-O invoke
these actions. Closing or reopening an edited tab asks before discarding
changes. Leaving the page prompts when the browser permits it.

**Examples** contains the bundled test suites. **Documentation** contains
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

Help includes a short offline summary. Install `%docs` for the full help
site and reference. Property execution controls and results are added in
the next workbench unit.
