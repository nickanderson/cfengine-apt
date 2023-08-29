#!/usr/bin/env bash
set -ex

cfbs build

# find the dir two levels up from here, home of all the repositories
PROJECT_ROOT="$(readlink -e "$(dirname "$0")/../")"

# image to use, debian for apt
image=craigcomstock/cfengine:debian-agent
name=test

# to debug things inside the container as it "will be" run
#docker run -it -v "${PROJECT_ROOT}/out/masterfiles":/var/cfengine/inputs $image bash

# validate policy
docker run -v "${PROJECT_ROOT}/out/masterfiles":/var/cfengine/inputs $image sh -c "cf-promises"

# run tests
for test in $(find tests -name '*.cf'); do
  docker run -v "${PROJECT_ROOT}/out/masterfiles":/var/cfengine/inputs $image sh -c "cf-agent -KIf services/cfbs/$test"
done

