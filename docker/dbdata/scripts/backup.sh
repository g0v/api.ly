docker run \
    -i \
    -t \
    --rm \
    --name lyapi-backup \
    --volumes-from lyapi-dbdata \
    -v $(pwd)/backup:/backup \
    lyapi-baseimage:latest \
    bash -c 'tar cvf /backup/dbdata.tar /var/lib/postgresql \
                                        /var/log/postgresql \
                                        /etc/postgresql'
