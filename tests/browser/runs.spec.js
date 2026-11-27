'use strict';
const fs = require('node:fs');
const {test, expect} = require('@playwright/test');
test.skip(!process.env.QUIZ_CODE, 'Set QUIZ_CODE for the disposable fake ship.');
test.beforeEach(async ({page}) => {
  await page.request.post('/~/login', {form: {password: process.env.QUIZ_CODE}});
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
});
const setSource = (page, text) => page.evaluate(text =>
  window.quiz.documents.editor('property').setSource(text, {history:'reset'}), text);
const selected = page => page.evaluate(() => {
  const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
  return window.quiz.runs.records.get(id);
});
const done = async page => {
  await expect.poll(async () => (await selected(page))?.status, {timeout:30000}).toBe('done');
  return selected(page);
};

test('document conf inspection and requested override preserve other budgets', async ({page}) => {
  const source = `/+  e=quiz-engine
|%
++  fate
  |=  n=@ud
  =(n n)
++  conf
  =/  cfg  defaults:e
  [[~ 0v123] cfg(requested 3, attempts-max 17)]
--`;
  await setSource(page, source);
  await page.locator('#run-inspect').click();
  await expect(page.locator('#run-settings-note')).toContainText('3 checks; sizes from 1, uncapped; repeats mug; seed 0v123');
  await page.locator('#run-requested').fill('5');
  await page.locator('#run-start').click();
  const record = await done(page);
  expect(record.outcome.kind).toBe('passed');
  expect(record.config.requested).toBe(5);
  expect(record.config['attempts-max']).toBe(17);
  expect(record.counts.accepted).toBe(5);
  expect(record.seed).toBe('0v123');
  expect(record.snapshot.source).toBe(source);
  await expect(page.locator('#run-stale')).toContainText('matches');
});

test('failure, stale snapshot, exact replay, rerun and browser restoration', async ({page}) => {
  const source = fs.readFileSync('desk/fixtures/quiz-replay/property.hoon','utf8');
  await setSource(page, source);
  await page.locator('#run-seed').fill('0v123');
  await page.locator('#run-start').click();
  const failed = await done(page);
  expect(failed.outcome.kind).toBe('failed');
  await expect(page.locator('#run-original')).toHaveText('value=541');
  await expect(page.locator('#run-shrunk')).toHaveText('value=501');
  await setSource(page, ':: changed since run\n' + source);
  await expect(page.locator('#run-stale')).toContainText('Stale');
  await page.locator('#run-snapshot summary').click();
  await page.evaluate(() => window.quiz.runs.refresh());
  await expect(page.locator('#run-snapshot')).toHaveAttribute('open', '');
  await page.locator('#run-replay').click();
  await expect.poll(async () => (await selected(page))?.id).not.toBe(failed.id);
  const replay = await done(page);
  expect(replay['replay-of']).toBe(failed.id);
  expect(replay.snapshot['source-hash']).toBe(failed.snapshot['source-hash']);
  expect(replay.outcome.evidence).toEqual(failed.outcome.evidence);
  expect(replay.counts).toEqual(failed.counts);
  await page.locator('#run-rerun').click();
  await expect.poll(async () => (await selected(page))?.id).not.toBe(replay.id);
  const rerun = await done(page);
  expect(rerun.outcome.kind).toBe('failed');
  await page.locator(`#run-history [data-run-id="${failed.id}"]`).click();
  await page.evaluate(() => window.quiz.runtime.session.save());
  page.once('dialog', dialog => dialog.accept());
  await page.reload(); await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  await expect(page.locator('#run-result-status')).toContainText(`Run ${failed.id}: failed`);
  await expect(page.locator('#run-stale')).toContainText('Stale');
  await page.screenshot({path:'test-results/quiz-failure.png',fullPage:true});
});

