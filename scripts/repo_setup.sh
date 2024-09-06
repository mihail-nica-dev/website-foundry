#!/bin/bash

# Function to initialize or update a repository
initialize_or_update_repo() {
    REPO_NAME=$1
    PAT_TOKEN=$2
    GITHUB_OWNER="richardbizzz"

    if [[ -z "$REPO_NAME" || -z "$PAT_TOKEN" ]]; then
        echo "Usage: ./scripts/repo_setup.sh <repo_name> <pat_token>"
        exit 1
    fi

    cd "$REPO_NAME" || { echo "Repository folder $REPO_NAME does not exist"; exit 1; }

    # Check if the repository exists on GitHub
    REPO_EXISTS=$(curl -H "Authorization: token $PAT_TOKEN" \
        -s "https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME}" | jq -r '.name')

    # If the repository exists
    if [[ "$REPO_EXISTS" == "$REPO_NAME" ]]; then
        echo "Repository $REPO_NAME exists. Pulling latest changes..."

        # Stash any local changes and pull the latest changes
        git init
        git remote add origin https://x-access-token:${PAT_TOKEN}@github.com/${GITHUB_OWNER}/${REPO_NAME}.git
        git fetch origin
        git checkout main || git checkout -b main
        git stash
        git pull origin main --rebase

        # Apply stashed changes if any
        git stash pop || echo "No stash to apply"

        # Add, commit, and push the updates
        git add .
        git commit -m "Update for $REPO_NAME"
        git push origin main
    else
        echo "Repository $REPO_NAME does not exist. Creating a new repository and pushing initial commit."

        # Initialize the repository, add files, and push
        git init
        git config --global user.name "GitHub Actions"
        git config --global user.email "actions@github.com"
        git remote add origin https://x-access-token:${PAT_TOKEN}@github.com/${GITHUB_OWNER}/${REPO_NAME}.git
        git add .
        git commit -m "Initial commit for $REPO_NAME"
        git branch -M main
        git push -u origin main
    fi
}

# Main entry point
initialize_or_update_repo "$1" "$2"
