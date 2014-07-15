docker run \
    -i \
    -t \
    --rm \
    --name worker-sitting \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'lsc app/calendar-sitting.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
