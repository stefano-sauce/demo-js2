// Shared config for the Deque axe DevTools Mobile examples on Sauce Labs real devices.
// Docs: https://docs.saucelabs.com/mobile-apps/automated-testing/appium/appium-deque-accessibility-testing/
exports.config = {
  runner: 'local',
  user: process.env.SAUCE_USERNAME,
  key: process.env.SAUCE_ACCESS_KEY,
  // Available short handles for regions are `eu` (default) and `us`.
  region: process.env.REGION || 'eu',

  specs: ['../specs/*.spec.js'],
  maxInstances: 10,
  capabilities: [],

  logLevel: 'silent',
  bail: 0,
  waitforTimeout: 30000,
  connectionRetryTimeout: 5 * 60 * 1000,
  connectionRetryCount: 2,

  services: ['sauce'],
  framework: 'mocha',
  reporters: ['spec'],
  mochaOpts: {
    ui: 'bdd',
    timeout: 5 * 60 * 1000,
  },
};
