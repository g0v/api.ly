cp docker/workers/Dockerfile .
docker build -t 'lyapi-worker:latest' .
rm Dockerfile
