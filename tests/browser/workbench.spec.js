'use strict';
const {test, expect} = require('@playwright/test');
const password = process.env.QUIZ_CODE;
test.skip(!password, 'Set QUIZ_CODE to the disposable ship login code.');
test.beforeEach(async ({page}) => {
  const login = await page.request.post('/~/login', {form: {password}});
  expect(login.ok()).toBeTruthy();
  await page.goto('/apps/quiz/');
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
});

test('create, save, save as, reopen, protect edits and restore session', async ({page}) => {
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  const stem = `browser-${Date.now()}`;
  const text = '|%\n++  fate\n  |=  n=@ud\n  =(n n)\n--';
  const paths = [stem, `${stem}-copy`];
  try {
    await page.locator('#quiz-editor .ace_text-input').focus();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.insertText(text);
    await expect.poll(() => page.evaluate(() =>
      window.quiz.documents.active('property').text)).toBe(text);
    await page.locator('#property-save').click();
    await page.locator('#urui-file-dialog-path').fill(stem);
    await page.locator('#urui-file-dialog-confirm').click();
    await expect(page.locator('#document-location')).toHaveText(`work/${stem}/hoon`);
    await page.locator('#property-save-as').click();
    await page.locator('#urui-file-dialog-path').fill(`${stem}-copy`);
    await page.locator('#urui-file-dialog-confirm').click();
    await expect(page.locator('#document-location')).toHaveText(`work/${stem}-copy/hoon`);
    await page.evaluate(() => window.quiz.documents.close('property',
      window.quiz.documents.active('property').id));
    await page.locator('#property-open').click();
    await page.locator('#urui-file-dialog-list').getByText(`work/${stem}/hoon`, {exact: true}).dblclick();
    await expect(page.locator('#document-location')).toHaveText(`work/${stem}/hoon`);
    expect(await page.evaluate(() => window.quiz.documents.active('property').text)).toBe(text);
    await page.locator('#quiz-editor .ace_text-input').focus();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.insertText(':: unsaved\n' + text);
    await page.evaluate(() => { window.quiz.documents.close('property',
      window.quiz.documents.active('property').id); });
    await expect(page.locator('#urui-confirm')).toBeVisible();
    await page.locator('#urui-confirm-cancel').click();
    await page.evaluate(() => window.quiz.runtime.session.save());
    page.once('dialog', (dialog) => dialog.accept());
    await page.reload();
    await page.waitForFunction(() => window.quiz?.ready);
    await page.evaluate(() => window.quiz.ready);
    expect(await page.evaluate(() => window.quiz.documents.active('property').text))
      .toBe(':: unsaved\n' + text);
    expect(await page.evaluate(() => window.quiz.documents.dirty('property',
      window.quiz.documents.active('property').id))).toBe(true);
    await page.screenshot({path: 'test-results/workbench.png', fullPage: true});
    expect(errors).toEqual([]);
  } finally {
    for (const name of paths) await page.request.post('/apps/quiz/files',
      {data: {op: 'delete', path: ['work', name, 'hoon']}});
  }
});

test('read-only examples/docs, editable copies, pinned Clay and fallback help', async ({page}) => {
  await page.evaluate(() => window.quiz.documents.open('property',
    ['examples', '02-boxcar', 'hoon']));
  await expect(page.locator('#editable-copy')).toBeVisible();
  await expect(page.locator('#property-save')).toBeDisabled();
  expect(await page.evaluate(() => ace.edit('quiz-editor').getReadOnly())).toBe(true);
  const source = await page.evaluate(() => window.quiz.documents.active('property').text);
  await page.locator('#editable-copy').click();
  await expect(page.locator('#property-save')).toBeEnabled();
  expect(await page.evaluate(() => window.quiz.documents.active('property').text)).toBe(source);
  await page.evaluate(() => window.quiz.documents.open('property',
    ['docs', 'source-format', 'md']));
  await expect(page.locator('#property-save')).toBeDisabled();
  await page.locator('#editable-copy').click();
  await expect(page.locator('#property-save')).toBeEnabled();
  await page.evaluate(() => window.quiz.runtime.explorer.setView('clay-source'));
  const rev = await page.locator('#clay-revision').inputValue();
  const pinned = String(Number(rev) - 1);
  await page.locator('#clay-revision').fill(pinned);
  await page.locator('#clay-browse').click();
  await expect(page.locator('#clay-state')).toContainText(`revision ${pinned}`);
  await page.locator('#clay-files button').filter({hasText: /^lib\/quiz\/hoon$/}).click();
  await expect(page.locator('#document-location')).toHaveText(`Read-only: clay/quiz/${pinned}/lib/quiz/hoon`);
  await page.evaluate(() => window.quiz.runtime.session.save());
  page.once('dialog', (dialog) => dialog.accept());
  await page.reload();
  await page.waitForFunction(() => window.quiz?.ready);
  await page.evaluate(() => window.quiz.ready);
  await expect(page.locator('#clay-revision')).toHaveValue(pinned);
  await expect(page.locator('#property-save')).toBeDisabled();
  await page.locator('#help').click();
  await expect(page.locator('#fallback-help-content')).toBeVisible();
  await expect(page.locator('#fallback-help-content p').first()).toContainText('Install %docs');
  expect(Number(rev)).toBeGreaterThan(1);
});

test('Hoon mode tokenizes runes, atoms, brackets and comments', async ({page}) => {
  const result = await page.evaluate(() => {
    const mode = ace.edit('quiz-editor').session.getMode();
    return {id: mode.$id, comment: mode.lineCommentStart,
      tokens: mode.getTokenizer().getLineTokens('|=  [n=@ud 42]  :: comment', 'start').tokens};
  });
  expect(result.id).toBe('ace/mode/hoon');
  expect(result.comment).toBe('::');
  for (const type of ['keyword.operator', 'storage.type', 'constant.numeric',
    'paren.lparen', 'paren.rparen', 'comment']) {
    expect(result.tokens.some((token) => token.type === type), type).toBe(true);
  }
});

test('file wire rejects writes outside work and unavailable contexts', async ({page}) => {
  const post = (data) => page.request.post('/apps/quiz/files', {data});
  for (const path of [['examples', 'copy', 'hoon'], ['docs', 'copy', 'md']]) {
    const save = await post({op: 'save', path, text: 'forbidden'});
    expect(save.status()).toBe(path[0] === 'docs' ? 400 : 403);
    const remove = await post({op: 'delete', path});
    expect(remove.status()).toBe(403);
  }
  for (const [scope, status] of [
    [['clay'], 400], [['clay', 'quiz', 'nope'], 400],
    [['clay', 'quiz', '999999999'], 404],
    [['clay', 'missing-unit-nine', '1'], 404]
  ]) expect((await post({op: 'browse', scope})).status()).toBe(status);
  expect((await post({op: 'save', path: ['work', '..', 'escape', 'hoon'],
    text: 'forbidden'})).status()).toBe(400);
  const rev = await page.locator('#clay-revision').inputValue();
  const path = ['clay', 'quiz', rev, 'lib', 'quiz', 'hoon'];
  expect((await post({op: 'save', path, text: 'forbidden'})).status()).toBe(403);
  expect((await post({op: 'delete', path})).status()).toBe(403);
});
