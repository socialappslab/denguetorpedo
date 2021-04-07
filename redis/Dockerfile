FROM bitnami/redis:latest
MAINTAINER Cristhian Parra <cdparra@gmail.com>
USER root
RUN apt-get update
RUN apt-get install -y sudo nano
ENV ALLOW_EMPTY_PASSWORD=yes
RUN sed -i '2s/^/source environment\n/' /opt/bitnami/scripts/redis/entrypoint.sh
