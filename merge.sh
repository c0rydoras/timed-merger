#!/bin/bash

MONOREPO_PATH="./timed"
TARGET_REPOSITORY="c0rydoras/timed"
UPSTREAM_REPOSITORY="adfinis/timed"


function _log() {
  python -c 'print("-"*100)'
  echo "$1"
  python -c 'print("-"*100)'
}

export FILTER_BRANCH_SQUELCH_WARNING=1

_log "Timed Merger"


echo "Creating temporary directories to store upstream frontend and backend"

tmp_frontend=$(mktemp -d)
tmp_backend=$(mktemp -d)

_monorepo_path="$(realpath $MONOREPO_PATH)"

_log "Cloning upstream repos"
git clone git@github.com:adfinis/timed-frontend "$tmp_frontend"
git clone git@github.com:adfinis/timed-backend "$tmp_backend"

_log "Rewrite git history so files are placed in $_monorepo_path/frontend"

cd "$tmp_frontend" || exit 1
git filter-branch --index-filter \
  'git ls-files -s | sed "s-\t\"*-&frontend/-" |
   GIT_INDEX_FILE=$GIT_INDEX_FILE.new \
   git update-index --index-info &&
   mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' HEAD

cd - || exit 1

_log "Rewrite git history so files are placed in $_monorepo_path/backend"

cd "$tmp_backend" || exit 1
git filter-branch --index-filter \
  'git ls-files -s | sed "s-\t\"*-&backend/-" |
   GIT_INDEX_FILE=$GIT_INDEX_FILE.new \
   git update-index --index-info &&
   mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' HEAD

cd - || exit 1

mkdir timed
cd timed || exit 1

_log "Creating monorepo in $_monorepo_path"
git init --initial-branch main

_log "Add repositories with rewritten history as remotes"
git remote add --fetch frontend "$tmp_frontend"
git remote add --fetch backend "$tmp_backend"

_log "Merging frontend"
git merge frontend/main --allow-unrelated-histories
_log "Merging backend"
git merge backend/main --allow-unrelated-histories -m "chore: merge backend"

_log "Adding remotes"
git remote add --fetch origin "git@github.com:$TARGET_REPOSITORY"
git remote add upstream "git@github.com:$UPSTREAM_REPOSITORY"

_log "Setting upstream to origin main"
git branch --set-upstream-to origin main

_log "Removing remotes of temporary repos"
git remote remove frontend
git remote remove backend

cd - || exit 1

echo "Cleaning up temporary repos"
rm -rf "$tmp_frontend" "$tmp_backend"

_log "Finished, enjoy your monorepo: $_monorepo_path"
