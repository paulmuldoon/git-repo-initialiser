#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "=== Git Repository Initialiser ===\n\n"
printf "This script will initialise a new Git repository and set up a remote.\n\n"

# Check Git is installed
if ! command -v git >/dev/null 2>&1; then
    printf "${RED}✗ Error: Git is not installed.${NC}\n"
    printf "Visit https://git-scm.com/install/ for installation instructions.\n"
    exit 1
else
    GIT_VERSION=$(git --version)
    printf "${GREEN}✓ Git is installed: $GIT_VERSION${NC}\n\n"
fi

# Check if already a Git repository
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "${RED}✗ Error: This directory is already a Git repository.${NC}\n"
    exit 1
fi

printf "If you need to create a new GitHub repository first, visit:\n"
printf "https://github.com/new\n\n"

# Get remote URL
while [[ -z "$REMOTE_URL" ]]; do
    read -rp "Enter remote repository URL: " REMOTE_URL
    printf "\n"

    # Check for empty input
    if [[ -z "$REMOTE_URL" ]]; then
        printf "${RED}✗ Error: Repository URL is required. Please try again.${NC}\n\n"
        continue
    fi

    # Validate URL format
    if [[ ! "$REMOTE_URL" =~ ^(https://|git@)[[:alnum:]._-]+[:/][[:alnum:]_./-]+(\.git)?$ ]]; then
        printf "${RED}✗ Error: Invalid repository URL format. Please enter a valid Git HTTPS or SSH URL.${NC}\n\n"
        continue
    fi
done

printf "\n"

# Get branch name with default
read -rp "Enter main branch name (default is 'main' if this is left blank): " MAIN_BRANCH
MAIN_BRANCH="${MAIN_BRANCH:-main}"

printf "\n"
printf "Using branch: $MAIN_BRANCH\n\n"

# Validate remote repository
printf "Validating remote repository...\n\n"

OUTPUT=$(git ls-remote "$REMOTE_URL" 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
    printf "${RED}✗ Unable to access remote repository.${NC}\n"
    printf "%s\n" "$OUTPUT"

    case "$OUTPUT" in
        *"Permission denied (publickey)"*)
            printf "Hint: Configure your SSH key and ensure it has access to the repository.\n"
            ;;
        *"Authentication failed"*)
            printf "Hint: Check your username, PAT, or credential manager configuration.\n"
            ;;
        *"Repository not found"*)
            printf "Hint: Verify the repository URL is correct.\n"
            ;;
    esac

    exit 1
fi

printf "${GREEN}✓ Remote repository is reachable.${NC}\n\n"

# Check whether remote already contains branches
if git ls-remote --heads "$REMOTE_URL" | grep -q .; then
    printf "${RED}✗ Warning: Remote repository already contains branches.${NC}\n"
    printf "You may need to pull or merge before pushing.\n\n"
fi

printf "Initialising repository...\n\n"

git init -b "$MAIN_BRANCH"
printf "\n"

# Add remote
git remote add origin "$REMOTE_URL"

# Ensure .gitignore exists, if not, create it
if [[ ! -f ".gitignore" ]]; then
    touch .gitignore
    printf "${GREEN}✓ Created .gitignore${NC}\n"
fi

# Add script to .gitignore
SCRIPT_NAME=$(basename "$0")

if ! grep -qxF "$SCRIPT_NAME" .gitignore; then
    echo "$SCRIPT_NAME" >> .gitignore
    printf "${GREEN}✓ Added $SCRIPT_NAME to .gitignore${NC}\n"
fi

printf "\n${GREEN}✓ Repository initialised successfully.${NC}\n\n"
printf "Remote: %s\n" "$REMOTE_URL"
printf "Main branch: %s\n\n" "$MAIN_BRANCH"

# Optional first commit
read -rp "Create initial commit? (y/n): " CREATE_COMMIT
printf "\n"

if [[ "$CREATE_COMMIT" =~ ^[Yy]$ ]]; then

    # Create README only if one doesn't already exist
    if [[ ! -f README.md ]]; then
        touch README.md
    fi

    git add .

    if git diff --cached --quiet; then
        printf "No files to commit.\n"
    else
        git commit -m "Initial commit"
        printf "\n${GREEN}✓ Initial commit created successfully.${NC}\n"
    fi

    printf "\n"
    read -rp "Push to remote? (y/n): " PUSH

    printf "\n"

    if [[ "$PUSH" =~ ^[Yy]$ ]]; then
        git push -u origin "$MAIN_BRANCH"
        printf "\n${GREEN}✓ Initial push successful.${NC}\n"
    fi
fi

# Optional cleanup
printf "\n"
read -rp "Delete bootstrap script after setup? (y/n): " DELETE_SCRIPT
printf "\n"

if [[ "$DELETE_SCRIPT" =~ ^[Yy]$ ]]; then

    SCRIPT_NAME=$(basename "$0")

    # Remove script from .gitignore if present
    if [[ -f ".gitignore" ]]; then
        grep -vxF "$SCRIPT_NAME" .gitignore > .gitignore.tmp || true
        mv .gitignore.tmp .gitignore
        printf "${GREEN}✓ Removed $SCRIPT_NAME from .gitignore${NC}\n"
    fi

    rm -- "$0"
    printf "${GREEN}✓ Bootstrap script deleted.${NC}\n"
fi

printf "\n${GREEN}✓ Setup complete!${NC}\n"
