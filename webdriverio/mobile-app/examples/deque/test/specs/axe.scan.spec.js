// Scan results are pushed to Deque's axe DevTools Mobile dashboard (https://axe-mobile.deque.com),
// the Sauce Labs job holds the usual video/logs/network/vitals for the session.
const API_KEY = process.env.DEQUE_API_KEY || process.env.AXE_DEVTOOLS_APIKEY;

/**
 * Runs a Deque axe scan of the current screen and fails the test if the driver reports
 * an error in-band (e.g. an invalid API key), instead of silently passing with no results.
 */
async function axeScan(scanName) {
  const platform = driver.isAndroid ? 'android' : 'ios';
  const result = await driver.execute('mobile: axeScan', {
    apiKey: API_KEY,
    scanName: `${scanName} (${platform})`,
    tags: ['deque-mobile', platform],
  });

  if (result && result.axeError) {
    throw new Error(`axe scan "${scanName}" failed: ${result.axeError}`);
  }

  return result;
}

describe('Deque axe DevTools Mobile', () => {
  before(() => {
    if (!API_KEY) {
      throw new Error('Set DEQUE_API_KEY (or AXE_DEVTOOLS_APIKEY) to your axe DevTools Mobile API key.');
    }
  });

  it('should accessibility scan the launch screen', async () => {
    // Give the app time to get past any splash screen
    await driver.pause(5000);
    await axeScan('Launch screen');
  });

  it('should accessibility scan a second screen', async () => {
    // Open the first item on the launch screen, the scan runs on whatever screen is shown next
    const selector = driver.isAndroid
      ? 'android=new UiSelector().clickable(true).index(0)'
      : '-ios class chain:**/XCUIElementTypeButton[`visible == 1`]';
    const elements = await $$(selector);

    if (elements.length > 0) {
      await elements[elements.length > 1 ? 1 : 0].click();
      await driver.pause(3000);
    }

    await axeScan('Second screen');
  });
});
