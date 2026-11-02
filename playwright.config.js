'use strict';
const {defineConfig} = require('@playwright/test');
module.exports = defineConfig({
  testDir: './tests/browser',
  testMatch: '*.spec.js',
  workers: 1,
  timeout: 60000,
  expect: {timeout: 15000},
  use: {
    baseURL: process.env.QUIZ_URL || 'http://127.0.0.1:18881',
    headless: true,
    locale: 'en-US', timezoneId: 'UTC', colorScheme: 'light',
    viewport: {width: 1440, height: 1000},
    screenshot: 'only-on-failure', trace: 'retain-on-failure'
  }
});
