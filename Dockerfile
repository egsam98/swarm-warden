FROM alpine:3.15.0
RUN apk add bash && \
    apk add coreutils && \
    apk add docker-cli && \
    apk add jq && \
    rm -rf /var/cache/apk/*

RUN mkdir scripts
COPY swarm-warden.sh /scripts
ENTRYPOINT ["/scripts/swarm-warden.sh"]