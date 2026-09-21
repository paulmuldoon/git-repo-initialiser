#!/bin/bash

set -e

echo "=== Git Repository Initialiser ==="

# Check if already a Git repository
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: This directory is already a Git repository."
    exit 1
fi

# Prompt user to create a new remote repository if none exists
echo "If you don't have a remote repository, you can create one at https://github.com/new"

# Get remote URL
read -rp "Enter remote repository URL: " REMOTE_URL

# Get branch name
read -rp "Enter main branch name: " MAIN_BRANCH

# Validate input
if [[ -z "$REMOTE_URL" || -z "$MAIN_BRANCH" ]]; then
    echo "Error: Repository URL and branch name are required."
    exit 1
fi

# Initialise repository
git init

# Create primary branch
git checkout -b "$MAIN_BRANCH"

# Validate remote repository
echo "Validating remote repository..."

OUTPUT=$(git ls-remote "$REMOTE_URL" 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo "Unable to access remote repository."
    echo "$OUTPUT"

    case "$OUTPUT" in
        *"Permission denied (publickey)"*)
            echo ""
            echo "Hint: Configure your SSH key and ensure it has access to the repository."
            ;;
        *"Authentication failed"*)
            echo ""
            echo "Hint: Check your username, PAT, or credential manager configuration."
            ;;
        *"Repository not found"*)
            echo ""
            echo "Hint: Verify the repository URL is correct."
            ;;
    esac

    exit 1
fi

echo "Remote repository is reachable."
# Add remote
git remote add origin "$REMOTE_URL"

echo
echo "Repository initialised successfully."
echo "Remote: $REMOTE_URL"
echo "Main branch: $MAIN_BRANCH"

# Optional first commit
read -rp "Create initial commit? (y/n): " CREATE_COMMIT

if [[ "$CREATE_COMMIT" =~ ^[Yy]$ ]]; then
    touch README.md
    git add .
    git commit -m "Initial commit"

    read -rp "Push to remote? (y/n): " PUSH

    if [[ "$PUSH" =~ ^[Yy]$ ]]; then
        git push -u origin "$MAIN_BRANCH"
    fi
fi