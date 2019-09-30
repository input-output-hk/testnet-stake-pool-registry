#!/bin/sh

set -e

NO_FETCH=
while true;
      do case "$1" in
                 -n | --no-fetch ) NO_FETCH=1; shift;;
                 -v | --verbose ) set -x; shift;;
                 * ) break; esac; done

. $(dirname $0)/lib.sh

show                       BUILDKITE_COMMAND
show                          BUILDKITE_REPO
show      BUILDKITE_PULL_REQUEST_BASE_BRANCH
show                       BUILDKITE_MESSAGE

show                        BUILDKITE_BRANCH
show                        BUILDKITE_COMMIT
show           BUILDKITE_BUILD_CHECKOUT_PATH

show                 BUILDKITE_BUILD_CREATOR
show           BUILDKITE_BUILD_CREATOR_EMAIL
show             BUILDKITE_PULL_REQUEST_REPO

banner "Validating environment.."

validateEnv                   BUILDKITE_COMMAND "nix-shell -p jq --run ./validate.sh"
validateEnv                      BUILDKITE_REPO "https://github.com/deepfire/registry"
# validateEnv  BUILDKITE_PULL_REQUEST_BASE_BRANCH "master"

banner "Validating Git history of the branch.."
set -u

test -z "${NO_FETCH}" &&
        git fetch origin master
validateGitHistory

banner "Checks passed."
