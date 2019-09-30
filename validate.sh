#!/bin/sh

. $(dirname $0)/lib.sh

show                        BUILDKITE_BRANCH
show                       BUILDKITE_COMMAND
show                        BUILDKITE_COMMIT
show           BUILDKITE_BUILD_CHECKOUT_PATH
show                 BUILDKITE_BUILD_CREATOR
show           BUILDKITE_BUILD_CREATOR_EMAIL
show       BUILDKITE_PIPELINE_DEFAULT_BRANCH
show             BUILDKITE_PULL_REQUEST_REPO
show      BUILDKITE_PULL_REQUEST_BASE_BRANCH
show                          BUILDKITE_REPO

echo

validate                   BUILDKITE_COMMAND "validate.sh"
validate   BUILDKITE_PIPELINE_DEFAULT_BRANCH
validate  BUILDKITE_PULL_REQUEST_BASE_BRANCH "master"
validate                      BUILDKITE_REPO "registry"

error "Failed."
