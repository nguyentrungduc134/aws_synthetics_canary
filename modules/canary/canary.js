const { URL } = require('url');
const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();
const syntheticsLogHelper = require('SyntheticsLogHelper');

const loadBlueprint = async function () {
    const apiHostname = process.env.API_HOSTNAME || '';
    const apiPath = process.env.API_PATH || '';
    const takeScreenshot = process.env.TAKE_SCREENSHOT === 'true';

    const urls = [`${apiHostname}${apiPath}`];

    syntheticsConfiguration.disableStepScreenshots();
    syntheticsConfiguration.setConfig({
        continueOnStepFailure: true,
        includeRequestHeaders: true,
        includeResponseHeaders: true,
        restrictedHeaders: [],
        restrictedUrlParameters: []
    });

    let page = await synthetics.getPage();

    for (const url of urls) {
        await loadUrl(page, url, takeScreenshot);
    }
};

const resetPage = async function (page) {
    try {
        await page.goto('about:blank', { waitUntil: ['load', 'networkidle0'], timeout: 30000 });
    } catch (ex) {
        synthetics.addExecutionError('Unable to open a blank page ', ex);
    }
};

const loadUrl = async function (page, url, takeScreenshot) {
    let stepName = null;
    let domcontentloaded = false;

    try {
        stepName = new URL(url).hostname;
    } catch (error) {
        log.error(`Error parsing url: ${url}. ${error}`);
        throw error;
    }

    await synthetics.executeStep(stepName, async function () {
        const sanitizedUrl = syntheticsLogHelper.getSanitizedUrl(url);

        const response = await page.goto(url, { waitUntil: ['domcontentloaded'], timeout: 30000 });

        if (response) {
            domcontentloaded = true;
            const status = response.status();
            const statusText = response.statusText();

            log.info(`Response from url: ${sanitizedUrl}  Status: ${status}  Status Text: ${statusText}`);

            if (status < 200 || status > 299) {
                throw new Error(`Failed to load url: ${sanitizedUrl} ${status} ${statusText}`);
            }
        } else {
            const msg = `No response returned for url: ${sanitizedUrl}`;
            log.error(msg);
            throw new Error(msg);
        }
    });

    if (domcontentloaded && takeScreenshot) {
        await new Promise(r => setTimeout(r, 15000));
        await synthetics.takeScreenshot(stepName, 'loaded');
    }

    await resetPage(page);
};

exports.handler = async () => {
    return await loadBlueprint();
};
