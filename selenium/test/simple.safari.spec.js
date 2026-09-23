const webdriver = require('selenium-webdriver');
const assert = require('assert');

describe('Sauce Demo Test', function() {
  let driver;
  
  it('should verify title of Sauce Demo site', async function() {
    const username = process.env.SAUCE_USERNAME;
    const accessKey = process.env.SAUCE_ACCESS_KEY;
    
    if (!username || !accessKey) {
      throw new Error('SAUCE_USERNAME and SAUCE_ACCESS_KEY environment variables must be set');
    }
    
    const capabilities = {
      browserName: 'safari',
      browserVersion: 'latest',
      platformName: 'macOS 13',
      'sauce:options': {
        username: username,
        accessKey: accessKey,
        build: 'sample safari-build',
        name: 'sample safari-test',
        // Network/console log capture (Chrome/Firefox get HAR; harmless no-op on Safari)
        extendedDebugging: true,
        tags: (process.env.SAUCE_TAGS || '').split(',').filter(Boolean),
      }
    }

    const region = process.env.SAUCE_REGION || 'us-west-1';

    driver = await new webdriver.Builder()
      .withCapabilities(capabilities)
      .usingServer(`https://ondemand.${region}.saucelabs.com:443/wd/hub`)
      .build();

    // run commands and assertions
    await driver.get('https://www.saucedemo.com');
    const title = await driver.getTitle();
    const titleIsCorrect = title.includes('Swag Labs');
    
    // Assert the title contains "Swag Labs"
    assert(titleIsCorrect, 'Title should contain "Swag Labs"');
    
    // end the session
    await driver.executeScript('sauce:job-result=' + (titleIsCorrect ? 'passed' : 'failed'));
  });
  
  afterEach(async function() {
    if (driver) {
      await driver.quit();
    }
  });
});