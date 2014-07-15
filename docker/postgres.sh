docker run \
    -i \
    -t \
    --rm \
    --name postgres \
    -p 5433:5432 api.ly:ubuntu.14.04 \
    bash -c "service postgresql start && \
             su - postgres -c 'pgqd /opt/ly/pgq.ini'"
