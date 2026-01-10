#!/bin/bash
set -x
BUILD_DATE=$(date +%Y%m%d-%H%M%S)

docker build -t kfk:${BUILD_DATE} -f image-kfk/kraft.dockerfile "${@}" image-kfk
res=$?
if [ 0 -ne "${res}" ]
then
	echo "Failed to build image-kfk, this should work first!"
else
	echo "IMG_KFK=kfk:${BUILD_DATE}" >.env
fi

