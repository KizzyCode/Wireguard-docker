FROM alpine:latest

RUN apk add --no-cache gettext iptables jq wireguard-tools

COPY ./files/wg0.conf.server-template /etc/wg0.conf.server-template
COPY ./files/wg0.conf.client-template /etc/wg0.conf.client-template
COPY ./files/start.sh /usr/libexec/start.sh

USER root
CMD [ "/usr/libexec/start.sh" ]
