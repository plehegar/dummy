#!/bin/bash
set -exu
# e: Exit immediately if a command exits with a non-zero status
# x: Print commands and their arguments as they are executed
# u: Treat unset variables as an error when substituting

# FOLDER: env variable in your YML file to indicate the output directory
# GITHUB_TOKEN: env variable for ${{ secrets.GITHUB_TOKEN }} in your YML file

echo "FOLDER: ${FOLDER}"

# set the GitHub credentials and env
git config --global user.email noreply@unknown.w3.org
git config --global user.name w3cbot
git config --global user.password $GITHUB_TOKEN

REPO_URL="https://w3cbot:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git"

# Recreate some Travis CI env variables
TRAVIS_BRANCH=${GH_BRANCH:-$(echo $GITHUB_REF | awk 'BEGIN { FS = "/" } ; { print $3 }')}
TRAVIS_PULL_REQUEST=${GH_EVENT_NUMBER:-false}

echo "TRAVIS_BRANCH: ${TRAVIS_BRANCH}"
echo "TRAVIS_PULL_REQUEST: ${TRAVIS_PULL_REQUEST}"

echo Cleaning $FOLDER before building

MAIN=$PWD

rm -rf $FOLDER

echo Using $GITHUB_REPOSITORY

git clone $REPO_URL $FOLDER

cd $FOLDER

TARGET=$PWD
TARGET_BRANCH=gh-pages

git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH

cd $MAIN

# Place your build operations below
# new files should go into $TARGET

echo Now building the output in $TARGET

cp index.html ${TARGET}
cp redirect.html ${TARGET}

# End of building the

cd ${TARGET}

if [ $TRAVIS_PULL_REQUEST != "false" ]
then
  # this is a pull request so exit
  exit 0
fi

if [[ -z $(git status --porcelain) ]]; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

echo Add the changes

git add -A .

echo Commit the changes

git commit -m ":robot: Deploy to GitHub Pages: $GITHUB_SHA from branch \"$TRAVIS_BRANCH\""

echo Attempt to push

git push $REPO_URL $TARGET_BRANCH

echo done
