#!/bin/bash

set -e

DEMO_PATH="../alto-demo"

echo "[deploy_demo] Updating alto gem in demo app at $DEMO_PATH"

cd "$DEMO_PATH" || { echo "Demo app not found at $DEMO_PATH"; exit 1; }

bundle update alto
git add Gemfile.lock
git commit -m "Update Alto gem from deploy script" || echo "[deploy_demo] No changes to commit"
git push heroku main
