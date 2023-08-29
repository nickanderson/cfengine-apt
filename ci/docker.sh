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
whoami

        ls -l | grep out
        ls -l out | grep masterfiles
        ls -l out/masterfiles | grep services
        ls -l out/masterfiles/services | grep cfbs
        ls -l out/masterfiles/services/cfbs | grep tests
        ls -l out/masterfiles/services/cfbs/tests | grep pin-package
        ls -l out/masterfiles/services/cfbs/tests/pin-package | grep artifacts
ls -l out/masterfiles/services/cfbs/tests/pin-package/artifacts
