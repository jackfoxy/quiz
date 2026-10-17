# About Quiz

Quiz 0.1.0 provides randomized property testing for Hoon and a document
workbench for authoring properties and running existing Clay suites.
The `%quiz` agent owns execution and history; `%quiz-web` serves the workbench.
The desk targets `%zuse 408`. Its application engine is `%quiz-engine-1`.

Copyright 2026 Jack Fox. Quiz uses the **MIT+n** license; read the
[complete license](https://github.com/jackfoxy/quiz/blob/dev/LICENSE) for its
terms. Vendored components retain their own notices.

- [Source repository](https://github.com/jackfoxy/quiz)
- [Report an issue](https://github.com/jackfoxy/quiz/issues)
- [User's guide](users-guide.md)
- [Reference](reference.md)
- [Examples](examples.md)

For a reproducible property issue, retain the exact source/import revision,
effective configuration and seed, engine version, diagnostics and original
and shrunk counterexamples. Avoid posting private source from run snapshots.

## Prior work and interface

The frozen Quiz library is inspired by QuickCheck. The user's guide draws
practical testing ideas from [FsCheck](https://fscheck.github.io/FsCheck/),
with page-specific citations and an explicit list of unsupported facilities.
Quiz has its own Hoon contracts and run semantics.

The workbench uses the shared urui shell, file dialogs, document/session
machinery and help tabs. Shipped Markdown opens as read-only source;
a Markdown-capable `%docs` app supplies rendered help pages.

## Ace editor

The editor bundles **Ace 1.44.0**, copyright 2010 Ajax.org B.V., under its BSD
license. The [bundled Ace license](../web/ace/license.txt) also has a local
application URL, `/apps/quiz/ace/license.txt`.
Settings selects the default or Vim keymap; see
[Keyboard shortcuts](keyboard-shortcuts.md).
