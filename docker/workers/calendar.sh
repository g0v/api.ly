docker run \
    -i \
    -t \
    --rm \
    --name worker-calendar \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'lsc app/populate-calendar.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
