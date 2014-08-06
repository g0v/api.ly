docker run \
    -i \
    -t \
    --rm \
    --name lyapi-psql \
    --link lyapi-postgres:pg \
    lyapi-baseimage:latest \
    bash -c 'touch /root/.psql_history && \
             export PGPASSWORD=ly && \
             psql -h $PG_PORT_5432_TCP_ADDR \
                  -p $PG_PORT_5432_TCP_PORT \
                  -U ly'
