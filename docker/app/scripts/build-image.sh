cp docker/app/Dockerfile .
docker build -t 'lyapi-app:latest' .
rm Dockerfile
