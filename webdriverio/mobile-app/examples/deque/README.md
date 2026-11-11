# Deque axe DevTools Mobile on Sauce Labs real devices

Runs [Deque axe DevTools Mobile](https://docs.saucelabs.com/mobile-apps/automated-testing/appium/appium-deque-accessibility-testing/)
scans of native apps on Sauce Labs real devices with WebdriverIO.

- Android: `SauceLabs-Demo-App.apk` with `appium:automationName: 'AxeUIAutomator2'`
- iOS: `SauceBankingDemo-iOS-RealDevice.ipa` with `appium:automationName: 'AxeXCUITest'`
- Both use `sauce:options.appiumVersion: 'appium3-deque-accessibility'`

The apps must already be uploaded to Sauce Storage in the region you run in.

## Run

```sh
export SAUCE_USERNAME=...
export SAUCE_ACCESS_KEY=...
export DEQUE_API_KEY=...   # AXE_DEVTOOLS_APIKEY also works
npm install
npm run test.sauce.rdc.android.eu
npm run test.sauce.rdc.ios.eu
```

Scan results show up in the [axe DevTools Mobile dashboard](https://axe-mobile.deque.com).
The Sauce Labs job holds the video, logs, network capture and device vitals.
