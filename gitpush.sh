#!/bin/bash

# User credentials
GIT_EMAIL="you_github_mail"
GIT_PASSWORD="you_github_password"

# Set up Git global config with your email
git config --global user.email "$GIT_EMAIL"

# Prompt for the folder or file to upload
read -p "Enter the folder or file path you want to upload: " FOLDER_PATH

# Change to the specified folder
if [ -d "$FOLDER_PATH" ] || [ -f "$FOLDER_PATH" ]; then
    cd "$FOLDER_PATH"
else
    echo "Invalid folder or file path."
    exit 1
fi

# Prompt for GitHub username and repository name
read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter the repository name: " REPO_NAME

# Initialize git if not already done
if [ ! -d .git ]; then
    git init
fi

# Add all files to the git staging area
git add .

# Commit the changes
git commit -m "Initial commit"

# Set the remote repository URL
REMOTE_URL="https://$GITHUB_USER:$GIT_PASSWORD@github.com/$GITHUB_USER/$REPO_NAME.git"
git remote add origin $REMOTE_URL

# Push the code to GitHub
git push -u origin master

# Display the repository URL
echo "Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
