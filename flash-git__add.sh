#!/bin/bash
# flash-git version: 0

# $USER is empty

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

tmpMounted=$(mktemp -d)
mount $1 $tmpMounted
#cp $tmpMounted/alias /home/boris/
umount $tmpMounted
exit 0
#----------------------


#r=$(mktemp -d)
#pushd $r

if [ ! -d "/tmp/tmp.ePbJmb" ]
then
    echo flash-git config lost
    exit 1
fi

pushd "/tmp/tmp.ePbJmb"
rm -rf root
if [ -z "" ]
then
    #ln -s fakeDevices/fd1 root
    if [[ ! -r fakeDevices/"$1"/hardware ]]
    then
        echo Please specify a fake device to set as your repository carrier
        exit 1
    fi
    ln -s fakeDevices/"$1"/root root
else
    if [[ ! -b "$1" ]]
    then
        echo Please specify a device to set as your repository carrier
        exit 1
    fi
    mkdir root
    mount "$1" root
fi
if [ ! -r root/repos ]
then
    echo "\"repos\" not found"
    exit 1
fi
for oRepo in $(cat root/repos) # boris e: read per-entire-line instead of split by space-symbols
do
	echo "repo:  $oRepo"
    tmp="$oRepo"
    if [ ! -z "sb2" ]
    then
        tmp="/tmp/tmp.ePbJmb/sandboxes/"$2"/$oRepo"
    fi
    pushd "$tmp"
	git pull flash-git
	git push flash-git
	git pull flash-git
	popd
done
if [ -z "" ]
then
    rm root
else
    umount root
    rm -rf root
fi
popd # /tmp/tmp.ePbJmb


