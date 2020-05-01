#!/bin/bash
# flash-git version: 0

# $USER is empty

function detectHardwareForMedia {
    # arguments:
    #   1. device
    #   2. file path to write hardware info
    for i in idVendor idProduct serial product manufacturer
    do
        var=$(udevadm info -a -n $1 | grep -m1 "ATTRS{$i}" | sed "s/^.*==\"//" | sed "s/\"$//")
        echo "ID_$i=\"$var\"" >> $2
    done
}

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

tmpMounted=$(mktemp -d)
tmpHardware=$(mktemp)
tmpLog=$(mktemp)
detectHardwareForMedia $1 $tmpHardware
mount $1 -tvfat -o"iocharset=utf8" $tmpMounted
#cp $tmpMounted/alias /home/boris/
workdir=
pushd /usr/share/flash-git
for i in $(seq 100)
do
    if [ -d $i ]
    then
        if [[ $(cat $tmpMounted/alias) == $(cat $i/alias) ]] && cmp -s $tmpHardware $i/hardware
        then
            if cmp -s $i/repos $tmpMounted/repos
            then
                workdir=/usr/share/flash-git/$i
            else
                echo "log about error"
            fi
            break
        fi
    fi
done
popd # /usr/share/flash-git

if [ $workdir ]
then
    #ln -s $tmpMounted/root $workdir/root # if do so git can not push ("can not create temporary file"). Make directory and copy instead.
	cp -r -u -T $tmpMounted/root $workdir/root
    while read -r line
    do
        tmp="$line"
        pushd "$tmp"
		echo "
$tmp:" >> /usr/share/flash-git/log
        su root -c "git pull flash-git" &> $tmpLog
		cat $tmpLog >> /usr/share/flash-git/log; echo -n > $tmpLog
        su root -c "git push flash-git" &> $tmpLog
		cat $tmpLog >> /usr/share/flash-git/log; echo -n > $tmpLog
        su root -c "git pull flash-git" &> $tmpLog
		cat $tmpLog >> /usr/share/flash-git/log; echo -n > $tmpLog
        popd # "$tmp"
    done < $workdir/repos
	cp -r -u -T $workdir/root $tmpMounted/root
else
    echo "log about error"
fi


umount $tmpMounted
rm tmpLog
rm tmpHardware
rm -rf tmpMounted
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


