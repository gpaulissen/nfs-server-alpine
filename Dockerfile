# uid 1000 and gid 1000, the same as user jenkins in Jenkins agents
ARG NFS_GRP=nfs_grp
ARG NFS_GID=1000
ARG NFS_USR=nfs_usr
ARG NFS_UID=1000
ARG IMAGE=itsthenetwork/nfs-server-alpine:latest

FROM $IMAGE

LABEL maintainer "Gert-Jan Paulissen <gertjan.paulissen@gmail.com>"
LABEL source "https://github.com/gpaulissen/nfs-server-alpine"
LABEL branch "master"

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG NFS_GRP
ARG NFS_GID
ARG NFS_USR
ARG NFS_UID

COPY Dockerfile README.md /
COPY nfsd.sh /usr/bin/nfsd.sh

RUN chmod +x /usr/bin/nfsd.sh && \
		addgroup --gid $NFS_GID $NFS_GRP && \
		adduser --no-create-home --disabled-password --gecos "" --uid $NFS_UID --ingroup $NFS_GRP $NFS_USR && \
		mkdir /nfs && \
		chown $NFS_USR:$NFS_GRP /nfs

ENV SHARED_DIRECTORY /nfs
