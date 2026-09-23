#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "=== Git Repository Initialiser ==="
printf "\n"
printf "This script will initialise a new Git repository and set up a remote."
printf "\n"

# Check Git is installed
if ! command -v git >/dev/null 2>&1; then
    printf "${RED}✗ Error: Git is not installed.${NC}"
    printf "\n"
    printf "Visit https://git-scm.com/install/ for installation instructions."
    printf "\n"
    exit 1
else
    GIT_VERSION=$(git --version)
    printf "${GREEN}✓ Git is installed: $GIT_VERSION${NC}"
    printf "\n"
fi

# Check if already a Git repository
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "${RED}✗ Error: This directory is already a Git repository.${NC}"
    printf "\n"
    exit 1
fi

printf "If you need to create a new GitHub repository first, visit:"
printf "\n"
printf "https://github.com/new"
printf "\n"

# Get remote URL
read -rp "Enter remote repository URL: " REMOTE_URL

if [[ -z "$REMOTE_URL" ]]; then
    printf "${RED}✗ Error: Repository URL is required.${NC}"
    exit 1
fi

printf "\n"

# Get branch name with default
read -rp "Enter main branch name (default is 'main' if this is left blank): " MAIN_BRANCH
MAIN_BRANCH="${MAIN_BRANCH:-main}"

printf "\n"
printf "Using branch: $MAIN_BRANCH"
printf "\n"

# Validate remote repository
printf "Validating remote repository...\n"

OUTPUT=$(git ls-remote "$REMOTE_URL" 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
    printf "\n"
    printf "${RED}✗ Unable to access remote repository.${NC}"
    printf "$OUTPUT"
    printf "\n"

    case "$OUTPUT" in
        *"Permission denied (publickey)"*)
            printf "Hint: Configure your SSH key and ensure it has access to the repository."
            ;;
        *"Authentication failed"*)
            printf "Hint: Check your username, PAT, or credential manager configuration."
            ;;
        *"Repository not found"*)
            printf "Hint: Verify the repository URL is correct."
            ;;
    esac

    exit 1
fi

printf "${GREEN}✓ Remote repository is reachable.${NC}"

# Check whether remote already contains branches
if git ls-remote --heads "$REMOTE_URL" | grep -q .; then
    printf "${RED}✗ Warning: Remote repository already contains branches.${NC}"
    printf "You may need to pull or merge before pushing."
fi

printf "\n"
printf "Initialising repository..."

git init -b "$MAIN_BRANCH"

# Add remote
git remote add origin "$REMOTE_URL"

# Ensure .gitignore exists, if not, create it
if [[ ! -f ".gitignore" ]]; then
    touch .gitignore
    printf "${GREEN}✓ Created .gitignore${NC}"
fi

# Add script to .gitignore
SCRIPT_NAME=$(basename "$0")

if ! grep -qxF "$SCRIPT_NAME" .gitignore; then
    echo "$SCRIPT_NAME" >> .gitignore
    printf "${GREEN}✓ Added $SCRIPT_NAME to .gitignore${NC}"
fi

printf "${GREEN}✓ Repository initialised successfully.${NC}"
printf "\n"
printf "Remote: $REMOTE_URL"
printf "\n"
printf "Main branch: $MAIN_BRANCH"
printf "\n"

# Optional first commit
read -rp "Create initial commit? (y/n): " CREATE_COMMIT

if [[ "$CREATE_COMMIT" =~ ^[Yy]$ ]]; then

    # Create README only if one doesn't already exist
    if [[ ! -f README.md ]]; then
        touch README.md
    fi

    git add .

    if git diff --cached --quiet; then
        printf "No files to commit."
    else
        git commit -m "Initial commit"
    fi

    printf "\n"
    read -rp "Push to remote? (y/n): " PUSH

    if [[ "$PUSH" =~ ^[Yy]$ ]]; then
        git push -u origin "$MAIN_BRANCH"
    fi
fi

# Optional cleanup
read -rp "Delete bootstrap script after setup? (y/n): " DELETE_SCRIPT

if [[ "$DELETE_SCRIPT" =~ ^[Yy]$ ]]; then

    SCRIPT_NAME=$(basename "$0")

    # Remove script from .gitignore if present
    if [[ -f ".gitignore" ]]; then
        grep -vxF "$SCRIPT_NAME" .gitignore > .gitignore.tmp || true
        mv .gitignore.tmp .gitignore
        printf "${GREEN}✓ Removed $SCRIPT_NAME from .gitignore${NC}"
    fi

    rm -- "$0"
    printf "${GREEN}✓ Bootstrap script deleted.${NC}"
fi

printf "\n"
printf "${GREEN}✓ Setup complete!${NC}"
