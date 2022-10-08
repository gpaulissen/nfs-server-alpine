# nfs-server-alpine

A handy NFS Server image comprising Alpine Linux and NFS v4 only, over TCP on port 2049.

Based on [itsthenetwork/nfs-server-alpine](https://github.com/sjiveson/nfs-server-alpine) but with the addition of:
- Bring Your Own Exports (BYOE)
- Automatically add directories below the root shared directory

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

### Automatically add directories below the root shared directory

When there is **not** a **read-only** `/etc/exports` and when you specify environment variable SHARED_DIRECTORY, the script `nfsd.sh` will create `/etc/exports` with that directory as root shared directory. The directories below that root directory will be added automatically to the `/etc/exports` as well.

There is no more need of an environment variable like SHARED_DIRECTORY_2 as described in the [original documentation](https://github.com/sjiveson/nfs-server-alpine).

This command:

```
$ docker run -d --name nfs --privileged \
         -v /some/where/fileshare:/nfsshare \
         -v /some/where/else2:/nfsshare/another2 \
         -v /some/where/else3:/nfsshare/another3 \
         -e SHARED_DIRECTORY=/nfsshare \
         gpaulissen/nfs-server-alpine:latest
```

will create an `/etc/exports` with three lines. There may be more lines if `/some/where/fileshare` contains other subfolders than `another2 or `another3`.
