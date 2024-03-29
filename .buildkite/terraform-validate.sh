#!/usr/bin/env bash

set -ex

cd "$(dirname "${BASH_SOURCE[0]}")"/..

MODULES=(
  ./modules/networking
  ./modules/docker-mirror
  ./modules/executors
  ./modules/credentials
  .
  ./examples/single-executor
  ./examples/private-single-executor
  ./examples/multiple-executors
)

for module in "${MODULES[@]}"; do
  pushd "${module}"
  terraform init
  terraform validate .
  popd
done
