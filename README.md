![Quiz logo](logo.png)

# Quiz

Property testing for Hoon, with an editable document workbench and a runner for
existing Clay test suites. Generate inputs, inspect failures and smaller
counterexamples, then replay a property with its recorded seed and source.

- [User's guide: seven steps](desk/doc/users-guide.md)
- [Reference: contracts, limits and legacy differences](desk/doc/reference.md)
- [Examples and recorded results](desk/doc/examples.md)
- [Keyboard shortcuts](desk/doc/keyboard-shortcuts.md)

## Installation

Use an Urbit development ship running `%zuse 408`. The packaged desk includes
both `%quiz` and `%quiz-web` and its dependencies. In Dojo, create and mount a
new desk; skip creation for an existing `%quiz` desk:

```dojo
|new-desk %quiz
|mount %quiz
```

From this repository's root, replace `/path/to/pier` with your pier directory:

```sh
cp -RL desk/. /path/to/pier/quiz/
```

Copy the complete desk, including `sur/`, `app/`, `web/`, `doc/` and examples.
Copying only `lib/`, `gen/` and tests does not install the app. Then, in Dojo:

```dojo
|commit %quiz
|install our %quiz
```

Sign in to the ship's web interface and open `/apps/quiz/`. No separate browser
build or hosted bundle is needed. A Markdown-capable `%docs` installation
provides rendered Help tabs; without it, short fallback help and the read-only
Documentation file browser remain available.

## Quick start

1. Open **Examples → props → 01-success**, leave requested/seed overrides blank
   and choose **Run saved property**. It accepts 20 checks.
2. Open **failing → 03-crash** to see zero underflow, or
   **failing → 08-seeded-threshold** to see the counterexample shrink 541 → 501.
3. Choose **Open editable copy**, edit and run **Draft property**, then save.
   Saved execution uses its selected Clay revision: choose **Use latest
   revision** after saving when you want the new version.
4. Open **examples → 02-boxcar** for a saved suite, discover arms and run all
   three. Use **Replay exact property** on a property result to repeat its
   recorded source, imports, effective seed and configuration.

The [user's guide](desk/doc/users-guide.md) teaches domain guards, norns,
shrinking, replay and ordinary regression tests with executable examples.
Passing randomized checks are evidence, not proof. App drops and duplicates
never count as accepted; exhaustion is a distinct outcome. Each Hoon call has a
CPU time limit, and a stuck run can also be stopped with Ctrl-C. Either way it
is recorded as interrupted. There is no memory isolation, so use a disposable
ship for experiments. See [limitations](desk/doc/limitations.md).

## Library-only use

Copy `desk/lib/quiz.hoon` to your development desk's `lib/quiz.hoon` and optionally
`desk/gen/quiz.hoon` to `gen/quiz.hoon`; commit that desk. These frozen legacy
entry points do not need either agent or the browser workbench.

If those files are on `%quiz`, this Dojo generator checks increment/decrement:

```dojo
+quiz!quiz !>(|=(value=@ud =(value (dec +(value))))), =runs 20
```

Recorded output: `[[%success-runs 20] %drops 0]`, `%.y`.
For explicit deterministic seeds or custom norns/alts, import `quiz` and use
its `check`/`check-verbose` arms; see the
[exact signatures](desk/doc/reference.md#legacy-library-signatures) and
[tutorial suite](desk/tests/examples/01-quiz-tutorial.hoon).
Legacy drops consume its run target, and duplicate exhaustion can return true.
The application's `lib/quiz-engine.hoon` has separate counters, limits and
structured outcomes. Do not interpret legacy success as an app run record.

## Development and verification

The desk is self-contained and targets `[%zuse 408]`. Copy changes into a
mounted development desk and `|commit %quiz`. Run the packaged regressions:

```dojo
-test /=quiz=/tests ~
```

Intentional teaching failures are under `desk/examples/failing/`, outside the
passing tests. The original suites also run through the UI. Browser checks use
its real compiled page on a disposable ship; setup and commands are in
[tests/browser/README.md](tests/browser/README.md).

Shared urui files are pinned copies; keep framework changes in urui, not these
copies. Preserve the frozen legacy library/generator. Deterministic app engine
changes require replay-version review. See the
[internal module map](desk/doc/reference.md#internal-implementation-map),
[Gall API](desk/doc/agent-api.md) and [HTTP API](desk/doc/http-api.md).

## About

Version 0.1.0. [MIT+n license](LICENSE); third-party components retain their
own licenses. [About Quiz and Ace](desk/doc/about.md).
[Source](https://github.com/jackfoxy/quiz) and
[issues](https://github.com/jackfoxy/quiz/issues).
The unchanged [original blog](blogpost.md) is historical; the guide and
reference correct its outdated output and behavior claims.
