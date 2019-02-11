###############################################################################
# Name:         Dockerfile
# Author:       Petr Hála
# Description:  Dockerfile used to build pehala/tinyproxy
###############################################################################

FROM alpine:3.9

MAINTAINER Daniel Middleton

RUN apk add --no-cache \
	bash \
	tinyproxy

RUN chmod 777 -R /etc/tinyproxy
RUN chmod 777 -R /var/log/tinyproxy

COPY run.sh /opt/docker-tinyproxy/run.sh

EXPOSE 8888

ENTRYPOINT ["/opt/docker-tinyproxy/run.sh"]
