#!/bin/bash

. settings.sh

DATE="$( date +%Y%m%d )"

export DOCKER_REPO="${DOCKER_REPO:-dblonski}"
export GO_VERSION="${GO_VERSION:-1.24}"
export TIMESCALE_VERSION="${TIMESCALE_VERSION:-2.25.0}"
export POSTGRES_VERSION="${POSTGRES_VERSION:-18}"
export PREV_IMAGE="$( cat PreviousImage )"

function build {
  docker build -t ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} \
    --build-arg DOCKER_REPO=${DOCKER_REPO} \
    --build-arg GO_VERSION=${GO_VERSION} \
    --build-arg PG_VERSION=${POSTGRES_VERSION} \
    --build-arg PREV_IMAGE=${PREV_IMAGE} \
    --build-arg TS_VERSION=${TIMESCALE_VERSION} \
    --no-cache \
    .
}

function tag_only {
  local POSTGRES_FULL_VERSION="$( docker run -it ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} psql --version | awk '{ print $3; }' | tr '\n\r' '  ' )"

  docker image tag \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_FULL_VERSION} && \
  docker image tag \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-latest
}

function publish {
  local POSTGRES_FULL_VERSION="$( docker run -it ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} psql --version | awk '{ print $3; }' | tr '\n\r' '  ' )"

  docker image tag \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_FULL_VERSION} && \
  docker image tag \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-${DATE} \
    ${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-latest && \

  local images=(
    "${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_FULL_VERSION}"
    "${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-latest"
    )

  for image in ${images[@]}; do
    docker image push ${image}
  done

  echo "${DOCKER_REPO}/timescaledb-plugins:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}-latest" > PreviousImage
}

if [[ $# -eq 0 ]]; then
  build
else
  while [[ $# -ne 0 ]]; do
    $1
    shift
  done
fi
