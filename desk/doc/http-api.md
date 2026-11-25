# Quiz HTTP API

`%quiz-web` serves `/apps/quiz` on the `%quiz` desk. The compiled urui
[workbench](workbench.md) provides editing, run controls and confirmed results.
The engine's [typed API](agent-api.md) remains available to Gall clients.

## Routes and authorization

| Method | Suffix | Response | Session |
|---|---|---|---|
| GET | empty or `/` | HTML urui shell | public |
| GET | `/app.js` | compiled config, urui runtime, application code | public |
| GET | `/doc.toc` | documentation table of contents | public |
| GET | `/favicon.png` | PNG | public |
| GET | `/quiz.png` | Landscape tile PNG | public |
| GET | `/ace/ace.js` | vendored Ace | public |
| GET | `/ace/theme-github.js`, `/ace/theme-monokai.js` | Ace themes | public |
| GET | `/ace/ext-beautify.js`, `/ace/ext-prompt.js` | Ace extensions | public |
| GET | `/ace/ext-searchbox.js`, `/ace/ext-settings_menu.js` | Ace extensions | public |
| GET | `/ace/keybinding-vim.js`, `/ace/license.txt` | Vim binding, license | public |
| POST | `/api` | JSON commands below | required |
| POST | `/files` | urui JSON file wire | required |

Paths are exact; query strings do not change routing. Other paths return 404
with a session, 401 without one. Known routes with the wrong method return 405
(after authentication for private routes). Both POST routes require
`Content-Type: application/json` (optionally `; charset=utf-8`) and at most
524,288 bytes. Missing/malformed JSON and invalid fields return 400, oversized
bodies 413, unsupported content types 415. Authentication is checked first.
The engine separately enforces its source and configuration limits.

Public GET responses are built once per commit. Each carries an `etag` and
`cache-control: no-cache`, so the browser revalidates on every load; a
matching `If-None-Match` returns 304 with no body. A commit that changes an
asset changes its `etag`.

Eyre uses a guest ship identity for anonymous HTTP, so its response watches and
HTTP request mark accept guests. Private commands require both Eyre's
`authenticated` flag and `src == our`; a foreign caller cannot forge the flag.
Foreign watchers of a private response path are kicked before its facts are
sent. Other pokes retain local-only authorization. JSON replies use JSON
escaping, `no-store`, and `nosniff`; user text is never interpolated as HTML.

## JSON conventions

IDs and immutable revision numbers are decimal strings, without separators,
so clients can retain integers larger than JavaScript's safe integer range.
The decoder also accepts nonnegative integer JSON tokens; clients should use
strings for large values. Seeds are Hoon `@uv` strings, including `"0v0"`.
Dates are Hoon `@da` strings. CPU time limits are whole seconds. Paths are arrays of Clay segments ending with
`"hoon"`; they are not URL paths. Optional configuration/seed fields may be
omitted or null. Unknown object fields are ignored. Invalid required fields,
invalid desk/path syntax, and unsupported revision kinds are refused.

A revision is one of:

```json
{"kind":"ud","value":"100"}
{"kind":"tas","value":"label"}
{"kind":"da","value":"~2026.10.15"}
```

Run contexts are pinned when the queued job activates. Choose an explicit `ud`
revision from `contexts` to make the submitted context immutable immediately.
Suite discovery pins the context when the HTTP request arrives.

## Commands

All commands below are POSTed as JSON to `/apps/quiz/api`.

### Contexts and defaults

```json
{"op":"contexts"}
```

Returns 200 with `contexts` (available local desks, each with `ship`, `desk`,
immutable `revision`), `defaults` (the complete engine configuration), and
`engine-version`. Configuration has `requested`, `attempts-max`, `drops-max`,
`duplicates-max`, `size-start`, `size-max`, `duplicates`, and `bounds`.
Bounds are `source-bytes`, `requested-max`, `shrink-candidates`,
`shrink-depth`, `sample-bytes`, `rendered-bytes`, `diagnostics-bytes`,
`alts-bytes`, `seen-bytes`, `retained-runs`, `samples-per-slice`,
`trace-steps`.
`duplicates` is the string `"mug"`, `"exact"` or `"allow"`, and `on-timeout`
is `"interrupt"`, `"fail"` or `"discard"`; every other
configuration value is a JSON integer. `requested` may be raised up to
`requested-max`; attempts, drop/duplicate budgets, and bounds cannot exceed
their engine defaults. `size-start` must be at least 1; `size-max` is 0
(uncapped) or at least `size-start`. Byte, retention, and slice bounds must
stay positive.

