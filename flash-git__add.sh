#!/bin/bash
# flash-git version: 0

# $USER is empty

source /usr/share/flash-git/flash-git__fs.sh
source /usr/share/flash-git/flash-git__hw.sh

if [ ! $(id -u) -eq 0 ]
then
	echo Run this under ROOT only!
	exit 1
fi

tmpMounted=$(mktemp -d)
tmpHardware=$(mktemp)
tmpLog=$(mktemp)
detectHardwareForMedia $1 $tmpHardware
myMount $1 $tmpMounted
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
	rm -rf $workdir/root
	ln -s $tmpMounted/root $workdir/root # if do so git can not push ("can not create temporary file"). Make directory and copy instead.
	echo >> /usr/share/flash-git/log
	date >> /usr/share/flash-git/log
	#ls -lh $workdir >> /usr/share/flash-git/log
	while read -r line
	do
		tmp="$line"
		pushd "$tmp"
		echo "
$tmp:" >> /usr/share/flash-git/log
		git pull flash-git &> $tmpLog
		cat $tmpLog >> /usr/share/flash-git/log; echo -n > $tmpLog
		git push flash-git &> $tmpLog
		cat $tmpLog >> /usr/share/flash-git/log; echo -n > $tmpLog
		git pull flash-git &> $tmpLog
		cat $tmpLog >> /usr/share/flash-git/log; echo -n > $tmpLog
		popd # "$tmp"
	done < $workdir/repos
	rm $workdir/root
else
	echo "log about error"
fi


umount $tmpMounted
rm tmpLog
rm tmpHardware
rm -rf tmpMounted
