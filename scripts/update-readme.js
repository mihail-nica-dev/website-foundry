const fs = require('fs');
const path = require('path');

const templatesDir = path.join(__dirname, "..", 'templates');
const baseUrl = 'https://richardbizzz.github.io/website-foundry/templates'; 

// Function to generate the list of templates with URLs
function generateTemplateList() {
    const list = fs.readdirSync(templatesDir);
    return list.map(template => {
        const templateName = template.replace(/\[\]/g, '.').replace('.html', '');
        const templateUrl = `${baseUrl}/${template}`;
        return `- [${templateName}](${templateUrl})`;
    }).join('\n');
}

// Function to update the README.md file
function updateReadme(templateList) {
    const readmePath = path.join(__dirname, '..', 'README.md');
    const readmeContent = fs.readFileSync(readmePath, 'utf8');
    const newContent = readmeContent.replace(
        /<!-- START TEMPLATE LIST -->[\s\S]*<!-- END TEMPLATE LIST -->/,
        `<!-- START TEMPLATE LIST -->\n${templateList}\n<!-- END TEMPLATE LIST -->`
    );
    fs.writeFileSync(readmePath, newContent, 'utf8');
}

// Generate the template list and update the README.md
const templateList = generateTemplateList();
updateReadme(templateList);

console.log('README.md updated successfully with the list of templates.');
