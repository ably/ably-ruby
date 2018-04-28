#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

failed="false"

bundle exec rubocop
if [ "$?" -eq "0" ]; then
  failed="true"
fi

"${DIR}/run_parallel_tests"
if [ "$?" -eq "0" ]; then
  failed="true"
fi

if [ $failed = "true" ]; then
  echo "Build failed!"
  exit 1
fi
