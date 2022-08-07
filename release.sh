#!/usr/bin/env bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Checking for clean working tree..."
if [[ "$(git diff --stat)" != "" ]]; then
  echo "❌ Dirty working tree (try git stash)"
  exit 1
fi

echo "Checking that we're on master..."
if [[ "$(git symbolic-ref HEAD | tr -d '\n')" != "refs/heads/master" ]]; then
  echo "❌ Not on master (try git checkout master)"
  exit 1
fi

echo "Checking that master is up to date..."
git fetch
if [[ "$(git rev-parse master)" != "$(git rev-parse origin/master)" ]]; then
  echo "❌ master is out of sync with origin/master (try git pull)"
  exit 1
fi

git ls-tree -r HEAD --name-only -z examples | xargs -0 sed -i.sedbak "s/\"[0-9]*\.[0-9]*\.[0-9]*\" # LATEST/\"$NEW\" # LATEST/g"
find . -name "*.sedbak" -print0 | xargs -0 rm

# Patch the image source. TODO: This has to write $MAJOR-$MINOR and not $NEW.
sed -i '' "s/\"sourcegraph-executors-docker-mirror-[0-9][0-9]*-[0-9][0-9]*\"/\"sourcegraph-executors-docker-mirror-$NEW\"/g" modules/docker-mirror/main.tf
sed -i '' "s/\"sourcegraph-executors-[0-9][0-9]*-[0-9][0-9]*\"/\"sourcegraph-executors-$NEW\"/g" modules/executors/main.tf

git commit --all --message "Release module version $NEW"
git push

echo ""
echo "✅ Released $NEW"
echo ""
echo "- Tags   : https://github.com/sourcegraph/terraform-google-executors/tags"
echo "- Commits: https://github.com/sourcegraph/terraform-google-executors/commits/master"
echo ""
echo "Make sure CI goes green 🟢:"
echo ""
echo "- https://buildkite.com/sourcegraph/terraform-google-executors/builds?branch=master"
echo "- https://buildkite.com/sourcegraph/terraform-google-executors/builds?branch=v$NEW"
