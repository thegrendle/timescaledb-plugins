#!/bin/bash

DATE="$( date +%Y%m%d )"
TIMESCALE_VERSION="${TIMESCALE_VERSION:-1.2.2}"
POSTGRES_VERSION="${POSTGRES_VERSION:-10}"

function build {
  docker build -t dblonski/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} \
    --build-arg TS_VERSION=${TIMESCALE_VERSION} \
    --build-arg PG_VERSION=${POSTGRES_VERSION} \
    --build-arg PREV_IMAGE=$( cat LastImage ) \
    . && \
  docker image tag dblonski/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} dblonski/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-latest
  echo dblonski/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} > LastImage
  git add LastImage
}

function publish {
  local images=(
    "dblonski/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE}"
    "dblonski/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-latest"
    )
  for image in ${images[@]}; do
    docker image push ${image}
  done
}

if [[ $# -eq 0 ]]; then
  build
else
  while [[ $# -ne 0 ]]; do
    $1
    shift
  done
fi
