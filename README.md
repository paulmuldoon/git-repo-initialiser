# Git Repository Setup Automation Script
A bash script that automates the process of initialising a Git repository, adding the remote origin, making an initial commit and pushing to the remote.

## Installation
Run this command in your project folder to download the script:
```bash
curl -O https://raw.githubusercontent.com/paulmuldoon/git-repo-setup-automation/refs/heads/main/git-repo-setup.sh
```

## Usage
```bash
bash git-repo-setup.sh
```
The script will ask:
* The remote GitHub repository URL
* The name of the main branch ('main' if this is left blank)
* Whether you want to add a README file
* Whether you want to create an initial commit
* Whether you want to push to remote
* Whether you want to delete the script from your project folder once the setup is complete

The script will create a .gitignore file if one does not already exist, then add itself to .gitignore to prevent it from being pushed to the remote. 

The reference to the script file will be removed from the .gitignore if you choose to delete the script in the last step of the setup process, as it is no longer needed.
