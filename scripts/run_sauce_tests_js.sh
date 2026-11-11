#!/bin/bash

# ------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------

# Project root (this script lives in <repo>/scripts; resolve symlinks so cron can call it via ~/scripts)
PROJECT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

# Credentials are never hardcoded: cron does not load your shell profile, so read the
# `export NAME=value` lines from ~/.zshrc. A value already set in the environment wins.
zshrc_var() {
    sed -n "s/^export $1=//p" "$HOME/.zshrc" 2>/dev/null | tail -1 | tr -d "\"'"
}
for var in SAUCE_USERNAME SAUCE_ACCESS_KEY AXE_DEVTOOLS_APIKEY; do
    [ -z "${!var}" ] && export "$var=$(zshrc_var "$var")"
done

# Region: nightwatch/webdriverio configs read `REGION` (short handle),
# selenium/top-level playwright configs read `SAUCE_REGION` (full DC name).
export REGION=eu
export SAUCE_REGION=eu-central-1

# PATH/Node setup for cron (cron has a minimal PATH)
export PATH="/opt/homebrew/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

LOG_FILE="$HOME/sauce_automation_js.log"

# ------------------------------------------------------------------
# EXECUTION
# ------------------------------------------------------------------

echo "--------------------------------------------------" >> "$LOG_FILE"
echo "Starting Sauce Labs JS Tests: $(date)" >> "$LOG_FILE"

for var in SAUCE_USERNAME SAUCE_ACCESS_KEY; do
    if [ -z "${!var}" ]; then
        echo "ERROR: $var is not set (export it in ~/.zshrc)." >> "$LOG_FILE"
        exit 1
    fi
done
[ -z "$AXE_DEVTOOLS_APIKEY" ] && echo "WARNING: AXE_DEVTOOLS_APIKEY is not set, deque-mobile scans will fail." >> "$LOG_FILE"