### Run and replay

```json
{
  "op":"run",
  "source":{"kind":"draft","text":"|%  ++  fate  |=(@ud &)  --"},
  "desk":"quiz",
  "revision":{"kind":"ud","value":"100"},
  "seed":"0v123"
}
```

Other source forms:

```json
{"kind":"file","path":["fixtures","quiz-replay","property","hoon"]}
{"kind":"suite","path":["tests","examples","02-boxcar","hoon"],"arms":[]}
```

For a suite, `arms` is required: empty selects every discovered test arm; a
nonempty array selects exact names. Suites have no controlled seed or sample
metrics. `config`, when supplied, overrides only the fields it names, for
example `{"requested":500,"size-max":40}`; an absent or `null` field keeps the
document's value, and `bounds`, when given, must be complete. `%quiz` merges it
after the build and records the effective configuration; a merged value out of
range ends the run `invalid` with code `conf-range`. Omit `config` to use the
document's configuration or engine defaults.

```json
{"op":"replay","id":"42"}
```

An optional `mode` asks for a [generator preview](reference.md#generator-preview)
instead of a run:

```json
{"kind":"preview","count":20,"verdicts":true,"alts":true}
```

An absent or `null` `mode`, or `{"kind":"run"}`, runs the property. `count`
is at most 100. A preview has no budgets: `requested` and the attempt, drop and
duplicate budgets in `config` are ignored, while sizes, the duplicate policy
and byte bounds apply. Suites cannot be previewed.

Replay uses the stored property text, immutable context, effective settings,
seed, and engine version. Suite replay is refused. Neither operation accepts
replacement replay inputs.

Both return **202 `{"accepted":true,"id":"43"}` after correlated engine
admission**. The decimal ID identifies this request even with concurrent
producers. Poll that ID's `status` for completion. The engine allocates it and
sends a local `%quiz-admitted` callback; an ordinary poke acknowledgement alone
does not complete this HTTP response. `request` in each record exposes the
original submitted inputs. No HTTP idempotency or automatic retry is provided.
A timeout or lost connection may occur after admission; inspect history before
retrying.

### Inspect document configuration

Send the same draft or file request as `run`, with `"op":"document-conf"`.
Suite sources are refused. Returns 200 with pinned `context`, full `config`
and nullable `seed` from the compiled document's `conf` or engine defaults.
This operation compiles the source and evaluates its configuration; it does
not enqueue a run or apply request overrides. Invalid source/context/imports
return 422 with a located diagnostic. Reads use the same pinned asynchronous
Clay build paths as execution. If the runtime aborts the inspection, because
compilation or `conf` evaluation exceeded the draft build limit,
exhausted memory or was interrupted, the event rolls back and Eyre answers
500 with the body `crud!`. No pending API request remains. `suite-arms`
discovery behaves the same way when interrupted; its Clay build has no CPU
limit.

The workbench uses this operation only for **Read document conf**. A run
with overridden fields sends just those fields, so it needs no extra build.
Blank controls leave the engine to resolve document settings.

### CPU time limits

```json
{"op":"timeouts"}
{"op":"set-timeouts","call-time":10,"build-time":30,"arm-time":60}
```

`timeouts` returns 200 with the three ship-wide limits in whole seconds.
`set-timeouts` returns 202 `{"accepted":true}` once `%quiz` accepts the change.
Each value must be a whole number from 1 to 3600, or the request is refused
with 400 `invalid-command`. The workbench's **Settings** dialog uses both.

### History, status, cancellation and deletion

```json
{"op":"runs"}
{"op":"status","id":"42"}
{"op":"cancel","id":"42"}
{"op":"delete","id":"42"}
{"op":"clear"}
```

`runs` returns 200 `{"ids":["42","41"],"runs":[...]}` newest first. Each
`runs` row is `{"id","kind","status","outcome"}`: `kind` is the source kind,
or `preview` for a preview,
`outcome` the result's kind (a suite's `passed`/`failed`) or `null` while
unfinished. Rows label history; fetch a whole record with `status`. `status` returns 200
with one record, or 404 `{"error":"run-not-found"}`. `cancel` returns 202
`{"accepted":true}` after acknowledgement. As in the typed API, cancelling an
unknown or completed ID is an idempotent no-op. Poll a known run to observe
its terminal outcome.

