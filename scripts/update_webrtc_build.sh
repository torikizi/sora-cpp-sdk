#!/bin/bash

set -ex

cd $(dirname $0)

if [ "$GITHUB_ACTIONS" == "true" ]; then
  git config --global user.name "${GITHUB_ACTOR}"
  git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
fi

git checkout develop

# update_webrtc_build コマンドが存在しないブランチに切り替わっても困らないように、
# checkout 前の run.py をコピーして利用する
cp run.py _run.py

python3 _run.py update_webrtc_build --base-branch develop --track normal > update-result.json

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
  exit 0
fi

git checkout -b "$BRANCH_NAME" develop
git add DEPS examples/DEPS CHANGES.md
git commit -m "$COMMIT_MESSAGE"

if [ "$GITHUB_ACTIONS" == "true" ]; then
  git push origin "$BRANCH_NAME"
fi
