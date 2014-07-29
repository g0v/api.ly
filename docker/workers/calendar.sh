docker run \
    -i \
    -t \
    --rm \
    --name lyapi-worker-calendar \
    --link lyapi-postgres:pg \
    lyapi-worker:latest \
    bash -c 'lsc app/populate-calendar.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
