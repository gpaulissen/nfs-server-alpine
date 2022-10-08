FROM itsthenetwork/nfs-server-alpine:latest

LABEL maintainer "Gert-Jan Paulissen <gertjan.paulissen@gmail.com>"
LABEL source "https://github.com/gpaulissen/nfs-server-alpine"
LABEL branch "master"

COPY Dockerfile README.md /
COPY nfsd.sh /usr/bin/nfsd.sh

RUN chmod +x /usr/bin/nfsd.sh

ENTRYPOINT ["/usr/bin/nfsd.sh"]
