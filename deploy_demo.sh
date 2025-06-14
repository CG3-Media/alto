#!/bin/bash

set -e

DEMO_PATH="../alto-demo"

echo "[deploy_demo] Updating alto gem in demo app at $DEMO_PATH"

cd "$DEMO_PATH" || { echo "Demo app not found at $DEMO_PATH"; exit 1; }

echo "[deploy_demo] Running standardrb --fix"
standardrb --fix

echo "[deploy_demo] Running bundle update alto"
bundle update alto

echo "[deploy_demo] Checking for file changes..."

if git diff --quiet && git diff --cached --quiet; then
  echo "[deploy_demo] No changes to commit"
else
  echo "[deploy_demo] The following files will be committed:"
  echo "================================================"
  git status --porcelain
  echo "================================================"

  read -p "[deploy_demo] Do you want to continue with commit and deploy? (y/N): " -n 1 -r
  echo    # Add newline after prompt

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "[deploy_demo] Deployment cancelled by user"
    exit 0
  fi

  echo "[deploy_demo] Committing all file changes"
  git add .
  git commit -m "Update Alto gem from deploy script"
fi

echo "[deploy_demo] Pushing to Heroku"
git push heroku main
