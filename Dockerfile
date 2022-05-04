from alpine:latest

COPY dist/rebash-0.0.8-any.apk /tmp/

RUN apk add --allow-untrusted /tmp/rebash-0.0.8-any.apk

ENTRYPOINT [ "/bin/bash", "-c" ]

CMD [ "exec bash --init-file <(echo '. /usr/lib/rebash.sh') -i" ]
