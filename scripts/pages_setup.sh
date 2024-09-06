#!/bin/bash

# Set GitHub Pages domain and source for a repository
set_github_pages() {
    REPO_NAME=$1
    PAT_TOKEN=$2
    GITHUB_OWNER="richardbizzz"

    echo "Setting GitHub Pages for repository: $REPO_NAME"

    # Use GitHub API to set the GitHub Pages branch and path
    curl -X PATCH \
        -H "Authorization: token $PAT_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME}/pages \
        -d '{"source": {"branch": "main", "path": "/"}}'

    echo "GitHub Pages set for $REPO_NAME"
}

# Create and commit the CNAME file for GitHub Pages
add_cname_file() {
    REPO_NAME=$1
    CNAME_CONTENT=$2

    echo "Adding CNAME file to $REPO_NAME with domain: $CNAME_CONTENT"

    # Create the CNAME file
    echo "$CNAME_CONTENT" > CNAME

    # Add, commit, and push the CNAME file
    git add CNAME
    git commit -m "Add CNAME file for GitHub Pages"
    git push origin main
}

# Function to update the repository description
update_repo_description() {
    REPO_NAME=$1
    DESCRIPTION=$2
    PAT_TOKEN=$3
    GITHUB_OWNER="richardbizzz"

    echo "Updating repository description for $REPO_NAME"

    # Update repository description via GitHub API
    curl -X PATCH \
        -H "Authorization: token $PAT_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME} \
        -d '{"description": "'"$DESCRIPTION"'"}'

    echo "Repository description updated for $REPO_NAME"
}

# Create and push the GitHub Actions workflow for Pages deployment
create_deploy_workflow() {
    REPO_NAME=$1
    DOMAIN=$2

    WORKFLOW_FILE=".github/workflows/deploy-pages.yml"

    echo "Creating GitHub Actions workflow for Pages deployment"

    WORKFLOW_TEMPLATE=$(cat <<EOF
# Simple workflow for deploying static content to GitHub Pages
name: Deploy static content to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: \${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Set custom domain
        run: echo "$DOMAIN" > CNAME

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF
)

    # Write the workflow to the file
    mkdir -p $(dirname "$WORKFLOW_FILE")
    echo "$WORKFLOW_TEMPLATE" > "$WORKFLOW_FILE"
    
    echo "Workflow written to $WORKFLOW_FILE with domain: $DOMAIN"

    # Add, commit, and push the workflow
    git add "$WORKFLOW_FILE"
    git commit -m "Add GitHub Actions workflow for Pages deployment"
    git push origin main
}

# Function to orchestrate the GitHub Pages setup process
setup_github_pages() {
    REPO_NAME=$1
    PAT_TOKEN=$2
    DOMAIN=$3
    GITHUB_OWNER="richardbizzz"

    # Set the custom GitHub Pages domain
    set_github_pages "$REPO_NAME" "$PAT_TOKEN"

    # Add the CNAME file with the custom domain
    add_cname_file "$REPO_NAME" "$DOMAIN"

    # Create and push the deployment workflow
    create_deploy_workflow "$REPO_NAME" "$DOMAIN"

    # Update the repository description
    DESCRIPTION="GitHub Pages Domain: $DOMAIN"
    update_repo_description "$REPO_NAME" "$DESCRIPTION" "$PAT_TOKEN"
}

# Main entry point
if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: ./scripts/pages_setup.sh <repo_name> <pat_token> <domain>"
    exit 1
fi

# Call the setup function with the provided repository name, token, and domain
setup_github_pages "$1" "$2" "$3"
