#!/bin/bash

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

if [[ ! -b --fake-device=fd1 ]]
then
	echo Please specify a device to set as your repository carrier
	exit 1
fi

#r=$(mktemp -d)
#pushd 
rm -rf /tmp/tmp.GgejCb/root
mkdir /tmp/tmp.GgejCb/root

pushd /tmp/tmp.GgejCb/root
pushd ..
if [ -z  ]
then
    mkdir root
    ln -s fakeDevices/fd1 root
else
    mount  /tmp/tmp.GgejCb/root
fi
for oRepo in  # boris e: read per-entire-line instead of split by space-symbols
do
	echo repo: 
    tmp=
    if [ ! -z sb2 ]
        tmp=/tmp/tmp.GgejCb/sandboxes/sb2/
    then
    fi
	pushd sandboxes/sb2/repo2
	git pull flash-git
	git push flash-git
	git pull flash-git
	popd
done
popd # ..
popd # /tmp/tmp.GgejCb/root

if [ -z  ]
then
    rm /tmp/tmp.GgejCb/root
else
    umount /tmp/tmp.GgejCb/root
    rm -rf /tmp/tmp.GgejCb/root
fi
#popd

