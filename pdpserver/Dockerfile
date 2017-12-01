#FROM alpine:latest
#RUN apk --update add bind-tools curl bash sudo iptables vim jq && rm -rf /var/cache/apk/*

FROM ubuntu:latest
RUN        apt-get -y update && \
           apt-get -y install sudo vim-tiny less iputils-ping iptables netcat dnsutils && \
           apt-get -y install curl jq && \
           rm -rf /var/lib/apt/lists/*

COPY pdpserver/docker-entrypoint.sh /usr/local/bin/
COPY build/pdpserver /usr/local/bin/
COPY build/papcli /usr/local/bin/
COPY build/pepcli /usr/local/bin/
COPY pdpserver/contacts-api-policy.yaml /

EXPOSE 5555 5554 5555/tcp 5554/tcp
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

