#!/bin/bash

set -ex

cd $(dirname $0)/..

if [ "$GITHUB_ACTIONS" == "true" ]; then
  git config --global user.name "${GITHUB_ACTOR}"
  git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
fi

git checkout develop

python3 run.py update_webrtc_build --base-branch develop --track normal > update-result.json

eval "$(python3 - <<'PY'
import json
import shlex

with open('update-result.json', encoding='utf-8') as f:
    data = json.load(f)

for key in ('status', 'branch_name', 'commit_message'):
    print(f'{key.upper()}={shlex.quote(data[key])}')
PY
)"

if [ "$STATUS" != "updated" ]; then
  if [ "$GITHUB_ACTIONS" != "true" ]; then
    rm -f update-result.json
  fi
  exit 0
fi

git checkout -b "$BRANCH_NAME" develop
git add DEPS examples/DEPS CHANGES.md
git commit -m "$COMMIT_MESSAGE"

if [ "$GITHUB_ACTIONS" == "true" ]; then
  git push origin "$BRANCH_NAME"
else
  rm -f update-result.json
fi
