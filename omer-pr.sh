#!/bin/bash
#
# typical invocation:
#
#   omer-pr.sh < /tmp/prs.txt
#
# where prs.txt has the format "commit branch-name" e.g.
#
#   2a646234b86e6d74eca416ac55d241b46f80a3b0 c-bindings
#

set -eu -o pipefail

while read -r COMMIT BRANCH_NAME; do
    echo $COMMIT $BRANCH_NAME
    echo git switch main
    echo git switch -c $BRANCH_NAME
    echo git cherry-pick $COMMIT
    echo git push -u cunnie $BRANCH_NAME
    echo git request-pull main \
      https://github.com/cunnie/e2 $BRANCH_NAME
    COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $COMMIT)
    echo "Subject: [PULL REQUEST] $COMMIT_MESSAGE"
done
