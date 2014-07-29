cp docker/postgres/Dockerfile .
docker build -t 'lyapi-postgres:latest' .
rm Dockerfile
