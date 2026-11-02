'use strict';
const fs = require('node:fs');
const {test, expect} = require('@playwright/test');
test.skip(!process.env.QUIZ_CODE, 'Set QUIZ_CODE for the disposable ship.');
test.beforeEach(async ({page}) => {
  await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
});

test('rendered help routes, repository links and restored tabs', async ({page}, info) => {
  test.skip(process.env.QUIZ_DOCS !== 'present', 'Install a Markdown-capable %docs and set QUIZ_DOCS=present.');
  test.setTimeout(300000);
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const toc = fs.readFileSync('desk/doc.toc','utf8').trim().split('\n')
    .map(line => line.trim().split(/\s{2,}/));
  const routes = [];
  for (const [path, title] of toc) {
    const slug = path.split('/')[1];
    const {status, html} = await page.evaluate(async slug => {
      const response = await fetch(`/docs/d/quiz/${slug}`);
      return {status:response.status, html:await response.text()};
    }, slug);
    expect(status, title).toBe(200);
    expect(html, title).toContain('<h1');
    expect(html, title).not.toContain('mark conversion failure');
    routes.push({slug, title, status});
    console.log(`Rendered ${slug}: ${status}`);
  }
  await page.locator('#help').click();
  await expect(page.locator('#docs-help-content')).toBeVisible();
  await page.locator('#docs-help-nav').getByText("User's Guide",{exact:true}).click();
  const guide = page.frameLocator('iframe[title="User\'s Guide documentation"]');
  await expect(guide.locator('main h1')).toHaveText("Quiz user's guide");
  await expect(guide.getByRole('link',{name:'reference',exact:true}).first())
    .toHaveAttribute('href','/docs/d/quiz/reference');
  await guide.getByRole('link',{name:'reference',exact:true}).first().click();
  await expect(guide.locator('main h1')).toHaveText('Quiz reference');
  await expect(guide.getByRole('link',{name:'legacy library',exact:true}))
    .toHaveAttribute('href','https://github.com/jackfoxy/quiz/blob/dev/desk/lib/quiz.hoon');
  await expect(guide.getByRole('link',{name:'legacy library',exact:true}))
    .toHaveAttribute('target','_blank');
  await page.locator('#help').click();
  await page.locator('#docs-help-nav').getByText("User's Guide",{exact:true}).click();
  await page.locator('#help').click();
  await page.locator('#docs-help-nav').getByText('Keyboard Shortcuts',{exact:true}).click();
  await expect(page.locator('.docs-tab')).toHaveCount(3);
  await page.evaluate(() => window.quiz.runtime.session.save());
  await page.reload();
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  await expect(page.locator('.docs-tab')).toHaveCount(3);
  const restoredPanel = await page.locator('.docs-tab[data-doc-path="keyboard-shortcuts"]')
    .getAttribute('aria-controls');
  await expect(page.frameLocator(`#${restoredPanel} iframe`).locator('main h1'))
    .toHaveText('Keyboard shortcuts');
  expect(errors).toEqual([]);
  fs.writeFileSync(info.outputPath('help-routes.json'),JSON.stringify(routes,null,2)+'\n');
  await page.screenshot({path:info.outputPath('help.png'),fullPage:true});
});

test('fallback help documents the configured commands', async ({page}) => {
  test.skip(process.env.QUIZ_DOCS === 'present', 'Run this check with %docs absent.');
  await page.locator('#help').click();
  await expect(page.locator('#fallback-help-content')).toBeVisible();
  const text = await page.locator('#fallback-help-content').innerText();
  for (const key of ['Ctrl-S','Ctrl-Shift-S','Ctrl-O','Command']) expect(text).toContain(key);
  expect(text).not.toContain('Heathcliff');
});
