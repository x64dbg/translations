#!/bin/bash

cp x64dbg.ts translations/
7z a qm.zip translations/*.qm
7z a ts.zip translations/*.ts

cp translations/*.ts translations_repo/
cd translations_repo

if [ $(git status --porcelain | wc -l) -eq 0 ]; then
    echo "No translation changes"
    exit 0
fi

git status

git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"

git add .
git commit -m "Translation update ($(date +'%Y-%m-%dT%H:%M:%S%z'))"
git push

gh config set prompt disabled
gh release delete -y translations
gh release create --title translations --notes translations translations ../qm.zip ../ts.zip