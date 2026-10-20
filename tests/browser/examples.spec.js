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
    if (outcome === 'passed') expect(got.counts.accepted).toBe(20);
    if (name === '04-discards') expect(got.counts.dropped).toBeGreaterThan(0);
    if (name === '07-positive') expect(got.counts.dropped).toBe(0);
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
