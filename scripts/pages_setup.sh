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
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME}/pages \
        -d '{"cname": "'"${REPO_NAME}"'", "source": {"branch": "main", "path": "."}}'
    
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
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME} \
        -d '{"description": "'"$DESCRIPTION"'"}'

    echo "Repository description updated for $REPO_NAME"
}

# Function to orchestrate the GitHub Pages setup process
setup_github_pages() {
    REPO_NAME=$1
    PAT_TOKEN=$2
    GITHUB_OWNER="richardbizzz"

    # Set the custom GitHub Pages domain
    set_github_pages "$REPO_NAME" "$PAT_TOKEN"

    # Add the CNAME file with the custom domain
    add_cname_file "$REPO_NAME" "$REPO_NAME"

    # Update the repository description
    DESCRIPTION="GitHub Pages Domain: $REPO_NAME"
    update_repo_description "$REPO_NAME" "$DESCRIPTION" "$PAT_TOKEN"
}

# Main entry point: requires repo name and PAT as arguments
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: ./scripts/pages_setup.sh <repo_name> <pat_token>"
    exit 1
fi

# Call the setup function with the provided repository name and token
setup_github_pages "$1" "$2"
