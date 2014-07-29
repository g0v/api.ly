docker run \
    -i \
    -t \
    --rm \
    --name lyapi-worker-sitting \
    --link lyapi-postgres:pg \
    lyapi-worker:latest \
    bash -c 'lsc app/calendar-sitting.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
