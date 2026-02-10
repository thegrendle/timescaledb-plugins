############################
# Build tools binaries in separate image
############################
ARG PG_VERSION
ARG TS_VERSION
ARG GO_VERSION=1.24
ARG PREV_IMAGE
ARG OSS_ONLY

FROM golang:${GO_VERSION}-alpine AS tools
ENV TOOLS_VERSION=0.17.0

RUN apk update && apk add --no-cache git \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@main \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@main


############################
# Grab old versions from previous version
###########################
FROM ${PREV_IMAGE} AS oldversion
RUN rm -f $( pg_config --sharedir )/extension/timescaledb*mock*.sql


############################
# Now build image and copy in tools
############################
FROM dblonski/postgresql-plugins:pg${PG_VERSION}-latest
LABEL maintainer="Timescale https://www.timescale.com"

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversion /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=oldversion /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

ARG TS_VERSION
RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        git \
        clang \
        clang-dev \
        openssl \
        openssl-dev \
        patch \
        tar \
    \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    && apk add --no-cache --virtual .build-deps \
        coreutils \
        dpkg-dev dpkg \
        gcc \
        krb5-dev \
        libc-dev \
        make \
        cmake \
        util-linux-dev \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
    \
    && if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