test('saved Clay suite discovery and exact arm selection', async ({page}) => {
  const revision = await page.locator('#run-revision').inputValue();
  await page.evaluate(rev => window.quiz.documents.open('property',
    ['clay','quiz',rev,'tests','examples','02-boxcar','hoon']), revision);
  await expect(page.locator('#run-mode')).toHaveValue('suite');
  await page.locator('#run-discover').click();
  await expect(page.locator('#run-settings-note')).toContainText('test-boxcar-sanity');
  await page.locator('#run-arms').fill('test-boxcar-4-5');
  await page.locator('#run-start').click();
  const record = await done(page);
  expect(record.outcome.kind).toBe('suite');
  expect(record.outcome.status).toBe('passed');
  expect(record.outcome.counts.total).toBe(1);
  expect(record.outcome.arms.map(arm=>arm.name)).toEqual(['test-boxcar-4-5']);
  expect(record['sample-metrics']).toBe('unavailable');
  await expect(page.locator('#run-unavailable')).toContainText('unavailable');
  await expect(page.locator('#run-replay')).toBeDisabled();
  await page.screenshot({path:'test-results/quiz-suite.png',fullPage:true});
});

test('save as regression, save it, and run the saved suite until the fix', async ({page}) => {
  const stem = `regression-browser-${Date.now()}`;
  const bug = '    ::  Bug: should take the head of (flop back.q).\n    [`i.back.q [t.back.q ~]]';
  const fix = '    =/  back  (flop back.q)\n    ?>  ?=(^ back)\n    [`i.back [t.back ~]]';
  const revision = () => page.locator('#run-revision').inputValue();
  const at = ['clay', 'quiz', 'now', 'data', 'quiz', stem, 'hoon'];
  try {
    await page.evaluate(() => window.quiz.documents.open('property',
      ['clay', 'quiz', 'now', 'examples', 'failing', '11-queue-model-bug', 'hoon']));
    await page.locator('#run-latest').click();
    await expect(page.locator('#run-message')).toContainText('Selected');
    await page.locator('#run-start').click();
    const failed = await done(page);
    expect(failed.outcome.kind).toBe('failed');
    await page.locator('#run-save-regression').click();
    await expect(page.locator('#run-message')).toContainText(`opened as regression-${failed.id}`);
    await expect(page.locator('#document-location')).toHaveText('Unsaved document');
    await expect(page.locator('#run-mode')).toHaveValue('suite');
    await expect(page.locator('#run-start')).toHaveText('Run saved suite');
    await expect(page.locator('#run-start')).toBeDisabled();
    const text = await page.evaluate(() => window.quiz.documents.active('property').text);
    expect(text).toContain(`::  Regression from run ${failed.id} of`);
    expect(text).toContain(failed.outcome.evidence.shrunk.text);
    expect(text).toContain(`(cue ${failed.outcome.evidence.shrunk['noun-jam']})`);
    expect(text).toContain(bug);
    const before = await revision();
    await page.locator('#property-save').click();
    await page.locator('#urui-file-dialog-path').fill(`data/quiz/${stem}`);
    await page.locator('#urui-file-dialog-confirm').click();
    await expect(page.locator('#document-location')).toHaveText(at.join('/'));
    await expect.poll(revision).not.toBe(before);
    await page.locator('#run-start').click();
    await expect.poll(async () => (await selected(page))?.id).not.toBe(failed.id);
    const broken = await done(page);
    expect(broken.outcome.kind).toBe('suite');
    expect(broken.outcome.status).toBe('failed');
    expect(broken.outcome.arms.map(arm => arm.name)).toEqual(['test-counterexample']);
    expect(broken.outcome.arms[0].trace).toEqual(['the fate failed the counterexample']);
    // The fix, saved, selects the next revision; the suite then passes.
    const saved = await revision();
    await setSource(page, text.replace(bug, fix));
    await page.locator('#property-save').click();
    await expect.poll(revision).not.toBe(saved);
    await page.locator('#run-start').click();
    await expect.poll(async () => (await selected(page))?.id).not.toBe(broken.id);
    const passed = await done(page);
    expect(passed.outcome.status).toBe('passed');
    await page.screenshot({path: 'test-results/quiz-regression.png', fullPage: true});
  } finally {
    await page.request.post('/apps/quiz/files', {data: {op: 'delete', path: at}});
  }
});

