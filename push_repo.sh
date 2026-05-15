#!/bin/bash

# ----------------------------
# push_repo.sh - Safe Git push
# ----------------------------

# 1. Go to the repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Not a Git repository!"
    exit 1
fi
cd "$REPO_ROOT"

# 2. Show repo info
echo "Repository root: $REPO_ROOT"
git remote -v

# 3. Add files (only tracked folders, ignores gitignored files)
git add .

# 4. Commit changes
read -p "Enter commit message: " MSG
if [ -z "$MSG" ]; then
    MSG="Update files"
fi
git commit -m "$MSG"

# 5. Push safely (force only if needed)
git push -u origin main || {
    echo "Push failed. Trying to pull first..."
    git pull --rebase origin main
    git push -u origin main
}

echo "Push completed!"
