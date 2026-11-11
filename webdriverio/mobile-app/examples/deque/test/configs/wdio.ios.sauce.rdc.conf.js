const { config } = require('./wdio.shared.sauce.conf');

const buildName = `deque-mobile: iOS axe DevTools Mobile build-${new Date().getTime()}`;
const sauceTags = (process.env.SAUCE_TAGS || '').split(',').filter(Boolean);

config.capabilities = [
  {
    platformName: 'iOS',
    'appium:deviceName': 'iPhone.*',
    // AxeXCUITest requires iOS 16 or later
    'appium:platformVersion': '^1(6|7|8).*$',
    // The axe-enabled XCUITest driver adds the `mobile: axeScan` command
    'appium:automationName': 'AxeXCUITest',
    'appium:app': 'storage:filename=SauceBankingDemo-iOS-RealDevice.ipa',
    'appium:autoAcceptAlerts': true,
    'appium:newCommandTimeout': 240,
    'sauce:options': {
      build: buildName,
      // Sauce-hosted Appium image that ships the Deque axe drivers
      appiumVersion: 'appium3-deque-accessibility',
      resigningEnabled: true,
      tags: sauceTags,
      networkCapture: true,
      vitals: true,
    },
  },
];

exports.config = config;
