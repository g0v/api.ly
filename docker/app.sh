docker run \
    --rm \
    --name app \
    -p 3000:3000 \
    --expose=3000 \
    --link postgres:pg \
    api.ly:ubuntu.14.04 \
    bash -c 'lsc app/app.ls \
                 --host 0.0.0.0 \
                 --port 3000 \
                 --db tcp://ly:ly@$PG_PORT_5432_TCP_ADDR:$PG_PORT_5432_TCP_PORT/ly'
