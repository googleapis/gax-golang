#!/bin/bash

# Fail on any error
set -eo pipefail

# Display commands being run
set -x

# Only run the linter on go1.11, since it needs type aliases (and we only care about its output once).
# TODO(deklerk) We should pass an environment variable from kokoro to decide this logic instead.
if [[ `go version` != *"go1.11"* ]]; then
    exit 0
fi

pwd

export GO111MODULE=on

# Fail if a dependency was added without the necessary go.mod/go.sum change
# being part of the commit.
go mod tidy
git diff go.mod | tee /dev/stderr | (! read)
git diff go.sum | tee /dev/stderr | (! read)

# Look at all .go files (ignoring .pb.go files) and make sure they have a Copyright. Fail if any don't.
git ls-files "*[^.pb].go" | xargs grep -L "\(Copyright [0-9]\{4,\}\)" 2>&1 | tee /dev/stderr | (! read)
gofmt -s -d -l . 2>&1 | tee /dev/stderr | (! read)
goimports -l . 2>&1 | tee /dev/stderr | (! read)

golint ./... 2>&1 | tee /dev/stderr | (! read)
staticcheck ./...
