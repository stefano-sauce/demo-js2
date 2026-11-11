const { config } = require('./wdio.shared.sauce.conf');

const buildName = `deque-mobile: Android axe DevTools Mobile build-${new Date().getTime()}`;
const sauceTags = (process.env.SAUCE_TAGS || '').split(',').filter(Boolean);

config.capabilities = [
  {
    platformName: 'Android',
    'appium:deviceName': '(Samsung Galaxy S.*)|(Google Pixel.*)',
    // The axe-enabled UiAutomator2 driver adds the `mobile: axeScan` command
    'appium:automationName': 'AxeUIAutomator2',
    'appium:app': 'storage:filename=SauceLabs-Demo-App.apk',
    'appium:appWaitActivity': '*',
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 240,
    'sauce:options': {
      build: buildName,
      // Sauce-hosted Appium image that ships the Deque axe drivers
      appiumVersion: 'appium3-deque-accessibility',
      phoneOnly: true,
      tags: sauceTags,
      // No networkCapture here: on Android it proxies device traffic through a Sauce
      // certificate the axe driver rejects, so every axeScan fails with "Authentication failed"
      vitals: true,
    },
  },
];

exports.config = config;
