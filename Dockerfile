# uid 1000 and gid 1000, the same as user jenkins in Jenkins agents
ARG NFS_GRP=nfs_grp
ARG NFS_GID=1000
ARG NFS_USR=nfs_usr
ARG NFS_UID=1000
ARG IMAGE=itsthenetwork/nfs-server-alpine:latest

FROM $IMAGE

LABEL maintainer "Paulissoft <paulissoft@gmail.com>"
LABEL source "https://github.com/paulissoft/nfs-server-alpine"
LABEL branch "master"

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG NFS_GRP
ARG NFS_GID
ARG NFS_USR
ARG NFS_UID

COPY Dockerfile README.md /
COPY nfsd.sh /usr/bin/nfsd.sh
# COPY hosts.allow.txt hosts.deny /etc

ENV SHARED_DIRECTORY /nfs

RUN apk add --no-cache --update --verbose net-tools gettext && \
		chmod +x /usr/bin/nfsd.sh && \
		mkdir /nfs && \
		test -z "$NFS_GRP" || \
		test "${NFS_GID:=0}" -eq 0 || \
		test -z "$NFS_USR" || \
		test "${NFS_UID:=0}" -eq 0 || \
		addgroup --gid $NFS_GID $NFS_GRP && \
		adduser --no-create-home --disabled-password --gecos "" --uid $NFS_UID --ingroup $NFS_GRP $NFS_USR && \
		chown $NFS_USR:$NFS_GRP /nfs

