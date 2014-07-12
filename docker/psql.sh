docker run \
    -i \
    -t \
    --rm \
    --name app \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'touch /var/lib/postgresql/.psql_history && \
             export PGPASSWORD=ly && \
             psql -h $PG_PORT_5432_TCP_ADDR \
                  -p $PG_PORT_5432_TCP_PORT \
                  -U ly'