test('deleted saved source reports a diagnostic while its pinned revision still runs', async ({page}) => {
  const path = ['clay', 'quiz', 'now', 'data', 'quiz', `run-deleted-${Date.now()}`, 'hoon'];
  const source = '/+  engine=quiz-engine\n|%\n++  fate\n  |=  n=@ud\n  =(n n)\n--';
  const file = async body => {
    const response = await page.request.post('/apps/quiz/files', {data: body});
    expect(response.ok()).toBeTruthy();
    return response.json();
  };
  try {
    await file({op:'save',path,text:source,base:null,overwrite:false});
    await page.evaluate(path => window.quiz.documents.open('property',path), path);
    await page.locator('#run-mode').selectOption('file');
    await page.locator('#run-latest').click();
    await expect(page.locator('#run-message')).toContainText('Selected');
    await file({op:'delete',path});
    // The previous revision remains a valid source after deletion.
    await page.locator('#run-inspect').click();
    await expect(page.locator('#run-settings-note')).toContainText('Document conf:');
    await page.locator('#run-start').click();
    const passed = await done(page);
    expect(passed.outcome.kind).toBe('passed');
    await page.locator('#run-latest').click();
    await expect(page.locator('#run-message')).toContainText('Selected');
    await page.locator('#run-start').click();
    await expect.poll(async () => (await selected(page))?.id).not.toBe(passed.id);
    const missing = await done(page);
    expect(missing.outcome.kind).toBe('invalid');
    expect(missing.outcome.diagnostic.code).toBe('source');
    await expect(page.locator('#run-diagnostic')).toBeVisible();
  } finally {
    await page.request.post('/apps/quiz/files', {data:{op:'delete',path}});
  }
});

test('cancellation, compile diagnostic and disconnected progress', async ({page}) => {
  await setSource(page, `|%
++  fate
  |=  n=@ud
  =(n n)
++  norn
  |=  [size=@ud rng=_og]
  (rad:rng 1.000.000)
--`);
  await page.locator('#run-requested').fill('10000');
  await page.locator('#run-start').click();
  await expect(page.locator('#run-cancel')).toBeEnabled({timeout:30000});
  await page.locator('#run-cancel').click();
  const cancelled = await done(page);
  expect(cancelled.outcome.kind).toBe('cancelled');
  expect(cancelled.outcome.reason).toBe('request');
  await page.locator('#run-requested').fill('');
  await setSource(page, 'not valid hoon !');
  await page.locator('#run-start').click();
  await expect.poll(async () => (await selected(page))?.id).not.toBe(cancelled.id);
  const invalid = await done(page);
  expect(invalid.outcome.kind).toBe('invalid');
  await expect(page.locator('#run-diagnostic')).toBeVisible();
  const before = await page.locator('#run-counts').innerText();
  await page.route('**/apps/quiz/api', route => route.abort('failed'));
  await page.locator('#runs-refresh').click();
  await expect(page.locator('#runs-connection')).toContainText('Last confirmed');
  await expect(page.locator('#run-counts')).toHaveText(before);
  await expect(page.locator('#run-start')).toBeDisabled();
  await page.unroute('**/apps/quiz/api');
  await page.locator('#runs-refresh').click();
  await expect(page.locator('#runs-connection')).toContainText('Connected');
});
test('a shrinker error shows its cause beside the evidence; the record downloads', async ({page, context}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write'],
    {origin: new URL(page.url()).origin});
  await setSource(page, '|%\n++  fate  |=(n=@ud (lth n 5))\n'
    + '++  alts  |=(v=vase ^-((list vase) ~|(%alts-broken !!)))\n--\n');
  await page.locator('#run-start').click();
  const record = await done(page);
  expect(record.outcome.kind).toBe('error');
  expect(record.outcome.stage).toBe('alts');
  await expect(page.locator('#run-error-cause')).toContainText('alts-broken');
  await expect(page.locator('#run-failure')).toContainText('false');
  await page.locator('#run-record summary').click();
  await expect(page.locator('#run-request')).toContainText('"draft"');
  await expect(page.locator('#run-record'))
    .toContainText(record.outcome.evidence.shrunk['noun-jam']);
  const [download] = await Promise.all([page.waitForEvent('download'),
    page.locator('#run-download').click()]);
  expect(download.suggestedFilename()).toBe(`quiz-run-${record.id}.json`);
  const saved = JSON.parse(fs.readFileSync(await download.path(), 'utf8'));
  const status = await (await page.request.post('/apps/quiz/api',
    {data: {op: 'status', id: record.id}})).json();
  expect(saved).toEqual(status);
  await page.locator('#run-copy-noun').click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText()))
    .toBe(record.outcome.evidence.shrunk['noun-jam']);
});
