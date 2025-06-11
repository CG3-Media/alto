#!/bin/bash

set -e

DEMO_PATH="../alto-demo"

echo "[deploy_demo] Updating alto gem in demo app at $DEMO_PATH"

cd "$DEMO_PATH" || { echo "Demo app not found at $DEMO_PATH"; exit 1; }

echo "[deploy_demo] Running standardrb --fix"
standardrb --fix

echo "[deploy_demo] Running bundle update alto"
bundle update alto

echo "[deploy_demo] Committing changes"
git add Gemfile.lock
git commit -m "Update Alto gem from deploy script" || echo "[deploy_demo] No changes to commit"

echo "[deploy_demo] Pushing to Heroku"
git push heroku main
