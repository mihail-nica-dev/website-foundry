const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Paths for workflow files and templates directory
const workflowsDir = path.join(__dirname,'..', '.github', 'workflows');
const templatesDir = path.join(__dirname,'..', 'templates');
const workflowFiles = ['site-process.yml', 'website-data.yml'];

// Ensure the workflows directory exists
if (!fs.existsSync(workflowsDir)) {
    fs.mkdirSync(workflowsDir, { recursive: true });
}

// Read the directories in the templates folder
const directories = fs.readdirSync(templatesDir).filter(dir => {
    return fs.statSync(path.join(templatesDir, dir)).isDirectory();
});

if (directories.length === 0) {
    console.error('No directories found in the templates directory.');
    process.exit(1);
}

// Create or update each workflow file
workflowFiles.forEach(workflowFileName => {
    const workflowFilePath = path.join(workflowsDir, workflowFileName);

    // If the file doesn't exist, create a base workflow structure
    if (!fs.existsSync(workflowFilePath)) {
        const baseWorkflow = {
            name: workflowFileName.replace('.yml', ''),
            on: {
                workflow_dispatch: {
                    inputs: {
                        site: {
                            description: 'Select the site to process',
                            required: true,
                            type: 'string',
                            options: directories,
                        }
                    }
                }
            },
            jobs: {}  // You can define default jobs here if needed
        };

        const workflowContent = yaml.dump(baseWorkflow);
        fs.writeFileSync(workflowFilePath, workflowContent, 'utf8');
        console.log(`Created base workflow file: ${workflowFilePath}`);
    } else {
        // Read the existing workflow YAML file
        let workflowContent = fs.readFileSync(workflowFilePath, 'utf8');
        let workflow = yaml.load(workflowContent);

        // Update the options for the site input
        if (workflow.on && workflow.on.workflow_dispatch && workflow.on.workflow_dispatch.inputs && workflow.on.workflow_dispatch.inputs.site) {
            workflow.on.workflow_dispatch.inputs.site.options = directories;
        } else {
            console.error(`The structure of ${workflowFilePath} is not as expected.`);
            return;
        }

        // Convert the updated workflow object back to YAML
        workflowContent = yaml.dump(workflow);

        // Write the updated YAML back to the workflow file
        fs.writeFileSync(workflowFilePath, workflowContent, 'utf8');
        console.log(`Updated the workflow options in: ${workflowFilePath}`);
    }
});