if [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
    echo "Changed directory to $PROJECT_DIR" >> "$LOG_FILE"
else
    echo "ERROR: Directory $PROJECT_DIR does not exist." >> "$LOG_FILE"
    exit 1
fi

# Runs `npm run <script>` with SAUCE_TAGS set for the duration of the run.
# $1 = comma-separated Sauce Labs tags, $2.. = npm run <script> (or a saucectl/npx command)
run_npm() {
    local tags="$1"
    shift
    echo "Running (tags=$tags): $@" >> "$LOG_FILE"
    if SAUCE_TAGS="$tags" "$@" >> "$LOG_FILE" 2>&1; then
        echo "SUCCESS: $@" >> "$LOG_FILE"
    else
        echo "FAILURE: $@" >> "$LOG_FILE"
    fi
}

install_deps() {
    echo "Running: npm install (in $(pwd))" >> "$LOG_FILE"
    npm install >> "$LOG_FILE" 2>&1
}

# --- 1. Nightwatch ---
echo "--- Section: Nightwatch ---" >> "$LOG_FILE"
pushd nightwatch/desktop > /dev/null
    install_deps
    run_npm "framework:nightwatch,cli:nightwatch,lang:javascript,usecase:desktop-ui,feature:network-capture" npm run test.saucelabs.eu
popd > /dev/null

pushd nightwatch/mobile > /dev/null
    install_deps
    run_npm "framework:nightwatch,cli:nightwatch,lang:javascript,usecase:mobile-web,feature:network-capture,feature:device-vitals" npm run test.saucelabs.android.eu
    run_npm "framework:nightwatch,cli:nightwatch,lang:javascript,usecase:mobile-web,feature:network-capture,feature:device-vitals" npm run test.saucelabs.ios.eu
popd > /dev/null

# --- 2. WebdriverIO: Desktop ---
echo "--- Section: WebdriverIO Desktop ---" >> "$LOG_FILE"
for dir in "best-practices:desktop-ui-best-practices:typescript:feature:network-capture" \
           "examples/w3c:w3c-capabilities:javascript:feature:network-capture" \
           "examples/deque:deque-web:typescript:feature:accessibility,feature:network-capture" \
           "examples/cucumberjs:bdd-cucumber:javascript:feature:network-capture" \
           "examples/typescript:typescript-demo:typescript:feature:network-capture,feature:performance-mode"; do
    subdir="${dir%%:*}"
    rest="${dir#*:}"
    usecase="${rest%%:*}"
    rest="${rest#*:}"
    lang="${rest%%:*}"
    features="${rest#*:}"
    pushd "webdriverio/desktop/$subdir" > /dev/null
        install_deps
        run_npm "framework:webdriverio,cli:wdio,lang:$lang,usecase:$usecase,$features" npm run test.saucelabs.eu
    popd > /dev/null
done

# --- 3. WebdriverIO: Mobile Web ---
echo "--- Section: WebdriverIO Mobile Web ---" >> "$LOG_FILE"
pushd webdriverio/mobile-web/examples > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:mobile-web" npm run test.saucelabs.eu
popd > /dev/null

pushd webdriverio/mobile-web/best-practices > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:mobile-web-best-practices" npm run test.saucelabs.android.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:mobile-web-best-practices" npm run test.saucelabs.ios.eu
popd > /dev/null

# --- 4. WebdriverIO: Mobile App ---
echo "--- Section: WebdriverIO Mobile App ---" >> "$LOG_FILE"

pushd webdriverio/mobile-app/best-practices > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:mobile-app-best-practices" npm run test.saucelabs.android.emu.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:mobile-app-best-practices,feature:network-capture,feature:device-vitals" npm run test.saucelabs.android.rdc.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:mobile-app-best-practices,feature:network-capture,feature:device-vitals" npm run test.saucelabs.ios.rdc.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:mobile-app-best-practices" npm run test.saucelabs.ios.sim.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/up-download-file > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:file-transfer" npm run test.sauce.android.emulator.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:file-transfer" npm run test.sauce.ios.simulator.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/simple-example > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:native-app-basics" npm run test.saucelabs.android.emu.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:native-app-basics" npm run test.saucelabs.ios.sim.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/appium-flutter-integration > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:flutter,feature:network-capture,feature:device-vitals" npm run android.flutter.sauce.rdc.app.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:flutter,feature:network-capture,feature:device-vitals" npm run ios.flutter.sauce.rdc.app.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/appium-flutter > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:flutter,feature:network-capture,feature:device-vitals" npm run test.sauce.real.android.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:flutter,feature:network-capture,feature:device-vitals" npm run test.sauce.real.ios.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/biometric-login > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:biometric-login" npm run test.sauce.emulator.andoid.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:biometric-login,feature:network-capture,feature:device-vitals" npm run test.sauce.rdc.andoid.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:biometric-login,feature:network-capture,feature:device-vitals" npm run test.sauce.rdc.ios.eu
    run_npm "framework:webdriverio,cli:wdio,lang:typescript,usecase:biometric-login" npm run test.sauce.simulator.ios.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/image-injection > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:image-injection,feature:network-capture,feature:device-vitals" npm run test.sauce.rdc.android.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:image-injection,feature:network-capture,feature:device-vitals" npm run test.sauce.rdc.ios.eu
popd > /dev/null

pushd webdriverio/mobile-app/examples/gestures > /dev/null
    install_deps
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:gestures,feature:network-capture,feature:device-vitals" npm run test.android.sauce.real.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:gestures" npm run test.android.sauce.emu.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:gestures,feature:network-capture,feature:device-vitals" npm run test.ios.sauce.real.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:gestures" npm run test.ios.sauce.sim.eu
popd > /dev/null

# Deque axe DevTools Mobile (scans also land in https://axe-mobile.deque.com)
pushd webdriverio/mobile-app/examples/deque > /dev/null
    install_deps
    # No network capture on Android: its proxy breaks the axe driver's TLS to Deque
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:deque-mobile,feature:accessibility,feature:device-vitals" npm run test.sauce.rdc.android.eu
    run_npm "framework:webdriverio,cli:wdio,lang:javascript,usecase:deque-mobile,feature:accessibility,feature:network-capture,feature:device-vitals" npm run test.sauce.rdc.ios.eu
popd > /dev/null

# --- 5. Playwright (top-level: reporter / grid / saucectl) ---
echo "--- Section: Playwright ---" >> "$LOG_FILE"
pushd playwright > /dev/null
    install_deps
    run_npm "framework:playwright,cli:playwright,lang:javascript,usecase:desktop-ui" npm run test.reporter
    run_npm "framework:playwright,cli:grid,lang:javascript,usecase:desktop-ui,feature:network-capture" npm run test.grid
    run_npm "framework:playwright,cli:saucectl,lang:javascript,usecase:desktop-ui" npm run test.saucectl
popd > /dev/null

# --- 6. SauceCTL (cypress-js, playwright, testcafe) ---
echo "--- Section: SauceCTL ---" >> "$LOG_FILE"
pushd saucectl/cypress-js > /dev/null
    install_deps
    run_npm "framework:cypress,cli:saucectl,lang:javascript,usecase:desktop-ui" npm run test.sauce.ex1.eu
popd > /dev/null

pushd saucectl/playwright > /dev/null
    install_deps
    run_npm "framework:playwright,cli:saucectl,lang:javascript,usecase:desktop-ui" npm run test.sauce.ex1.eu
popd > /dev/null

pushd saucectl/testcafe > /dev/null
    install_deps
    run_npm "framework:testcafe,cli:saucectl,lang:javascript,usecase:desktop-ui" npm run test.sauce.ex1.eu
popd > /dev/null

# --- 7. Selenium ---
echo "--- Section: Selenium ---" >> "$LOG_FILE"
pushd selenium > /dev/null
    install_deps
    run_npm "framework:selenium,cli:mocha,lang:javascript,usecase:cross-browser,feature:network-capture" npm run test.safari.eu
popd > /dev/null

# --- 8. Mobilewright (mobilewright-saucelabs driver, Real Device Access API) ---
# Results land in Access API > Test Results, not Automated > Test Results. Builds the local driver checkout and
# links it into both e2e suites (`npm install` in a suite replaces the link, so link again after it).
echo "--- Section: Mobilewright ---" >> "$LOG_FILE"
MOBILEWRIGHT_DIR="$HOME/Documents/GitHub/mobilewright-saucelabs"
MOBILEWRIGHT_TAGS="repo:mobilewright-saucelabs,framework:mobilewright,lang:typescript"
if [ -d "$MOBILEWRIGHT_DIR" ]; then
    pushd "$MOBILEWRIGHT_DIR" > /dev/null
        # npm ci: no lockfile rewrites in the checkout
        npm ci >> "$LOG_FILE" 2>&1
        run_npm "$MOBILEWRIGHT_TAGS" npm run build
        npm link >> "$LOG_FILE" 2>&1
        # Unit tests (no devices), then the driver's integration tests on real devices
        run_npm "$MOBILEWRIGHT_TAGS" npm test
        run_npm "$MOBILEWRIGHT_TAGS,cli:playwright,usecase:driver-integration" env SAUCE_INTEGRATION=1 SAUCE_PLATFORM=android npx playwright test src/integration.test.ts
        run_npm "$MOBILEWRIGHT_TAGS,cli:playwright,usecase:driver-integration" env SAUCE_INTEGRATION=1 SAUCE_PLATFORM=ios npx playwright test src/integration.test.ts
        # e2e suites through `mobilewright test`, one platform per process
        for suite in "sauce-demo-app:,feature:sauce-connect" "mobilewright-demo-app:"; do
            name="${suite%%:*}"
            features="${suite#*:}"
            pushd "e2e/$name" > /dev/null
                npm ci >> "$LOG_FILE" 2>&1
                npm link @saucelabs/mobilewright-driver >> "$LOG_FILE" 2>&1
                run_npm "$MOBILEWRIGHT_TAGS,cli:mobilewright,usecase:$name$features" npm run test:android
                run_npm "$MOBILEWRIGHT_TAGS,cli:mobilewright,usecase:$name$features" npm run test:ios
            popd > /dev/null
        done
        # `npm link` can touch the suites' lockfiles; keep the checkout clean
        git checkout -- package-lock.json e2e/*/package-lock.json >> "$LOG_FILE" 2>&1
    popd > /dev/null
else
    echo "ERROR: Directory $MOBILEWRIGHT_DIR does not exist, skipping Mobilewright." >> "$LOG_FILE"
fi

# --- 9. Maestro (maestro-runner over Appium: Android/iOS real devices, emulators, simulators) ---
# The repo's own script tags every job (repo:demo-maestro-runner, framework:maestro, platform:*, device:*);
# run_npm's SAUCE_TAGS adds ci:cron on top.
echo "--- Section: Maestro ---" >> "$LOG_FILE"
MAESTRO_DIR="$HOME/Documents/GitHub/demo-maestro-runner"
if [ -x "$MAESTRO_DIR/scripts/run_sauce_maestro.sh" ]; then
    run_npm "ci:cron" "$MAESTRO_DIR/scripts/run_sauce_maestro.sh"
else
    echo "ERROR: $MAESTRO_DIR/scripts/run_sauce_maestro.sh not found, skipping Maestro." >> "$LOG_FILE"
fi

# --- 10. Vibium (desktop Chrome/Firefox/Edge over WebDriver BiDi: JS client, Python client, CLI) ---
# The repo's own script installs deps and tags every job (repo:vibium-on-saucelabs, framework:vibium,
# lang:*, cli:*, usecase:*, browser:*, os:*); run_npm's SAUCE_TAGS adds ci:cron on top.
echo "--- Section: Vibium ---" >> "$LOG_FILE"
VIBIUM_DIR="$HOME/github/vibium-on-saucelabs"
if [ -x "$VIBIUM_DIR/scripts/run_sauce_vibium.sh" ]; then
    run_npm "ci:cron" "$VIBIUM_DIR/scripts/run_sauce_vibium.sh"
else
    echo "ERROR: $VIBIUM_DIR/scripts/run_sauce_vibium.sh not found, skipping Vibium." >> "$LOG_FILE"
fi

echo "All tests completed: $(date)" >> "$LOG_FILE"
echo "--------------------------------------------------" >> "$LOG_FILE"
