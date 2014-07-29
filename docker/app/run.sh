docker run \
    -i \
    -t \
    --rm \
    --name lyapi-app \
    -p 3000:3000 \
    --link lyapi-postgres:pg \
    lyapi-app:latest
