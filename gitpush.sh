#!/bin/bash

# Function to handle errors and exit script
handle_error() {
    echo "Error: $1"
    exit 1
}

# Configuration file path
CONFIG_FILE="$HOME/.git_automation_config"

# Load previous configuration if it exists
if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
else
    # Prompt for GitHub token
    read -p "Enter your GITHUB_TOKEN: " GITHUB_TOKEN
    if [[ -z "$GITHUB_TOKEN" ]]; then
        handle_error "GITHUB_TOKEN is required."
    fi

    # Prompt for GitHub username
    read -p "Enter your GitHub username: " GITHUB_USER
    if [[ -z "$GITHUB_USER" ]]; then
        handle_error "GitHub username is required."
    fi

    # Save the configuration to a file
    echo "GITHUB_TOKEN='$GITHUB_TOKEN'" > $CONFIG_FILE
    echo "GITHUB_USER='$GITHUB_USER'" >> $CONFIG_FILE
    echo "Configuration saved."
fi

# Use the loaded or saved configuration
echo "Using GITHUB_TOKEN: $GITHUB_TOKEN"
echo "Using GITHUB_USER: $GITHUB_USER"

# Prompt for GitHub repository name
read -p "Enter your GitHub repository name: " REPO_NAME
if [[ -z "$REPO_NAME" ]]; then
    handle_error "GitHub repository name is required."
fi

# Check if the repository directory already exists
if [ -d "$REPO_NAME" ]; then
    echo "The repository directory '$REPO_NAME' already exists."
    read -p "Do you want to delete the existing directory and clone again? (y/n): " CONFIRM_DELETE
    if [[ "$CONFIRM_DELETE" == "y" ]]; then
        echo "Deleting existing directory..."
        rm -rf $REPO_NAME || handle_error "Failed to delete existing directory."
    else
        echo "Skipping the clone step and using the existing directory."
    fi
fi

# Clone the repository if the directory doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning the repository from GitHub..."
    git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git || handle_error "Failed to clone repository."
fi

cd ${REPO_NAME} || handle_error "Failed to change directory to repository."

# Fetch the available branches
echo "Fetching available branches..."
git fetch --all || handle_error "Failed to fetch branches."

# List and select a branch
echo "Available branches:"
AVAILABLE_BRANCHES=$(git branch -r | sed 's/origin\///')
echo "$AVAILABLE_BRANCHES"

if [[ -z "$AVAILABLE_BRANCHES" ]]; then
    echo "No branches found. Creating a new 'main' branch."
    git checkout -b main || handle_error "Failed to create new branch 'main'."
    
    # Create an initial commit in the new branch
    touch README.md  # Create a README file
    git add README.md || handle_error "Failed to stage README.md."
    git commit -m "Initial commit" || handle_error "Failed to commit the changes."
    
    git push -u origin main || handle_error "Failed to push new branch 'main' to remote."
else
    read -p "Enter the branch name you want to use: " BRANCH_NAME
    # Checkout to the selected branch
    git checkout $BRANCH_NAME || handle_error "Failed to checkout to branch $BRANCH_NAME."
fi

# Pull the latest changes from the selected branch
echo "Pulling latest changes from $BRANCH_NAME..."
git pull origin $BRANCH_NAME || handle_error "Failed to pull the latest changes."

# Prompt for file or folder to upload
read -p "Enter the file or folder path you want to upload: " FILE_PATH
if [[ ! -e "$FILE_PATH" ]]; then
    handle_error "File or folder not found: $FILE_PATH"
fi

# Copy the content of the folder to the repository
if [[ -d "$FILE_PATH" ]]; then
    echo "Copying contents of the folder $FILE_PATH to the repository directory..."
    cp -r $FILE_PATH/* ./ || handle_error "Failed to copy contents of the folder."
else
    echo "Copying file $FILE_PATH to the repository directory..."
    cp "$FILE_PATH" ./ || handle_error "Failed to copy the file."
fi

# Add the file/folder to the git staging area
git add .

# Commit the changes
read -p "Enter your commit message: " COMMIT_MESSAGE
git commit -m "$COMMIT_MESSAGE" || handle_error "Failed to commit the changes."

# Push the changes to the selected branch
echo "Pushing changes to GitHub..."
git push origin $BRANCH_NAME || handle_error "Failed to push changes."

echo "Changes pushed successfully!"
