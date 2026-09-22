#!/usr/bin/env bash

set -e

echo "=== Git Repository Initialiser ==="
echo "This script will initialise a new Git repository and set up a remote."
echo

# Check Git is installed
if ! command -v git >/dev/null 2>&1; then
    echo "Error: Git is not installed."
    exit 1
fi

# Check if already a Git repository
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: This directory is already a Git repository."
    exit 1
fi

echo "If you need to create a new GitHub repository first, visit:"
echo "https://github.com/new"
echo

# Get remote URL
read -rp "Enter remote repository URL: " REMOTE_URL

if [[ -z "$REMOTE_URL" ]]; then
    echo "Error: Repository URL is required."
    exit 1
fi

# Get branch name with default
read -rp "Enter main branch name [main\] (default is 'main' if this is left blank): " MAIN_BRANCH
MAIN_BRANCH="${MAIN_BRANCH:-main}"

echo
echo "Using branch: $MAIN_BRANCH"
echo

# Validate remote repository
echo "Validating remote repository..."

OUTPUT=$(git ls-remote "$REMOTE_URL" 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo
    echo "Unable to access remote repository."
    echo "$OUTPUT"
    echo

    case "$OUTPUT" in
        *"Permission denied (publickey)"*)
            echo "Hint: Configure your SSH key and ensure it has access to the repository."
            ;;
        *"Authentication failed"*)
            echo "Hint: Check your username, PAT, or credential manager configuration."
            ;;
        *"Repository not found"*)
            echo "Hint: Verify the repository URL is correct."
            ;;
    esac

    exit 1
fi

echo "Remote repository is reachable."

# Check whether remote already contains branches
if git ls-remote --heads "$REMOTE_URL" | grep -q .; then
    echo
    echo "Warning: Remote repository already contains branches."
    echo "You may need to pull or merge before pushing."
fi

echo
echo "Initialising repository..."

git init -b "$MAIN_BRANCH"

# Add remote
git remote add origin "$REMOTE_URL"

# Ensure .gitignore exists, if not, create it
if [[ ! -f ".gitignore" ]]; then
    touch .gitignore
    echo "Created .gitignore"
fi

# Add script to .gitignore
SCRIPT_NAME=$(basename "$0")

if ! grep -qxF "$SCRIPT_NAME" .gitignore; then
    echo "$SCRIPT_NAME" >> .gitignore
    echo "Added $SCRIPT_NAME to .gitignore"
fi

echo
echo "Repository initialised successfully."
echo "Remote: $REMOTE_URL"
echo "Main branch: $MAIN_BRANCH"

# Optional first commit
read -rp "Create initial commit? (y/n): " CREATE_COMMIT

if [[ "$CREATE_COMMIT" =~ ^[Yy]$ ]]; then

    # Create README only if one doesn't already exist
    if [[ ! -f README.md ]]; then
        touch README.md
    fi

    git add .

    if git diff --cached --quiet; then
        echo "No files to commit."
    else
        git commit -m "Initial commit"
    fi

    read -rp "Push to remote? (y/n): " PUSH

    if [[ "$PUSH" =~ ^[Yy]$ ]]; then
        git push -u origin "$MAIN_BRANCH"
    fi
fi

# Optional cleanup
read -rp "Delete bootstrap script after setup? (y/n): " DELETE_SCRIPT

if [[ "$DELETE_SCRIPT" =~ ^[Yy]$ ]]; then
    rm -- "$0"
    echo "Bootstrap script deleted."
fi

echo
echo "Setup complete."
