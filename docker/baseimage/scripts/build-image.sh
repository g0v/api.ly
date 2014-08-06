cp docker/baseimage/Dockerfile .
docker build -t 'lyapi-baseimage:latest' .
rm Dockerfile
