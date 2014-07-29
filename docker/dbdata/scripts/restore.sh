docker run \
    -i \
    -t \
    --rm \
    --name lyapi-restore \
    --volumes-from lyapi-dbdata \
    -v $(pwd)/backup:/backup \
    lyapi-baseimage:latest \
    bash -c 'tar xvf /backup/dbdata.tar'
