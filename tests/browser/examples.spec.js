'use strict';
const fs = require('node:fs');
const {test, expect} = require('@playwright/test');
const examples = [
  ['props', '01-success', 'passed'],
  ['failing', '02-boolean', 'failed', 'false'],
  ['failing', '03-crash', 'failed', 'crash'],
  ['props', '04-discards', 'passed'],
  ['failing', '05-duplicates', 'exhausted'],
  ['props', '06-composed', 'passed'],
  ['props', '07-positive', 'passed'],
  ['failing', '08-seeded-threshold', 'failed', 'false'],
  ['failing', '09-custom-alts', 'failed', 'false'],
  ['props', '10-queue-model', 'passed'],
  ['failing', '11-queue-model-bug', 'failed', 'false'],
  ['props', '12-labels-coverage', 'passed'],
  ['failing', '13-expected-actual', 'failed', 'false'],
  ['failing', '14-coverage-shortfall', 'uncovered'],
  ['props', '15-expect-failure', 'failed-as-expected', 'false'],
  ['props', '16-sorted-insert', 'passed'],
  ['failing', '17-bst-delete-bug', 'failed', 'false'],
  ['props', '18-parse-print', 'passed'],
  ['failing', '19-queue-gen-lib', 'failed', 'false'],
  ['failing', '20-dependent', 'failed', 'false'],
  ['props', '21-small-domain-allow', 'passed'],
  ['props', '22-size-capped', 'passed'],
  ['props', '23-map-fusion', 'passed'],
  ['failing', '24-filter-map-swap', 'failed', 'false'],
  ['props', '25-counter-agent', 'passed'],
  ['failing', '26-counter-agent-bug', 'failed', 'false'],
  ['props', '28-confident-coverage', 'passed'],
  ['failing', '29-bst-coordinated', 'failed', 'false'],
  ['failing', '30-dependent-inner', 'failed', 'false'],
  ['failing', '31-float-associativity', 'failed', 'false'],
  ['props', '32-expiry-agent', 'passed'],
  ['failing', '33-expiry-agent-bug', 'failed', 'false'],
  ['failing', '34-typed-defaults', 'failed', 'false'],
  ['props', '35-cover-table', 'passed'],
  ['props', '36-weak-generator', 'passed'],
  ['props', '37-insert-generated', 'passed'],
  ['failing', '38-shrink-order', 'failed', 'false'],
  ['failing', '39-shrink-together', 'failed', 'false'],
  ['props', '40-tree-depth-budget', 'passed'],
  ['props', '41-tree-divided-budget', 'passed'],
  ['examples', '01-quiz-tutorial', 'suite'],
  ['examples', '02-boxcar', 'suite'],
  ['examples', '03-euler', 'suite']
];
test.skip(!process.env.QUIZ_CODE, 'Set QUIZ_CODE for the disposable fake ship.');
for (const [root, name, outcome, why] of examples) {
  test(`bundled example ${root}/${name}`, async ({page}, info) => {
    const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
    expect(login.ok()).toBeTruthy();
    await page.goto('/apps/quiz/');
    await page.waitForFunction(() => window.quiz?.ready);
    await page.evaluate(() => window.quiz.ready);
    // Each example is a file of %quiz, listed by the index at its head.
    const rel = root === 'examples' ? ['tests', 'examples', name, 'hoon']
      : ['examples', root, name, 'hoon'];
    const api = async (data) => (await page.request.post('/apps/quiz/api', {data})).json();
    const head = (await api({op:'contexts'})).contexts.find(item => item.desk === 'quiz').revision;
    const {entries} = await api({op:'properties', desk:'quiz', revision:head});
    const listed = entries.find(entry =>
      JSON.stringify(entry.path) === JSON.stringify(['clay', 'quiz', head, ...rel]));
    expect(listed?.role).toBe(outcome === 'suite' ? 'quiz-suite' : 'property');
    const path = ['clay', 'quiz', 'now', ...rel];
    await page.evaluate(path => window.quiz.documents.open('property', path), path);
    await expect(page.locator('#run-mode')).toHaveValue(outcome === 'suite' ? 'suite' : 'file');
    // A numbered revision refuses both writes.
    for (const op of ['save', 'delete']) {
      const refused = await page.request.post('/apps/quiz/files',
        {data:{op, path:['clay', 'quiz', head, ...rel], text:'x'}});
      expect(refused.status()).toBe(403);
    }
    await page.locator('#run-start').click();
    const record = () => page.evaluate(() => {
      const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
      return window.quiz.runs.records.get(id);
    });
    await expect.poll(async () => (await record())?.status, {timeout:45000}).toBe('done');
    const got = await record();
    expect(got.outcome.kind).toBe(outcome);
    expect(got.snapshot.path).toEqual(rel);
    await expect(page.locator('#run-stale')).toContainText('matches');
    if (outcome === 'suite') {
      expect(got.outcome.status).toBe('passed');
      expect(got.outcome.counts.passed).toBe(got.outcome.counts.total);
      expect(got['sample-metrics']).toBe('unavailable');
    } else expect(got.seed).toBe('0v123');
    if (why) expect(got.outcome.evidence.why.kind).toBe(why);
    if (outcome === 'passed' && name !== '28-confident-coverage')
      expect(got.counts.accepted).toBe(['10-queue-model', '12-labels-coverage', '16-sorted-insert', '18-parse-print',
        '21-small-domain-allow', '22-size-capped', '23-map-fusion',
        '25-counter-agent', '32-expiry-agent', '35-cover-table', '36-weak-generator',
        '37-insert-generated', '40-tree-depth-budget', '41-tree-divided-budget'].includes(name) ? 100 : 20);
    if (name === '04-discards') expect(got.counts.dropped).toBeGreaterThan(0);
    if (name === '07-positive') expect(got.counts.dropped).toBe(0);
    if (name === '10-queue-model') {
      expect(got.counts).toMatchObject({attempted:107, dropped:0, duplicate:7});
    }
    if (name === '11-queue-model-bug') {
      // ~[[%push 0] [%push 1] [%pop ~]], rendered through the `*` sample.
      expect(got.outcome.evidence.shrunk.text)
        .toBe('cmds=[[1.752.397.168 0] [1.752.397.168 1] [7.368.560 0] 0]');
      expect(got.counts).toMatchObject({'shrink-tried':68, 'shrink-steps':20});
      // The whole shrink fits the 100-row trace: 68 candidates and 21 alts calls.
      expect(got.outcome.evidence.trace.length).toBe(89);
      expect(got.outcome.evidence.trace.filter(row => row.why === 'accepted').length).toBe(20);
      // The step view: 21 alts calls, 20 accepting a candidate; it opens on
      // the last, whose candidates were all seen before or passed.
      const trace = page.locator('#run-shrink-trace');
      await expect(trace).toContainText('Shrink trace: 21 steps, 20 accepted (last 89 trace rows)');
      await trace.locator('summary').click();
      await expect(page.locator('#run-trace-position')).toHaveText('Step 21 of 21');
      await expect(page.locator('#run-trace-heading')).toContainText('none was accepted (2 seen, 2 passed), so shrinking stopped here');
      await page.locator('#run-trace-first').click();
      await expect(page.locator('#run-trace-heading')).toContainText('offered 20 candidates; candidate 1 was accepted');
      await page.locator('#run-trace-next').click();
      await expect(page.locator('#run-trace-position')).toHaveText('Step 2 of 21');
      await page.locator('#run-trace-accepted').check();
      await expect(page.locator('#run-trace-path tr')).toHaveCount(21);
      await expect(page.locator('#run-trace-path')).toContainText('cmds=[[1.752.397.168 0] [1.752.397.168 1] [7.368.560 0] 0]');
    }
    if (name === '38-shrink-order' || name === '39-shrink-together') {
      // One bug, two shrinkers: fields one at a time reach the smallest
      // order; quantity and price moving together stop at a heavier one.
      const order = name === '38-shrink-order';
      expect(got.outcome.evidence.original.text).toBe('lines=[[4 13] [0 33] [0 18] 0]');
      expect(got.outcome.evidence.shrunk.text).toBe(order ? 'lines=[[4 1] 0]' : 'lines=[[4 13] 0]');
      expect(got.counts).toMatchObject(order ? {'shrink-tried':35, 'shrink-steps':6}
        : {'shrink-tried':9, 'shrink-steps':2});
      await page.locator('#run-shrink-trace summary').click();
      await expect(page.locator('#run-trace-heading')).toContainText(order
        ? 'none was accepted (2 seen, 3 passed)' : 'none was accepted (1 seen, 2 passed)');
      if (!order) await expect(page.locator('#run-trace-step')).toContainText('lines=[[3 12] 0]');
    }
    // Every coverage requirement is reported, met or not.
    const rows = {
      '12-labels-coverage': [['short', 15, 100, true], ['long', 84, 100, true]],
      '14-coverage-shortfall': [['empty', 1, 100, false]],
      '28-confident-coverage': [['heads', 377, 800, true]],
      '35-cover-table': [['0', 24, 99, true], ['1', 21, 99, true], ['5', 6, 99, true]]}[name];
    if (rows) {
      expect(got.outcome.coverage.map(row => [row.label, row.hits, row.total, row.met])).toEqual(rows);
      await expect(page.locator('#run-coverage-rows')).toBeVisible();
    }
    if (name === '28-confident-coverage') {
      const [heads] = got.outcome.coverage;
      expect([heads.low, heads.high, heads.decision]).toEqual([36.71, 57.79, {kind:'established'}]);
      await expect(page.locator('#run-coverage-rows')).toContainText('36.71% – 57.79%');
      await expect(page.locator('#run-coverage-modes')).toContainText('checkCoverage');
      // %confident runs past requested until the Wilson bound decides.
      expect(got.counts).toMatchObject({accepted:800, attempted:800});
      expect(got.distribution.labels).toEqual({heads:377});
    }
    if (name === '40-tree-depth-budget' || name === '41-tree-divided-budget') {
      // Size as depth makes trees up to 2^12 - 1 nodes; a divided budget, at most 12.
      const deep = name === '40-tree-depth-budget';
      expect(got.counts).toMatchObject({attempted:130, accepted:100, duplicate:30});
      expect(got.distribution.tables.depth[deep ? '12' : '9']).toBe(deep ? 84 : 1);
      expect(got.distribution.tables.nodes['up to 1024']).toBe(deep ? 11 : undefined);
      expect(got.distribution.tables.nodes['up to 16']).toBe(deep ? 1 : 30);
    }
    if (name === '12-labels-coverage') {
      expect(got.distribution.labels).toEqual({empty:1, short:15, long:84});
      expect(got.outcome.warnings).toEqual([]);
      await expect(page.locator('#run-labels')).toContainText('long');
    }
    if (name === '13-expected-actual') {
      expect(got.outcome.evidence.why.detail.compared).toEqual({want:'1', got:'0'});
      await expect(page.locator('#run-want')).toHaveText('1');
      await expect(page.locator('#run-got')).toHaveText('0');
    }
    if (name === '14-coverage-shortfall') {
      expect(got.outcome.shortfalls).toEqual([{label:'empty', want:10, got:1, table:null}]);
      await expect(page.locator('#run-coverage-shortfalls')).toContainText('empty');
    }
    if (name === '15-expect-failure') expect(got.outcome.evidence.shrunk.text).toBe('value=10');
    if (name === '16-sorted-insert') {
      expect(got.distribution.labels).toEqual({empty:3, front:18, middle:65, end:14});
    }
    if (name === '17-bst-delete-bug') {
      expect(got.counts).toMatchObject({'shrink-tried':60, 'shrink-steps':6});
    }
    if (name === '19-queue-gen-lib') {
      // The same minimum as 11-queue-model-bug, from library shrinkers.
      expect(got.outcome.evidence.shrunk.text)
        .toBe('cmds=[[1.752.397.168 0] [1.752.397.168 1] [7.368.560 0] 0]');
    }
    if (name === '20-dependent') expect(got.counts['shrink-steps']).toBe(2);
    if (name === '29-bst-coordinated') {
      // Equal keys shrink together, below 17-bst-delete-bug's three keys.
      expect(got.outcome.evidence.shrunk.text).toBe('[items=[1 0 2 0] gone=1]');
      expect(got.counts).toMatchObject({'shrink-tried':146, 'shrink-steps':14});
    }
    if (name === '30-dependent-inner') {
      // The bound stops at 1; the pinned dependent list shrinks to ~[90].
      expect(got.outcome.evidence.shrunk.text).toBe('raw=[value=1 seed=0v0 size=0 pin=[~ ~[90]]]');
      expect(got.counts).toMatchObject({'shrink-tried':24, 'shrink-steps':5});
    }
    if (name === '31-float-associativity') {
      // Sized reals start exact; shrink-real ends at short decimals.
      expect(got.outcome.evidence.shrunk.text).toBe('[a=.~-1.2 b=.~-1 c=.~1]');
      expect(got.counts).toMatchObject({attempted:6, accepted:5, 'shrink-tried':33, 'shrink-steps':4});
    }
    if (name === '32-expiry-agent') {
      expect(got.counts).toMatchObject({attempted:115, accepted:100, duplicate:15});
    }
    if (name === '33-expiry-agent-bug') {
      // The first put's timer deletes the second put's value early.
      expect(got.counts).toMatchObject({attempted:9, accepted:6, duplicate:2, 'shrink-tried':56, 'shrink-steps':7});
      expect(got.outcome.evidence.why.detail.compared).toEqual({want:'{%a}', got:'{}'});
    }
    if (name === '34-typed-defaults') {
      // No norn or alts: quiz-auto fills printable text and a list of terms.
      expect(got.outcome.evidence.shrunk.text).toBe("[name='' tags=~[%a %a %a]]");
      expect(got.counts).toMatchObject({attempted:3, accepted:2, 'shrink-tried':44, 'shrink-steps':8});
    }
    if (name === '36-weak-generator') {
      // Passes, but on dropped samples and short lists.
      expect(got.counts).toMatchObject({attempted:324, accepted:100, dropped:215, duplicate:9});
      expect(got.distribution.labels).toEqual({short:94, long:6});
    }
    if (name === '37-insert-generated') {
      expect(got.counts).toMatchObject({attempted:101, accepted:100, dropped:0, duplicate:1});
      expect(got.distribution.labels).toEqual({short:39, long:61});
    }
    if (name === '35-cover-table') {
      // ++cover-table shares are of the table's entries; all are met.
      expect(got.counts).toMatchObject({attempted:164, accepted:100, duplicate:64});
      expect(got.outcome.warnings).toEqual([]);
    }
    if (name === '21-small-domain-allow') {
      expect(got.config.duplicates).toBe('allow');
      expect(got.counts.duplicate).toBe(0);
      expect(got.distribution.labels).toEqual({both:28, 'a only':21, 'b only':28, neither:23});
    }
    if (name === '24-filter-map-swap') {
      // Generated functions shrink like data; the notes print the tables.
      expect(got.outcome.evidence.why.detail.notes)
        .toEqual(['f = {_ -> 0}', 'p = {8 -> %.y, _ -> %.n}']);
      expect(got.outcome.evidence.why.detail.compared).toEqual({want:'~[0]', got:'~'});
      expect(got.counts).toMatchObject({'shrink-tried':37, 'shrink-steps':5});
      await expect(page.locator('#run-notes')).toContainText('p = {8 -> %.y, _ -> %.n}');
    }
    if (name === '26-counter-agent-bug') {
      // The agent drops an add above ten; the shrunk sample is one add of 11.
      expect(got.outcome.evidence.why.detail.compared).toEqual({want:'11', got:'0'});
      expect(got.counts).toMatchObject({'shrink-tried':21, 'shrink-steps':4});
    }
    if (name === '25-counter-agent') {
      expect(got.counts).toMatchObject({attempted:105, accepted:100, duplicate:5});
    }
    if (name === '22-size-capped') {
      expect(got.config['size-max']).toBe(30);
      expect(got.counts.size).toBe(30);
    }
    if (name === '05-duplicates') {
      expect(got.outcome.budget).toBe('duplicates');
      expect(got.counts).toMatchObject({attempted:4, accepted:1, duplicate:3});
    }
    if (name === '09-custom-alts') {
      expect(got.outcome.evidence.shrunk.text).toBe('value=502');
      expect(got.counts['shrink-steps']).toBeGreaterThan(0);
    }
    const evidence = {path, record:got};
    if (name === '08-seeded-threshold') {
      expect(got.outcome.evidence.original.text).toBe('value=541');
      expect(got.outcome.evidence.shrunk.text).toBe('value=501');
      await page.locator('#run-replay').click();
      await expect.poll(async () => (await record())?.id).not.toBe(got.id);
      await expect.poll(async () => (await record())?.status).toBe('done');
      evidence.replay = await record();
      expect(evidence.replay.outcome.evidence).toEqual(got.outcome.evidence);
      expect(evidence.replay.counts).toEqual(got.counts);
      await page.screenshot({path:info.outputPath('threshold.png'),fullPage:true});
    }
    fs.writeFileSync(info.outputPath('run.json'), JSON.stringify(evidence,null,2)+'\n');
  });
}
test('Preview shows samples, verdicts and shrink candidates', async ({page}) => {
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  await page.evaluate(path => window.quiz.documents.open('property', path),
    ['clay', 'quiz', 'now', 'examples', 'failing', '08-seeded-threshold', 'hoon']);
  await page.locator('#run-previewCount').fill('5');
  await page.locator('#run-preview').click();
  const record = () => page.evaluate(() => {
    const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
    return window.quiz.runs.records.get(id);
  });
  await expect.poll(async () => (await record())?.status, {timeout:45000}).toBe('done');
  const got = await record();
  expect(got.request.mode).toEqual({kind:'preview', count:5, verdicts:true, alts:true});
  expect(got.outcome.kind).toBe('preview');
  expect(got.outcome.rows.map(row => row.size)).toEqual([1, 2, 3, 4, 5]);
  expect(got.outcome.rows.every(row => typeof row.verdict === 'string')).toBeTruthy();
  expect(got.outcome.candidates.length).toBeGreaterThan(0);
  expect(got.counts.accepted).toBe(0);
  await expect(page.locator('#run-preview-rows')).toContainText('Size');
  await expect(page.locator('#run-replay')).toBeDisabled();
});
test('Run panel overrides the duplicates policy', async ({page}) => {
  // 05-duplicates exhausts under %mug; evaluating repeats lets it pass.
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  await page.evaluate(path => window.quiz.documents.open('property', path),
    ['clay', 'quiz', 'now', 'examples', 'failing', '05-duplicates', 'hoon']);
  await expect(page.locator('#run-mode')).toHaveValue('file');
  await page.locator('#run-duplicates').selectOption('allow');
  await page.locator('#run-sizeMax').fill('4');
  await page.locator('#run-start').click();
  const record = () => page.evaluate(() => {
    const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
    return window.quiz.runs.records.get(id);
  });
  await expect.poll(async () => (await record())?.status, {timeout:45000}).toBe('done');
  const got = await record();
  expect(got.outcome.kind).toBe('passed');
  expect(got.config).toMatchObject({duplicates:'allow', 'size-max':4, 'duplicates-max':3, requested:2});
  expect(got.counts).toMatchObject({attempted:2, accepted:2, duplicate:0});
  await page.locator('#run-duplicates').selectOption('');
  await page.locator('#run-sizeMax').fill('');
});
test('hanging samples fail with a timeout under on-timeout %fail', async ({page}) => {
  // Example 27's ++within lowers its call limit to 0.5 s under the ship's
  // 10 s default, so no Settings change is needed.
  test.setTimeout(120000);
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  const started = Date.now();
  {
    await page.goto('/apps/quiz/');
    await page.waitForFunction(() => window.quiz?.ready);
    await page.evaluate(() => window.quiz.ready);
    await page.evaluate(path => window.quiz.documents.open('property', path),
      ['clay', 'quiz', 'now', 'examples', 'props', '27-timeout-fail', 'hoon']);
    await page.locator('#run-start').click();
    const record = () => page.evaluate(() => {
      const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
      return window.quiz.runs.records.get(id);
    });
    await expect.poll(async () => (await record())?.status, {timeout:100000}).toBe('done');
    const got = await record();
    expect(got.outcome.kind).toBe('failed');
    expect(got.outcome.evidence.why.kind).toBe('timeout');
    expect(got.outcome.evidence.shrunk.text).toBe('n=11');
    expect(got.config['on-timeout']).toBe('fail');
    expect(got['call-ms']).toBe(500);
    await expect(page.locator('#run-detail')).toContainText('500 ms per call');
    console.log(`27-timeout-fail took ${(Date.now() - started) / 1000} s`);
  }
});
test('hanging samples are discarded and counted as drops under %discard', async ({page}) => {
  // Each hanging sample costs the call limit; a drop budget of 3 keeps this short.
  test.setTimeout(300000);
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  const limits = (call) => page.request.post('/apps/quiz/api',
    {data:{op:'set-timeouts', 'call-time':call, 'build-time':30, 'arm-time':60}});
  expect((await limits(2)).status()).toBe(202);
  try {
    await page.goto('/apps/quiz/');
    await page.waitForFunction(() => window.quiz?.ready);
    await page.evaluate(() => window.quiz.ready);
    await page.evaluate(() => window.quiz.documents.create('property', {text: [
      '/+  engine=quiz-engine, gen=quiz-gen',
      '|%',
      '++  fate',
      '  |=  n=@ud',
      '  ^-  ?(? %drop)',
      '  ?:  (lth n 11)  &',
      '  |-  ^-  ?(? %drop)',
      '  $',
      '++  norn  (range:gen 0 99)',
      '++  conf',
      '  =/  cfg  defaults:engine',
      '  [[~ 0v123] cfg(requested 5, drops-max 3, on-timeout %discard)]',
      '--'].join('\n')}));
    await page.locator('#run-start').click();
    const record = () => page.evaluate(() => {
      const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
      return window.quiz.runs.records.get(id);
    });
    await expect.poll(async () => (await record())?.status, {timeout:240000}).toBe('done');
    const got = await record();
    expect(got.outcome.kind).toBe('exhausted');
    expect(got.outcome.budget).toBe('drops');
    expect(got.counts.dropped).toBe(3);
    expect(got.config['on-timeout']).toBe('discard');
  } finally {
    expect((await limits(10)).status()).toBe(202);
  }
});
test('Preview summarizes a weak generator against its repair', async ({page}) => {
  test.setTimeout(120000);
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  const summary = async (name) => {
    await page.evaluate(path => window.quiz.documents.open('property', path),
      ['clay', 'quiz', 'now', 'examples', 'props', name, 'hoon']);
    await page.locator('#run-previewShow').selectOption('verdicts');
    await page.locator('#run-previewCount').fill('200');
    const newest = () => page.evaluate(() =>
      window.quiz.documents.active('property').runIds?.[0] || null);
    const before = await newest();
    await page.locator('#run-preview').click();
    let id;
    await expect.poll(async () => (id = await newest()) !== before).toBe(true);
    let record;
    await expect.poll(async () => (record = await (await page.request.post('/apps/quiz/api',
      {data:{op:'status', id}})).json())?.outcome?.kind, {timeout:60000}).toBe('preview');
    await expect(page.locator('#run-preview-summary')).toContainText('Generator summary: 200 samples');
    return record.outcome;
  };
  const weak = await summary('36-weak-generator');
  expect(weak.rows.length).toBe(100);
  expect(weak.summary.verdicts.drop).toBe(132);
  expect(weak.summary.labels.long).toBe(1);
  await expect(page.locator('#run-preview-notes')).toContainText('66% of samples were discarded');
  await expect(page.locator('#run-detail')).toContainText('Preview: first 100 of 200 samples');
  const strong = await summary('37-insert-generated');
  expect(strong.summary.verdicts.drop).toBeUndefined();
  expect(strong.summary.labels.long).toBe(119);
  await expect(page.locator('#run-preview-notes')).toHaveCount(0);
});

