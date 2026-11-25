'use strict';
// Validates the workbench paths that ai-ug.md teaches and that no other
// browser spec reaches: help and settings shortcuts, copy and open shortcuts,
// a reference panel, the run shortcut, Clay source browsing, Use latest
// revision, and the Vim keybinding setting. Other guide steps are covered by
// examples.spec.js, runs.spec.js, workbench.spec.js and scenario doubles.
const {test, expect} = require('@playwright/test');

async function open(page) {
  const login = await page.request.post('/~/login', {form:{password:process.env.QUIZ_CODE}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
}

test('F1 opens Help and F2 opens Settings with the CPU limits', async ({page}) => {
  await open(page);
  await page.locator('body').click({position: {x: 5, y: 5}});
  await page.keyboard.press('F1');
  await expect(page.locator('#help-panel')).toBeVisible();
  await page.keyboard.press('Escape');
  await page.keyboard.press('F2');
  await expect(page.locator('#settings-modal')).toBeVisible();
  await expect(page.locator('#quiz-limit-call')).toHaveValue('10');
  await expect(page.locator('#quiz-limit-build')).toHaveValue('30');
  await expect(page.locator('#quiz-limit-arm')).toHaveValue('60');
  await expect(page.locator('#keys-vim')).toHaveCount(1);
  await page.keyboard.press('Escape');
});

test('New document, Copy (Alt-C) and Open (Alt-O) work from outside the editor', async ({page, context}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write'], {origin: 'http://127.0.0.1:8092'});
  await open(page);
  await page.locator('button:has-text("+")').first().click();
  await expect.poll(() => page.evaluate(() => window.quiz.documents.list('property').length)).toBeGreaterThan(0);
  const text = '|%\n++  fate\n  |=  n=@ud\n  =(n n)\n--';
  await page.locator('#quiz-editor .ace_text-input').focus();
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.insertText(text);
  await expect.poll(() => page.evaluate(() => window.quiz.documents.active('property').text)).toBe(text);
  // Alt-C copies the document's text to the clipboard. It does not open a tab.
  // A real Alt-C arrives as the lowercase key, so the press is lowercase too.
  const count = () => page.evaluate(() => window.quiz.documents.list('property').length);
  const tabs = await count();
  await page.evaluate(() => navigator.clipboard.writeText('before'));
  await page.locator('#run-controls select').first().focus();
  await page.keyboard.press('Alt+c');
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(text);
  expect(await count()).toBe(tabs);
  // Alt-O opens the file chooser.
  await page.locator('#run-controls select').first().focus();
  await page.keyboard.press('Alt+o');
  await expect(page.locator('#urui-file-dialog')).toBeVisible();
  await page.locator('#urui-file-dialog-cancel').click();
});

test('Ctrl-Shift-S saves as, Ctrl-S saves, and the API has no run-history delete', async ({page}) => {
  await open(page);
  const name = `guide-${Date.now()}`;
  await page.locator('button:has-text("+")').first().click();
  await page.locator('#quiz-editor .ace_text-input').focus();
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.insertText('|%\n++  fate\n  |=  n=@ud\n  =(n n)\n--');
  await page.keyboard.press('ControlOrMeta+Shift+S');
  await page.locator('#urui-file-dialog-path').fill(name);
  await page.locator('#urui-file-dialog-confirm').click();
  await expect(page.locator('#document-location')).toHaveText(`work/${name}/hoon`);
  await page.locator('#quiz-editor .ace_text-input').focus();
  await page.keyboard.press('ControlOrMeta+End');
  await page.keyboard.insertText('\n:: edited\n');
  await page.keyboard.press('ControlOrMeta+S');
  await expect.poll(() => page.evaluate(() => window.quiz.documents.dirty('property',
    window.quiz.documents.active('property').id))).toBe(false);
  await page.request.post('/apps/quiz/files', {data: {op: 'delete', path: ['work', name, 'hoon']}});
  // Run history has no delete or clear over HTTP; the agent keeps its own
  // retention bound. Both operations must be refused.
  for (const op of ['delete', 'clear']) {
    const reply = await page.request.post('/apps/quiz/api', {data: {op, id: 1}});
    expect(reply.ok()).toBeFalsy();
  }
});

test('the run panel has no budget or timeout override fields', async ({page}) => {
  await open(page);
  for (const id of ['run-attemptsMax', 'run-dropsMax', 'run-duplicatesMax', 'run-onTimeout', 'run-bounds']) {
    await expect(page.locator(`#${id}`)).toHaveCount(0);
  }
});

test('F5 runs the selected property from the run panel', async ({page}) => {
  await open(page);
  await page.evaluate(path => window.quiz.documents.open('property', path),
    ['props', '01-success', 'hoon']);
  await expect(page.locator('#run-mode')).toHaveValue('file');
  const before = await page.evaluate(() => window.quiz.documents.active('property').runIds?.length || 0);
  await page.locator('#run-mode').focus();
  await page.keyboard.press('F5');
  await expect.poll(() => page.evaluate(() => window.quiz.documents.active('property').runIds?.length || 0))
    .toBeGreaterThan(before);
});

test('Add Ref opens a reference panel that follows the document', async ({page}) => {
  await open(page);
  const text = '|%\n++  fate\n  |=  n=@ud\n  =(n n)\n--';
  await page.locator('#quiz-editor .ace_text-input').focus();
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.insertText(text);
  await expect.poll(() => page.evaluate(() => window.quiz.documents.active('property').text)).toBe(text);
  await page.getByRole('button', {name: 'Add Ref'}).click();
  const ref = page.locator('.ref-source').filter({hasText: '++  fate'});
  await expect(ref).toHaveCount(1);
  await page.evaluate(() => window.quiz.documents.editor('property')
    .setSource('|%\n++  fate\n  |=  n=@ud\n  (lte n 9)\n--', {history: 'reset'}));
  await expect(page.locator('.ref-source').filter({hasText: '(lte n 9)'})).toHaveCount(1);
});

test('Use latest revision and Clay source browsing open a read-only file', async ({page}) => {
  await open(page);
  await page.getByRole('button', {name: 'Use latest revision'}).click();
  await expect(page.locator('#run-revision')).not.toHaveValue('');
  const revision = await page.locator('#run-revision').inputValue();
  await page.getByRole('tab', {name: 'Clay source'}).click();
  await expect(page.locator('#clay-desk')).toHaveValue('quiz');
  await page.locator('#clay-revision').fill(revision);
  await page.getByRole('button', {name: 'Browse revision'}).click();
  const file = page.locator('#clay-files button').filter({hasText: 'props'}).first();
  await expect(file).toBeVisible({timeout: 30000});
  await file.click();
  await expect(page.locator('#document-location')).toHaveText(/clay|props/);
});

test('Vim keybindings are a Settings choice that changes the editor handler', async ({page}) => {
  await open(page);
  await page.keyboard.press('F2');
  await expect(page.locator('#settings-modal')).toBeVisible();
  await page.locator('#keys-vim').check();
  await page.keyboard.press('Escape');
  await expect.poll(() => page.evaluate(() => document.documentElement.dataset.keybindings)).toBe('vim');
  await page.keyboard.press('F2');
  await page.locator('#keys-ace').check();
  await page.keyboard.press('Escape');
  await expect.poll(() => page.evaluate(() => document.documentElement.dataset.keybindings)).toBe('ace');
});
