# Property documents

A document builds to a core with a required `++fate` gate. Optional arms are
`++norn`, `++alts`, and `++conf`. Other arms may hold helpers. See the executable
[fixture](../fixtures/quiz-build/property.hoon).

```hoon
|%
++  fate
  |=  value=@ud
  =(+(value) (add value 1))
--
```

The compiler checks types without calling the property, generator, or shrinker:

| Arm | Required type |
| --- | --- |
| `fate` | Gate with any sample; product nests in `?(? %drop)` |
| `norn` | Gate accepting `[@ud _og]`, returning the fate sample type |
| `alts` | Gate accepting a `vase`, returning `(list vase)` |
| `conf` | `[seed=(unit @uv) config=conf:quiz-engine]` |

A missing `conf` uses `[~ defaults:quiz-engine]`. A null seed asks the caller to
choose and record a seed; an explicit seed is replayable. No generator or
shrinker uses ambient entropy. Configuration uses the full engine record; import
`/+  engine=quiz-engine` and update `defaults:engine` to change selected fields.
Requested checks may be zero and must fit `requested-max`. Each budget must be
at most the engine default ceiling. Byte, retention, and slice bounds must be
positive. Shrink and attempt/drop/duplicate budgets may be zero.

## Restricted Ford prelude

These groups must appear in this order. Groups may repeat; whitespace and Hoon
comments are accepted. Imports belong to the selected desk and pinned revision.

| Form | Meaning |
| --- | --- |
| `/-  types` | Build `/sur/types/hoon`, face `types` |
| `/+  helpers` | Build `/lib/helpers/hoon`, face `helpers` |
| `/+  h=helpers, *other` | Alias an import; import another without a face |
| `/=  helper  /fixtures/quiz-build/helper` | Build the explicit path plus `/hoon` |
| `/*  text  %txt  /fixtures/quiz-build/note/txt` | Read a raw native-mark noun |

Raw marks are restricted to `%hoon` (cord), `%txt` (wain), and `%noun` (noun).
The path suffix must match the mark. Mark conversion, cross-desk imports, and
other Ford prelude runes (`/~`, `/%`, `/$`, etc.) are unsupported. Unsupported
runes and malformed/out-of-order supported runes produce distinct diagnostics.
Built dependencies use Clay's normal compiler; their own preludes are ordinary
Ford. The restriction applies to the submitted document.

Desk names use Hoon symbol syntax, at most 64 bytes. Paths are nonempty lists
of at most 32 segments. Each segment is 1–64 lowercase letters, digits, or
hyphens; traversal and separators inside segments are rejected. Documents must
end in `/hoon`; source is limited to 262,144 bytes before parsing.

## Builder API

`lib/quiz-build.hoon` returns either `%ready` with context, settings, and engine
parts, or `%invalid` with code, path, line/column, optional arm, and bounded tang.
Semantic errors anchor at the relevant arm declaration; compiler traces retain
more precise spans. Oversized traces are omitted and `clipped` is true.

1. `pin [our desk case now]` resolves a local desk/case (`%ud`, `%da`, or `%tas`) to a positive `%ud`
   revision. `%uv`, revision zero, unsafe names, and unavailable contexts fail.
2. Draft: `prepare` validates and parses source against that context. Send
   each `draft-requests` entry as Gall `%c %warp`, then pass the replies in
   prelude order to `draft [doc replies]`. Compiled imports use `%a`, raw
   imports `%x`; every request uses the pinned `%ud` revision. Missing or
   failed imports become located errors.
3. Saved: `prepare-file` reads source at that context, validates it, and parses
   its prelude. Send `saved-request` as a Gall `%c %warp` request; pass the
   resulting `riot:clay` to `take-saved`. Do not substitute source from another
   revision. A failed Clay build yields `%build` at the file start (Clay does
   not return its compiler tang). The draft path can provide a more precise
   diagnostic for the same source.
4. `compile` accepts already loaded dependency vases in prelude order, for
   pure callers and tests. `check-core` validates a compiled document vase.

`prepared` values are internal validated data, not an untrusted wire format.
A caller must use `prepare`/`prepare-file` before requesting compilation. The
Gall action boundary and job lifecycle are described in the
[agent API](agent-api.md).

Document and arm evaluation reject scries; dependency reads are explicit.
Failed build scries can escape Gall virtualization, so dependency builds use
asynchronous requests. Context metadata and existing native Hoon source use
local scries only after checking desk, revision, and file existence. `our` and
`now` must come from the caller’s Gall bowl.
Draft compilation, type inference and arm evaluation run under a fixed 30 s
`%jinx` CPU limit (`build-time`). A build that exceeds it, is stopped with
Ctrl-C, or exhausts memory aborts its Gall event; the run is recorded as
`%interrupted` with `during=%building`. Saved files compile in Clay through
`%warp %a`, outside this limit. Size checks are not memory isolation.

Suite execution and durable replay are documented in
[suites and replay](suites-and-replay.md). Unavailable context diagnostics
distinguish `%desk-unavailable` from `%revision-unavailable`.
