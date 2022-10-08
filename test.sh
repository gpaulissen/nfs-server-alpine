#!/bin/sh -eu
docker rm -f nfs || true

./build.sh

echo ""
echo "Starting nfs server"
echo ""

docker run -d --name nfs --privileged --volume nfs-server-alpine:/nfs gpaulissen/nfs-server-alpine:latest
sleep 1
docker logs nfs
