docker run \
    -i \
    -t \
    --rm \
    --name worker-motion-and-bill \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'lsc app/ys-misq.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
