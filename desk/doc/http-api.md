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
Dates are Hoon `@da` strings. Paths are arrays of Clay segments ending with
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
`duplicates-max`, and `bounds`. Bounds are `source-bytes`, `requested-max`,
`shrink-candidates`, `shrink-depth`, `sample-bytes`, `rendered-bytes`,
`diagnostics-bytes`, `alts-bytes`, `retained-runs`, `samples-per-slice`.
All configuration values are JSON integers. `requested` may be raised up to
`requested-max`; attempts, drop/duplicate budgets, and bounds cannot exceed
their engine defaults. Size, retention, and slice bounds must stay positive.

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
metrics. `config`, when supplied, is a **complete** override, including every
bound. Omit it to use the document's configuration or engine defaults.

```json
{"op":"replay","id":"42"}
```

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
Clay build paths as execution.

The workbench uses this operation when overriding requested checks: it copies
the document's full configuration and changes only `requested`, preserving
other budgets. Blank controls leave the engine to resolve document settings.

### History, status and cancellation

```json
{"op":"runs"}
{"op":"status","id":"42"}
{"op":"cancel","id":"42"}
```

`runs` returns 200 `{"ids":["42","41"]}` newest first. `status` returns 200
with one record, or 404 `{"error":"run-not-found"}`. `cancel` returns 202
`{"accepted":true}` after acknowledgement. As in the typed API, cancelling an
unknown or completed ID is an idempotent no-op. Poll a known run to observe
its terminal outcome.

A record contains:

- `id`, source `kind`, `status`, `engine-version`, `created`, `updated`, `finished`.
- `request`: submitted source, desk, revision, seed, configuration and replay ID.
- `snapshot`: null until available, then pinned `context`, `path`, exact `source`,
  and `source-hash` (`@uv`).
- Effective `seed`, `config`, and `replay-of` (nullable).
- `counts`, `sample-metrics` (`available` or `unavailable`), and nullable `outcome`.

Property counts are `attempted`, `accepted`, `dropped`, `duplicate`,
`shrink-tried`, `shrink-steps`. Suite counts are `total`, `completed`, `passed`,
`failed`, `crashed`, `invalid`. A suite never synthesizes property counters.

Outcome `kind` is `passed`, `failed`, `error`, `limited`, `exhausted`, `invalid`,
`cancelled`, or `suite`. Additional fields follow the typed result:

- `failed`: `evidence` with `why`, `original`, `shrunk`.
- `error`: `stage`, `why`, nullable `evidence`.
- `limited`: `which`, nullable `evidence`.
- `exhausted`: `budget`, `all-dropped`.
- `invalid`: `diagnostic` with `code`, `path`, `line`, `column`, nullable `arm`,
  `trace` (rendered lines), and `clipped`.
- `cancelled`: `reason` (`request` or `reload`).
- `suite`: aggregate `status`, `counts`, `sample-metrics: "unavailable"`, and
  `arms` with `name`, `status`, `trace`, `clipped`.

Evidence samples have rendered `text` and `noun-jam` (a jammed noun as `@uv`).
`why` has `kind` (`false`, `crash`, `scry`, `bad-product`) and `detail`: null,
trace lines, or a jammed noun string respectively. Rendering and retained
samples obey engine bounds. `passed` means the requested checks passed, not a
proof.

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

One API mutation/discovery/configuration inspection may await a reply at a time; another returns 503
`{"error":"api-busy"}`. Reads remain available. Pending API requests time out
after 30 seconds with 504 `{"error":"api-timeout"}`; stale replies are ignored.
A timeout is not a rollback of an admitted run. An engine rejection returns
422 `{"error":"action-rejected"}`. Pending state is transient across reload.

## File wire

The Unit 8 policy serves `.hoon` source as text under `/data/quiz` in the app's
own desk. Paths in this protocol are relative to that root. The shared urui
implementation is unchanged. Save/delete are verified asynchronously with a
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
| `examples` | This desk's `/tests/examples` | Read-only Hoon |
| `docs` | This desk's `/doc` | Read-only Markdown |
| `clay/<desk>/<revision>` | Local desk, explicit decimal revision | Read-only Hoon |

The earlier relative Hoon paths remain writable aliases under `/data/quiz`.
Read-only restrictions are enforced by the server, including save and
delete requests. Browse Clay with a desk and revision; bare `clay` returns
a context-selection error. Unavailable desks or revisions return 404.
