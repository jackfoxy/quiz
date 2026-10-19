# AGENTS.md

Guidance for agents working in this repository. Quiz is a property-testing
library for Hoon plus a Gall application: `%quiz` runs property and suite jobs,
`%quiz-web` serves a urui workbench at `/apps/quiz/`. The desk targets
`[%zuse 408]`.

Start with [llms.txt](llms.txt) for the documentation index. Contracts live in
`desk/doc/`; this file covers ownership, rules and contributor commands.

## Repository map

| Path | Contents | Owner |
| --- | --- | --- |
| `desk/lib/quiz.hoon`, `desk/gen/quiz.hoon` | Legacy library and `%say` generator | **Frozen** |
| `desk/tests/lib/quiz.hoon`, `desk/tests/lib/quiz-legacy.hoon` | Legacy behaviour pins | **Frozen** |
| `desk/lib/quiz-engine.hoon` | Resumable stepper, classification, bounded shrinking, limits | quiz |
| `desk/lib/quiz-build.hoon` | Property document prelude, pinned Clay context, type checks | quiz |
| `desk/lib/quiz-suite.hoon`, `desk/lib/quiz-replay.hoon` | `test-*` suite runner; replay capture | quiz |
| `desk/lib/quiz-job.hoon` | Pure FIFO queue, slices, cancellation, retention, reload | quiz |
| `desk/lib/quiz-agent.hoon`, `desk/app/quiz.hoon` | `%quiz` Gall adapter and export | quiz |
| `desk/lib/quiz-json.hoon`, `desk/lib/quiz-web-agent.hoon`, `desk/app/quiz-web.hoon` | HTTP codec and `%quiz-web` | quiz |
| `desk/lib/quiz-web.hoon`, `desk/lib/quiz-files.hoon`, `desk/web/quiz*.js`, `desk/web/ace/mode-hoon.js` | Workbench config, file roots, client code, Hoon Ace mode | quiz |
| `desk/sur/quiz-app.hoon`, `desk/mar/quiz/` | Public types and marks | quiz |
| `desk/sur/urui.hoon`, `desk/lib/urui-*.hoon`, `desk/tests/lib/urui-files.hoon`, `desk/web/ace/` (except `mode-hoon.js`), `tests/browser/doubles/`, `tests/browser/ace-win-linux-shortcuts.json` | urui framework copies | **urui** |
| `desk/lib/{default-agent,skeleton,dbug,server,docket,test}.hoon`, `desk/sur/docket.hoon`, most of `desk/mar/` | Vendored `%base`/neighbour support | vendored |
| `desk/examples/props/`, `desk/examples/failing/` | Passing and intentionally failing property documents | quiz |
| `desk/tests/examples/` | Original tutorial, boxcar and Euler suites (all pass) | quiz |
| `desk/fixtures/` | Inputs used by builder and replay tests | quiz |
| `desk/doc/*.md`, `desk/doc.toc` | User and contract documentation, served as Help | quiz |
| `tests/browser/` | Doubles scenarios and Playwright specs | quiz (except copies) |
| `blogpost.md` | Original blog post; historical source material | **Frozen** |

