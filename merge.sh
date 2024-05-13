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
tmp_charts=$(mktemp -d)

_monorepo_path="$(realpath $MONOREPO_PATH)"

_log "Cloning upstream repos"
git clone git@github.com:adfinis/timed-frontend "$tmp_frontend"
git clone git@github.com:adfinis/timed-backend "$tmp_backend"
git clone git@github.com:adfinis/helm-charts "$tmp_charts" -n --filter=tree:0

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

_log "Sparse Checkout Charts Repo"
cd "$tmp_charts" || exit 1
git sparse-checkout set --no-cone /charts/timed
git checkout

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
_log "Adding charts"
cp "$tmp_charts/charts" . -r
git add charts
git commit -m "chore: merge chart"

_log "Adding remotes"
git remote add --fetch origin "git@github.com:$TARGET_REPOSITORY"
git remote add upstream "https://github.com/$UPSTREAM_REPOSITORY"

_log "Setting upstream to origin main"
git branch --set-upstream-to origin main

_log "Rebase to origin/main"
git checkout -b cherry-picked-main

_log "Cherry picking commits"
# https://github.com/c0rydoras/timed/pull/2
git cherry-pick 84f329fd09387e2014308a9e858e4b227234fe68 # update frontend dockerfile and drop husky and semrel (https://github.com/c0rydoras/timed/pull/2/commits/84f329fd09387e2014308a9e858e4b227234fe68)
git cherry-pick 9e8d997abba024c9eb9f2198b08885715ff72c91 # add @adfinis/eslint-config back which was accidentally removed (https://github.com/c0rydoras/timed/pull/2/commits/9e8d997abba024c9eb9f2198b08885715ff72c91)
# chore dev-setup (https://github.com/c0rydoras/timed/pull/3)
git cherry-pick 188e8365906405318073a6d070b9e1c1b4dded90 # delete old files like .bowerrc, renovate.json, .husky/ (https://github.com/c0rydoras/timed/pull/2/commits/188e8365906405318073a6d070b9e1c1b4dded90 )
git cherry-pick 611ac1d1f2f500dd6c500c31e46a570bb70f59be # add up to date keycloak (https://github.com/c0rydoras/timed/pull/3/commits/611ac1d1f2f500dd6c500c31e46a570bb70f59be)
git cherry-pick a856777b27492a1b972f4d64542b59cc6cc14c10 # use caddy as reverse proxy (https://github.com/c0rydoras/timed/pull/3/commits/a856777b27492a1b972f4d64542b59cc6cc14c10)
git cherry-pick 0fdf5f95c68c957f0f4d6bd69d428f4d287ca173 # add compose.yaml (https://github.com/c0rydoras/timed/pull/3/commits/0fdf5f95c68c957f0f4d6bd69d428f4d287ca173)
git cherry-pick dbe693f1917ad28b597fce3f5c2a7ea62a4a8f78 # drop old dev-config (https://github.com/c0rydoras/timed/pull/3/commits/dbe693f1917ad28b597fce3f5c2a7ea62a4a8f78)
git cherry-pick 7c914ff40da90810dc4bda25200c3b8659ffe83a # add mailhog to reverse proxy (https://github.com/c0rydoras/timed/pull/3/commits/7c914ff40da90810dc4bda25200c3b8659ffe83a)
# merge makefile (https://github.com/c0rydoras/timed/pull/5)
git cherry-pick bf4f1210c6b8bd3c3a3ce1f4eec5bf19224df8b8 # merge makefile (https://github.com/c0rydoras/timed/pull/5/commits/bf4f1210c6b8bd3c3a3ce1f4eec5bf19224df8b8)
git cherry-pick af8f097b3485fc900cc3aa5897b7aecba1e5322e # add combined targets to makefile (https://github.com/c0rydoras/timed/pull/5/commits/af8f097b3485fc900cc3aa5897b7aecba1e5322e)
# merge gh workflows (https://github.com/c0rydoras/timed/pull/4)
git cherry-pick 96f55c9c73461b6cabbfa2fe2f3ead64f7728628 # merge github workflows (https://github.com/c0rydoras/timed/pull/4/commits/96f55c9c73461b6cabbfa2fe2f3ead64f7728628)
git cherry-pick c64cf05a8cf4de89ffdfcb13dfb6082526cf8080 # adjust versions (pyproject.toml, package.json, Chart.yaml etc.) to work with the semrel workflow
git cherry-pick 2d77580995ae25130b08d7286b8b8d974fce8572 # add kube-prometheus stack crds to chart testing workflow
# merge codeowners (https://github.com/c0rydoras/timed/pull/6)
git cherry-pick 04a89a9add1946e9a2eff9e648ef31e1a6286949 # merge CODEOWNERS (https://github.com/c0rydoras/timed/pull/6/commits/04a89a9add1946e9a2eff9e648ef31e1a6286949)
# adjust django root and set default db host (django configuration) to `db` (https://github.com/c0rydoras/timed/pull/8)
git cherry-pick 18fb186fa45253f7c0cae51e13b6fdb1ad5666f2 #  https://github.com/c0rydoras/timed/pull/8/commits/18fb186fa45253f7c0cae51e13b6fdb1ad5666f2
git cherry-pick 7e3390f4a2ed11e5856feab824753c2b158e3c1a # drop the adjustement of django_root as its wrong (https://github.com/c0rydoras/timed/pull/8/commits/7e3390f4a2ed11e5856feab824753c2b158e3c1a)
# ---
# disable prometheus and grafana integrations for chart testing
# git cherry-pick 97674bc43c77f369fac7bcf5649e63f84a380138 # https://github.com/c0rydoras/timed/pull/9/commits/97674bc43c77f369fac7bcf5649e63f84a380138
# ---
# merge dependabot config (https://github.com/c0rydoras/timed/pull/11)
git cherry-pick 9a924fa2caf2e6bde244a7d3c01428a2d29c3576 # https://github.com/c0rydoras/timed/pull/11/commits/9a924fa2caf2e6bde244a7d3c01428a2d29c3576
# add issue templates (https://github.com/c0rydoras/timed/pull/12) 
git cherry-pick 9c72599e879cc0bc1fedede7e45b3c47c1c2e707 # https://github.com/c0rydoras/timed/pull/12/commits/9c72599e879cc0bc1fedede7e45b3c47c1c2e707
# merge docs (README, etc.) (https://github.com/c0rydoras/timed/pull/13)
git cherry-pick ef267e2959ae0f19add1de8c7f2109a808ea3744 # merge LICENSE (https://github.com/c0rydoras/timed/pull/13/commits/ef267e2959ae0f19add1de8c7f2109a808ea3744)
git cherry-pick 46d8c7d4102c5f61c6c62fd595b84128b3958b36 # merge CHANGELOG.md (https://github.com/c0rydoras/timed/pull/13/commits/46d8c7d4102c5f61c6c62fd595b84128b3958b36)
git cherry-pick 6777cea03c6fd5f2caf501e8a71c212e2fba5b09 # merge CONTRIBUTING.md (https://github.com/c0rydoras/timed/pull/13/commits/6777cea03c6fd5f2caf501e8a71c212e2fba5b09)
git cherry-pick 7db6ebd04b096605dc78f7787b888d91eb8efa1e # merge README.md (https://github.com/c0rydoras/timed/pull/13/commits/9af233cfda5ad1ed6a3de8c05a7ad397a8b3b0bb)

_log "Removing remotes of temporary repos"
git remote remove frontend
git remote remove backend

cd - || exit 1

echo "Cleaning up temporary repos"
rm -rf "$tmp_frontend" "$tmp_backend" "$tmp_charts"

_log "Finished, enjoy your monorepo: $_monorepo_path"
