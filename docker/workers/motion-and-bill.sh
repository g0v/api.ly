docker run \
    -i \
    -t \
    --rm \
    --name lyapi-worker-motion-and-bill \
    --link lyapi-postgres:pg \
    lyapi-worker:latest \
    bash -c 'lsc app/ys-misq.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
