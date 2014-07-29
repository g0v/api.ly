docker run \
    -i \
    -t \
    --rm \
    --name lyapi-postgres \
    --volumes-from lyapi-dbdata \
    -p 5433:5432 \
    lyapi-postgres:latest