`delete` removes one completed record: 202 `{"accepted":true}`, 404
`{"error":"run-not-found"}` for an unknown ID, or 409
`{"error":"run-unfinished"}` for a queued or active run. `clear` removes every
completed record and keeps queued and active work: 202 `{"accepted":true}`.
Neither resets IDs. Both are mutations: like `cancel` they hold the API slot
until `%quiz` acknowledges them, and they are never retried automatically.

A record contains:

- `id`, source `kind`, `status`, `engine-version`, `created`, `updated`, `finished`.
- `request`: submitted source, desk, revision, seed, configuration, replay ID
  and `mode` (`{"kind":"run"}` or the preview's mode).
- `snapshot`: null until available, then pinned `context`, `path`, exact `source`,
  and `source-hash` (`@uv`).
- Effective `seed`, `config`, and `replay-of` (nullable).
- `counts`, `sample-metrics` (`available` or `unavailable`), nullable
  `distribution`, and nullable `outcome`.
- `call-ms`: the call limit, in whole milliseconds, that a property's last
  slice ran under: the ship-wide limit, lowered by the document's `++within`.
  Null until a property slice has run, and for suites.

Property counts are `size` (the size the next generated sample will use),
`attempted`, `accepted`, `dropped`, `duplicate`, `shrink-tried`,
`shrink-steps`. Suite counts are `total`, `completed`, `passed`,
`failed`, `crashed`, `invalid`. A suite never synthesizes property counters.

A property's `distribution` counts labels and table rows over accepted samples,
and is null for suites:

```json
{"labels":{"short":15,"long":84},"tables":{"length":{"3":7,"10":12}}}
```

Outcome `kind` is `passed`, `uncovered`, `passed-unexpectedly`, `failed`,
`failed-as-expected`, `error`, `limited`, `exhausted`, `invalid`, `cancelled`,
`interrupted`, `suite`, or `preview`. Additional fields follow the typed result:

- `passed`: `warnings` (coverage shortfalls under `%warn`, usually empty) and
  `examples`.
- `uncovered`: `shortfalls` and `examples`. A shortfall is
  `{"label","want","got","table"}`, percentages as numbers. `table` is `null`
  for a label row; for a `++cover-table` row it is the table's name and
  `label` is the value. An example is
  `{"label","sample"}`, with a sample shaped like evidence samples.
- `passed-unexpectedly`: no fields.
- `failed` and `failed-as-expected`: `evidence` with `why`, `original`,
  `shrunk`, `trace`.
- `error`: `stage`, `why`, nullable `evidence`.
- `limited`: `which`, nullable `evidence`.
- `exhausted`: `budget`, `all-dropped`.
- `invalid`: `diagnostic` with `code`, `path`, `line`, `column`, nullable `arm`,
  `trace` (rendered lines), and `clipped`.
- `cancelled`: `reason` (`request` or `reload`).
- `interrupted`: `during` (`building`, `running` or `shrinking`), nullable
  `evidence` (the best counterexample committed before the abort), and
  nullable `arm` (the suite arm that was executing).
- `suite`: aggregate `status`, `counts`, `sample-metrics: "unavailable"`, and
  `arms` with `name`, `status`, `trace`, `clipped`.
- `preview`: `rows` and `candidates`. A row is
  `{"size","sample","repeat","verdict","labels"}`: the size the sample was made
  at, the sample (shaped like evidence samples), whether a run would skip it
  as a repeat, the fate's verdict kind (`pass`, `drop`, `false`, `crash`,
  `scry`, `bad-product`) or `null` without `verdicts`, and its labels. A
  candidate is `{"sample","weight","lighter"}`; `weight` is a decimal string,
  or `null` with `lighter` false when the candidate could not be shown.
  `candidates` is empty without `alts`.

Evidence samples have rendered `text` and `noun-jam` (a jammed noun as `@uv`).
`why` has `kind` (`false`, `timeout`, `crash`, `scry`, `bad-product`) and
`detail`. A `timeout` has a null `detail`. For
`false` it is `{"notes":[…],"compared":null|{"want","got"}}`; otherwise trace
lines, or a jammed noun string. Rendering and retained
samples obey engine bounds. `passed` means the requested checks passed, not a
proof.

