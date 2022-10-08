# nfs-server-alpine

A handy NFS Server image comprising Alpine Linux and NFS v4 only, over TCP on port 2049.

Based on [itsthenetwork/nfs-server-alpine](https://github.com/sjiveson/nfs-server-alpine) but with the addition of:
- Bring Your Own Exports (BYOE)
- Multiple shared directories below the root share

## Overview

See the [original documentation](https://github.com/sjiveson/nfs-server-alpine) with the additions below.

## Bring Your Own Exports (BYOE)

Attached to the container as a read-only Docker volume, the script `nfsd.sh` will not modify it. But it must be **read-only**.

Here two examples:

```
$ docker run -d --name nfs --privileged \
         -v /some/where/fileshare:/nfsshare \
         -v /path/to/my/exports:/etc/exports:ro \
         gpaulissen/nfs-server-alpine:latest
```

or

```
$ docker run -d --name nfs --privileged \
         -v /some/where/fileshare:/nfsshare \
         -v exports-volume:/etc/exports:ro \
         gpaulissen/nfs-server-alpine:latest
```

The Container folder `/nfsshare` is here intended as the NFS root share in the first line of the `/etc/exports`.

### Constructed by using environment variables

When you specify environment variables SHARED_DIRECTORY (mandatory), SHARED_DIRECTORY_2 (optional), SHARED_DIRECTORY_3 (optional) and so on, the script `nfsd.sh` will create `/etc/exports`.

```
$ docker run -d --name nfs --privileged \
         -v /some/where/fileshare:/nfsshare \
         -v /some/where/else2:/nfsshare/another2 \
         -v /some/where/else3:/nfsshare/another3 \
         -e SHARED_DIRECTORY=/nfsshare \
         -e SHARED_DIRECTORY_2=/nfsshare/another2 \
         -e SHARED_DIRECTORY_3=/nfsshare/another3 \
         gpaulissen/nfs-server-alpine:latest
```
