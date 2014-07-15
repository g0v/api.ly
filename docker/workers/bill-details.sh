docker run \
    -i \
    -t \
    --rm \
    --name worker-bill-details \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'lsc app/bill-details.ls \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
