#!/bin/bash

create_sql=$( mktemp )

POSTGRES_MAX_CONNECTIONS=${POSTGRES_MAX_CONNECTIONS:-200}

# Checks to support bitnami image with same scripts so they stay in sync
if [ ! -z "${BITNAMI_IMAGE_VERSION:-}" ]; then
        if [ -z "${POSTGRES_USER:-}" ]; then
                POSTGRES_USER=${POSTGRESQL_USERNAME}
        fi

        if [ -z "${POSTGRES_DB:-}" ]; then
                POSTGRES_DB=${POSTGRESQL_DATABASE}
        fi

        if [ -z "${PGDATA:-}" ]; then
                PGDATA=${POSTGRESQL_DATA_DIR}
        fi
fi

if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
        POSTGRESQL_CONF_DIR=${PGDATA}
fi

cat << EOF >> ${POSTGRESQL_CONF_DIR}/postgresql.conf
max_connections = ${POSTGRES_MAX_CONNECTIONS}
EOF


cat <<EOF >${create_sql}
ALTER ROLE ${POSTGRES_USER} CONNECTION LIMIT ${POSTGRES_MAX_CONNECTIONS};
EOF

psql -U "${POSTGRES_USER}" postgres -f "${create_sql}"
psql -U "${POSTGRES_USER}" template1 -f "${create_sql}"

if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
    psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -f "${create_sql}"
fi
rm -Rf "${create_sql}"
