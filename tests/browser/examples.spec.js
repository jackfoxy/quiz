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
    const path = [root, name, 'hoon'];
    const listing = await page.request.post('/apps/quiz/files', {data:{op:'browse',scope:[root]}});
    expect(listing.ok()).toBeTruthy();
    expect((await listing.json()).entries.some(entry =>
      JSON.stringify(entry.path) === JSON.stringify(path))).toBeTruthy();
    await page.evaluate(path => window.quiz.documents.open('property', path), path);
    await expect(page.locator('#run-mode')).toHaveValue(outcome === 'suite' ? 'suite' : 'file');
    await expect(page.locator('#property-save')).toBeDisabled();
    // Both write operations must remain refused on every example root.
    for (const op of ['save', 'delete']) {
      const refused = await page.request.post('/apps/quiz/files', {data:{op,path,text:'x'}});
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
    expect(got.snapshot.path).toEqual(root === 'examples'
      ? ['tests','examples',name,'hoon'] : ['examples',root,name,'hoon']);
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
        '25-counter-agent', '32-expiry-agent'].includes(name) ? 100 : 20);
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
    }
    if (name === '28-confident-coverage') {
      // %confident runs past requested until the Wilson bound decides.
      expect(got.counts).toMatchObject({accepted:800, attempted:800});
      expect(got.distribution.labels).toEqual({heads:377});
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
      expect(got.outcome.shortfalls).toEqual([{label:'empty', want:10, got:1}]);
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
test('Run panel overrides the duplicates policy', async ({page}) => {
  // 05-duplicates exhausts under %mug; evaluating repeats lets it pass.
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  await page.evaluate(path => window.quiz.documents.open('property', path),
    ['failing', '05-duplicates', 'hoon']);
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
  // Each hanging sample costs the whole call limit, so set 2 s and restore.
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
    await page.evaluate(path => window.quiz.documents.open('property', path),
      ['props', '27-timeout-fail', 'hoon']);
    await page.locator('#run-start').click();
    const record = () => page.evaluate(() => {
      const id = JSON.parse(localStorage.getItem('quiz.session')).runSelection;
      return window.quiz.runs.records.get(id);
    });
    await expect.poll(async () => (await record())?.status, {timeout:240000}).toBe('done');
    const got = await record();
    expect(got.outcome.kind).toBe('failed');
    expect(got.outcome.evidence.why.kind).toBe('timeout');
    expect(got.outcome.evidence.shrunk.text).toBe('n=11');
    expect(got.config['on-timeout']).toBe('fail');
    await page.locator('#run-cancel').isVisible();
  } finally {
    expect((await limits(10)).status()).toBe(202);
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
