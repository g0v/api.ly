docker run \
    -i \
    -t \
    --rm \
    --name psql \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'touch /root/.psql_history && \
             export PGPASSWORD=ly && \
             psql -h $PG_PORT_5432_TCP_ADDR \
                  -p $PG_PORT_5432_TCP_PORT \
                  -U ly'
