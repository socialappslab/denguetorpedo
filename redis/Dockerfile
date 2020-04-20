FROM bitnami/redis:4
MAINTAINER Cristhian Parra <cdparra@gmail.com>
USER root
RUN apt-get update
RUN apt-get install -y sudo nano
RUN sed -i '2s/^/source environment\n/' entrypoint.sh