The [internal implementation map](desk/doc/reference.md#internal-implementation-map)
lists each module's entry points.

## Rules

- **Hoon style.** Follow the `hoon-style-guide` skill when writing Hoon. Match
  the surrounding code: lowercase-hyphen names; two-space indentation; lines
  of at most 80 columns; an empty `::` line before each `++` arm; arm and core
  header comments indented one gap inside the arm; `^-` casts on gate
  products; wide form only when the whole expression fits on one line.
- **Frozen legacy.** Never change the frozen files above. App semantics belong
  in `quiz-engine`; [legacy and app semantics](desk/doc/reference.md#app-and-legacy-semantics-compared)
  differ on purpose.
- **Engine version.** Any change to deterministic generation, evaluation,
  shrinking or defaults must bump `++version` in `desk/lib/quiz-engine.hoon`.
  Replay refuses records from another version.
- **Durable state.** `state-0` in `desk/sur/quiz-app.hoon` holds nouns and
  text only, never vases, compiled gates or RNG cores. Changing `state-0` or
  `record` needs a new versioned state and an `on-load` migration; none exists
  yet.
- **Containment.** Evaluated user code runs under `mong` with a refusing scry
  gate. Dependency reads use asynchronous `%warp`, not build scries: a failed
  `%ca` scry can escape Gall's virtualization. There is no hard timeout; do not
  claim one.
- **urui copies.** Never edit a urui copy here. Make the change in the urui
  repository, test it there, re-copy every changed file by hand, and update the
  pinned revision below. There is no sync manifest.
  Pinned urui revision: `fba9f973e234594bb17efcf7c74c6480e511c1e5`.
- **No secrets or machine paths** in committed files. Use `<pier>`, `<vere>`
  and `QUIZ_*` environment variables as placeholders.
- **Disposable ships only.** Develop and test on a fake ship. Never install on,
  or run browser mutation tests against, a live ship.

## Commands

This section is the canonical contributor command reference. End-user
installation is in [README.md](README.md#installation); browser test setup and
commands are in [tests/browser/README.md](tests/browser/README.md).

Boot a disposable fake ship on `%zuse 408` (for example `<vere> -F zod`), then
install the desk as the README describes. To iterate after editing:

```sh
rsync -a --delete desk/ <pier>/quiz/
```

```dojo
|commit %quiz
```

`cp -RL desk/. <pier>/quiz/` also works but leaves deleted files in the mount.
Installed agents rebuild and reload on commit; reload cancels in-flight jobs
with reason `%reload`.

Hoon tests, from Dojo:

```dojo
-test /=quiz=/tests ~
-test /=quiz=/tests/lib/quiz-engine ~
-test /=quiz=/tests/app ~
-test /=quiz=/tests/examples ~
```

The first runs every regression arm and must report `ok=%.y`. Point `-test`
at one file or directory for a faster loop.

JavaScript syntax, from the repository root:

```sh
node --check desk/web/quiz.js
node --check desk/web/quiz-runs.js
for f in tests/browser/*.js; do node --check "$f"; done
```

urui drift check, with the urui repository checked out at `../urui`:

```sh
rev=fba9f973e234594bb17efcf7c74c6480e511c1e5
for f in desk/sur/urui.hoon desk/lib/urui-*.hoon \
    desk/tests/lib/urui-files.hoon desk/web/ace/README.md \
    desk/web/ace/license.txt desk/web/ace/ace.js desk/web/ace/ext-*.js \
    desk/web/ace/keybinding-vim.js desk/web/ace/theme-*.js \
    tests/browser/ace-win-linux-shortcuts.json tests/browser/doubles/*; do
  git -C ../urui show "$rev:$f" | cmp -s - "$f" || echo "drift: $f"
done
```

No output means all 27 copies match the pin. Compare against the pinned
revision, not the urui working tree, which may have moved ahead.

Also run `git diff --check` and `find desk -type l` (expect no symlinks).

## Documentation maintenance

- `desk/doc/*.md` is the single source for both the repository and in-app
  Help. Add every new page to `desk/doc.toc`. Use relative links only.
- Authorities: [reference.md](desk/doc/reference.md) for public contracts,
  [agent-api.md](desk/doc/agent-api.md) for the Gall interface,
  [http-api.md](desk/doc/http-api.md) for the HTTP wire, and
  [source-format.md](desk/doc/source-format.md) for property documents.
  Update the authority in the same change as the code.
- [examples.md](desk/doc/examples.md) and the user's guide quote recorded
  counters. Re-run the affected examples after any engine or example change
  and update the numbers.
- The fallback help in `desk/lib/quiz-web.hoon` is a short summary. Keep its
  shortcut list in step with `desk/doc/keyboard-shortcuts.md` and the
  configured shortcuts.
- Keep this file, [CLAUDE.md](CLAUDE.md), [llms.txt](llms.txt) and the
  skills in `.claude/skills/` in step with the tree.
