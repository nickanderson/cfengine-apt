#!/usr/bin/env bash
set -ex

cfbs build

# find the dir two levels up from here, home of all the repositories
PROJECT_ROOT="$(readlink -e "$(dirname "$0")/../")"

# image to use, debian for apt
image=craigcomstock/cfengine:debian-agent

# to debug things inside the container as it "will be" run
#docker run -it -v "${PROJECT_ROOT}/out/masterfiles":/var/cfengine/inputs $image bash

# validate policy
docker run -v "${PROJECT_ROOT}/out/masterfiles":/var/cfengine/inputs $image sh -c "cf-promises"

# cfengine policy seems to create dirs owned by root:root even outside the container :( so fix it
# docker in github doesn't seem to honor creation of artifacts dirs for tap results as the right uid
# instead the artifacts directories end up being owned by root in the host and inaccessible
# locally on macos with docker desktop, no such issue exists, so test before `sudo chown` to avoid extra work for manual runs
me=$(whoami)

# run tests
while IFS= read -r -d '' test; do
  docker run -v "${PROJECT_ROOT}/out/masterfiles":/var/cfengine/inputs $image sh -c "cf-agent -KIf services/cfbs/$test"
  dir=$(dirname "out/masterfiles/services/cfbs/$test")
  artifacts="$dir/artifacts"
  owner=$(stat -c '%U' "$artifacts")
  if [ "$owner" != "$me" ]; then
    sudo chown -R "$me" "$artifacts"
  fi
done< <(find tests -name '*.cf' -type f -print0)

echo "### test results ###'
find out/masterfiles -name '*.tap' | xargs cat # just show all the results

echo "### errors? ###"
exit_code=0 # assume pass if no failures found
while IFS= read -r -d '' tap; do
  if grep "not ok" "$tap"; then
    exit_code=1
  fi
done< <(find out/masterfiles -name '*.tap' -type f -print0)


exit $exit_code
