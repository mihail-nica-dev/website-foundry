const puppeteer = require('puppeteer');
const axios = require('axios');
const fs = require('fs-extra');
const path = require('path');

// Function to download and save images or media assets
async function downloadMedia(url, savePath) {
    const response = await axios({
        url,
        method: 'GET',
        responseType: 'stream',
    });

    // Ensure directory exists
    await fs.ensureDir(path.dirname(savePath));

    // Save the media
    return new Promise((resolve, reject) => {
        const writer = fs.createWriteStream(savePath);
        response.data.pipe(writer);
        writer.on('finish', resolve);
        writer.on('error', reject);
    });
}

// Retrieve site argument from the command line
const args = process.argv.slice(2);
const siteArgIndex = args.indexOf('--site');
const siteToProcess = siteArgIndex !== -1 ? args[siteArgIndex + 1] : null;

if (!siteToProcess) {
    console.error('Please specify a site using the --site argument.');
    process.exit(1);
}

console.log(`Processing site: ${siteToProcess}`);

// Function to process a single website
async function processWebsite(websiteDir) {
    // Read metadata.json
    const metadataPath = path.join(websiteDir, 'metadata.json');
    let metadata;

    try {
        metadata = await fs.readJson(metadataPath);
    } catch (err) {
        console.error(`Failed to read metadata.json in ${websiteDir}:`, err);
        return;
    }

    const websiteUrl = metadata.url || `https://${path.basename(websiteDir)}`;
    const replacements = metadata.replacements || {};
    const newUrl = metadata.newUrl;

    console.log(`Processing website: ${websiteUrl} with replacements: ${JSON.stringify(replacements)} and new domain: ${newUrl}`);

    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    // Intercept and log requests
    const mediaUrls = new Set();

    await page.setRequestInterception(true);
    page.on('request', request => {
        const url = request.url();
        const resourceType = request.resourceType();

        // Log and collect media assets
        if (['image', 'media', 'font', 'stylesheet'].includes(resourceType)) {
            console.log(`Loading: ${url} [${resourceType}]`);
            mediaUrls.add(url);
        }

        request.continue();
    });

    try {
        await page.goto(websiteUrl, { waitUntil: 'networkidle2' });

        // Get the page's HTML content
        let content = await page.content();

        // Replace URLs according to the replacements in metadata
        for (const [oldPath, newPath] of Object.entries(replacements)) {
            const regex = new RegExp(oldPath, 'g');
            content = content.replace(regex, newPath);
        }

        // Replace old domain with the new domain
        const urlObject = new URL(websiteUrl);
        const oldDomain = urlObject.origin;
        const newDomain = `https://${newUrl}`;
        content = content.replace(new RegExp(oldDomain, 'g'), newDomain);

        // Save the modified HTML content to a new file
        const outputHtmlPath = path.join(websiteDir, 'index.html');
        await fs.writeFile(outputHtmlPath, content);
        console.log(`Rendered and saved: ${outputHtmlPath}`);

        // Get all image URLs from <img> tags
        const imageUrls = await page.$$eval('img', imgs => imgs.map(img => img.src));

        // Get all image URLs from <link> tags with rel="icon" or rel="apple-touch-icon"
        const linkImageUrls = await page.$$eval('link[rel="icon"], link[rel="apple-touch-icon"]', links => links.map(link => link.href));

        // Combine all collected URLs
        const allMediaUrls = [...mediaUrls, ...imageUrls, ...linkImageUrls];

        for (let mediaUrl of allMediaUrls) {
            try {
                // Convert the media URL to a relative path
                const mediaUrlObject = new URL(mediaUrl);
                let relativePath = mediaUrlObject.pathname;

                // Apply path replacements based on the metadata
                for (const [oldPath, newPath] of Object.entries(replacements)) {
                    if (relativePath.startsWith(oldPath)) {
                        relativePath = relativePath.replace(oldPath, newPath);
                    }
                }

                // Ensure the path is relative to the root
                if (relativePath.startsWith('/')) {
                    relativePath = relativePath.slice(1);
                }

                // Create the correct save path within the website's directory
                const savePath = path.join(websiteDir, relativePath);

                // Download and save the media asset
                await downloadMedia(mediaUrl, savePath);
                console.log(`Downloaded and saved: ${savePath}`);
            } catch (err) {
                console.error(`Failed to download media ${mediaUrl}:`, err);
            }
        }
    } catch (err) {
        console.error(`Failed to process website ${websiteUrl}:`, err);
    } finally {
        await browser.close();
    }
}

// Main function to process all websites under the templates directory
(async () => {
    const templatesDir = path.join(__dirname, '..', 'templates');

    // Get the list of all directories (websites) under the templates directory
    const websites = (await fs.readdir(templatesDir))
        .map(name => path.join(templatesDir, name))
        .filter(source => fs.lstatSync(source).isDirectory());

    const websiteDir = path.join(templatesDir, siteToProcess);
    if (!fs.existsSync(websiteDir)) {
        console.error(`Directory for site ${siteToProcess} does not exist.`);
        process.exit(1);
    }

    await processWebsite(websiteDir);

    console.log('All websites processed.');
})();
