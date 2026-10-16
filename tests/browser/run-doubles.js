'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
(async () => {
  const bundle = process.env.QUIZ_BUNDLE;
  const source = bundle ? fs.readFileSync(bundle, 'utf8')
    : await (await fetch(`${process.env.QUIZ_URL || 'http://127.0.0.1:18881'}/apps/quiz/app.js`)).text();
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'quiz-doubles-'));
  const filename = path.join(directory, 'app.js');
  fs.writeFileSync(filename, source);
  for (const scenario of ['documents', 'restore', 'invalid-session', 'runs', 'run-errors']) {
    const result = spawnSync(process.execPath,
      [require.resolve('./scenario.js'), scenario, filename], {encoding: 'utf8', timeout: 15000});
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    if (result.status !== 0) throw new Error(`${scenario} failed`);
  }
  fs.rmSync(directory, {recursive: true});
})().catch((error) => { console.error(error); process.exitCode = 1; });