Evidence `trace` is the shrink trace, oldest step first, at most
`trace-steps` rows (empty when it is 0). A row is
`{"kind":"alts","best","count"}` for an alts call on the best sample, or
`{"kind":"candidate","weight","why","text"}` for one candidate. `why` is
`accepted`, `timeout`, `passed`, `dropped`, `other-failure`, `heavier` or
`visited`. `weight` and `best` are decimal strings, because a noun weight can
exceed JavaScript's exact integer range; `weight` is `null` for `visited`.
`text` is the rendered candidate, at most 160 bytes, or `null` for `heavier`,
`visited` and a candidate that failed to render. See the
[reference](reference.md#alts-and-shrinking).

### Suite arm discovery

```json
{
  "op":"suite-arms",
  "desk":"quiz",
  "revision":{"kind":"ud","value":"100"},
  "path":["tests","examples","02-boxcar","hoon"]
}
```

Returns 200 with pinned `context` and ordered `arms` names after an asynchronous
Clay build. Discovery does not execute the test arms. Invalid/missing source,
desk, revision, or test core returns 422 with the located diagnostic object.

### Property documents and suites on a desk

```json
{"op":"properties","desk":"quiz","revision":"100"}
```

Returns 200 with `entries`, in path order, as
`{"path":["clay","quiz","100",…,"hoon"],"kind":"file","role":…}`. `role` is
`property` for a Hoon file whose prelude imports `/lib/quiz-engine` on a `/+`
line, under any face, and that declares a `++  fate` arm; otherwise `suite`
for a file with a `++  test-` arm. Other files are omitted. The first 4,096
bytes of each file are parsed for the prelude, in whole lines. The arm checks
are textual: a line must start at column 0 with `++  fate` followed by a
space or the end of the line, or with `++  test-`; nothing is compiled. The paths open through the file
wire below. The workbench's **Clay source** view uses this; the file wire's
`browse` lists every file. A missing or unavailable desk or revision returns
the file wire's error envelope (400 or 404). The command is a read and takes
no API slot.

One API mutation/discovery/configuration inspection may await a reply at a time; another returns 503
`{"error":"api-busy"}`. Reads remain available. Pending API requests time out
after 30 seconds with 504 `{"error":"api-timeout"}`; stale replies are ignored.
A timeout is not a rollback of an admitted run. An engine rejection returns
422 `{"error":"action-rejected"}`. Pending state is transient across reload.

## File wire

The file wire serves `.hoon` source as text under `/data/quiz` in the app's
own desk. Paths in this protocol are relative to that root. Save/delete are verified asynchronously with a
10-second timeout and one pending change at a time.

```json
{"op":"browse","scope":[]}
{"op":"save","path":["example","hoon"],"text":"|%  ++  fate  |=(@ud &)  --","base":null,"overwrite":false}
{"op":"load","path":["example","hoon"]}
```

`load` returns `{"ok":true,"text":"...","hash":"0v..."}`. Supply that hash as
`base` on a later save or delete to detect conflicts:

```json
{"op":"delete","path":["example","hoon"],"base":"0v..."}
```

Errors use urui's `{"ok":false,"error":{"code":...,"message":...,
"retryable":...,"details":[]}}` shape. Common statuses are 400 (invalid path),
403 (read-only), 404 (missing), 409 (conflict), 503 (busy), and 504 (timeout).
The route's authentication, method, size and content-type errors use the
simpler `{"error":"..."}` shape described above.

## Workbench file locations

The `/apps/quiz/files` wire accepts these virtual paths (the last segment
is the mark, such as `hoon` or `md`):

| Prefix | Clay location | Access |
| --- | --- | --- |
| `work` | This desk's `/data/quiz` | Read/write Hoon and Markdown |
| `examples` | This desk's `/tests/examples` | Read-only Hoon suites |
| `props` | This desk's `/examples/props` | Read-only Hoon properties |
| `failing` | This desk's `/examples/failing` | Read-only teaching failures |
| `docs` | This desk's `/doc` | Read-only Markdown |
| `clay/<desk>/<revision>` | Local desk, explicit decimal revision | Read-only Hoon |

The earlier relative Hoon paths remain writable aliases under `/data/quiz`.
Read-only restrictions are enforced by the server, including save and
delete requests. Browse Clay with a desk and revision; bare `clay` returns
a context-selection error. The workbench's Open chooser sends the context
last browsed in Clay source instead of a bare `clay`. Unavailable desks or revisions return 404.
