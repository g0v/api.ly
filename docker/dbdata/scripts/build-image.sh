cp docker/dbdata/Dockerfile .
docker build -t 'lyapi-dbdata:latest' .
rm Dockerfile
