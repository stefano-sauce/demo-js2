import config from './wdio.shared.sauce.conf';
const buildName = `iOS Simulator Native Simple Example: build-${new Date().getTime()}`;
const sauceTags = (process.env.SAUCE_TAGS || '').split(',').filter(Boolean);

config.capabilities = [{
   platformName: 'iOS',
   'appium:platformVersion': '15.0',
   'appium:deviceName': 'iPhone X Simulator',
   'appium:automationName': 'XCUITest',
   // The name of the App in the Sauce Labs storage, for more info see
   // https://docs.saucelabs.com/mobile-apps/app-storage/
   'appium:app': 'storage:filename=iOS.MyDemoAppRN.zip',
   'appium:noReset': true,
   'appium:shouldTerminateApp': true,
   'appium:newCommandTimeout': 240,
   'sauce:options': {
      build: buildName,
      appiumVersion: '1.22.0',
      tags: sauceTags,
   },
}];

exports.config = config;