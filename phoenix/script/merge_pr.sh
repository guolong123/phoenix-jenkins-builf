#!/bin/bash
set -e -x
BRANCH=$1
PR=$2
echo "BRANCH     => " ${BRANCH}
echo "PR => " ${PR}

git rm --cached -r . > /dev/null
git reset --hard  > /dev/null
git checkout origin/${BRANCH}  #branch
# 合并 PR
if [ -n "$PR" ]; then
  for PR_NUMBER in ${PR}
  do
      PR_NAME="${BUILD_ID}_${PR_NUMBER}"
      git fetch origin pull/$PR_NUMBER/head:${PR_NAME}
      echo "FETCH PR ${PR_NUMBER} DONE."
      git merge $PR_NAME
      echo "MERGE PR ${PR_NUMBER} DONE."
  done
fi