test('Find examples for each label shows the smallest of each', async ({page}) => {
  test.setTimeout(240000);
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  const search = async (name) => {
    await page.evaluate(path => window.quiz.documents.open('property', path),
      ['clay', 'quiz', 'now', 'examples', 'props', name, 'hoon']);
    await page.locator('#run-examplesCount').fill('100');
    const newest = () => page.evaluate(() =>
      window.quiz.documents.active('property').runIds?.[0] || null);
    const before = await newest();
    await page.locator('#run-find-examples').click();
    let id;
    await expect.poll(async () => (id = await newest()) !== before).toBe(true);
    let record;
    await expect.poll(async () => (record = await (await page.request.post('/apps/quiz/api',
      {data:{op:'status', id}})).json())?.outcome?.kind, {timeout:90000}).toBe('examples');
    expect(record.request.mode).toEqual({kind:'examples', count:100});
    expect(record.outcome.evidence).toBeNull();
    await expect(page.locator('#run-found-examples')).toBeVisible();
    await expect(page.locator('#run-replay')).toBeDisabled();
    return Object.fromEntries(record.outcome.found.map(row => [row.label, row.sample.text]));
  };
  // Tags and times render as numbers: %pop 7.368.560, %push 1.752.397.168,
  // %put 7.632.240, %wait 1.953.063.287, %a 97, ~s1 2^64.
  expect(await search('10-queue-model')).toEqual({
    'empty-pop': 'cmds=[[7.368.560 0] 0]',
    refill: 'cmds=[[1.752.397.168 0] [7.368.560 0] 0]'});
  await expect(page.locator('#run-found')).toContainText('Smallest example for each of 2 labels');
  expect(await search('16-sorted-insert')).toEqual({
    empty: '[items=0 new=0]', end: '[items=[0 0] new=1]',
    front: '[items=[0 0] new=0]', middle: '[items=[0 1 0] new=1]'});
  const put = '[7.632.240 97 0 18.446.744.073.709.551.616]';
  expect(await search('32-expiry-agent')).toEqual({
    expired: `raw=[${put} [1.953.063.287 18.446.744.073.709.551.616] 0]`,
    'repeated-key': `raw=[${put} ${put} 0]`});
});
